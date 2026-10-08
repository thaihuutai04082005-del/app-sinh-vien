'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const G = require('../src/quan_an/logic/gia');

const vn = (y, m, d, g = 0, p = 0) => Date.UTC(y, m - 1, d, g - 7, p);

test('mức giá quán = P25 / trung vị / P75 của món chính, bỏ nhóm đồ uống / món thêm', () => {
  const mon = [
    ...[25000, 30000, 35000, 40000, 45000].map((gia) => ({ gia, laDoUong: false })),
    { gia: 8000, laDoUong: true }, { gia: 12000, laDoUong: true },
  ];
  const r = G.thongKeGia(mon);
  assert.equal(r.soMon, 7);
  assert.equal(r.giaP25, 30000);
  assert.equal(r.giaTrungVi, 35000);
  assert.equal(r.giaP75, 40000);
});

test('quán không có món chính thì tính mọi món', () => {
  const r = G.thongKeGia([{ gia: 20000, laDoUong: true }, { gia: 30000, laDoUong: true }, { gia: 40000, laDoUong: true }]);
  assert.equal(r.giaTrungVi, 30000);
  assert.equal(r.giaP25, 25000);
  assert.equal(r.giaP75, 35000);
});

test('món đã xóa không tính, quán không món thì null', () => {
  assert.equal(G.thongKeGia([{ gia: 10000, daXoa: true }]).giaTrungVi, null);
});

const dong = [
  { monId: 'a', ten: 'Cơm gà', gia: 35000, soLuong: 2, tuyChon: [{ nhom: 'Topping', ten: 'Thêm trứng', giaThem: 5000 }] },
  { monId: 'b', ten: 'Trà đào', gia: 20000, soLuong: 1, tuyChon: [] },
];
const gia1 = { id: 'k1', trangThai: 'chay', batDau: vn(2026, 10, 1), ketThuc: vn(2026, 10, 31) };

test('tiền món = (giá + tùy chọn) × số lượng, không gồm phí giao', () => {
  const r = G.tinhDon({ dong, now: vn(2026, 10, 7, 12), phiGiaoDon: 10000 });
  assert.equal(r.tienMon, 80000 + 20000);
  assert.equal(r.tong, 100000 + 10000);
  assert.equal(r.monAn[0].thanhTien, 80000);
});

test('giảm % có mức tối đa; giảm tiền; đơn tối thiểu tính trên tiền món trước giảm', () => {
  const now = vn(2026, 10, 7, 12);
  const pt = { ...gia1, id: 'p', loai: 'giam_phan_tram', phanTram: 10, giamToiDa: 5000, donToiThieu: 50000, tieuDe: '-10%' };
  assert.equal(G.tinhDon({ dong, khuyenMai: [pt], now }).giamGia, 5000);
  const dat = { ...pt, donToiThieu: 150000 };
  assert.equal(G.tinhDon({ dong, khuyenMai: [dat], now }).giamGia, 0);
  const tien = { ...gia1, id: 't', loai: 'giam_tien', giamTien: 15000, donToiThieu: 80000, tieuDe: '-15k' };
  assert.equal(G.tinhDon({ dong, khuyenMai: [tien], now }).tong, 100000 - 15000);
});

test('mức giảm không vượt tiền món và không áp lên phí giao', () => {
  const now = vn(2026, 10, 7, 12);
  const lon = { ...gia1, id: 'l', loai: 'giam_tien', giamTien: 999999, donToiThieu: 0, tieuDe: 'x' };
  const r = G.tinhDon({ dong, khuyenMai: [lon], now, phiGiaoDon: 12000 });
  assert.equal(r.giamGia, 100000);
  assert.equal(r.tong, 12000);
});

test('mỗi đơn chỉ áp 1 khuyến mãi đơn có lợi nhất; bằng nhau thì sắp hết hạn trước', () => {
  const now = vn(2026, 10, 7, 12);
  const a = { ...gia1, id: 'a', loai: 'giam_tien', giamTien: 10000, tieuDe: 'A', ketThuc: vn(2026, 10, 20) };
  const b = { ...gia1, id: 'b', loai: 'giam_tien', giamTien: 10000, tieuDe: 'B', ketThuc: vn(2026, 10, 10) };
  const c = { ...gia1, id: 'c', loai: 'giam_phan_tram', phanTram: 5, tieuDe: 'C' }; // 5.000
  const r = G.tinhDon({ dong, khuyenMai: [a, b, c], now });
  assert.equal(r.khuyenMaiApDung.length, 1);
  assert.equal(r.khuyenMaiApDung[0].id, 'b');
});

test('khuyến mãi hết hạn / đã dừng không được áp', () => {
  const now = vn(2026, 10, 7, 12);
  const het = { ...gia1, id: 'h', loai: 'giam_tien', giamTien: 10000, tieuDe: 'h', ketThuc: vn(2026, 10, 6) };
  const dung = { ...gia1, id: 'd', loai: 'giam_tien', giamTien: 10000, tieuDe: 'd', trangThai: 'dung' };
  assert.equal(G.tinhDon({ dong, khuyenMai: [het, dung], now }).giamGia, 0);
});

test('giờ vàng: trong khung giờ và đúng ngày thì áp, ngoài thì không (giờ của hệ thống)', () => {
  // 2026-10-07 = Thứ tư (3). Giờ vàng 14:00–16:00 T2–T6 giảm 20%.
  const gv = { ...gia1, id: 'gv', loai: 'giam_phan_tram', tieuDe: 'Giờ vàng' };
  const km = { ...gv, loai: 'gio_vang', gioVang: { tu: 840, den: 960, ngay: [1, 2, 3, 4, 5], phanTram: 20, giamToiDa: 50000 } };
  assert.equal(G.tinhDon({ dong, khuyenMai: [km], now: vn(2026, 10, 7, 15, 0) }).giamGia, 20000);
  assert.equal(G.tinhDon({ dong, khuyenMai: [km], now: vn(2026, 10, 7, 16, 0) }).giamGia, 0);
  assert.equal(G.tinhDon({ dong, khuyenMai: [km], now: vn(2026, 10, 10, 15, 0) }).giamGia, 0); // thứ bảy
});

test('ưu đãi sinh viên chỉ áp cho tài khoản có huy hiệu email trường', () => {
  const sv = { ...gia1, id: 's', loai: 'sinh_vien', giamTien: 5000, tieuDe: 'SV' };
  const now = vn(2026, 10, 7, 12);
  assert.equal(G.tinhDon({ dong, khuyenMai: [sv], now }).giamGia, 0);
  assert.equal(G.tinhDon({ dong, khuyenMai: [sv], now, coHuyHieuSinhVien: true }).giamGia, 5000);
});

test('combo: đủ bộ thì áp giá combo, phần dư tính giá thường, giá cộng thêm của tùy chọn vẫn giữ', () => {
  const now = vn(2026, 10, 7, 12);
  const combo = { ...gia1, id: 'cb', loai: 'combo', tieuDe: 'Cơm + nước', combo: { mon: [{ monId: 'a', soLuong: 1 }, { monId: 'b', soLuong: 1 }], gia: 45000 } };
  // Giỏ: 2 cơm gà (35k + trứng 5k) + 1 trà đào (20k) → 1 bộ (55k → 45k) giảm 10k, dư 1 cơm tính thường.
  const r = G.tinhDon({ dong, khuyenMai: [combo], now });
  assert.equal(r.giamCombo, 10000);
  assert.equal(r.tong, 100000 - 10000);
  // Thiếu món trong bộ: không áp.
  const thieu = G.tinhDon({ dong: [dong[0]], khuyenMai: [combo], now });
  assert.equal(thieu.giamCombo, 0);
  // Đủ 2 bộ: giảm 2 lần.
  const hai = G.tinhDon({ dong: [{ ...dong[0], soLuong: 2 }, { ...dong[1], soLuong: 2 }], khuyenMai: [combo], now });
  assert.equal(hai.giamCombo, 20000);
});

test('combo + 1 khuyến mãi đơn cùng áp; tổng giảm không vượt tiền món', () => {
  const now = vn(2026, 10, 7, 12);
  const combo = { ...gia1, id: 'cb', loai: 'combo', tieuDe: 'Combo', combo: { mon: [{ monId: 'a', soLuong: 1 }, { monId: 'b', soLuong: 1 }], gia: 45000 } };
  const tien = { ...gia1, id: 't', loai: 'giam_tien', giamTien: 15000, tieuDe: '-15k' };
  const r = G.tinhDon({ dong, khuyenMai: [combo, tien], now });
  assert.equal(r.khuyenMaiApDung.length, 2);
  assert.equal(r.tong, 100000 - 10000 - 15000);
});

test('quán bán lẻ: khuyến mãi chỉ hiển thị, không tự trừ', () => {
  const tien = { ...gia1, id: 't', loai: 'giam_tien', giamTien: 15000, tieuDe: '-15k' };
  assert.equal(G.tinhDon({ dong, khuyenMai: [tien], now: vn(2026, 10, 7, 12), tuTru: false }).giamGia, 0);
});

test('phí giao cố định và theo km, quán không giao thì 0', () => {
  assert.equal(G.phiGiao({ giaoTanNoi: true, phiGiaoKieu: 'co_dinh', phiGiao: 12000 }, 3), 12000);
  assert.equal(G.phiGiao({ giaoTanNoi: true, phiGiaoKieu: 'theo_km', phiGiao: 5000, phiMoiKm: 3000 }, 2.2), 14000); // 5k + 3 km × 3k
  assert.equal(G.phiGiao({ giaoTanNoi: false, phiGiao: 12000 }, 1), 0);
});

test('khoảng cách haversine', () => {
  const d = G.khoangCachMet({ lat: 10.0, lng: 105.0 }, { lat: 10.0, lng: 105.01 });
  assert.ok(d > 1090 && d < 1130);
});
