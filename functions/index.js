'use strict';

/**
 * Backend Cloud Functions của app.
 * - taiKhoanApi: phần tài khoản dùng chung tối thiểu (OTP thử nghiệm, xác nhận người thật).
 * - troApi / troDinhKy / troCongBaoVe: module Tìm trọ.
 * - quanAnApi / quanAnDinhKy / quanAnHangDem / quanAnCongBaoVe: module Quán ăn.
 */

const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { setGlobalOptions } = require('firebase-functions/v2');

setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const TRO_CONG_BI_MAT = defineSecret('TRO_CONG_BI_MAT');
const TK_BI_MAT = defineSecret('TK_BI_MAT');
const QA_CONG_BI_MAT = defineSecret('QA_CONG_BI_MAT');

const troApi = require('./src/tro/api');
const troDinhKy = require('./src/tro/dinh_ky');
const cong = require('./src/tro/cong_gia_lap');
const quanAnApi = require('./src/quan_an/api');
const quanAnDinhKy = require('./src/quan_an/dinh_ky');
const congQuanAn = require('./src/quan_an/cong_gia_lap');
const tk = require('./src/tai_khoan/tai_khoan_service');
const { nguoiDung, uidTu } = require('./src/chung/tai_khoan');
const { thamSoSai } = require('./src/chung/loi');

exports.troApi = onCall({ secrets: [TRO_CONG_BI_MAT] }, (request) => troApi.xuLy(request, () => TRO_CONG_BI_MAT.value()));

exports.troDinhKy = onSchedule({ schedule: 'every 1 minutes', timeZone: 'Asia/Ho_Chi_Minh' }, async () => {
  await troDinhKy.chay();
});

/** Cổng thanh toán "báo về" (webhook). Chữ ký sai → 403, không đổi gì. */
exports.troCongBaoVe = onRequest({ secrets: [TRO_CONG_BI_MAT] }, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
  try {
    const banTin = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
    const kq = await cong.nhanBaoVe(banTin, req.get('x-chu-ky'), TRO_CONG_BI_MAT.value());
    return res.status(200).json({ ok: true, ...kq });
  } catch (e) {
    return res.status(e.code === 'permission-denied' ? 403 : 400).json({ ok: false, loi: e.message });
  }
});

// ---- Quán ăn ----
exports.quanAnApi = onCall({ secrets: [QA_CONG_BI_MAT] }, (request) => quanAnApi.xuLy(request, () => QA_CONG_BI_MAT.value()));

exports.quanAnDinhKy = onSchedule({ schedule: 'every 1 minutes', timeZone: 'Asia/Ho_Chi_Minh' }, async () => {
  await quanAnDinhKy.chay();
});

exports.quanAnHangDem = onSchedule({ schedule: '0 3 * * *', timeZone: 'Asia/Ho_Chi_Minh' }, async () => {
  await quanAnDinhKy.hangDem();
});

/** Cổng thanh toán giả lập của Quán ăn "báo về" (webhook). Chữ ký sai → 403, không đổi gì. */
exports.quanAnCongBaoVe = onRequest({ secrets: [QA_CONG_BI_MAT] }, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
  try {
    const banTin = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
    const kq = await congQuanAn.nhanBaoVe(banTin, req.get('x-chu-ky'), QA_CONG_BI_MAT.value());
    return res.status(200).json({ ok: true, ...kq });
  } catch (e) {
    return res.status(e.code === 'permission-denied' ? 403 : 400).json({ ok: false, loi: e.message });
  }
});

exports.taiKhoanApi = onCall({ secrets: [TK_BI_MAT] }, async (request) => {
  const { hanhDong, ...tham } = request.data || {};
  if (hanhDong === 'thietBi') return tk.thietBi(uidTu(request), tham);
  const { uid } = await nguoiDung(request);
  switch (hanhDong) {
    case 'guiOtp': return tk.guiOtp(uid, tham);
    case 'xacNhanOtp': return tk.xacNhanOtp(uid, tham);
    case 'guiXacThucDanhTinh': return tk.guiXacThucDanhTinh(uid, tham, TK_BI_MAT.value());
    case 'adminDuyetDanhTinh': return tk.adminDuyetDanhTinh(uid, tham);
    default: throw thamSoSai('Hành động không hợp lệ.');
  }
});
