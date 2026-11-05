import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  bangGia, bienSo, chuyenTrangThai, hoSoTaiXe, ketQuaDuyet, trangThaiDuyetSauKhiLuu, yeuCauMoi,
} from '../src/xe_logic.js';

const NOW = Date.UTC(2026, 9, 13, 3);
const don = (status) => ({ userId: 'sv', driverId: 'tx', status });
const loiCo = (re) => (e) => re.test(e.message);

const HO_SO = {
  vehicleType: 'xe_ba_gac', licensePlate: ' 59c1-234.56 ', vehiclePhotos: ['https://x/xe.jpg'],
  licensePhotos: ['https://x/bang.jpg'], area: ' Thủ Đức ', priceTrip: 150000,
  priceReference: 'Dưới 5km',
};

test('hồ sơ tài xế: loại xe, biển số, ảnh xe, bằng lái; bằng lái tách riêng', () => {
  const { hoSo, giayTo } = hoSoTaiXe(HO_SO);
  assert.equal(hoSo.licensePlate, '59C1-234.56');
  assert.equal(hoSo.area, 'Thủ Đức');
  assert.equal(hoSo.licensePhotos, undefined);
  assert.deepEqual(giayTo, { licensePhotos: ['https://x/bang.jpg'] });
  assert.equal(bienSo('51F12345'), '51F12345');
  assert.equal(bienSo('29A-123.45'), '29A-123.45');
  assert.throws(() => hoSoTaiXe({ ...HO_SO, vehicleType: 'xe_bay' }), loiCo(/Loại xe/));
  assert.throws(() => hoSoTaiXe({ ...HO_SO, licensePlate: 'abc' }), loiCo(/Biển số/));
  assert.throws(() => hoSoTaiXe({ ...HO_SO, vehiclePhotos: [] }), loiCo(/ảnh xe/));
  assert.throws(() => hoSoTaiXe({ ...HO_SO, licensePhotos: [] }), loiCo(/bằng lái/));
  assert.throws(() => hoSoTaiXe({ ...HO_SO, area: '' }), loiCo(/khu vực/));
});

test('lưu hồ sơ: mới / bị từ chối thì chờ duyệt; đã duyệt chỉ đổi giá thì giữ duyệt', () => {
  const moi = hoSoTaiXe(HO_SO);
  const daDuyet = { ...moi.hoSo, approval: 'approved' };
  assert.equal(trangThaiDuyetSauKhiLuu(null, null, moi), 'pending');
  assert.equal(trangThaiDuyetSauKhiLuu({ ...daDuyet, approval: 'rejected' }, moi.giayTo, moi), 'pending');
  assert.equal(trangThaiDuyetSauKhiLuu(daDuyet, moi.giayTo, hoSoTaiXe({ ...HO_SO, priceTrip: 200000 })), 'approved');
  assert.equal(trangThaiDuyetSauKhiLuu(daDuyet, moi.giayTo, hoSoTaiXe({ ...HO_SO, licensePlate: '51F12345' })), 'pending');
  assert.equal(
    trangThaiDuyetSauKhiLuu(daDuyet, moi.giayTo, hoSoTaiXe({ ...HO_SO, licensePhotos: ['https://x/moi.jpg'] })),
    'pending',
  );
});

test('admin duyệt: chỉ hồ sơ đang chờ, từ chối cần lý do', () => {
  assert.deepEqual(ketQuaDuyet({ approval: 'pending' }, { dongY: true }), { approval: 'approved', rejectReason: null });
  assert.deepEqual(
    ketQuaDuyet({ approval: 'pending' }, { dongY: false, lyDo: 'Ảnh xe mờ' }),
    { approval: 'rejected', rejectReason: 'Ảnh xe mờ' },
  );
  assert.throws(() => ketQuaDuyet({ approval: 'pending' }, { dongY: false }), loiCo(/lý do/i));
  assert.throws(() => ketQuaDuyet({ approval: 'approved' }, { dongY: true }), loiCo(/không còn chờ/));
  assert.throws(() => ketQuaDuyet(null, { dongY: true }), loiCo(/không tồn tại/));
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

test('bảng giá: cần ít nhất một mức giá, kiểm tra khoảng giá', () => {
  assert.deepEqual(bangGia({ pricePerKm: 10000, priceReference: ' Có phụ bốc xếp ' }), {
    priceTrip: null, pricePerKm: 10000, priceHourly: null, priceReference: 'Có phụ bốc xếp',
  });
  assert.throws(() => bangGia({ priceReference: '150k' }), (e) => /ít nhất một mức giá/.test(e.message));
  assert.throws(() => bangGia({ priceTrip: 5000 }), (e) => /Giá theo chuyến/.test(e.message));
  assert.throws(() => bangGia({ priceHourly: 1.5 }), (e) => /Giá theo giờ/.test(e.message));
});

test('chuyến kết thúc thì xóa vị trí tài xế', () => {
  const d = { userId: 'u', driverId: 'd', status: 'in_progress' };
  assert.equal(chuyenTrangThai(d, 'hoanThanh', 'd', {}, Date.now()).ghi.driverLastLocation, null);
  assert.equal('driverLastLocation' in chuyenTrangThai({ ...d, status: 'confirmed' }, 'batDau', 'd', {}, Date.now()).ghi, false);
});
