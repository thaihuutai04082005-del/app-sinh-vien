'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { MAC_DINH, PHUT } = require('../src/tro/config');
const V = require('../src/tro/logic/vi_pham');

const NGAY = 24 * 60 * PHUT;
const now = Date.parse('2026-10-10T07:00:00Z');

test('đếm vi phạm theo cửa sổ trượt, bỏ lần đã gỡ và lần quá cửa sổ', () => {
  const ds = [
    { luc: now - 1 * NGAY },
    { luc: now - 89 * NGAY },
    { luc: now - 91 * NGAY },
    { luc: now - 2 * NGAY, daGo: true },
  ];
  assert.equal(V.demTrongCuaSo(ds, now, 90 * 24 * 60), 2);
});

test('chủ trọ 3 vi phạm / 90 ngày → khóa đăng tin / nhận cọc 30 ngày', () => {
  const opt = { soLan: MAC_DINH.viPhamChuSoLan, cuaSoPhut: MAC_DINH.viPhamChuCuaSoPhut, khoaPhut: MAC_DINH.khoaDangTinPhut };
  assert.equal(V.hanKhoaMoi([{ luc: now - NGAY }, { luc: now }], now, opt), null);
  assert.equal(V.hanKhoaMoi([{ luc: now - 80 * NGAY }, { luc: now - NGAY }, { luc: now }], now, opt), now + 30 * NGAY);
  // Lần cũ hơn 90 ngày không còn tính.
  assert.equal(V.hanKhoaMoi([{ luc: now - 95 * NGAY }, { luc: now - NGAY }, { luc: now }], now, opt), null);
});

test('hủy miễn phí tối đa 2 lần / 30 ngày; lần cũ hơn 30 ngày không còn tính', () => {
  assert.equal(V.conQuyenHuyMienPhi([{ luc: now - NGAY }], now, MAC_DINH), true);
  assert.equal(V.conQuyenHuyMienPhi([{ luc: now - NGAY }, { luc: now - 2 * NGAY }], now, MAC_DINH), false);
  assert.equal(V.conQuyenHuyMienPhi([{ luc: now - 31 * NGAY }, { luc: now - 2 * NGAY }], now, MAC_DINH), true);
});
