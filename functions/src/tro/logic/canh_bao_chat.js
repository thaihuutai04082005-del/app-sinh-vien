'use strict';

/**
 * Cảnh báo lừa đảo trong chat (mục 2.8). Logic thuần, dùng chung danh sách từ khóa cấu hình.
 * - Chuẩn hóa: chữ thường, bỏ dấu, bỏ ký tự đặc biệt / khoảng trắng thừa.
 * - "ck", "stk", "qr" phải khớp NGUYÊN TỪ (không bắt "check", "tick").
 * - "momo" chỉ cảnh báo khi đi cùng ngữ cảnh chuyển tiền.
 */

const TU_KHOA = Object.freeze({
  cum: ['chuyen khoan', 'coc truoc', 'so tai khoan', 'zalo', 'vi dien tu', 'ngan hang'],
  nguyenTu: ['ck', 'stk', 'qr'],
  momo: { tu: 'momo', nguCanh: ['chuyen', 'truoc', 'qua', 'gui', 'nap', 'bank', 'ck'] },
});

const CANH_BAO = '⚠️ Hãy đặt cọc qua app để được bảo vệ. Không chuyển tiền cọc ngoài app.';

function boDau(s) {
  return String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
}

/** Trả về { tu: [các từ / cụm bị bắt] }. */
function quet(noiDung, tuKhoa = TU_KHOA) {
  const thuong = boDau(noiDung);
  // Dạng có ranh giới từ: ký tự đặc biệt thành khoảng trắng.
  const cacTu = thuong.replace(/[^a-z0-9]+/g, ' ').trim().split(' ').filter(Boolean);
  const coKhoangTrang = ' ' + cacTu.join(' ') + ' ';
  // Dạng dính liền: bắt cả "c.h.u.y.e.n k.h.o.a.n", "chuyểnkhoản".
  const dinhLien = cacTu.join('');
  const bat = new Set();

  for (const cum of tuKhoa.cum) {
    if (coKhoangTrang.includes(' ' + cum + ' ') || dinhLien.includes(cum.replace(/ /g, ''))) bat.add(cum);
  }
  for (const tu of tuKhoa.nguyenTu) {
    // Khớp nguyên từ, hoặc từ bị tách bằng dấu chấm ("c.k" → các ký tự đơn liền nhau).
    if (cacTu.includes(tu)) bat.add(tu);
    else {
      const kyTuDon = cacTu.map((t) => (t.length === 1 ? t : '|')).join('');
      if (kyTuDon.split('|').includes(tu)) bat.add(tu);
    }
  }
  const viTriMomo = cacTu.indexOf(tuKhoa.momo.tu);
  if (viTriMomo >= 0) {
    const lanCan = cacTu.slice(Math.max(0, viTriMomo - 3), viTriMomo + 4);
    // "trả bằng momo trên app" là thanh toán hợp lệ, không cảnh báo.
    if (!lanCan.includes('app') && lanCan.some((t) => tuKhoa.momo.nguCanh.includes(t))) bat.add('momo');
  }
  return [...bat];
}

module.exports = { TU_KHOA, CANH_BAO, quet, boDau };
