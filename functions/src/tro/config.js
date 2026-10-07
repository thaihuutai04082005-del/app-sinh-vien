'use strict';

/**
 * Các con số quy định của module Tìm trọ (đặc tả mục 2.16).
 * Không viết cứng con số ở nơi khác: mọi thời hạn, giới hạn lấy từ đây.
 *
 * Mọi khoảng thời gian tính bằng PHÚT để có thể rút ngắn khi test / demo:
 * admin ghi đè từng giá trị trong document Firestore `tro_cau_hinh/hien_hanh`.
 */
const GIO = 60;
const NGAY = 24 * GIO;

const MAC_DINH = Object.freeze({
  // Đăng tin
  anhToiThieu: 3,
  anhToiDa: 10,
  videoToiThieu: 1,
  videoToiDa: 2,
  nhaTroHetHanPhut: 30 * NGAY,
  nhaTroNhacTruocPhut: 3 * NGAY,
  videoCuPhut: 90 * NGAY,

  // Đặt cọc và thanh toán
  choThanhToanPhut: 15,
  cocToiDaSoThang: 1,
  nhanPhongSauItNhatPhut: 2 * GIO,
  nhanPhongToiDaPhut: 14 * NGAY,
  huyMienPhiPhut: 30,
  huyMienPhiSoLan: 2,
  huyMienPhiCuaSoPhut: 30 * NGAY,
  nhacTruocNhanPhongPhut: NGAY,

  // Yêu cầu thay đổi thời điểm nhận phòng
  doiPhaiTruocPhut: NGAY, // chỉ gửi khi còn > 24 giờ tới T
  doiCachLucGuiItNhatPhut: NGAY, // thời điểm mới >= lúc gửi + 24 giờ
  doiToiDaSauTBanDauPhut: 14 * NGAY,
  doiNhacSinhVienTruocHanPhut: 12 * GIO, // nhắc lúc T - 36 giờ
  chuTraLoiDoiPhut: NGAY,
  chuTraLoiDoiNhacConPhut: [6 * GIO, GIO],

  // Nhận phòng
  anHanKhongDenPhut: 3 * GIO,
  baoKhongDenDenPhut: 48 * GIO,
  phanDoiPhut: 12 * GIO,
  phanDoiNhacConPhut: 2 * GIO,
  khieuNaiDenPhut: 48 * GIO,
  nhacCuoiPhut: 24 * GIO,
  tuHoanTatPhut: 48 * GIO,

  // Khiếu nại, vi phạm
  chuTraLoiKhieuNaiPhut: 24 * GIO,
  khieuNaiCoKhanPhut: 72 * GIO,
  khieuNaiSaiSoLan: 3,
  khieuNaiSaiCuaSoPhut: 30 * NGAY,
  khoaCocPhut: 30 * NGAY,
  viPhamChuSoLan: 3,
  viPhamChuCuaSoPhut: 90 * NGAY,
  khoaDangTinPhut: 30 * NGAY,
  tyLeCamKetCuaSoPhut: 90 * NGAY,

  // Cọc trực tiếp
  cocTrucTiepNhacSauPhut: 3 * NGAY,
  daThueXacNhanPhut: 7 * NGAY,

  // Đánh giá
  danhGiaThoiHanPhut: 365 * NGAY,
  danhGiaKhieuNaiPhut: 30 * NGAY,
  danhGiaNhanXetToiThieu: 20,
  danhGiaAnhToiDa: 5,

  // Báo cáo
  baoCaoTaiKhoanToiThieuPhut: 7 * NGAY,
  baoCaoGanCoSoNguoi: 3,
  baoCaoAnTamSoLan: 3,
  baoCaoToiDaMoiNgay: 10,
  baoCaoSaiSoLan: 3,
  khoaBaoCaoPhut: 30 * NGAY,

  // Kháng nghị
  khangNghiTrongPhut: 7 * NGAY,
  khangNghiTraLoiPhut: 48 * GIO,
  khangNghiBangChungToiDa: 3,

  // Chat
  phanHoiTrongPhut: 24 * GIO,
  phanHoiCuaSoPhut: 30 * NGAY,

  // Vị trí
  gpsLechMet: 200,
  banKinhMet: [300, 500, 1000, 2000, 3000, 5000],

  // Cổng giả lập: khoảng chênh kỹ thuật khi hỏi lại cổng trước khi cho hết hạn
  congChenhGiay: 0,
});

const PHUT = 60 * 1000;

/** Gộp cấu hình mặc định với phần ghi đè (bỏ qua khóa lạ, sai kiểu). */
function gopCauHinh(ghiDe) {
  const kq = { ...MAC_DINH };
  if (ghiDe && typeof ghiDe === 'object') {
    for (const [k, v] of Object.entries(ghiDe)) {
      if (!(k in MAC_DINH)) continue;
      const goc = MAC_DINH[k];
      if (Array.isArray(goc)) {
        if (Array.isArray(v) && v.every((x) => typeof x === 'number')) kq[k] = v;
      } else if (typeof v === typeof goc) {
        kq[k] = v;
      }
    }
  }
  return Object.freeze(kq);
}

module.exports = { MAC_DINH, gopCauHinh, PHUT, GIO, NGAY };
