// Đánh giá dùng chung Shop + Xe dọn trọ: collection `reviews` (mục 7.3), không đụng Firestore để test được.
import { chuoiTuyChon, danhSachLink, diemSao } from './kiem_tra.js';

/** Tiêu chí chấm sao: khóa trong `ratingDetail` → tên hiện cho người dùng. */
export const TIEU_CHI_SHOP = { quality: 'Chất lượng sản phẩm', accuracy: 'Đúng mô tả', service: 'Thái độ shop' };
export const TIEU_CHI_XE = { attitude: 'Thái độ', punctuality: 'Đúng giờ', priceAccuracy: 'Giá đúng như báo' };

/** Kiểm tra điểm từng tiêu chí, lời nhận xét, ảnh; `rating` là trung bình các tiêu chí, làm tròn 1 chữ số. */
export function noiDungDanhGia(tham, tieuChi) {
  const chiTiet = tham.ratingDetail ?? {};
  const ratingDetail = {};
  for (const [khoa, ten] of Object.entries(tieuChi)) ratingDetail[khoa] = diemSao(chiTiet[khoa], ten);
  const diem = Object.values(ratingDetail);
  return {
    rating: Math.round((diem.reduce((a, b) => a + b, 0) / diem.length) * 10) / 10,
    ratingDetail,
    comment: chuoiTuyChon(tham.comment, 'Nhận xét', 1000),
    images: danhSachLink(tham.images, 'ảnh', { max: 5 }),
  };
}

