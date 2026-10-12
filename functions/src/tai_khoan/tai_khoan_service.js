'use strict';

/**
 * Phần tài khoản và xác nhận người thật TỐI THIỂU (đặc tả Phần 4) để module Tìm trọ chạy được:
 * - OTP số điện thoại bản THỬ NGHIỆM (mã cố định 123456, đúng ghi chú "OTP thử nghiệm khi demo"),
 *   có đủ giới hạn: 5 lần gửi / giờ, mã hết hạn 5 phút, sai 5 lần khóa 15 phút; mỗi số 1 tài khoản.
 * - Xác nhận người thật: theo quyết định của nhóm, CHƯA chụp CCCD / khuôn mặt trong app.
 *   Người dùng gửi họ tên + số CCCD; số CCCD chỉ lưu dạng băm (HMAC) + 4 số cuối; admin danh tính duyệt tay.
 */

const crypto = require('node:crypto');
const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, thamSoSai, khongCoQuyen } = require('../chung/loi');

const SO = Object.freeze({
  otpGuiMoiGio: 5, otpHieuLucPhut: 5, otpSaiToiDa: 5, otpKhoaPhut: 15, maThuNghiem: '123456',
});
const PHUT = 60 * 1000;

function chuanHoaSdt(s) {
  let x = String(s || '').replace(/[^0-9+]/g, '');
  if (x.startsWith('+84')) x = '0' + x.slice(3);
  if (x.startsWith('84') && x.length === 11) x = '0' + x.slice(2);
  return /^0\d{9}$/.test(x) ? x : null;
}

const bam = (s, biMat) => crypto.createHmac('sha256', biMat || 'chua-dat-bi-mat').update(String(s)).digest('hex');

async function guiOtp(uid, { sdt }) {
  const so = chuanHoaSdt(sdt);
  if (!so) throw thamSoSai('Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0).');
  const chan = await db.collection('danh_sach_chan').doc(`sdt_${so}`).get();
  if (chan.exists) throw loiNguoiDung('Số điện thoại này đã bị chặn.');
  const daCo = await db.collection('so_dien_thoai').doc(so).get();
  if (daCo.exists && daCo.get('uid') !== uid) throw loiNguoiDung('Số điện thoại này đã gắn với tài khoản khác.');
  const ref = db.collection('otp').doc(uid);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const o = s.exists ? s.data() : {};
    if (ms(o.khoaDen) > now) throw loiNguoiDung('Bạn nhập sai quá nhiều lần, thử lại sau 15 phút.');
    const lanGui = (o.lanGui || []).map(ms).filter((t) => t > now - 60 * PHUT);
    if (lanGui.length >= SO.otpGuiMoiGio) throw loiNguoiDung('Đã gửi mã quá 5 lần trong 1 giờ, thử lại sau.');
    tx.set(ref, {
      sdt: so, maBam: bam(SO.maThuNghiem, uid), hetHan: Timestamp.fromMillis(now + SO.otpHieuLucPhut * PHUT),
      soLanSai: 0, khoaDen: null, lanGui: [...lanGui, now].map((t) => Timestamp.fromMillis(t)),
    });
  });
  return { thuNghiem: true, goiY: 'Bản thử nghiệm: mã OTP là 123456.' };
}

async function xacNhanOtp(uid, { ma }) {
  const ref = db.collection('otp').doc(uid);
  const now = Date.now();
  const kq = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (!s.exists) throw loiNguoiDung('Hãy gửi mã OTP trước.');
    const o = s.data();
    if (ms(o.khoaDen) > now) throw loiNguoiDung('Bạn nhập sai quá nhiều lần, thử lại sau 15 phút.');
    if (ms(o.hetHan) < now) throw loiNguoiDung('Mã đã hết hạn, hãy gửi lại.');
    if (bam(String(ma || '').trim(), uid) !== o.maBam) {
      const sai = (o.soLanSai || 0) + 1;
      tx.update(ref, { soLanSai: sai, khoaDen: sai >= SO.otpSaiToiDa ? Timestamp.fromMillis(now + SO.otpKhoaPhut * PHUT) : null });
      return { loi: sai >= SO.otpSaiToiDa ? 'Sai 5 lần, khóa nhập mã 15 phút.' : `Mã không đúng (còn ${SO.otpSaiToiDa - sai} lần).` };
    }
    const refSo = db.collection('so_dien_thoai').doc(o.sdt);
    const so = await tx.get(refSo);
    if (so.exists && so.get('uid') !== uid) return { loi: 'Số điện thoại này đã gắn với tài khoản khác.' };
    const refXt = db.collection('xac_thuc').doc(uid);
    const xt = await tx.get(refXt);
    const sdtCu = xt.exists ? xt.get('sdt') : null;
    if (sdtCu && sdtCu !== o.sdt) tx.delete(db.collection('so_dien_thoai').doc(sdtCu));
    tx.set(refSo, { uid, luc: Timestamp.now() });
    tx.set(refXt, { sdt: o.sdt, sdtDaXacThuc: true, sdtXacThucLuc: Timestamp.now() }, { merge: true });
    tx.set(db.collection('users').doc(uid), { phone: o.sdt }, { merge: true });
    tx.delete(ref);
    return { ok: true, sdt: o.sdt };
  });
  if (kq.loi) throw loiNguoiDung(kq.loi);
  return kq;
}

async function guiXacThucDanhTinh(uid, { hoTen, soCccd, dongYXuLyDuLieu, camKet }, biMat) {
  const ten = String(hoTen || '').trim().replace(/\s+/g, ' ');
  const cccd = String(soCccd || '').replace(/\D/g, '');
  if (ten.length < 4) throw thamSoSai('Nhập họ tên đầy đủ như trên CCCD.');
  if (!/^\d{12}$/.test(cccd)) throw thamSoSai('Số CCCD gồm 12 chữ số.');
  if (!dongYXuLyDuLieu || !camKet) throw thamSoSai('Bạn cần đồng ý xử lý dữ liệu cá nhân và cam kết thông tin đúng sự thật.');
  const xt = await db.collection('xac_thuc').doc(uid).get();
  if (!xt.exists || !xt.get('sdtDaXacThuc')) throw loiNguoiDung('Hãy xác thực số điện thoại trước.');
  if (xt.get('danhTinh') === 'da_xac_thuc') return { ok: true, daXacThuc: true };
  const ma = bam(cccd, biMat);
  const chan = await db.collection('danh_sach_chan').doc(`cccd_${ma}`).get();
  if (chan.exists) throw loiNguoiDung('Số CCCD này không thể đăng ký.');
  const trung = await db.collection('xac_thuc').where('cccdBam', '==', ma).get();
  if (trung.docs.some((d) => d.id !== uid)) throw loiNguoiDung('Số CCCD này đã được dùng cho tài khoản khác.');
  await xt.ref.set({
    danhTinh: 'cho_duyet', hoTenKhai: ten, cccdBam: ma, cccd4: cccd.slice(-4), lyDoTuChoi: null,
    dongYXuLyDuLieuLuc: Timestamp.now(), camKetLuc: Timestamp.now(), guiDanhTinhLuc: Timestamp.now(),
  }, { merge: true });
  return { ok: true };
}

async function adminDuyetDanhTinh(adminUid, { uid, dongY, lyDo }) {
  const a = await db.collection('admins').doc(adminUid).get();
  if (!a.exists || !a.get('danhTinh')) throw khongCoQuyen();
  const ref = db.collection('xac_thuc').doc(uid);
  const s = await ref.get();
  if (!s.exists || s.get('danhTinh') !== 'cho_duyet') throw loiNguoiDung('Hồ sơ không còn chờ duyệt.');
  await ref.update(dongY
    ? { danhTinh: 'da_xac_thuc', hoTenXacThuc: s.get('hoTenKhai'), duyetBoi: adminUid, duyetLuc: Timestamp.now() }
    : { danhTinh: 'tu_choi', lyDoTuChoi: String(lyDo || 'Thông tin không khớp'), duyetBoi: adminUid, duyetLuc: Timestamp.now() });
  await db.collection('nhat_ky_danh_tinh').add({ adminUid, viec: dongY ? 'duyet' : 'tu_choi', uid, luc: Timestamp.now() });
  return { ok: true };
}

/** Lưu / xóa mã nhận thông báo đẩy của thiết bị (đăng xuất thì xóa). */
async function thietBi(uid, { token, xoa }) {
  if (typeof token !== 'string' || token.length < 10) throw thamSoSai();
  const ref = db.collection('thiet_bi').doc(bam(token, 'thiet-bi'));
  if (xoa) await ref.delete();
  else await ref.set({ uid, token, capNhatLuc: Timestamp.now() });
  return { ok: true };
}

module.exports = { SO, chuanHoaSdt, guiOtp, xacNhanOtp, guiXacThucDanhTinh, adminDuyetDanhTinh, thietBi };
