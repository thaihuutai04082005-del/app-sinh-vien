'use strict';

/**
 * Các con số quy định của module Quán ăn (đặc tả mục 3.16).
 * Không viết cứng con số ở nơi khác: mọi thời hạn, giới hạn lấy từ đây.
 *
 * Mọi khoảng thời gian tính bằng PHÚT để rút ngắn được khi test / demo:
 * admin ghi đè từng giá trị trong document `qa_cau_hinh/hien_hanh`.
 */
const GIO = 60;
const NGAY = 24 * GIO;

const MAC_DINH = Object.freeze({
  // Đăng quán, menu
  anhMatTienToiThieu: 1,
  anhMatTienToiDa: 3,
  anhKhacToiDa: 10,
  monToiThieuHienSanh: 3,
  nhomMonToiDa: 20,
  monToiDa: 200,
  monNoiBatToiDa: 5,
  caMoiNgayToiDa: 2,
  sapDongPhut: 30,
  tenQuanToiThieu: 3,
  tenQuanToiDa: 80,
  loaiMonToiDa: 3,
  mstChuSoToiThieu: 10,
  mstChuSoToiDa: 13,

  // Khuyến mãi
  khuyenMaiToiDaHoKinhDoanh: 5,
  khuyenMaiToiDaBanLe: 1,
  khuyenMaiThoiHanPhut: 90 * NGAY,

  // Giá
  mocGia: [20000, 35000, 50000],

  // Check-in, nhãn "Sinh viên hay ăn", "Mới mở"
  checkInMet: 100,
  hayAnSoNguoi: 10,
  hayAnCuaSoPhut: 30 * NGAY,
  hayAnTopPhanTram: 20,
  hayAnBanKinhMet: 3000,
  moiMoPhut: 30 * NGAY,

  // Quán còn hoạt động không
  nhacHoatDongPhut: 90 * NGAY,
  anSauNhacPhut: 7 * NGAY,

  // Khai sai loại hình
  khaiSaiMonToiDa: 40,
  khaiSaiGioMoiNgay: 14,
  hanChuyenLoaiPhut: 7 * NGAY,

  // Đặt bàn
  datBanCachItNhatPhut: GIO,
  datBanToiDaPhut: 7 * NGAY,
  datBanSoNguoiToiThieu: 1,
  datBanSoNguoiToiDa: 20,
  datBanQuanXacNhanPhut: 30,
  datBanXacNhanTruocGioHenPhut: 30,
  giuBanPhut: 15,
  checkInSomPhut: 30,
  huySatGioPhut: GIO,
  nhacDatBanPhut: GIO,
  banTuDongDongPhut: 24 * GIO,
  khoaDatBanSoLan: 3,
  khoaDatBanCuaSoPhut: 30 * NGAY,
  khoaDatBanPhut: 7 * NGAY,

  // Đặt món
  banKinhGiaoToiThieuKm: 1,
  banKinhGiaoToiDaKm: 5,
  quanXacNhanDonPhut: 5,
  nhacChuongLaiPhut: 2,
  tuTamNgungSoLan: 3,
  quanChamPhut: 30,
  giaoLauPhut: 60,
  henGioToiThieuPhut: 30,
  henGioToiDaPhut: 2 * GIO,
  khachKhongToiLayPhut: 30,
  khongNhanPhanDoiPhut: 24 * GIO,
  khieuNaiPhut: 24 * GIO,
  quanTraLoiKhieuNaiPhut: 2 * GIO,
  khieuNaiCoKhanPhut: 72 * GIO,
  tuHoanTatPhut: 24 * GIO,
  nhacNhanMonSauPhut: GIO,
  nhacNhanMonConPhut: GIO,
  quaHanBangChungPhut: 6 * GIO,
  tienMatToiDa: 200000,
  choThanhToanPhut: 15,
  gpsLechMet: 200,
  tyLeCuaSoPhut: 30 * NGAY,

  // Vi phạm, khóa
  bomHangMatTienMatSoLan: 2,
  bomHangKhoaSoLan: 3,
  bomHangCuaSoPhut: 30 * NGAY,
  khoaDatMonPhut: 7 * NGAY,
  khieuNaiSaiSoLan: 3,
  khieuNaiSaiCuaSoPhut: 30 * NGAY,
  khoaDatMonAppPhut: 30 * NGAY,

  // Đánh giá
  danhGiaToiDaMoiNgay: 10,
  danhGiaNhanXetToiThieu: 20,
  danhGiaAnhToiDa: 5,
  danhGiaNhacSauPhut: 0,

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
  banKinhMet: [300, 500, 1000, 2000, 3000, 5000],

  // Cổng giả lập: khoảng chênh kỹ thuật khi hỏi lại cổng trước khi cho hết hạn
  congChenhGiay: 0,
});

const PHUT = 60 * 1000;

/** Từ khóa cảnh báo lừa đảo trong chat (mục 3.8) — đặt ở file cấu hình, không viết cứng ở logic. */
const TU_KHOA_CANH_BAO = Object.freeze({
  cum: ['chuyen khoan', 'tra truoc', 'so tai khoan', 'zalo', 'vi dien tu', 'ngan hang'],
  nguyenTu: ['ck', 'stk', 'qr'],
  momo: { tu: 'momo', nguCanh: ['chuyen', 'truoc', 'qua', 'gui', 'nap', 'bank', 'ck'] },
});

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

module.exports = { MAC_DINH, TU_KHOA_CANH_BAO, gopCauHinh, PHUT, GIO, NGAY };
