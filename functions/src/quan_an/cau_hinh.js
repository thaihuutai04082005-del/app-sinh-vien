'use strict';

const { db } = require('../chung/firebase');
const { gopCauHinh } = require('./config');

let boNho = null;
let docLuc = 0;

/** Cấu hình đang áp dụng: mặc định (mục 3.16) gộp với ghi đè trong `qa_cau_hinh/hien_hanh`. Lưu tạm 30 giây. */
async function layCauHinh() {
  if (boNho && Date.now() - docLuc < 30 * 1000) return boNho;
  const snap = await db.collection('qa_cau_hinh').doc('hien_hanh').get();
  boNho = gopCauHinh(snap.exists ? snap.data() : null);
  docLuc = Date.now();
  return boNho;
}

function xoaBoNho() {
  boNho = null;
}

module.exports = { layCauHinh, xoaBoNho };
