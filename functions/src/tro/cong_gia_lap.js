'use strict';

/**
 * Cổng thanh toán GIẢ LẬP của module Tìm trọ (thay cho PayPal / MoMo sandbox, mục 2.6).
 *
 * Mô phỏng đúng cách một cổng thật làm việc với app:
 *  1. Cổng ghi nhận giao dịch (thành công / thất bại) và giờ ghi nhận.
 *  2. Cổng "báo về" hệ thống bằng một bản tin có CHỮ KÝ HMAC-SHA256 (khóa bí mật chỉ
 *     server biết, đặt qua `firebase functions:secrets:set TRO_CONG_BI_MAT`).
 *  3. Hệ thống chỉ ghi nhận "đã thanh toán" khi chữ ký hợp lệ; báo 2 lần chỉ nhận lần đầu.
 * Sau này thay bằng cổng thật chỉ cần đổi phần 1–2, luồng khoản cọc giữ nguyên.
 */

const crypto = require('node:crypto');
const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen } = require('../chung/loi');
const { COL, chayTrenKhoanCoc } = require('./dat_coc_service');

function kyBanTin(banTin, biMat) {
  return crypto.createHmac('sha256', biMat).update(banTin).digest('hex');
}

function chuKyHopLe(banTin, chuKy, biMat) {
  if (typeof chuKy !== 'string' || !/^[0-9a-f]{64}$/.test(chuKy)) return false;
  const dung = Buffer.from(kyBanTin(banTin, biMat), 'hex');
  const nhan = Buffer.from(chuKy, 'hex');
  return dung.length === nhan.length && crypto.timingSafeEqual(dung, nhan);
}

/**
 * Hệ thống nhận bản tin cổng báo về. Chữ ký sai → từ chối, không đổi gì.
 * `banTin` là chuỗi JSON nguyên văn: { datCocId, maGiaoDich, trangThai, ghiNhanLuc }.
 */
async function nhanBaoVe(banTin, chuKy, biMat) {
  if (!biMat || !chuKyHopLe(banTin, chuKy, biMat)) {
    throw loiNguoiDung('Chữ ký thanh toán không hợp lệ.', 'permission-denied');
  }
  let tin;
  try {
    tin = JSON.parse(banTin);
  } catch (e) {
    throw loiNguoiDung('Bản tin thanh toán không hợp lệ.', 'invalid-argument');
  }
  const refTien = db.collection(COL.khoanTien).doc(tin.datCocId);
  // Chống ghi nhận 2 lần: đánh dấu mã giao dịch trên khoản tiền (chỉ lần đầu được nhận).
  const laLanDau = await db.runTransaction(async (tx) => {
    const tien = await tx.get(refTien);
    if (!tien.exists) throw khongTimThay('Khoản tiền');
    const daNhan = tien.get('maGiaoDichCong');
    if (daNhan) return false;
    tx.update(refTien, {
      maGiaoDichCong: tin.maGiaoDich,
      congBaoVeLuc: Timestamp.now(),
      congGhiNhanLuc: tin.ghiNhanLuc ? Timestamp.fromMillis(tin.ghiNhanLuc) : null,
    });
    return true;
  });
  if (!laLanDau) return { boQua: true };
  const su = tin.trangThai === 'thanh_cong'
    ? { loai: 'THANH_TOAN_OK', ghiNhanLuc: tin.ghiNhanLuc }
    : { loai: 'THANH_TOAN_LOI' };
  return chayTrenKhoanCoc(tin.datCocId, { su, nguoiLam: { vaiTro: 'he_thong' } });
}

/**
 * Người dùng bấm thanh toán trên trang cổng giả lập (TRO-SV-16).
 * `ketQua`: 'thanh_cong' | 'that_bai'. Chỉ người trả của khoản cọc được thanh toán.
 * `treBaoVeGiay` (chỉ admin, để test): cổng ghi nhận ngay nhưng báo về chậm vài giây.
 */
async function thanhToan({ uid, laAdmin }, { datCocId, ketQua, treBaoVeGiay = 0 }, biMat) {
  const refCong = db.collection(COL.cong).doc(datCocId);
  const now = Date.now();
  const maGiaoDich = `GL${now}${crypto.randomInt(1000, 9999)}`;
  const banTin = await db.runTransaction(async (tx) => {
    const snap = await tx.get(refCong);
    if (!snap.exists) throw khongTimThay('Phiên thanh toán');
    const cong = snap.data();
    if (cong.nguoiTra !== uid) throw khongCoQuyen();
    if (cong.trangThai !== 'cho') {
      // Bấm thanh toán 2 lần: không trừ tiền 2 lần, trả lại kết quả cũ.
      return null;
    }
    const thanhCong = ketQua === 'thanh_cong';
    tx.update(refCong, {
      trangThai: thanhCong ? 'thanh_cong' : 'that_bai',
      maGiaoDich,
      ghiNhanLuc: Timestamp.fromMillis(now),
    });
    return JSON.stringify({ datCocId, maGiaoDich, trangThai: thanhCong ? 'thanh_cong' : 'that_bai', ghiNhanLuc: now });
  });
  if (!banTin) return { daThanhToan: true };
  const tre = laAdmin ? Math.min(Math.max(Number(treBaoVeGiay) || 0, 0), 20) : 0;
  if (tre) await new Promise((r) => setTimeout(r, tre * 1000));
  const chuKy = kyBanTin(banTin, biMat);
  const kq = await nhanBaoVe(banTin, chuKy, biMat);
  return { maGiaoDich, ...kq };
}

/** Xem lại phiên cổng (để hiện trang thanh toán). */
async function xemPhien(uid, datCocId) {
  const snap = await db.collection(COL.cong).doc(datCocId).get();
  if (!snap.exists) throw khongTimThay('Phiên thanh toán');
  if (snap.get('nguoiTra') !== uid) throw khongCoQuyen();
  const c = snap.data();
  return { soTien: c.soTien, trangThai: c.trangThai, ghiNhanLuc: ms(c.ghiNhanLuc) };
}

module.exports = { kyBanTin, chuKyHopLe, nhanBaoVe, thanhToan, xemPhien };
