'use strict';

const { PHUT } = require('../config');

/**
 * Bộ đếm vi phạm theo cửa sổ trượt (mục 3.5, 3.16): chỉ đếm các lần còn hiệu lực
 * (chưa được gỡ qua kháng nghị) trong `cuaSoPhut` gần nhất.
 */
function demTrongCuaSo(danhSach, now, cuaSoPhut) {
  const tu = now - cuaSoPhut * PHUT;
  return danhSach.filter((v) => !v.daGo && v.luc > tu && v.luc <= now).length;
}

/**
 * Tính hạn khóa sau khi ghi thêm một lần vi phạm.
 * Đủ `soLan` trong cửa sổ → khóa `khoaPhut` kể từ lúc này; chưa đủ → null.
 */
function hanKhoaMoi(danhSach, now, { soLan, cuaSoPhut, khoaPhut }) {
  return demTrongCuaSo(danhSach, now, cuaSoPhut) >= soLan ? now + khoaPhut * PHUT : null;
}

module.exports = { demTrongCuaSo, hanKhoaMoi };
