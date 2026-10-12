'use strict';

/** Tên collection và hàm dùng chung của module Quán ăn (tiền tố `qa_`). */

const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung } = require('../chung/loi');
const { docAdmin } = require('../chung/tai_khoan');
const { ghiThongBao, dayThongBao } = require('./thong_bao');
const { dauNgayVn, NGAY_MS } = require('./logic/gio_mo_cua');

const COL = Object.freeze({
  quan: 'qa_quan', nhomMon: 'qa_nhom_mon', mon: 'qa_mon', khuyenMai: 'qa_khuyen_mai', checkIn: 'qa_check_in',
  datBan: 'qa_dat_ban', don: 'qa_don', khoanTien: 'qa_khoan_tien', cong: 'qa_cong_gia_lap', vi: 'qa_vi',
  hoSo: 'qa_ho_so', khoa: 'qa_khoa', viPham: 'qa_vi_pham', chiSoChu: 'qa_chi_so_chu', chat: 'qa_chat',
  danhGia: 'qa_danh_gia', luu: 'qa_luu', baoCao: 'qa_bao_cao', baoCaoSai: 'qa_bao_cao_sai', khangNghi: 'qa_khang_nghi',
  thongBao: 'qa_thong_bao', nhatKy: 'qa_nhat_ky_admin', khieuNaiSai: 'qa_khieu_nai_sai',
});

async function ghiNhatKy(adminUid, viec, doiTuong, ghiChu = '') {
  await db.collection(COL.nhatKy).add({ adminUid, viec, doiTuong, ghiChu, luc: Timestamp.now() });
}

/** Ghi và đẩy nhiều thông báo (ngoài transaction). Mỗi tin: { khoa, nguoiNhan, loai, bien?, moTrang?, tieuDe?, noiDung?, nhom? }. */
async function thongBao(cacTin) {
  const batch = db.batch();
  const ids = [];
  for (const tin of cacTin) {
    const caiDatSnap = tin.nguoiNhan ? await db.collection(COL.hoSo).doc(tin.nguoiNhan).get() : null;
    const id = ghiThongBao(batch, { ...tin, caiDat: (caiDatSnap && caiDatSnap.exists && caiDatSnap.get('caiDatThongBao')) || {} });
    if (id) ids.push(id);
  }
  if (ids.length) await batch.commit();
  await dayThongBao(ids);
}

async function cacAdminQuanAn() {
  const snap = await db.collection('admins').where('quanAn', '==', true).get();
  return snap.docs.map((d) => d.id);
}

async function laAdminQuanAn(uid) {
  const a = await docAdmin(uid);
  return !!a.quanAn;
}

/** Bị khóa bán vĩnh viễn trong Quán ăn: không đăng quán, không nhận đơn mới (mục 3.14). */
function kiemTraKhoaBan(quan) {
  if (quan && quan.khoaBan) throw loiNguoiDung('Bạn đã bị khóa bán trong Quán ăn.', 'permission-denied');
}

const fmtGio = (t) => new Date(t).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });

/** Hết ngày hôm nay (00:00 ngày mai giờ Việt Nam) — hạn "tạm ngưng nhận đơn tới hết ngày". */
const hetNgayVn = (t) => dauNgayVn(t) + NGAY_MS;

/** Tài liệu `qa_khoa/{khoa}`: khóa chức năng của một số điện thoại (hoặc uid) trong module. */
async function docKhoa(khoa, tx = null) {
  const ref = db.collection(COL.khoa).doc(khoa);
  const snap = tx ? await tx.get(ref) : await ref.get();
  return snap.exists ? snap.data() : {};
}

function conKhoa(k, truong, now = Date.now()) {
  return !!k && ms(k[truong]) != null && ms(k[truong]) > now;
}

module.exports = { COL, ghiNhatKy, thongBao, cacAdminQuanAn, laAdminQuanAn, kiemTraKhoaBan, fmtGio, hetNgayVn, docKhoa, conKhoa };
