'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { MAC_DINH } = require('../src/tro/config');
const K = require('../src/tro/logic/kiem_tra_tin');

const anh = ['https://x.com/1.jpg', 'https://x.com/2.jpg', 'https://x.com/3.jpg'];
const nhaHopLe = {
  ten: 'Nhà trọ Hoàng Anh', loaiHinh: 'phong', tongSoPhong: 10, soTang: 2, tienIchChung: ['wifi'],
  noiQuy: { gioGiac: 'gioi_han', gioDongCua: '22:00', thuCung: false, oQuaDem: true, baoTruocTuan: 2 },
  moTa: 'Nhà trọ sạch sẽ, gần trường, an ninh tốt, có chỗ để xe rộng.', diaChi: '12 Nguyễn Huệ, Phường 1',
  viTri: { lat: 10.46, lng: 105.63 }, anh, video: ['https://x.com/v.mp4'], anhBia: anh[0], giayTo: ['tro_rieng/u/1.jpg'], camKet: true,
};
const phongHopLe = {
  ten: 'P.101', coGac: true, dienTich: 18, dienTichGac: 10, soNguoiToiDa: 2, tienIch: ['may_lanh'],
  giaThue: 1500000, tienCoc: 1500000, tienDien: { cach: 'theo_so', gia: 3500 }, tienNuoc: { cach: 'theo_nguoi', gia: 50000 },
  phiKhac: [{ ten: 'Wifi', gia: 50000 }], anh, video: ['https://x.com/v.mp4'], anhBia: anh[1],
};

test('bỏ dấu để tìm không dấu: "Nguyễn Huệ" → "nguyen hue"', () => {
  assert.equal(K.boDau('Nguyễn Huệ, Đường (số) 5*'), 'nguyen hue duong so 5');
});

test('nhà trọ hợp lệ không có lỗi', () => {
  assert.deepEqual(K.kiemTraNhaTro(nhaHopLe, MAC_DINH), []);
});

test('nhà trọ: chưa đủ 4 tiêu chí nội quy hoặc "Có giới hạn" chưa nhập giờ thì không gửi được', () => {
  assert.ok(K.kiemTraNhaTro({ ...nhaHopLe, noiQuy: { gioGiac: 'tu_do', thuCung: true } }, MAC_DINH).length);
  assert.ok(K.kiemTraNhaTro({ ...nhaHopLe, noiQuy: { ...nhaHopLe.noiQuy, gioDongCua: '' } }, MAC_DINH).includes('Nhập giờ đóng cửa (ví dụ 22:00).'));
});

test('nhà trọ: tên 5–80 ký tự, mô tả ≥ 30, ảnh 3–10, video 1–2, có giấy tờ, cam kết', () => {
  const loi = K.kiemTraNhaTro({ ...nhaHopLe, ten: 'abc', moTa: 'ngắn', anh: anh.slice(0, 2), video: [], giayTo: [], camKet: false }, MAC_DINH);
  for (const m of ['Tên nhà trọ 5–80 ký tự.', 'Mô tả ít nhất 30 ký tự.', 'Cần 3–10 ảnh.', 'Cần 1–2 video.', 'Tick cam kết thông tin đúng sự thật.']) {
    assert.ok(loi.includes(m), m);
  }
});

test('phòng hợp lệ; tiền cọc lớn hơn 1 tháng thuê không lưu được', () => {
  assert.deepEqual(K.kiemTraPhong(phongHopLe, { loaiHinh: 'phong' }, MAC_DINH), []);
  assert.ok(K.kiemTraPhong({ ...phongHopLe, tienCoc: 1500001 }, { loaiHinh: 'phong' }, MAC_DINH).includes('Tiền cọc tối đa 1 tháng tiền thuê.'));
});

test('phòng: tên không trùng trong cùng nhà trọ (không phân biệt dấu, hoa thường)', () => {
  assert.ok(K.kiemTraPhong(phongHopLe, { loaiHinh: 'phong', tenKhac: ['p.101'] }, MAC_DINH).includes('Tên phòng bị trùng trong nhà trọ.'));
});

test('nguyên căn cần số phòng ngủ, WC, bếp; không cần chọn gác', () => {
  const p = { ...phongHopLe, coGac: undefined };
  const loi = K.kiemTraPhong(p, { loaiHinh: 'nguyen_can' }, MAC_DINH);
  assert.ok(loi.includes('Nhập số phòng ngủ.'));
  assert.ok(!loi.includes('Chọn có gác hay không.'));
  assert.deepEqual(K.kiemTraPhong({ ...p, soPhongNgu: 2, soWc: 1, coBep: true }, { loaiHinh: 'nguyen_can' }, MAC_DINH), []);
});
