'use strict';

/** Menu (nhóm món, món) và khuyến mãi của quán (mục 3.3 Bước 3–4). Sửa menu, giá hiện ngay, không cần duyệt. */

const { db, Timestamp, ms, ts } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { layCauHinh } = require('./cau_hinh');
const K = require('./logic/kiem_tra');
const { COL, kiemTraKhoaBan } = require('./ho_tro');
const QS = require('./quan_service');

async function quanCuaChu(uid, quanId) {
  const { ref, quan } = await QS.layQuanCuaChu(uid, quanId);
  kiemTraKhoaBan(quan);
  if (['suspended', 'closed'].includes(quan.trangThai)) throw loiNguoiDung('Quán này không sửa menu được.');
  return { ref, quan };
}

async function chamHoatDong(ref) {
  await ref.update({ hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null });
}

// ---------------------------------------------------------------- Nhóm món

async function luuNhomMon({ uid }, { quanId, nhomId = null, ten, laDoUong, thuTu = 0 }) {
  const cfg = await layCauHinh();
  const { ref } = await quanCuaChu(uid, quanId);
  const loi = K.kiemTraNhomMon({ ten, laDoUong });
  if (loi.length) throw thamSoSai(loi.join(' '));
  let docRef;
  if (nhomId) {
    docRef = db.collection(COL.nhomMon).doc(nhomId);
    const s = await docRef.get();
    if (!s.exists || s.get('quanId') !== quanId) throw khongTimThay('Nhóm món');
  } else {
    const dem = await db.collection(COL.nhomMon).where('quanId', '==', quanId).get();
    if (dem.size >= cfg.nhomMonToiDa) throw loiNguoiDung(`Tối đa ${cfg.nhomMonToiDa} nhóm món.`);
    docRef = db.collection(COL.nhomMon).doc();
  }
  await docRef.set({ quanId, chuQuanId: uid, ten: String(ten).trim(), laDoUong: !!laDoUong, thuTu: Number(thuTu) || 0 }, { merge: true });
  // Đổi loại nhóm thì sao lại cờ đồ uống sang các món trong nhóm (để tính mức giá).
  if (nhomId) {
    const mon = await db.collection(COL.mon).where('nhomId', '==', nhomId).get();
    const batch = db.batch();
    mon.docs.forEach((m) => batch.update(m.ref, { laDoUong: !!laDoUong }));
    await batch.commit();
  }
  await QS.capNhatSoLieuQuan(quanId);
  await chamHoatDong(ref);
  return { nhomId: docRef.id };
}

async function xoaNhomMon({ uid }, { nhomId }) {
  const s = await db.collection(COL.nhomMon).doc(String(nhomId || '')).get();
  if (!s.exists) throw khongTimThay('Nhóm món');
  if (s.get('chuQuanId') !== uid) throw khongCoQuyen();
  const con = await db.collection(COL.mon).where('nhomId', '==', nhomId).get();
  if (con.docs.some((m) => !m.get('daXoa'))) throw loiNguoiDung('Nhóm còn món. Hãy xóa hoặc chuyển món sang nhóm khác trước.');
  await s.ref.delete();
  return { ok: true };
}

// ---------------------------------------------------------------- Món

async function luuMon({ uid }, { quanId, monId = null, nhomId, ten, moTa = '', gia, anh = '', noiBat = false, conHang = true, thuTu = 0, tuyChon = [] }) {
  const cfg = await layCauHinh();
  const { ref } = await quanCuaChu(uid, quanId);
  const loi = K.kiemTraMon({ ten, moTa, gia, anh, tuyChon });
  if (loi.length) throw thamSoSai(loi.join(' '));
  const nhom = await db.collection(COL.nhomMon).doc(String(nhomId || '')).get();
  if (!nhom.exists || nhom.get('quanId') !== quanId) throw thamSoSai('Chọn nhóm món.');
  const tatCa = await db.collection(COL.mon).where('quanId', '==', quanId).get();
  const hienCo = tatCa.docs.filter((m) => !m.get('daXoa'));
  let docRef;
  if (monId) {
    docRef = db.collection(COL.mon).doc(monId);
    const s = await docRef.get();
    if (!s.exists || s.get('quanId') !== quanId || s.get('daXoa')) throw khongTimThay('Món');
  } else {
    if (hienCo.length >= cfg.monToiDa) throw loiNguoiDung(`Tối đa ${cfg.monToiDa} món.`);
    docRef = db.collection(COL.mon).doc();
  }
  if (noiBat) {
    const soNoiBat = hienCo.filter((m) => m.get('noiBat') && m.id !== docRef.id).length;
    if (soNoiBat >= cfg.monNoiBatToiDa) throw loiNguoiDung(`Tối đa ${cfg.monNoiBatToiDa} món nổi bật.`);
  }
  await docRef.set({
    quanId, nhomId, chuQuanId: uid, ten: String(ten).trim(), moTa: String(moTa).trim(), gia, anh: anh || '',
    noiBat: !!noiBat, conHang: !!conHang, thuTu: Number(thuTu) || 0, laDoUong: !!nhom.get('laDoUong'), daXoa: false,
    tuyChon: tuyChon.map((t) => ({ ten: String(t.ten).trim(), batBuoc: !!t.batBuoc, toiDa: t.toiDa, lua: t.lua.map((l) => ({ ten: String(l.ten).trim(), giaThem: l.giaThem })) })),
    capNhatLuc: Timestamp.now(),
  }, { merge: true });
  await QS.capNhatSoLieuQuan(quanId);
  await chamHoatDong(ref);
  return { monId: docRef.id };
}

/** Xóa mềm: đơn đã đặt vẫn giữ nguyên giá và tên lúc đặt. */
async function xoaMon({ uid }, { monId }) {
  const s = await db.collection(COL.mon).doc(String(monId || '')).get();
  if (!s.exists) throw khongTimThay('Món');
  if (s.get('chuQuanId') !== uid) throw khongCoQuyen();
  await s.ref.update({ daXoa: true, noiBat: false, conHang: false });
  await QS.capNhatSoLieuQuan(s.get('quanId'));
  return { ok: true };
}

async function batTatMon({ uid }, { monId, conHang }) {
  const s = await db.collection(COL.mon).doc(String(monId || '')).get();
  if (!s.exists || s.get('daXoa')) throw khongTimThay('Món');
  if (s.get('chuQuanId') !== uid) throw khongCoQuyen();
  await s.ref.update({ conHang: !!conHang }); // hết món thì không đặt được
  return { ok: true };
}

// ---------------------------------------------------------------- Khuyến mãi

async function luuKhuyenMai({ uid }, { quanId, khuyenMaiId = null, ...k }) {
  const cfg = await layCauHinh();
  const { quan, ref } = await quanCuaChu(uid, quanId);
  if (!['active', 'hidden'].includes(quan.trangThai)) throw loiNguoiDung('Quán cần được duyệt trước khi tạo khuyến mãi.');
  const now = Date.now();
  const dangChay = await db.collection(COL.khuyenMai).where('quanId', '==', quanId).where('trangThai', '==', 'chay').get();
  const soDangChay = dangChay.docs.filter((d) => d.id !== khuyenMaiId && ms(d.get('ketThuc')) > now).length;
  const loi = K.kiemTraKhuyenMai(k, { loaiQuan: quan.loaiQuan, soDangChay, now }, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  if (k.loai === 'combo') {
    const monIds = k.combo.mon.map((m) => m.monId);
    const snaps = await Promise.all(monIds.map((id) => db.collection(COL.mon).doc(id).get()));
    if (snaps.some((s) => !s.exists || s.get('quanId') !== quanId || s.get('daXoa'))) throw thamSoSai('Combo có món không thuộc quán.');
  }
  const docRef = khuyenMaiId ? db.collection(COL.khuyenMai).doc(khuyenMaiId) : db.collection(COL.khuyenMai).doc();
  if (khuyenMaiId) {
    const s = await docRef.get();
    if (!s.exists || s.get('quanId') !== quanId) throw khongTimThay('Khuyến mãi');
  }
  const duLieu = {
    quanId, chuQuanId: uid, loai: k.loai, tieuDe: String(k.tieuDe).trim(), phanTram: k.phanTram || null, giamToiDa: k.giamToiDa || null,
    giamTien: k.giamTien || null, donToiThieu: k.donToiThieu || 0, combo: k.loai === 'combo' ? k.combo : null,
    gioVang: k.loai === 'gio_vang' ? k.gioVang : null, batDau: ts(k.batDau), ketThuc: ts(k.ketThuc), trangThai: 'chay',
    // Quán bán lẻ: khuyến mãi chỉ hiển thị, không tự trừ (mục 3.3).
    chiHienThi: quan.loaiQuan !== 'ho_kinh_doanh',
  };
  await docRef.set(duLieu, { merge: true });
  await QS.capNhatSoLieuQuan(quanId);
  await chamHoatDong(ref);
  if (!khuyenMaiId) await QS.baoNguoiDaLuu(quanId, quan, 'quan_da_luu_khuyen_mai');
  return { khuyenMaiId: docRef.id };
}

async function dungKhuyenMai({ uid }, { khuyenMaiId }) {
  const s = await db.collection(COL.khuyenMai).doc(String(khuyenMaiId || '')).get();
  if (!s.exists) throw khongTimThay('Khuyến mãi');
  if (s.get('chuQuanId') !== uid) throw khongCoQuyen();
  await s.ref.update({ trangThai: 'dung' });
  await QS.capNhatSoLieuQuan(s.get('quanId'));
  return { ok: true };
}

module.exports = { luuNhomMon, xoaNhomMon, luuMon, xoaMon, batTatMon, luuKhuyenMai, dungKhuyenMai };
