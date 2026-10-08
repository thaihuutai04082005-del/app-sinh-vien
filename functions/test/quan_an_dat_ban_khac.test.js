'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const B = require('../src/quan_an/logic/dat_ban');
const H = require('../src/quan_an/logic/hay_an');
const DG = require('../src/quan_an/logic/danh_gia');
const { MAC_DINH, PHUT } = require('../src/quan_an/config');

const cfg = MAC_DINH;
const T0 = Date.UTC(2026, 9, 7, 5, 0);
const phut = (n) => n * PHUT;
const GIO_HEN = T0 + phut(180);
const ban = () => B.taoBan({ now: T0, gio: GIO_HEN }, cfg);
const ap = (d, su, now) => B.apDung(d, su, now, cfg);

test('đặt bàn: cách ≥ 1 giờ, trong 7 ngày, 1–20 người, trong giờ mở cửa', () => {
  const k = (o) => B.kiemTraDatBan({ now: T0, gio: T0 + phut(120), soNguoi: 4, trongGioMoCua: true, ...o }, cfg);
  assert.equal(k({}), null);
  assert.match(k({ gio: T0 + phut(59) }), /ít nhất 1 giờ/);
  assert.match(k({ gio: T0 + phut(8 * 24 * 60) }), /7 ngày/);
  assert.match(k({ soNguoi: 0 }), /Số người/);
  assert.match(k({ soNguoi: 21 }), /Số người/);
  assert.match(k({ trongGioMoCua: false }), /không mở cửa/);
});

test('hạn quán xác nhận = min(gửi + 30 phút, giờ hẹn − 30 phút)', () => {
  assert.equal(ban().hanXacNhan, T0 + phut(30));
  const gan = B.taoBan({ now: T0, gio: T0 + phut(60) }, cfg);
  assert.equal(gan.hanXacNhan, T0 + phut(30));
  const sat = B.taoBan({ now: T0, gio: T0 + phut(45) }, cfg);
  assert.equal(sat.hanXacNhan, T0 + phut(15));
});

test('quán không xác nhận kịp → expired', () => {
  const { d } = B.xuLyHan(ban(), T0 + phut(31), cfg);
  assert.equal(d.status, 'expired');
});

test('quán xác nhận trong hạn; quá hạn thì không xác nhận được', () => {
  assert.equal(ap(ban(), { loai: 'QUAN_XAC_NHAN' }, T0 + phut(10)).d.status, 'confirmed');
  assert.match(ap(ban(), { loai: 'QUAN_XAC_NHAN' }, T0 + phut(31)).loi, /quá hạn/);
  assert.equal(ap(ban(), { loai: 'QUAN_TU_CHOI' }, T0 + phut(10)).d.status, 'rejected');
});

const xacNhan = () => ap(ban(), { loai: 'QUAN_XAC_NHAN' }, T0 + phut(10)).d;

test('hủy khi quán CHƯA xác nhận: không phạt dù sát giờ', () => {
  const d = B.taoBan({ now: T0, gio: T0 + phut(90) }, cfg);
  const r = ap(d, { loai: 'SV_HUY' }, T0 + phut(80));
  assert.equal(r.d.status, 'cancelled_student');
  assert.deepEqual(r.viPham, []);
});

test('hủy bàn đã xác nhận: trước ≥ 1 giờ không phạt; dưới 1 giờ tính 1 lần bỏ hẹn', () => {
  const ok = ap(xacNhan(), { loai: 'SV_HUY' }, GIO_HEN - phut(61));
  assert.deepEqual(ok.viPham, []);
  const sat = ap(xacNhan(), { loai: 'SV_HUY' }, GIO_HEN - phut(59));
  assert.deepEqual(sat.viPham, ['bo_hen_dat_ban']);
  assert.equal(sat.d.huySatGio, true);
});

test('"Khách không đến": chỉ sau 15 phút giữ bàn; tính 1 lần bỏ hẹn', () => {
  const d = xacNhan();
  assert.match(ap(d, { loai: 'QUAN_KHONG_DEN' }, GIO_HEN + phut(14)).loi, /15 phút/);
  const r = ap(d, { loai: 'QUAN_KHONG_DEN' }, GIO_HEN + phut(15));
  assert.equal(r.d.status, 'no_show');
  assert.deepEqual(r.viPham, ['bo_hen_dat_ban']);
});

test('SV check-in hợp lệ trong giờ giữ bàn → arrived (nhãn 🍽) và nút "Khách không đến" bị vô hiệu', () => {
  const c = ap(xacNhan(), { loai: 'SV_CHECK_IN' }, GIO_HEN + phut(5));
  assert.equal(c.d.status, 'arrived');
  assert.equal(c.d.ghiNhanDen, 'check_in');
  assert.match(ap(c.d, { loai: 'QUAN_KHONG_DEN' }, GIO_HEN + phut(20)).loi, /đã xác nhận/);
});

test('check-in ngoài khoảng giờ giữ bàn không tác dụng', () => {
  assert.ok(ap(xacNhan(), { loai: 'SV_CHECK_IN' }, GIO_HEN - phut(31)).boQua);
  assert.ok(ap(xacNhan(), { loai: 'SV_CHECK_IN' }, GIO_HEN + phut(16)).boQua);
});

test('quán bấm "Khách đã đến" không cấp nhãn 🍽; sau đó SV check-in hợp lệ thì nâng lên nhãn 🍽', () => {
  const q = ap(xacNhan(), { loai: 'QUAN_KHACH_DEN' }, GIO_HEN + phut(2));
  assert.equal(q.d.ghiNhanDen, 'quan');
  const c = ap(q.d, { loai: 'SV_CHECK_IN' }, GIO_HEN + phut(5));
  assert.equal(c.d.ghiNhanDen, 'check_in');
});

test('bàn đã xác nhận mà quán không bấm gì: hết giờ giữ bàn + 24 giờ tự đóng, không bỏ hẹn, không nhãn 🍽', () => {
  const d = xacNhan();
  const { d: d2, tacDong } = B.xuLyHan(d, d.hanTuDong, cfg);
  assert.equal(d2.status, 'arrived');
  assert.equal(d2.ghiNhanDen, 'tu_dong');
  assert.deepEqual(tacDong.flatMap((t) => t.viPham), []);
});

test('nhắc 1 giờ trước giờ hẹn, đúng 1 lần', () => {
  const d = xacNhan();
  const a = B.xuLyHan(d, GIO_HEN - phut(60), cfg);
  assert.equal(a.tacDong.length, 1);
  assert.equal(B.xuLyHan(a.d, GIO_HEN - phut(30), cfg).tacDong.length, 0);
});

test('quán hủy bàn đã xác nhận → giảm tỷ lệ giữ bàn; quán tạm nghỉ → bàn bị hủy, không tính lỗi SV', () => {
  const q = ap(xacNhan(), { loai: 'QUAN_HUY' }, T0 + phut(60));
  assert.equal(q.d.status, 'cancelled_restaurant');
  const n = ap(xacNhan(), { loai: 'QUAN_NGUNG_NHAN', lyDo: 'admin_an' }, T0 + phut(60));
  assert.equal(n.d.status, 'cancelled_restaurant');
  assert.deepEqual(n.viPham, []);
  assert.equal(H.tyLeGiuBan([{ xacNhanLuc: 1, status: 'arrived' }, { xacNhanLuc: 1, status: 'cancelled_restaurant', lyDoKetThuc: 'quan_huy' }]), 50);
  assert.equal(H.tyLeGiuBan([{ xacNhanLuc: 1, status: 'cancelled_restaurant', lyDoKetThuc: 'admin_an' }]), 100);
  assert.equal(H.tyLeGiuBan([]), null);
});

test('tỷ lệ nhận đơn: không tính SV hủy / hết hạn thanh toán / quán ngừng nhận do admin', () => {
  const ds = [
    { status: 'completed' }, { status: 'completed' }, { status: 'cancelled_student' }, { status: 'expired' },
    { status: 'rejected' }, { status: 'cancelled_restaurant', lyDoKetThuc: 'restaurant_late' },
    { status: 'cancelled_restaurant', lyDoKetThuc: 'restaurant_stopped' },
  ];
  assert.equal(H.tyLeNhanDon(ds), 60); // tính 5 đơn (2 hoàn tất, 1 từ chối, 1 quán chậm, 1 quán ngừng nhận); 2 đơn lỗi của quán → 3/5
  assert.equal(H.tyLeNhanDon([]), null);
});

test('"Sinh viên hay ăn": đếm người khác nhau, không tính chủ quán, ≥ 10 người và top 20% trong 3 km', () => {
  const luot = [];
  const nguoi = (q, n) => { for (let i = 0; i < n; i++) luot.push({ quanId: q, uid: `u${i}`, luc: 5 }); };
  nguoi('a', 12); nguoi('b', 11); nguoi('c', 3);
  luot.push({ quanId: 'a', uid: 'u1', luc: 6 }, { quanId: 'a', uid: 'chu', luc: 6 });
  const dem = H.demNguoiTheoQuan(luot, new Map([['a', 'chu']]), 0, 10);
  assert.equal(dem.get('a'), 12);
  assert.equal(dem.get('b'), 11);
  const quan = [{ id: 'a', lat: 10, lng: 105 }, { id: 'b', lat: 10.001, lng: 105 }, { id: 'c', lat: 10.002, lng: 105 },
    { id: 'd', lat: 10.003, lng: 105 }, { id: 'e', lat: 10.004, lng: 105 }, { id: 'xa', lat: 11, lng: 106 }];
  const co = H.quanHayAn(quan, dem, { soNguoi: 10, topPhanTram: 20, banKinhMet: 3000 });
  assert.ok(co.has('a')); // hạng 1 / 5 quán lân cận → top 20%
  assert.ok(!co.has('b')); // đủ 10 người nhưng hạng 2 / 5, ngoài top 20%
  assert.ok(!co.has('c')); // dưới 10 người
});

test('đánh giá: điểm tổng thể = trung bình 4 tiêu chí (5·4·3·4 → 4,0); thiếu tiêu chí thì không có điểm', () => {
  assert.equal(DG.diemTong({ monAn: 5, giaCa: 4, veSinh: 3, phucVu: 4 }), 4);
  assert.equal(DG.diemTong({ monAn: 5, giaCa: 4, veSinh: 3 }), null);
  assert.equal(DG.diemTong({ monAn: 5, giaCa: 4, veSinh: 6, phucVu: 4 }), null);
});

test('điểm quán chỉ tính đánh giá đã xác minh; chưa xác minh hiện điểm phụ; đánh giá bị ẩn không tính', () => {
  const dg = (m, g, v, p, o = {}) => ({ diem: { monAn: m, giaCa: g, veSinh: v, phucVu: p }, diemTong: (m + g + v + p) / 4, tinhDiem: true, trangThaiHienThi: 'hien', ...o });
  const r = DG.tinhDiemQuan([
    dg(5, 5, 4, 5), dg(4, 5, 4, 3), dg(1, 1, 1, 1, { tinhDiem: false }), dg(1, 1, 1, 1, { trangThaiHienThi: 'an' }),
  ]);
  assert.equal(r.soDanhGia, 2);
  assert.equal(r.diemTong, 4.4); // (4.75 + 4) / 2 = 4.375 → làm tròn 1 chữ số = 4.4
  assert.equal(r.diemTieuChi.monAn, 4.5);
  assert.equal(r.soDanhGiaChuaXm, 1);
  assert.equal(r.diemChuaXm, 1);
  assert.equal(DG.tinhDiemQuan([]).diemTong, null);
});

test('nhãn mạnh nhất: 🛵 > 🍽 > 📍 > chưa xác minh', () => {
  assert.equal(DG.nhanManhNhat({ dat_mon: true, dat_ban: true, check_in: true }), 'dat_mon');
  assert.equal(DG.nhanManhNhat({ dat_ban: true, check_in: true }), 'dat_ban');
  assert.equal(DG.nhanManhNhat({ check_in: true }), 'check_in');
  assert.equal(DG.nhanManhNhat({}), null);
});
