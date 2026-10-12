'use strict';

const { db } = require('../chung/firebase');
const { gopCauHinh, NGAY } = require('./config');

let boNho = null;
let docLuc = 0;

/** Cấu hình đang áp dụng: mặc định (mục 3.16) gộp với ghi đè trong `qa_cau_hinh/hien_hanh`. Lưu tạm 30 giây. */
async function layCauHinh() {
  if (boNho && Date.now() - docLuc < 30 * 1000) return boNho;
  const snap = await db.collection('qa_cau_hinh').doc('hien_hanh').get();
  boNho = gopCauHinh(snap.exists ? snap.data() : null);
  docLuc = Date.now();
  return boNho;
}

function xoaBoNho() {
  boNho = null;
}

/**
 * Cấu hình gửi cho app: giữ nguyên các khóa gốc và thêm tên khóa mà `QuanAnConfig` của app đọc
 * (một số tính bằng ngày thay vì phút). Admin ghi đè trong `qa_cau_hinh/hien_hanh` thì app thấy ngay.
 */
function choApp(c) {
  const ngay = (phut) => Math.round(phut / NGAY);
  return {
    ...c,
    monToiThieuHienThi: c.monToiThieuHienSanh,
    caMoCuaToiDa: c.caMoiNgayToiDa,
    khuyenMaiToiDaNgay: ngay(c.khuyenMaiThoiHanPhut),
    chipGiaReDen: c.mocGia[1],
    hayAnToiThieuNguoi: c.hayAnSoNguoi,
    hayAnPhanTram: c.hayAnTopPhanTram,
    hayAnBanKinhKm: Math.round(c.hayAnBanKinhMet / 1000),
    moiMoNgay: ngay(c.moiMoPhut),
    nhacConHoatDongNgay: ngay(c.nhacHoatDongPhut),
    hanXacNhanHoatDongNgay: ngay(c.anSauNhacPhut),
    khaiSaiMenuTren: c.khaiSaiMonToiDa,
    khaiSaiGioMoTren: c.khaiSaiGioMoiNgay,
    hanChuyenLoaiNgay: ngay(c.hanChuyenLoaiPhut),
    datBanTruocToiDaNgay: ngay(c.datBanToiDaPhut),
    datBanTruocGioHenPhut: c.datBanXacNhanTruocGioHenPhut,
    khoaDatBanNgay: ngay(c.khoaDatBanPhut),
    tuDongDongBanPhut: c.banTuDongDongPhut,
    quanXacNhanPhut: c.quanXacNhanDonPhut,
    chuongNhacLaiPhut: c.nhacChuongLaiPhut,
    chiSoNgay: ngay(c.tyLeCuaSoPhut),
    phanDoiPhut: c.khongNhanPhanDoiPhut,
    giuThemPhut: c.khongNhanPhanDoiPhut,
    quanTraLoiPhut: c.quanTraLoiKhieuNaiPhut,
    nhacTuHoanTatSauPhut: c.nhacNhanMonSauPhut,
    nhacTuHoanTatConLaiPhut: c.nhacNhanMonConPhut,
    maNhanMonSoChu: 4,
    quaHanPhut: c.quaHanBangChungPhut,
    tienMatDuoi: c.tienMatToiDa,
    bomHangKhoaNgay: ngay(c.khoaDatMonPhut),
    khieuNaiSaiKhoaNgay: ngay(c.khoaDatMonAppPhut),
    danhGiaToiDaNgay: c.danhGiaToiDaMoiNgay,
    baoCaoTuoiTaiKhoanNgay: ngay(c.baoCaoTaiKhoanToiThieuPhut),
    baoCaoToiDaNgay: c.baoCaoToiDaMoiNgay,
    khieuNaiKhanPhut: c.khieuNaiCoKhanPhut,
    khangNghiHanGuiNgay: ngay(c.khangNghiTrongPhut),
    tenMonToiThieu: 2,
    tenMonToiDa: 60,
  };
}

module.exports = { layCauHinh, xoaBoNho, choApp };
