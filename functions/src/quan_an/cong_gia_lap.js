'use strict';

/**
 * Cổng thanh toán GIẢ LẬP của module Quán ăn (thay cho PayPal / MoMo sandbox, mục 3.6).
 * Mô phỏng đúng cách một cổng thật làm việc: cổng ghi nhận giao dịch + giờ ghi nhận; báo về hệ thống bằng bản tin
 * có CHỮ KÝ HMAC-SHA256 (khóa bí mật chỉ server biết: `firebase functions:secrets:set QA_CONG_BI_MAT`); hệ thống chỉ
 * ghi nhận "đã thanh toán" khi chữ ký hợp lệ, báo 2 lần chỉ nhận lần đầu. Thay cổng thật chỉ cần đổi phần này.
 */

const crypto = require('node:crypto');
const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen } = require('../chung/loi');
const { COL } = require('./ho_tro');
const { chayTrenDon } = require('./don_mon_service');

function kyBanTin(banTin, biMat) {
  return crypto.createHmac('sha256', biMat).update(banTin).digest('hex');
}

function chuKyHopLe(banTin, chuKy, biMat) {
  if (typeof chuKy !== 'string' || !/^[0-9a-f]{64}$/.test(chuKy)) return false;
  const dung = Buffer.from(kyBanTin(banTin, biMat), 'hex');
  const nhan = Buffer.from(chuKy, 'hex');
  return dung.length === nhan.length && crypto.timingSafeEqual(dung, nhan);
}

/** Hệ thống nhận bản tin cổng báo về. Chữ ký sai → từ chối, không đổi gì. `banTin`: { donId, maGiaoDich, trangThai, ghiNhanLuc }. */
async function nhanBaoVe(banTin, chuKy, biMat) {
  if (!biMat || !chuKyHopLe(banTin, chuKy, biMat)) throw loiNguoiDung('Chữ ký thanh toán không hợp lệ.', 'permission-denied');
  let tin;
  try { tin = JSON.parse(banTin); } catch (e) { throw loiNguoiDung('Bản tin thanh toán không hợp lệ.', 'invalid-argument'); }
  const refTien = db.collection(COL.khoanTien).doc(tin.donId);
  // Chống ghi nhận 2 lần: đánh dấu mã giao dịch trên khoản tiền (chỉ lần đầu được nhận).
  const laLanDau = await db.runTransaction(async (tx) => {
    const tien = await tx.get(refTien);
    if (!tien.exists) throw khongTimThay('Khoản tiền');
    if (tien.get('maGiaoDichCong')) return false;
    tx.update(refTien, { maGiaoDichCong: tin.maGiaoDich, congBaoVeLuc: Timestamp.now(), congGhiNhanLuc: tin.ghiNhanLuc ? Timestamp.fromMillis(tin.ghiNhanLuc) : null });
    return true;
  });
  if (!laLanDau) return { boQua: true };
  const su = tin.trangThai === 'thanh_cong' ? { loai: 'THANH_TOAN_OK', ghiNhanLuc: tin.ghiNhanLuc } : { loai: 'THANH_TOAN_LOI' };
  return chayTrenDon(tin.donId, { su, nguoiLam: { vaiTro: 'he_thong' } });
}

/**
 * Người dùng bấm thanh toán trên trang cổng giả lập. `ketQua`: 'thanh_cong' | 'that_bai'.
 * Chỉ người trả của đơn được thanh toán. `treBaoVeGiay` (chỉ admin, để test): cổng ghi nhận ngay nhưng báo về chậm vài giây.
 */
async function thanhToan({ uid, laAdmin }, { donId, ketQua, treBaoVeGiay = 0 }, biMat) {
  const refCong = db.collection(COL.cong).doc(String(donId || ''));
  const now = Date.now();
  const maGiaoDich = `GL${now}${crypto.randomInt(1000, 9999)}`;
  const banTin = await db.runTransaction(async (tx) => {
    const snap = await tx.get(refCong);
    if (!snap.exists) throw khongTimThay('Phiên thanh toán');
    const cong = snap.data();
    if (cong.nguoiTra !== uid) throw khongCoQuyen();
    if (cong.trangThai !== 'cho') return null; // bấm 2 lần: không trừ tiền 2 lần
    const thanhCong = ketQua === 'thanh_cong';
    tx.update(refCong, { trangThai: thanhCong ? 'thanh_cong' : 'that_bai', maGiaoDich, ghiNhanLuc: Timestamp.fromMillis(now) });
    return JSON.stringify({ donId, maGiaoDich, trangThai: thanhCong ? 'thanh_cong' : 'that_bai', ghiNhanLuc: now });
  });
  if (!banTin) return { daThanhToan: true };
  const tre = laAdmin ? Math.min(Math.max(Number(treBaoVeGiay) || 0, 0), 20) : 0;
  if (tre) await new Promise((r) => setTimeout(r, tre * 1000));
  const kq = await nhanBaoVe(banTin, kyBanTin(banTin, biMat), biMat);
  return { maGiaoDich, ...kq };
}

/** Xem lại phiên cổng (để hiện trang thanh toán). */
async function xemPhien(uid, donId) {
  const [cong, don] = await Promise.all([db.collection(COL.cong).doc(String(donId || '')).get(), db.collection(COL.don).doc(String(donId || '')).get()]);
  if (!cong.exists || !don.exists) throw khongTimThay('Phiên thanh toán');
  if (cong.get('nguoiTra') !== uid) throw khongCoQuyen();
  const tien = await db.collection(COL.khoanTien).doc(donId).get();
  return {
    donId, soTien: cong.get('soTien'), trangThai: cong.get('trangThai'), ghiNhanLuc: ms(cong.get('ghiNhanLuc')),
    tenQuan: don.get('tenQuan'), trangThaiDon: don.get('status'), trangThaiTien: tien.exists ? tien.get('trangThai') : null, hanThanhToan: ms(don.get('hanThanhToan')),
  };
}

module.exports = { kyBanTin, chuKyHopLe, nhanBaoVe, thanhToan, xemPhien };
