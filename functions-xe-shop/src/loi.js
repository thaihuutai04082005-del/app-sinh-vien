import { HttpsError } from 'firebase-functions/v2/https';

/** Lỗi nghiệp vụ, câu tiếng Việt hiện thẳng cho người dùng. */
export const loi = (thongDiep, ma = 'failed-precondition') => new HttpsError(ma, thongDiep);
export const thamSoSai = (thongDiep = 'Thông tin gửi lên không hợp lệ.') => loi(thongDiep, 'invalid-argument');
export const khongCoQuyen = () => loi('Bạn không có quyền làm việc này.', 'permission-denied');
export const khongTimThay = (cai) => loi(`${cai} không tồn tại hoặc đã bị xóa.`, 'not-found');
