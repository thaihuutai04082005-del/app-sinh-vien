'use strict';

/**
 * Việc chạy định kỳ (mỗi phút) của module Quán ăn: xử lý mọi hạn đã tới của đơn và bàn, nhắc "quán còn hoạt động",
 * khuyến mãi hết hạn. Chạy lại / chạy trễ không làm 2 lần (logic có khóa riêng, mục 3.18 quy tắc 6).
 */

const { db, Timestamp } = require('../chung/firebase');
const { chayTrenDon } = require('./don_mon_service');
const { chayTrenBan } = require('./dat_ban_service');
const { xuLyHetHanQuan, tinhHangDem } = require('./quan_service');
const { DANG_CHAY } = require('./logic/don_mon');
const { COL } = require('./ho_tro');

async function chay(now = Date.now()) {
  const moc = Timestamp.fromMillis(now);
  const [don, ban] = await Promise.all([
    db.collection(COL.don).where('status', 'in', [...DANG_CHAY]).where('hanKeTiep', '<=', moc).limit(200).get(),
    db.collection(COL.datBan).where('status', 'in', ['pending', 'confirmed']).where('hanKeTiep', '<=', moc).limit(200).get(),
  ]);
  let soDon = 0;
  let soBan = 0;
  for (const d of don.docs) {
    try { await chayTrenDon(d.id, { now }); soDon++; } catch (e) { console.error('Xử lý hạn đơn lỗi', d.id, e.message); }
  }
  for (const d of ban.docs) {
    try { await chayTrenBan(d.id, { now }); soBan++; } catch (e) { console.error('Xử lý hạn bàn lỗi', d.id, e.message); }
  }
  await xuLyHetHanQuan(now).catch((e) => console.error('Hết hạn quán lỗi', e.message));
  return { don: soDon, ban: soBan };
}

/** Mỗi đêm: nhãn "Sinh viên hay ăn", số liệu 30 ngày, tỷ lệ nhận đơn / giữ bàn. */
async function hangDem() {
  return tinhHangDem();
}

module.exports = { chay, hangDem };
