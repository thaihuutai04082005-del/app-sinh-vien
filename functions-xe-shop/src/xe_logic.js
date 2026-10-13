// Quy tắc nghiệp vụ Xe dọn trọ (mục 3.3), không đụng Firestore để test được.
import { khongCoQuyen, loi, thamSoSai } from './loi.js';
import { chuoi, chuoiTuyChon, danhSachLink, motTrong, soDienThoai, soNguyen } from './kiem_tra.js';

export const LOAI_XE = ['xe_tai_nho', 'xe_ba_gac', 'xe_may'];
export const GIA_TOI_DA = 50_000_000;
/** Số yêu cầu chưa chốt (chờ báo giá / đã báo giá) tối đa của một sinh viên. */
export const YEU_CAU_CHO_TOI_DA = 5;
const NGAY = 86_400_000;

export function hoSoTaiXe(tham) {
  return {
    vehicleType: motTrong(tham.vehicleType, LOAI_XE, 'Loại xe'),
    area: chuoi(tham.area, 'Khu vực hoạt động', { max: 120 }),
    priceReference: chuoi(tham.priceReference, 'Bảng giá tham khảo', { max: 300 }),
    description: chuoiTuyChon(tham.description, 'Giới thiệu', 500),
  };
}

export function yeuCauMoi(tham, now) {
  const scheduledAt = tham.scheduledAt;
  if (!Number.isInteger(scheduledAt) || scheduledAt < now - 5 * 60_000 || scheduledAt > now + 90 * NGAY) {
    throw thamSoSai('Ngày giờ chuyển phải trong 90 ngày tới.');
  }
  return {
    driverId: chuoi(tham.driverId, 'Tài xế', { max: 128 }),
    fromAddress: chuoi(tham.fromAddress, 'Điểm đi', { max: 300 }),
    toAddress: chuoi(tham.toAddress, 'Điểm đến', { max: 300 }),
    contactPhone: soDienThoai(tham.contactPhone),
    note: chuoiTuyChon(tham.note, 'Ghi chú', 500),
    itemPhotos: danhSachLink(tham.itemPhotos, 'ảnh đồ đạc', { min: 1, max: 10 }),
    videos: danhSachLink(tham.videos, 'video', { max: 1 }),
    scheduledAt,
  };
}

/**
 * Bảng chuyển trạng thái: hành động → ai làm (user = sinh viên, driver = tài xế)
 * và từ trạng thái nào sang trạng thái nào.
 */
const CHUYEN = {
  baoGia: { ai: 'driver', tu: ['pending', 'quoted'], sang: 'quoted' },
  chapNhan: { ai: 'user', tu: ['quoted'], sang: 'confirmed' },
  batDau: { ai: 'driver', tu: ['confirmed'], sang: 'in_progress' },
  hoanThanh: { ai: 'driver', tu: ['in_progress'], sang: 'done' },
  huy: { ai: 'ca_hai', tu: ['pending', 'quoted', 'confirmed'], sang: 'cancelled' },
};

export const HANH_DONG_DON = Object.keys(CHUYEN);

/**
 * Các trường cần ghi khi `uid` làm `hanhDong` trên đơn `don`; ném lỗi nếu không được.
 * `lichSuMoi` là mục thêm vào lịch sử đơn.
 */
export function chuyenTrangThai(don, hanhDong, uid, tham, now) {
  const quy = CHUYEN[hanhDong];
  if (!quy) throw thamSoSai('Hành động không hợp lệ.');
  const vaiTro = uid === don.userId ? 'user' : uid === don.driverId ? 'driver' : null;
  if (!vaiTro || (quy.ai !== 'ca_hai' && quy.ai !== vaiTro)) throw khongCoQuyen();
  if (!quy.tu.includes(don.status)) throw loi('Đơn không còn ở trạng thái làm được việc này.');

  const ghi = { status: quy.sang };
  const lichSuMoi = { status: quy.sang, by: vaiTro, at: now };
  if (hanhDong === 'baoGia') {
    ghi.quotedPrice = soNguyen(tham.price, 'Giá báo', { min: 1000, max: GIA_TOI_DA });
    lichSuMoi.price = ghi.quotedPrice;
  }
  if (hanhDong === 'huy') {
    ghi.cancelledBy = vaiTro;
    ghi.cancelReason = chuoi(tham.reason, 'Lý do hủy', { max: 300 });
  }
  return { ghi, lichSuMoi };
}
