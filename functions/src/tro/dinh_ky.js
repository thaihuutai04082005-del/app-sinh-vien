'use strict';

/**
 * Việc chạy định kỳ (mỗi phút) của module Tìm trọ: xử lý mọi hạn đã tới của khoản cọc,
 * hết hạn nhà trọ, nhắc cọc trực tiếp. Chạy lại / chạy trễ không làm 2 lần (logic có khóa riêng).
 */

const { db, Timestamp } = require('../chung/firebase');
const { chayTrenKhoanCoc } = require('./dat_coc_service');
const { xuLyHetHanNhaTro } = require('./nha_tro_service');
const { nhacChuaCapNhat } = require('./coc_truc_tiep_service');

async function chay(now = Date.now()) {
  const den = await db.collection('tro_dat_coc')
    .where('status', 'in', ['pending_payment', 'held', 'disputed'])
    .where('hanKeTiep', '<=', Timestamp.fromMillis(now))
    .limit(200).get();
  let xong = 0;
  for (const doc of den.docs) {
    try {
      await chayTrenKhoanCoc(doc.id, { now });
      xong++;
    } catch (e) {
      console.error('Xử lý hạn khoản cọc lỗi', doc.id, e.message);
    }
  }
  await xuLyHetHanNhaTro(now).catch((e) => console.error('Hết hạn nhà trọ lỗi', e.message));
  await nhacChuaCapNhat(now).catch((e) => console.error('Nhắc cọc trực tiếp lỗi', e.message));
  return { khoanCoc: xong };
}

module.exports = { chay };
