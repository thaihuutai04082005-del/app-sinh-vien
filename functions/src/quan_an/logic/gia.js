'use strict';

/**
 * Giá của quán và cách tính tiền đơn (đặc tả mục 3.3 "Mức giá của quán" + "Cách tính tiền khuyến mãi").
 * Logic THUẦN: nhận dữ liệu đã đọc sẵn, trả về con số. Hệ thống luôn tự tính lại, app chỉ gửi món.
 */

const { thuVn, phutTrongNgayVn } = require('./gio_mo_cua');

// ---------------------------------------------------------------- Mức giá của quán

/** Phân vị `q` (0–1) của danh sách đã sắp xếp, nội suy tuyến tính giữa hai giá liền kề. */
function phanVi(daSapXep, q) {
  if (!daSapXep.length) return null;
  if (daSapXep.length === 1) return daSapXep[0];
  const vt = (daSapXep.length - 1) * q;
  const duoi = Math.floor(vt);
  const tren = Math.ceil(vt);
  return Math.round(daSapXep[duoi] + (daSapXep[tren] - daSapXep[duoi]) * (vt - duoi));
}

/**
 * Mức giá của quán: lấy giá các món thuộc nhóm "món chính" (không phải nhóm đồ uống / món thêm);
 * quán không có món chính thì lấy toàn bộ món. Trả về { soMon, giaP25, giaTrungVi, giaP75 }.
 * `monAn`: [{ gia, laDoUong, daXoa }].
 */
function thongKeGia(monAn) {
  const con = monAn.filter((m) => !m.daXoa && Number(m.gia) > 0);
  const chinh = con.filter((m) => !m.laDoUong);
  const dung = (chinh.length ? chinh : con).map((m) => Number(m.gia)).sort((a, b) => a - b);
  return {
    soMon: con.length,
    giaP25: phanVi(dung, 0.25),
    giaTrungVi: phanVi(dung, 0.5),
    giaP75: phanVi(dung, 0.75),
  };
}

// ---------------------------------------------------------------- Tính tiền đơn

const sao = (x) => JSON.parse(JSON.stringify(x));

/** Khoảng cách đường thẳng (mét) giữa hai điểm { lat, lng }. */
function khoangCachMet(a, b) {
  const R = 6371000;
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/**
 * Tiền món của một dòng: (giá món + tổng giá cộng thêm của các lựa chọn) × số lượng.
 * Dòng đã được hệ thống dựng từ menu hiện tại, không lấy giá từ app.
 */
function thanhTienDong(d) {
  const them = (d.tuyChon || []).reduce((s, t) => s + (Number(t.giaThem) || 0), 0);
  return (Number(d.gia) + them) * Number(d.soLuong);
}

/** Phí giao theo cài đặt của quán. `km` = khoảng cách đường thẳng. */
function phiGiao(datMon, km) {
  if (!datMon || !datMon.giaoTanNoi) return 0;
  if (datMon.phiGiaoKieu === 'theo_km') {
    const tron = Math.max(1, Math.ceil(km));
    return Math.round(((Number(datMon.phiGiao) || 0) + (Number(datMon.phiMoiKm) || 0) * tron) / 1000) * 1000;
  }
  return Number(datMon.phiGiao) || 0;
}

/** Khuyến mãi đơn (giảm %, giảm tiền, giờ vàng, ưu đãi sinh viên) → số tiền giảm, hoặc 0 nếu không áp dụng. */
function giamCuaKhuyenMai(km, tienMon, now, { coHuyHieuSinhVien = false } = {}) {
  if (tienMon < (km.donToiThieu || 0)) return 0; // đơn tối thiểu tính trên tiền món trước giảm, không gồm phí giao
  let giam = 0;
  if (km.loai === 'giam_phan_tram') {
    giam = Math.floor((tienMon * (km.phanTram || 0)) / 100);
    if (km.giamToiDa) giam = Math.min(giam, km.giamToiDa);
  } else if (km.loai === 'giam_tien') {
    giam = km.giamTien || 0;
  } else if (km.loai === 'gio_vang') {
    const g = km.gioVang || {};
    // Giờ vàng xét theo thời điểm đặt đơn (giờ của hệ thống) và các ngày áp dụng.
    const thu = thuVn(now);
    const phut = phutTrongNgayVn(now);
    const trongNgay = !g.ngay || !g.ngay.length || g.ngay.includes(thu);
    const trongGio = g.tu <= g.den ? phut >= g.tu && phut < g.den : phut >= g.tu || phut < g.den;
    if (!trongNgay || !trongGio) return 0;
    giam = Math.floor((tienMon * (g.phanTram || 0)) / 100);
    if (g.giamToiDa) giam = Math.min(giam, g.giamToiDa);
  } else if (km.loai === 'sinh_vien') {
    if (!coHuyHieuSinhVien) return 0;
    giam = km.giamTien || 0;
  }
  return Math.max(0, Math.min(giam, tienMon));
}

/**
 * Combo: khi giỏ có đủ các món của combo với số lượng ≥ yêu cầu thì giá combo thay cho tổng giá
 * thường của bộ món (áp nhiều lần nếu đủ nhiều bộ); phần dư tính giá thường. Mức giảm của combo =
 * tổng giá thường của bộ món − giá combo. Chỉ tính giá món gốc, giá cộng thêm của tùy chọn vẫn giữ.
 */
function giamCuaCombo(km, dong) {
  const cb = km.combo;
  if (!cb || !Array.isArray(cb.mon) || !cb.mon.length) return { giam: 0, soBo: 0 };
  const soLuong = new Map();
  const gia = new Map();
  for (const d of dong) {
    soLuong.set(d.monId, (soLuong.get(d.monId) || 0) + d.soLuong);
    gia.set(d.monId, d.gia);
  }
  let soBo = Infinity;
  let giaThuong = 0;
  for (const m of cb.mon) {
    const co = soLuong.get(m.monId) || 0;
    soBo = Math.min(soBo, Math.floor(co / m.soLuong));
    giaThuong += (gia.get(m.monId) || 0) * m.soLuong;
  }
  if (!Number.isFinite(soBo) || soBo < 1) return { giam: 0, soBo: 0 };
  const moiBo = giaThuong - cb.gia;
  return moiBo > 0 ? { giam: moiBo * soBo, soBo } : { giam: 0, soBo: 0 };
}

/**
 * Tính tiền đơn (mục 3.3 Bước 4, 7 quy tắc):
 *  1. tiền món (tạm tính) = Σ (giá + tùy chọn) × số lượng, không gồm phí giao;
 *  2. combo (nếu có, chọn combo giảm nhiều nhất) + 1 khuyến mãi đơn có lợi nhất (bằng nhau → sắp hết hạn trước);
 *  3. mức giảm không vượt tiền món, không áp lên phí giao; hết hạn / dừng thì không áp.
 * `dong`: [{ monId, ten, gia, soLuong, tuyChon: [{ nhom, ten, giaThem }], ghiChu }];
 * `khuyenMai`: danh sách khuyến mãi của quán (chỉ quán hộ kinh doanh mới tự trừ).
 */
function tinhDon({ dong, khuyenMai = [], now, phiGiaoDon = 0, coHuyHieuSinhVien = false, tuTru = true }) {
  const dongTinh = dong.map((d) => ({ ...sao(d), thanhTien: thanhTienDong(d) }));
  const tienMon = dongTinh.reduce((s, d) => s + d.thanhTien, 0);
  const conHan = (km) => km.trangThai === 'chay' && km.batDau <= now && now < km.ketThuc;
  const ap = [];
  let giamCombo = 0;
  let giamGia = 0;

  if (tuTru) {
    let tot = null;
    for (const km of khuyenMai.filter((k) => k.loai === 'combo' && conHan(k))) {
      const r = giamCuaCombo(km, dongTinh);
      if (r.giam > 0 && (!tot || r.giam > tot.giam || (r.giam === tot.giam && km.ketThuc < tot.km.ketThuc))) tot = { km, ...r };
    }
    if (tot) {
      giamCombo = Math.min(tot.giam, tienMon);
      ap.push({ id: tot.km.id, tieuDe: tot.km.tieuDe, loai: 'combo', giam: giamCombo });
    }
    let totDon = null;
    for (const km of khuyenMai.filter((k) => k.loai !== 'combo' && conHan(k))) {
      const g = giamCuaKhuyenMai(km, tienMon, now, { coHuyHieuSinhVien });
      if (g > 0 && (!totDon || g > totDon.giam || (g === totDon.giam && km.ketThuc < totDon.km.ketThuc))) totDon = { km, giam: g };
    }
    if (totDon) {
      giamGia = Math.min(totDon.giam, tienMon - giamCombo);
      if (giamGia > 0) ap.push({ id: totDon.km.id, tieuDe: totDon.km.tieuDe, loai: totDon.km.loai, giam: giamGia });
      else giamGia = 0;
    }
  }
  const tong = tienMon - giamCombo - giamGia + phiGiaoDon;
  return { monAn: dongTinh, tienMon, giamCombo, giamGia, khuyenMaiApDung: ap, phiGiao: phiGiaoDon, tong };
}

module.exports = {
  phanVi, thongKeGia, khoangCachMet, thanhTienDong, phiGiao, giamCuaKhuyenMai, giamCuaCombo, tinhDon,
};
