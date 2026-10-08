'use strict';

/**
 * Cảnh báo lừa đảo trong chat (mục 3.8). Logic thuần; danh sách từ khóa đặt ở `config.js`.
 * - Chuẩn hóa: chữ thường, bỏ dấu, bỏ ký tự đặc biệt / khoảng trắng thừa.
 * - "ck", "stk", "qr" phải khớp NGUYÊN TỪ (không bắt "check", "tick").
 * - "momo" chỉ cảnh báo khi đi cùng ngữ cảnh chuyển tiền ("trả bằng momo trên app" là hợp lệ).
 */

const { TU_KHOA_CANH_BAO } = require('../config');

const CANH_BAO = '⚠️ Hãy thanh toán qua app để được bảo vệ. Không chuyển tiền trước khi nhận món.';

function boDau(s) {
  return String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
}

/** Trả về danh sách từ / cụm bị bắt. */
function quet(noiDung, tuKhoa = TU_KHOA_CANH_BAO) {
  const thuong = boDau(noiDung);
  const cacTu = thuong.replace(/[^a-z0-9]+/g, ' ').trim().split(' ').filter(Boolean);
  const coKhoangTrang = ' ' + cacTu.join(' ') + ' ';
  const dinhLien = cacTu.join('');
  const bat = new Set();

  for (const cum of tuKhoa.cum) {
    if (coKhoangTrang.includes(' ' + cum + ' ') || dinhLien.includes(cum.replace(/ /g, ''))) bat.add(cum);
  }
  for (const tu of tuKhoa.nguyenTu) {
    if (cacTu.includes(tu)) bat.add(tu);
    else {
      const kyTuDon = cacTu.map((t) => (t.length === 1 ? t : '|')).join('');
      if (kyTuDon.split('|').includes(tu)) bat.add(tu);
    }
  }
  const viTriMomo = cacTu.indexOf(tuKhoa.momo.tu);
  if (viTriMomo >= 0) {
    const lanCan = cacTu.slice(Math.max(0, viTriMomo - 3), viTriMomo + 4);
    if (!lanCan.includes('app') && lanCan.some((t) => tuKhoa.momo.nguCanh.includes(t))) bat.add('momo');
  }
  return [...bat];
}

module.exports = { CANH_BAO, quet, boDau };
