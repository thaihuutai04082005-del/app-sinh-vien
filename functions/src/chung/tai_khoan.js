'use strict';

const { db } = require('./firebase');
const { canDangNhap, khongCoQuyen, loiNguoiDung } = require('./loi');

/**
 * Phần dùng chung DUY NHẤT giữa các module (đặc tả Phần 4): tài khoản và xác nhận người thật.
 * Collection `xac_thuc/{uid}` chỉ Cloud Functions ghi; `admins/{uid}` do người quản trị
 * dự án tạo trực tiếp trong Firebase Console.
 */
async function docXacThuc(uid) {
  const snap = await db.collection('xac_thuc').doc(uid).get();
  return snap.exists ? snap.data() : {};
}

async function docAdmin(uid) {
  const snap = await db.collection('admins').doc(uid).get();
  return snap.exists ? snap.data() : {};
}

function uidTu(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw canDangNhap();
  if (request.auth.token && request.auth.token.firebase && request.auth.token.firebase.sign_in_provider === 'anonymous') {
    throw canDangNhap();
  }
  return uid;
}

/** Người dùng đăng nhập, không bị khóa cả tài khoản. Trả về { uid, xacThuc }. */
async function nguoiDung(request) {
  const uid = uidTu(request);
  const xacThuc = await docXacThuc(uid);
  if (xacThuc.khoaTaiKhoan) throw loiNguoiDung('Tài khoản của bạn đã bị khóa.', 'permission-denied');
  return { uid, xacThuc };
}

/** Bắt buộc đã xác thực số điện thoại bằng OTP (mục 4.1). */
function canOtp(xacThuc) {
  if (!xacThuc.sdtDaXacThuc || !xacThuc.sdt) {
    throw loiNguoiDung('Bạn cần xác thực số điện thoại (OTP) trước.', 'failed-precondition');
  }
  return xacThuc.sdt;
}

/** Bắt buộc đã xác nhận người thật (mục 4.2) — với chủ trọ khi gửi duyệt. */
function canDanhTinh(xacThuc) {
  if (xacThuc.danhTinh !== 'da_xac_thuc') {
    throw loiNguoiDung('Bạn cần xác nhận người thật (danh tính) trước khi gửi duyệt.', 'failed-precondition');
  }
}

async function canAdmin(uid, quyen) {
  const a = await docAdmin(uid);
  if (!a[quyen]) throw khongCoQuyen();
  return a;
}

module.exports = { docXacThuc, docAdmin, uidTu, nguoiDung, canOtp, canDanhTinh, canAdmin };
