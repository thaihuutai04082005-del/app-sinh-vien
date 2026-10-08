'use strict';

/**
 * Kiểm tra dữ liệu quán, món, khuyến mãi (đặc tả mục 3.3) và dấu hiệu khai sai loại (mục 3.5f).
 * Logic thuần, test được. Hàm `kiemTra*` trả về danh sách lỗi (rỗng = hợp lệ).
 */

const { kiemTraLich, gioMoNhieuNhat } = require('./gio_mo_cua');

const LOAI_QUAN = ['ho_kinh_doanh', 'ban_le'];
const LOAI_MON = ['com', 'bun_pho_mi', 'banh_mi', 'an_vat', 'lau_nuong', 'chay', 'do_uong', 'tra_sua', 'ca_phe', 'trang_mien', 'khac'];
const TIEN_ICH = ['trong_nha', 'ngoai_troi', 'may_lanh', 'wifi', 'o_cam', 'do_xe', 'hoc_nhom'];
const LOAI_KHUYEN_MAI = ['giam_phan_tram', 'giam_tien', 'combo', 'gio_vang', 'sinh_vien'];

function boDau(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

const laHttps = (u) => typeof u === 'string' && /^https:\/\/[^\s]+$/.test(u) && u.length <= 2000;
const laSo = (x) => typeof x === 'number' && Number.isFinite(x);

/** Chữ tìm kiếm không dấu: tên quán + tên các món + đường + phường (cập nhật khi menu đổi). */
function chuTimKiem(quan, tenMon = []) {
  return boDau([quan.ten, ...tenMon, quan.diaChi, quan.phuong].filter(Boolean).join(' '));
}

function kiemTraDatMon(dm, cfg, loaiQuan) {
  const loi = [];
  if (!dm || !dm.bat) return loi;
  if (loaiQuan !== 'ho_kinh_doanh') return ['Chỉ quán hộ kinh doanh mới nhận đặt món qua app.'];
  if (!dm.denLay && !dm.giaoTanNoi) loi.push('Chọn ít nhất 1 hình thức: Đến lấy hoặc Quán tự giao.');
  if (dm.giaoTanNoi) {
    if (!laSo(dm.banKinhKm) || dm.banKinhKm < cfg.banKinhGiaoToiThieuKm || dm.banKinhKm > cfg.banKinhGiaoToiDaKm) {
      loi.push(`Bán kính giao từ ${cfg.banKinhGiaoToiThieuKm} đến ${cfg.banKinhGiaoToiDaKm} km.`);
    }
    if (!['co_dinh', 'theo_km'].includes(dm.phiGiaoKieu)) loi.push('Chọn cách tính phí giao.');
    if (!laSo(dm.phiGiao) || dm.phiGiao < 0) loi.push('Nhập phí giao hợp lệ.');
    if (dm.phiGiaoKieu === 'theo_km' && (!laSo(dm.phiMoiKm) || dm.phiMoiKm < 0)) loi.push('Nhập phí mỗi km.');
  }
  if (!laSo(dm.donToiThieu) || dm.donToiThieu < 0) loi.push('Nhập đơn tối thiểu (0 nếu không đặt).');
  if (!Number.isInteger(dm.chuanBiPhut) || dm.chuanBiPhut < 1 || dm.chuanBiPhut > 240) loi.push('Thời gian chuẩn bị trung bình 1–240 phút.');
  if (typeof dm.tienMat !== 'boolean') loi.push('Chọn có nhận tiền mặt khi nhận hàng không.');
  return loi;
}

/**
 * Kiểm tra quán trước khi gửi duyệt (mục 3.3 Bước 2). `giayTo` = nội dung `rieng/giay_to`.
 */
function kiemTraQuan(q, giayTo, cfg) {
  const loi = [];
  const ten = String(q.ten || '').trim();
  if (ten.length < cfg.tenQuanToiThieu || ten.length > cfg.tenQuanToiDa) loi.push(`Tên quán ${cfg.tenQuanToiThieu}–${cfg.tenQuanToiDa} ký tự.`);
  if (!LOAI_QUAN.includes(q.loaiQuan)) loi.push('Chọn loại quán (hộ kinh doanh / bán lẻ - vỉa hè).');
  if (!Array.isArray(q.loaiMon) || q.loaiMon.length < 1 || q.loaiMon.length > cfg.loaiMonToiDa || !q.loaiMon.every((x) => LOAI_MON.includes(x))) {
    loi.push(`Chọn 1–${cfg.loaiMonToiDa} loại món chính.`);
  }
  if (String(q.moTa || '').trim().length < 10) loi.push('Mô tả quán ít nhất 10 ký tự.');
  if (!/^0\d{9}$/.test(String(q.sdt || ''))) loi.push('Nhập số điện thoại quán (10 số, bắt đầu bằng 0).');
  if (String(q.diaChi || '').trim().length < 5) loi.push('Nhập địa chỉ đầy đủ.');
  if (!q.viTri) loi.push('Ghim vị trí quán trên bản đồ.');
  if (q.luuDong && String(q.ghiChuViTri || '').trim().length < 3) loi.push('Quán lưu động: ghi chú chỗ bán thường xuyên (ví dụ "Đầu hẻm 51").');
  const lichLoi = kiemTraLich(q.gioMoCua, cfg.caMoiNgayToiDa);
  if (lichLoi) loi.push(lichLoi);
  const pv = q.phucVu || {};
  if (!pv.anTaiQuan && !pv.mangDi) loi.push('Chọn ít nhất 1 hình thức phục vụ (ăn tại quán / mang đi).');
  if (!Array.isArray(q.tienIch) || !q.tienIch.every((x) => TIEN_ICH.includes(x))) loi.push('Tiện ích không hợp lệ.');
  const mt = q.anhMatTien;
  if (!Array.isArray(mt) || mt.length < cfg.anhMatTienToiThieu || mt.length > cfg.anhMatTienToiDa || !mt.every(laHttps)) {
    loi.push(`Cần ${cfg.anhMatTienToiThieu}–${cfg.anhMatTienToiDa} ảnh mặt tiền.`);
  }
  if (q.anhKhac && (!Array.isArray(q.anhKhac) || q.anhKhac.length > cfg.anhKhacToiDa || !q.anhKhac.every(laHttps))) {
    loi.push(`Tối đa ${cfg.anhKhacToiDa} ảnh khác.`);
  }
  if (q.loaiQuan === 'ban_le') {
    if (q.nhanDatBan) loi.push('Quán bán lẻ / vỉa hè không nhận đặt bàn.');
    if (q.datMon && q.datMon.bat) loi.push('Quán bán lẻ / vỉa hè không nhận đặt món qua app.');
  }
  if (q.loaiQuan === 'ho_kinh_doanh') {
    const g = giayTo || {};
    const mst = String(g.maSoThue || '').replace(/\s/g, '');
    if (!new RegExp(`^\\d{${cfg.mstChuSoToiThieu},${cfg.mstChuSoToiDa}}$`).test(mst)) loi.push('Nhập mã số thuế (chỉ gồm chữ số).');
    if (!Array.isArray(g.anhGiayChungNhan) || g.anhGiayChungNhan.length < 1 || !g.anhGiayChungNhan.every(laHttps)) {
      loi.push('Tải lên ảnh giấy chứng nhận hộ kinh doanh.');
    }
    loi.push(...kiemTraDatMon(q.datMon, cfg, q.loaiQuan));
  }
  if (!q.camKet) loi.push('Tick cam kết thông tin đúng sự thật.');
  return loi;
}

/** Dấu hiệu quán khai bán lẻ nhưng có vẻ là hộ kinh doanh (mục 3.5f): trả về danh sách lý do (rỗng = không nghi). */
function canhBaoKhaiSai(q, soMon, cfg) {
  if (q.loaiQuan !== 'ban_le') return [];
  const lyDo = [];
  if ((q.tienIch || []).some((t) => t === 'may_lanh' || t === 'trong_nha')) lyDo.push('Chọn máy lạnh / chỗ ngồi trong nhà');
  if (soMon > cfg.khaiSaiMonToiDa) lyDo.push(`Menu trên ${cfg.khaiSaiMonToiDa} món`);
  if (q.gioMoCua && gioMoNhieuNhat(q.gioMoCua) > cfg.khaiSaiGioMoiNgay) lyDo.push(`Mở cửa trên ${cfg.khaiSaiGioMoiNgay} giờ mỗi ngày`);
  return lyDo;
}

function kiemTraNhomMon(n) {
  const loi = [];
  const ten = String(n.ten || '').trim();
  if (ten.length < 2 || ten.length > 40) loi.push('Tên nhóm món 2–40 ký tự.');
  if (typeof n.laDoUong !== 'boolean') loi.push('Chọn nhóm là món chính hay đồ uống / món thêm.');
  return loi;
}

function kiemTraTuyChon(ds) {
  const loi = [];
  if (!Array.isArray(ds)) return ['Tùy chọn không hợp lệ.'];
  if (ds.length > 10) return ['Tối đa 10 nhóm tùy chọn cho một món.'];
  for (const t of ds) {
    if (String(t.ten || '').trim().length < 1 || String(t.ten).length > 40) { loi.push('Tên nhóm tùy chọn 1–40 ký tự.'); continue; }
    if (typeof t.batBuoc !== 'boolean') loi.push(`Nhóm "${t.ten}": chọn bắt buộc hay không.`);
    if (!Number.isInteger(t.toiDa) || t.toiDa < 1) loi.push(`Nhóm "${t.ten}": chọn tối đa mấy lựa chọn.`);
    if (!Array.isArray(t.lua) || t.lua.length < 1 || t.lua.length > 20) { loi.push(`Nhóm "${t.ten}": cần 1–20 lựa chọn.`); continue; }
    for (const l of t.lua) {
      if (String(l.ten || '').trim().length < 1 || !laSo(l.giaThem) || l.giaThem < 0 || !Number.isInteger(l.giaThem)) {
        loi.push(`Nhóm "${t.ten}": lựa chọn cần tên và giá cộng thêm (≥ 0).`);
        break;
      }
    }
    if (t.toiDa > (t.lua || []).length) loi.push(`Nhóm "${t.ten}": số lựa chọn tối đa vượt số lựa chọn có.`);
  }
  return loi;
}

function kiemTraMon(m) {
  const loi = [];
  const ten = String(m.ten || '').trim();
  if (ten.length < 2 || ten.length > 60) loi.push('Tên món 2–60 ký tự.');
  if (!Number.isInteger(m.gia) || m.gia <= 0) loi.push('Giá món phải lớn hơn 0.');
  if (m.anh && !laHttps(m.anh)) loi.push('Ảnh món không hợp lệ.');
  if (String(m.moTa || '').length > 300) loi.push('Mô tả món tối đa 300 ký tự.');
  loi.push(...kiemTraTuyChon(m.tuyChon || []));
  return loi;
}

/** Kiểm tra khuyến mãi (mục 3.3 Bước 4). `soDangChay` = số khuyến mãi đang chạy của quán (không tính chính nó). */
function kiemTraKhuyenMai(k, { loaiQuan, soDangChay, now }, cfg) {
  const loi = [];
  if (!LOAI_KHUYEN_MAI.includes(k.loai)) return ['Chọn loại khuyến mãi.'];
  if (String(k.tieuDe || '').trim().length < 3 || String(k.tieuDe).length > 80) loi.push('Tiêu đề khuyến mãi 3–80 ký tự.');
  if (!laSo(k.batDau) || !laSo(k.ketThuc)) loi.push('Nhập ngày bắt đầu và ngày kết thúc.');
  else {
    if (k.ketThuc <= k.batDau) loi.push('Ngày kết thúc phải sau ngày bắt đầu.');
    if (k.ketThuc - k.batDau > cfg.khuyenMaiThoiHanPhut * 60000) loi.push('Khuyến mãi tối đa 90 ngày.');
    if (k.ketThuc <= now) loi.push('Ngày kết thúc phải ở tương lai.');
  }
  const toiDa = loaiQuan === 'ho_kinh_doanh' ? cfg.khuyenMaiToiDaHoKinhDoanh : cfg.khuyenMaiToiDaBanLe;
  if (soDangChay >= toiDa) loi.push(`Quán chỉ có tối đa ${toiDa} khuyến mãi cùng lúc.`);
  if (loaiQuan !== 'ho_kinh_doanh' && k.loai !== 'giam_phan_tram' && k.loai !== 'giam_tien' && k.loai !== 'gio_vang') {
    // Quán bán lẻ vẫn tạo được để hiển thị; combo / ưu đãi sinh viên không tự trừ nên cũng chỉ hiển thị.
  }
  const donToiThieu = k.donToiThieu == null ? 0 : k.donToiThieu;
  if (!laSo(donToiThieu) || donToiThieu < 0) loi.push('Đơn tối thiểu không hợp lệ.');
  if (k.loai === 'giam_phan_tram' && (!Number.isInteger(k.phanTram) || k.phanTram < 1 || k.phanTram > 90)) loi.push('Giảm 1–90%.');
  if ((k.loai === 'giam_tien' || k.loai === 'sinh_vien') && (!Number.isInteger(k.giamTien) || k.giamTien <= 0)) loi.push('Nhập số tiền giảm lớn hơn 0.');
  if (k.loai === 'gio_vang') {
    const g = k.gioVang || {};
    if (!Number.isInteger(g.tu) || !Number.isInteger(g.den) || g.tu === g.den || g.tu < 0 || g.den > 1439) loi.push('Khung giờ vàng không hợp lệ.');
    if (!Array.isArray(g.ngay) || !g.ngay.length || !g.ngay.every((n) => Number.isInteger(n) && n >= 1 && n <= 7)) loi.push('Chọn các ngày áp dụng giờ vàng.');
    if (!Number.isInteger(g.phanTram) || g.phanTram < 1 || g.phanTram > 90) loi.push('Giờ vàng giảm 1–90%.');
  }
  if (k.loai === 'combo') {
    const c = k.combo || {};
    if (!Array.isArray(c.mon) || c.mon.length < 2 || c.mon.some((m) => !m.monId || !Number.isInteger(m.soLuong) || m.soLuong < 1)) loi.push('Combo cần ít nhất 2 món, mỗi món số lượng ≥ 1.');
    if (!Number.isInteger(c.gia) || c.gia <= 0) loi.push('Nhập giá combo.');
  }
  return loi;
}

module.exports = {
  LOAI_QUAN, LOAI_MON, TIEN_ICH, LOAI_KHUYEN_MAI, boDau, laHttps, chuTimKiem,
  kiemTraDatMon, kiemTraQuan, canhBaoKhaiSai, kiemTraNhomMon, kiemTraTuyChon, kiemTraMon, kiemTraKhuyenMai,
};
