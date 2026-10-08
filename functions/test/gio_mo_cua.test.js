'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const G = require('../src/quan_an/logic/gio_mo_cua');

// Mốc giờ Việt Nam → mili giây UTC (UTC+7).
const vn = (y, m, d, g = 0, p = 0) => Date.UTC(y, m - 1, d, g - 7, p);
// 2026-10-07 là Thứ tư (3). 2026-10-05 là Thứ hai.
const lichCom = {
  1: [{ tu: 360, den: 600 }, { tu: 960, den: 1260 }], // 6:00–10:00, 16:00–21:00
  2: [{ tu: 360, den: 600 }, { tu: 960, den: 1260 }],
  3: [{ tu: 360, den: 600 }, { tu: 960, den: 1260 }],
  4: [{ tu: 360, den: 600 }, { tu: 960, den: 1260 }],
  5: [{ tu: 360, den: 600 }, { tu: 960, den: 1260 }],
  6: [], 7: [],
};
const lichDem = { 1: [], 2: [], 3: [{ tu: 1080, den: 120 }], 4: [], 5: [], 6: [], 7: [] }; // Thứ tư 18:00–02:00

test('thứ trong tuần theo giờ Việt Nam', () => {
  assert.equal(G.thuVn(vn(2026, 10, 7, 12)), 3);
  assert.equal(G.thuVn(vn(2026, 10, 5, 0, 1)), 1);
  assert.equal(G.thuVn(vn(2026, 10, 11, 23, 59)), 7);
  // 23:30 UTC ngày 6/10 đã là 06:30 ngày 7/10 giờ Việt Nam.
  assert.equal(G.thuVn(Date.UTC(2026, 9, 6, 23, 30)), 3);
});

test('trạng thái mở / sắp đóng / đóng theo hai ca', () => {
  const t = (g, p) => vn(2026, 10, 7, g, p);
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom }, t(8, 0)).trangThai, 'mo');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom }, t(9, 40)).trangThai, 'sap_dong');
  const dong = G.trangThaiMoCua({ gioMoCua: lichCom }, t(12, 0));
  assert.equal(dong.trangThai, 'dong');
  assert.equal(dong.moLuc, t(16, 0));
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom }, t(20, 40)).trangThai, 'sap_dong');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom }, t(21, 0)).trangThai, 'dong');
});

test('ca qua nửa đêm thuộc ngày bắt đầu: 01:00 hôm sau vẫn đang mở', () => {
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichDem }, vn(2026, 10, 8, 1, 0)).trangThai, 'mo');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichDem }, vn(2026, 10, 8, 1, 40)).trangThai, 'sap_dong');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichDem }, vn(2026, 10, 8, 2, 0)).trangThai, 'dong');
  // Thứ năm 01:00 mở vì ca của Thứ tư; thứ năm 19:00 đóng vì Thứ năm không có ca.
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichDem }, vn(2026, 10, 8, 19, 0)).trangThai, 'dong');
});

test('giờ đóng của ca đang mở và ca mở kế tiếp', () => {
  const t = vn(2026, 10, 7, 8, 0);
  assert.equal(G.caDangMo(lichCom, t).ketThuc, vn(2026, 10, 7, 10, 0));
  // Thứ sáu 22:00 → ca kế tiếp là Thứ hai 6:00 (thứ bảy, chủ nhật nghỉ).
  assert.equal(G.caKeTiep(lichCom, vn(2026, 10, 9, 22, 0)).batDau, vn(2026, 10, 12, 6, 0));
});

test('tạm nghỉ hôm nay hết hiệu lực ở ca mở kế tiếp tính từ NGÀY MAI', () => {
  const t = vn(2026, 10, 7, 8, 0); // Thứ tư, đang trong ca sáng
  const han = G.hanTamNghiHomNay(lichCom, t);
  assert.equal(han, vn(2026, 10, 8, 6, 0)); // không phải ca chiều hôm nay
  const tt = G.trangThaiMoCua({ gioMoCua: lichCom, tamNghiDen: han }, vn(2026, 10, 7, 17, 0));
  assert.equal(tt.trangThai, 'tam_nghi');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom, tamNghiDen: han }, vn(2026, 10, 8, 6, 0)).trangThai, 'mo');
});

test('nghỉ đến ngày: mở lại đúng ngày', () => {
  const han = G.hanNghiDenNgay(vn(2026, 10, 12, 15, 0));
  assert.equal(han, vn(2026, 10, 12, 0, 0));
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom, tamNghiDen: han }, vn(2026, 10, 11, 23, 0)).trangThai, 'tam_nghi');
  assert.equal(G.trangThaiMoCua({ gioMoCua: lichCom, tamNghiDen: han }, vn(2026, 10, 12, 7, 0)).trangThai, 'mo');
});

test('kiểm tra lịch: 3 ca, ca chồng nhau, lịch trống đều bị chặn', () => {
  assert.equal(G.kiemTraLich(lichCom), null);
  assert.match(G.kiemTraLich({ ...lichCom, 1: [{ tu: 0, den: 100 }, { tu: 200, den: 300 }, { tu: 400, den: 500 }] }), /tối đa 2 ca/);
  assert.match(G.kiemTraLich({ ...lichCom, 1: [{ tu: 360, den: 700 }, { tu: 600, den: 800 }] }), /chồng/);
  assert.match(G.kiemTraLich({ 1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [] }), /ít nhất 1 ca/);
});

test('giờ mở nhiều nhất một ngày (dấu hiệu khai sai loại)', () => {
  assert.equal(G.gioMoNhieuNhat(lichCom), 9); // 4 + 5 giờ
  assert.equal(G.gioMoNhieuNhat(lichDem), 8);
});
