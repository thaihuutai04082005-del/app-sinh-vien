// Quy tắc nghiệp vụ Xe dọn trọ (mục 3.3), không đụng Firestore để test được.
import { khongCoQuyen, loi, thamSoSai } from './loi.js';
import { chuoi, chuoiTuyChon, danhSachLink, motTrong, soDienThoai, soNguyen } from './kiem_tra.js';

export const LOAI_XE = ['xe_tai_nho', 'xe_ba_gac', 'xe_may'];
export const GIA_TOI_DA = 50_000_000;
/** Số yêu cầu chưa chốt (chờ báo giá / đã báo giá) tối đa của một sinh viên. */
export const YEU_CAU_CHO_TOI_DA = 5;
const NGAY = 86_400_000;

/** Biển số Việt Nam, viết hoa, bỏ khoảng trắng thừa: "59-C1 234.56", "51F12345". */
export function bienSo(v) {
  const s = String(v ?? '').trim().toUpperCase().replace(/\s+/g, ' ');
  if (!/^\d{2}[A-Z]{1,2}[- ]?\d{0,2}[- ]?[\d.]{4,6}$/.test(s.replace(/ /g, ''))) {
    throw thamSoSai('Biển số xe không hợp lệ (VD: 59C1-234.56).');
  }
  return s;
}

/** Giá không bắt buộc: null hoặc số nguyên trong khoảng. */
function giaTuyChon(v, ten, min, max) {
  return v == null || v === '' ? null : soNguyen(v, ten, { min, max });
}

/**
 * Bảng giá tham khảo (mục 3.3): theo chuyến, theo km, theo giờ (chỉ khuân vác) — có ít nhất một
 * để sinh viên so sánh; `priceReference` là ghi chú thêm.
 */
export function bangGia(tham) {
  const gia = {
    priceTrip: giaTuyChon(tham.priceTrip, 'Giá theo chuyến', 10_000, GIA_TOI_DA),
    pricePerKm: giaTuyChon(tham.pricePerKm, 'Giá theo km', 1000, 1_000_000),
    priceHourly: giaTuyChon(tham.priceHourly, 'Giá theo giờ', 10_000, 5_000_000),
  };
  if (Object.values(gia).every((g) => g == null)) {
    throw thamSoSai('Nhập ít nhất một mức giá: theo chuyến, theo km hoặc theo giờ.');
  }
  return { ...gia, priceReference: chuoiTuyChon(tham.priceReference, 'Ghi chú giá', 300) };
}

export function hoSoTaiXe(tham) {
  return {
    hoSo: {
      vehicleType: motTrong(tham.vehicleType, LOAI_XE, 'Loại xe'),
      licensePlate: bienSo(tham.licensePlate),
      vehiclePhotos: danhSachLink(tham.vehiclePhotos, 'ảnh xe', { min: 1, max: 4 }),
      area: chuoi(tham.area, 'Khu vực hoạt động', { max: 120 }),
      ...bangGia(tham),
      description: chuoiTuyChon(tham.description, 'Giới thiệu', 500),
    },
    giayTo: { licensePhotos: danhSachLink(tham.licensePhotos, 'ảnh bằng lái', { min: 1, max: 2 }) },
  };
}

/** Các trường admin đã xem khi duyệt; đổi một trong số này thì phải duyệt lại. */
const TRUONG_CAN_DUYET = ['vehicleType', 'licensePlate', 'vehiclePhotos'];

/**
 * Trạng thái duyệt sau khi tài xế lưu hồ sơ: hồ sơ mới, bị từ chối, hoặc đổi xe / giấy tờ thì chờ duyệt;
 * chỉ sửa khu vực, bảng giá, giới thiệu thì giữ "đã duyệt".
 */
export function trangThaiDuyetSauKhiLuu(cu, giayToCu, moi) {
  if (!cu || cu.approval !== 'approved') return 'pending';
  const doi = TRUONG_CAN_DUYET.some((k) => JSON.stringify(cu[k] ?? null) !== JSON.stringify(moi.hoSo[k]))
    || JSON.stringify(giayToCu?.licensePhotos ?? null) !== JSON.stringify(moi.giayTo.licensePhotos);
  return doi ? 'pending' : 'approved';
}

/** Admin duyệt / từ chối hồ sơ đang chờ. Từ chối phải có lý do. */
export function ketQuaDuyet(hoSo, tham) {
  if (!hoSo) throw loi('Hồ sơ tài xế không tồn tại.', 'not-found');
  if (hoSo.approval !== 'pending') throw loi('Hồ sơ này không còn chờ duyệt.');
  if (typeof tham.dongY !== 'boolean') throw thamSoSai();
  return tham.dongY
    ? { approval: 'approved', rejectReason: null }
    : { approval: 'rejected', rejectReason: chuoi(tham.lyDo, 'Lý do từ chối', { max: 300 }) };
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
  // Chuyến xong thì không giữ vị trí tài xế nữa (đang chuyển thì không hủy được).
  if (quy.sang === 'done') ghi.driverLastLocation = null;
  return { ghi, lichSuMoi };
}
