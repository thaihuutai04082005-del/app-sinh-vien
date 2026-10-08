'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const K = require('../src/quan_an/logic/kiem_tra');
const C = require('../src/quan_an/logic/canh_bao_chat');
const { MAC_DINH } = require('../src/quan_an/config');

const cfg = MAC_DINH;
const lich = { 1: [{ tu: 360, den: 600 }], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [] };
const quanBanLe = () => ({
  ten: 'Xe bánh mì Cô Ba', loaiQuan: 'ban_le', loaiMon: ['banh_mi'], moTa: 'Bánh mì nóng giòn mỗi sáng.', sdt: '0901234567',
  diaChi: '12 Lê Lợi, Cao Lãnh', viTri: { lat: 10.4, lng: 105.6 }, luuDong: false, gioMoCua: lich, phucVu: { anTaiQuan: false, mangDi: true },
  tienIch: ['do_xe'], anhMatTien: ['https://x.test/a.jpg'], camKet: true,
});
const quanHkd = () => ({
  ...quanBanLe(), loaiQuan: 'ho_kinh_doanh', nhanDatBan: true,
  datMon: { bat: true, denLay: true, giaoTanNoi: true, banKinhKm: 3, phiGiaoKieu: 'co_dinh', phiGiao: 10000, donToiThieu: 30000, chuanBiPhut: 15, tienMat: true },
});

test('quán bán lẻ hợp lệ không có lỗi, không cần giấy tờ', () => {
  assert.deepEqual(K.kiemTraQuan(quanBanLe(), null, cfg), []);
});

test('hộ kinh doanh không có mã số thuế / ảnh giấy chứng nhận thì không gửi duyệt được', () => {
  const l = K.kiemTraQuan(quanHkd(), {}, cfg);
  assert.ok(l.some((x) => /mã số thuế/.test(x)));
  assert.ok(l.some((x) => /giấy chứng nhận/.test(x)));
  assert.deepEqual(K.kiemTraQuan(quanHkd(), { maSoThue: '0312345678', anhGiayChungNhan: ['https://x.test/g.jpg'] }, cfg), []);
});

test('quán bán lẻ không bật được đặt bàn và đặt món qua app', () => {
  const l = K.kiemTraQuan({ ...quanBanLe(), nhanDatBan: true, datMon: { bat: true } }, null, cfg);
  assert.ok(l.some((x) => /không nhận đặt bàn/.test(x)));
  assert.ok(l.some((x) => /không nhận đặt món/.test(x)));
});

test('không chọn hình thức phục vụ nào, không có ảnh mặt tiền, thiếu cam kết đều bị chặn', () => {
  const l = K.kiemTraQuan({ ...quanBanLe(), phucVu: { anTaiQuan: false, mangDi: false }, anhMatTien: [], camKet: false }, null, cfg);
  assert.ok(l.some((x) => /hình thức phục vụ/.test(x)));
  assert.ok(l.some((x) => /ảnh mặt tiền/.test(x)));
  assert.ok(l.some((x) => /cam kết/.test(x)));
});

test('quán lưu động bắt buộc ghi chú chỗ bán thường xuyên', () => {
  assert.ok(K.kiemTraQuan({ ...quanBanLe(), luuDong: true, ghiChuViTri: '' }, null, cfg).some((x) => /lưu động/.test(x)));
});

test('cảnh báo khai sai loại: máy lạnh, menu > 40 món, mở > 14 giờ', () => {
  assert.deepEqual(K.canhBaoKhaiSai(quanBanLe(), 10, cfg), []);
  assert.equal(K.canhBaoKhaiSai({ ...quanBanLe(), tienIch: ['may_lanh'] }, 10, cfg).length, 1);
  assert.equal(K.canhBaoKhaiSai(quanBanLe(), 41, cfg).length, 1);
  assert.equal(K.canhBaoKhaiSai({ ...quanBanLe(), gioMoCua: { ...lich, 1: [{ tu: 360, den: 1380 }] } }, 5, cfg).length, 1);
  assert.deepEqual(K.canhBaoKhaiSai(quanHkd(), 100, cfg), []); // chỉ áp cho quán khai bán lẻ
});

test('món: giá > 0, tên 2–60, tùy chọn hợp lệ', () => {
  const tot = { ten: 'Cơm gà', gia: 35000, tuyChon: [{ ten: 'Cỡ', batBuoc: true, toiDa: 1, lua: [{ ten: 'Nhỏ', giaThem: 0 }, { ten: 'Lớn', giaThem: 5000 }] }] };
  assert.deepEqual(K.kiemTraMon(tot), []);
  assert.ok(K.kiemTraMon({ ...tot, gia: 0 }).length);
  assert.ok(K.kiemTraMon({ ...tot, ten: 'A' }).length);
  assert.ok(K.kiemTraMon({ ...tot, tuyChon: [{ ten: 'Cỡ', batBuoc: true, toiDa: 3, lua: [{ ten: 'Nhỏ', giaThem: 0 }] }] }).length);
});

test('khuyến mãi: tối đa 90 ngày, giới hạn số lượng theo loại quán', () => {
  const now = Date.UTC(2026, 9, 7);
  const km = { loai: 'giam_tien', tieuDe: 'Giảm 15k', giamTien: 15000, donToiThieu: 80000, batDau: now, ketThuc: now + 30 * 86400000 };
  assert.deepEqual(K.kiemTraKhuyenMai(km, { loaiQuan: 'ho_kinh_doanh', soDangChay: 4, now }, cfg), []);
  assert.ok(K.kiemTraKhuyenMai(km, { loaiQuan: 'ho_kinh_doanh', soDangChay: 5, now }, cfg).some((x) => /tối đa 5/.test(x)));
  assert.ok(K.kiemTraKhuyenMai(km, { loaiQuan: 'ban_le', soDangChay: 1, now }, cfg).some((x) => /tối đa 1/.test(x)));
  assert.ok(K.kiemTraKhuyenMai({ ...km, ketThuc: now + 91 * 86400000 }, { loaiQuan: 'ban_le', soDangChay: 0, now }, cfg).some((x) => /90 ngày/.test(x)));
});

test('chữ tìm kiếm không dấu gồm tên quán, tên món, đường, phường', () => {
  const s = K.chuTimKiem({ ten: 'Bún Bò Huế Cô Lan', diaChi: '12 Đường Nguyễn Huệ', phuong: 'Phường 1' }, ['Bún bò', 'Chả cua']);
  assert.ok(s.includes('bun bo hue co lan') && s.includes('cha cua') && s.includes('nguyen hue') && s.includes('phuong 1'));
});

test('cảnh báo lừa đảo trong chat: chuyển khoản, CK, momo có ngữ cảnh; "check", "momo trên app" thì không', () => {
  for (const t of ['Chuyển khoản trước nha', 'chuyen khoan', 'CK trước giúp mình', 'c.k nhé', 'cho xin STK', 'gửi mã QR đi']) {
    assert.ok(C.quet(t).length, t);
  }
  for (const t of ['check giúp mình', 'tick vào đây', 'trả bằng momo trên app', 'Quán còn mở không ạ?']) {
    assert.equal(C.quet(t).length, 0, t);
  }
  assert.ok(C.quet('chuyển momo trước cho anh').includes('momo'));
});
