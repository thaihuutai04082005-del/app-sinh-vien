import assert from 'node:assert/strict';
import { test } from 'node:test';
import { chuyenTrangThai, hoSoTaiXe, yeuCauMoi } from '../src/xe_logic.js';

const NOW = Date.UTC(2026, 9, 13, 3);
const don = (status) => ({ userId: 'sv', driverId: 'tx', status });
const loiCo = (re) => (e) => re.test(e.message);

test('hồ sơ tài xế cần loại xe hợp lệ và khu vực', () => {
  assert.deepEqual(
    hoSoTaiXe({ vehicleType: 'xe_ba_gac', area: ' Thủ Đức ', priceReference: '150k/chuyến' }),
    { vehicleType: 'xe_ba_gac', area: 'Thủ Đức', priceReference: '150k/chuyến', description: '' },
  );
  assert.throws(() => hoSoTaiXe({ vehicleType: 'xe_bay', area: 'A', priceReference: 'B' }), loiCo(/Loại xe/));
  assert.throws(() => hoSoTaiXe({ vehicleType: 'xe_may', area: '', priceReference: 'B' }), loiCo(/khu vực/));
});

test('yêu cầu mới: cần ảnh, số điện thoại, giờ trong 90 ngày', () => {
  const hop = {
    driverId: 'tx', fromAddress: 'KTX A', toAddress: 'Q.9', contactPhone: '+84 912 345 678',
    itemPhotos: ['https://x/1.jpg'], scheduledAt: NOW + 3600_000,
  };
  const yc = yeuCauMoi(hop, NOW);
  assert.equal(yc.contactPhone, '0912345678');
  assert.deepEqual(yc.videos, []);
  assert.throws(() => yeuCauMoi({ ...hop, itemPhotos: [] }, NOW), loiCo(/ảnh đồ đạc/));
  assert.throws(() => yeuCauMoi({ ...hop, itemPhotos: ['http://x'] }, NOW), loiCo(/ảnh đồ đạc/));
  assert.throws(() => yeuCauMoi({ ...hop, contactPhone: '123' }, NOW), loiCo(/điện thoại/));
  assert.throws(() => yeuCauMoi({ ...hop, scheduledAt: NOW - 86_400_000 }, NOW), loiCo(/90 ngày/));
  assert.throws(() => yeuCauMoi({ ...hop, scheduledAt: NOW + 91 * 86_400_000 }, NOW), loiCo(/90 ngày/));
});

test('luồng đủ: báo giá → chấp nhận → bắt đầu → hoàn thành', () => {
  let d = don('pending');
  const bg = chuyenTrangThai(d, 'baoGia', 'tx', { price: 350000 }, NOW);
  assert.deepEqual(bg.ghi, { status: 'quoted', quotedPrice: 350000 });
  assert.deepEqual(bg.lichSuMoi, { status: 'quoted', by: 'driver', at: NOW, price: 350000 });
  d = { ...d, ...bg.ghi };
  // Tài xế báo lại giá khi khách chưa chốt.
  assert.equal(chuyenTrangThai(d, 'baoGia', 'tx', { price: 300000 }, NOW).ghi.quotedPrice, 300000);
  d = { ...d, ...chuyenTrangThai(d, 'chapNhan', 'sv', {}, NOW).ghi };
  assert.equal(d.status, 'confirmed');
  d = { ...d, ...chuyenTrangThai(d, 'batDau', 'tx', {}, NOW).ghi };
  assert.equal(d.status, 'in_progress');
  d = { ...d, ...chuyenTrangThai(d, 'hoanThanh', 'tx', {}, NOW).ghi };
  assert.equal(d.status, 'done');
});

test('đúng người mới được làm', () => {
  assert.throws(() => chuyenTrangThai(don('pending'), 'baoGia', 'sv', { price: 100000 }, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThai(don('quoted'), 'chapNhan', 'tx', {}, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThai(don('pending'), 'huy', 'nguoi_la', { reason: 'x' }, NOW), loiCo(/quyền/));
});

test('không nhảy cóc trạng thái, không chấp nhận khi chưa có giá', () => {
  assert.throws(() => chuyenTrangThai(don('pending'), 'chapNhan', 'sv', {}, NOW), loiCo(/trạng thái/));
  assert.throws(() => chuyenTrangThai(don('pending'), 'batDau', 'tx', {}, NOW), loiCo(/trạng thái/));
  assert.throws(() => chuyenTrangThai(don('confirmed'), 'baoGia', 'tx', { price: 100000 }, NOW), loiCo(/trạng thái/));
  assert.throws(() => chuyenTrangThai(don('pending'), 'baoGia', 'tx', { price: 500 }, NOW), loiCo(/Giá báo/));
  assert.throws(() => chuyenTrangThai(don('pending'), 'baoGia', 'tx', { price: 1.5e5 + 0.5 }, NOW), loiCo(/Giá báo/));
});

test('hủy: cả hai bên, cần lý do, không hủy khi đang chuyển', () => {
  const h = chuyenTrangThai(don('confirmed'), 'huy', 'tx', { reason: 'Xe hỏng' }, NOW);
  assert.deepEqual(h.ghi, { status: 'cancelled', cancelledBy: 'driver', cancelReason: 'Xe hỏng' });
  assert.equal(chuyenTrangThai(don('pending'), 'huy', 'sv', { reason: 'Đổi lịch' }, NOW).ghi.cancelledBy, 'user');
  assert.throws(() => chuyenTrangThai(don('pending'), 'huy', 'sv', {}, NOW), loiCo(/lý do/i));
  assert.throws(() => chuyenTrangThai(don('in_progress'), 'huy', 'sv', { reason: 'x' }, NOW), loiCo(/trạng thái/));
  assert.throws(() => chuyenTrangThai(don('done'), 'huy', 'tx', { reason: 'x' }, NOW), loiCo(/trạng thái/));
});

test('hành động lạ bị từ chối', () => {
  assert.throws(() => chuyenTrangThai(don('pending'), 'xoa', 'sv', {}, NOW), loiCo(/Hành động/));
});
