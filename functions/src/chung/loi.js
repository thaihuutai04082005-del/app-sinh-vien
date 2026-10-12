'use strict';

const { HttpsError } = require('firebase-functions/v2/https');

/** Lỗi nghiệp vụ hiện cho người dùng (tiếng Việt). */
function loiNguoiDung(thongDiep, ma = 'failed-precondition') {
  return new HttpsError(ma, thongDiep);
}

const canDangNhap = () => loiNguoiDung('Vui lòng đăng nhập để tiếp tục.', 'unauthenticated');
const khongCoQuyen = () => loiNguoiDung('Bạn không có quyền làm việc này.', 'permission-denied');
const khongTimThay = (cai = 'Dữ liệu') => loiNguoiDung(`${cai} không tồn tại hoặc đã bị xóa.`, 'not-found');
const thamSoSai = (thongDiep = 'Thông tin gửi lên không hợp lệ.') => loiNguoiDung(thongDiep, 'invalid-argument');

module.exports = { loiNguoiDung, canDangNhap, khongCoQuyen, khongTimThay, thamSoSai, HttpsError };
