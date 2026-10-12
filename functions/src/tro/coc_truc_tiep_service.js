'use strict';

/**
 * Cọc trực tiếp ngoài app (mục 2.5d): chủ trọ ghi nhận để không ai cọc qua app được nữa.
 * App KHÔNG giữ, KHÔNG hoàn, KHÔNG giải quyết khiếu nại tiền của khoản này,
 * và không tự đổi trạng thái phòng (chỉ nhắc chủ trọ khi quá ngày dự kiến 3 ngày).
 */

const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { canOtp } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const { capNhatSoLieuNhaTro, thongBao } = require('./nha_tro_service');

const COL = 'tro_coc_truc_tiep';

const chuanSdt = (s) => String(s || '').replace(/[^0-9+]/g, '');

async function xacNhan({ uid }, { phongId, ngayNhanDuKien, sdtNguoiCoc }) {
  if (!Number.isFinite(ngayNhanDuKien)) throw thamSoSai('Nhập ngày nhận phòng dự kiến.');
  const refPhong = db.collection('phong_tro').doc(phongId);
  const sdt = sdtNguoiCoc ? chuanSdt(sdtNguoiCoc) : null;
  const ref = db.collection(COL).doc();
  const kq = await db.runTransaction(async (tx) => {
    const snap = await tx.get(refPhong);
    if (!snap.exists || snap.get('daXoa')) throw khongTimThay('Phòng');
    const p = snap.data();
    if (p.chuTroId !== uid) throw khongCoQuyen();
    if (p.khoaThanhToan && ms(p.khoaThanhToan.den) > Date.now()) {
      throw loiNguoiDung('Đang có người thanh toán cọc qua app, thử lại sau khi hết 15 phút.');
    }
    if (p.trangThai !== 'available' || p.dangGiu) throw loiNguoiDung('Chỉ xác nhận được với phòng đang còn trống.');
    tx.set(ref, {
      phongId, nhaTroId: p.nhaTroId, chuTroId: uid, tenPhong: p.ten || '',
      xacNhanLuc: Timestamp.now(), ngayNhanDuKien: Timestamp.fromMillis(ngayNhanDuKien), lichSuNgay: [],
      sdtNguoiCoc: sdt, ketQua: 'dang_cho', capNhatLuc: Timestamp.now(), daNhac: false,
      daChoThueLuc: null, hanXacNhanDaThue: null, nguoiCocXacNhanLuc: null, nguoiCocUid: null,
    });
    tx.update(refPhong, { trangThai: 'reserved', dangGiu: { loai: 'truc_tiep', cocTrucTiepId: ref.id }, capNhatLuc: Timestamp.now() });
    return { nhaTroId: p.nhaTroId, tenPhong: p.ten };
  });
  await capNhatSoLieuNhaTro(kq.nhaTroId);
  if (sdt) {
    const tk = await db.collection('so_dien_thoai').doc(sdt).get();
    if (tk.exists) {
      await thongBao([{
        khoa: `coc_truc_tiep_${ref.id}`, nguoiNhan: tk.get('uid'), loai: 'ghi_coc_truc_tiep', nhom: 'giao_dich',
        tieuDe: 'Chủ trọ ghi bạn là người cọc trực tiếp',
        noiDung: `Chủ trọ ghi bạn đã cọc trực tiếp ${kq.tenPhong}. Khoản cọc ngoài app KHÔNG được app bảo vệ. Sau khi chủ bấm "Đã cho thuê", hãy bấm "Tôi đã thuê phòng này" trong 7 ngày để được đánh giá.`,
        moTrang: { loai: 'coc_truc_tiep', id: ref.id },
      }]);
    }
  }
  return { cocTrucTiepId: ref.id };
}

/** Chủ trọ cập nhật: 'da_cho_thue' | 'khong_thue' | 'sua_ngay'. */
async function capNhat({ uid }, { id, ketQua, ngayNhanDuKien }) {
  const cfg = await layCauHinh();
  const ref = db.collection(COL).doc(id);
  const kq = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Cọc trực tiếp');
    const c = snap.data();
    if (c.chuTroId !== uid) throw khongCoQuyen();
    if (c.ketQua !== 'dang_cho') throw loiNguoiDung('Khoản cọc trực tiếp này đã được cập nhật.');
    const refPhong = db.collection('phong_tro').doc(c.phongId);
    const now = Date.now();
    if (ketQua === 'sua_ngay') {
      if (!Number.isFinite(ngayNhanDuKien)) throw thamSoSai('Nhập ngày nhận phòng dự kiến.');
      tx.update(ref, {
        lichSuNgay: [...(c.lichSuNgay || []), c.ngayNhanDuKien],
        ngayNhanDuKien: Timestamp.fromMillis(ngayNhanDuKien), daNhac: false, capNhatLuc: Timestamp.now(),
      });
      return { nhaTroId: c.nhaTroId, doiPhong: false };
    }
    if (ketQua === 'da_cho_thue') {
      tx.update(ref, {
        ketQua: 'da_cho_thue', capNhatLuc: Timestamp.now(), daChoThueLuc: Timestamp.fromMillis(now),
        hanXacNhanDaThue: Timestamp.fromMillis(now + cfg.daThueXacNhanPhut * PHUT),
      });
      tx.update(refPhong, { trangThai: 'rented', dangGiu: null, capNhatLuc: Timestamp.now() });
      return { nhaTroId: c.nhaTroId, doiPhong: true, sdt: c.sdtNguoiCoc, tenPhong: c.tenPhong };
    }
    if (ketQua === 'khong_thue') {
      tx.update(ref, { ketQua: 'khong_thue', capNhatLuc: Timestamp.now() });
      tx.update(refPhong, { trangThai: 'available', dangGiu: null, capNhatLuc: Timestamp.now() });
      return { nhaTroId: c.nhaTroId, doiPhong: true };
    }
    throw thamSoSai();
  });
  if (kq.doiPhong) await capNhatSoLieuNhaTro(kq.nhaTroId);
  if (kq.sdt) {
    const tk = await db.collection('so_dien_thoai').doc(kq.sdt).get();
    if (tk.exists) {
      await thongBao([{
        khoa: `coc_truc_tiep_da_thue_${id}`, nguoiNhan: tk.get('uid'), loai: 'xac_nhan_da_thue', nhom: 'danh_gia',
        tieuDe: 'Xác nhận bạn đã thuê phòng', noiDung: `Bấm "Tôi đã thuê phòng này" cho ${kq.tenPhong} trong 7 ngày để được viết đánh giá.`,
        moTrang: { loai: 'coc_truc_tiep', id },
      }]);
    }
  }
  return { ok: true };
}

/** Người cọc (đúng số điện thoại chủ trọ đã nhập) bấm "Tôi đã thuê phòng này" trong 7 ngày. */
async function nguoiCocXacNhan({ uid, xacThuc }, { id }) {
  const sdt = canOtp(xacThuc);
  const cfg = await layCauHinh();
  const ref = db.collection(COL).doc(id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Cọc trực tiếp');
    const c = snap.data();
    if (c.sdtNguoiCoc !== sdt) throw khongCoQuyen();
    if (c.chuTroId === uid) throw khongCoQuyen();
    if (c.ketQua !== 'da_cho_thue') throw loiNguoiDung('Chủ trọ chưa bấm "Đã cho thuê".');
    if (c.nguoiCocXacNhanLuc) return { ok: true };
    if (Date.now() > ms(c.hanXacNhanDaThue)) throw loiNguoiDung('Đã quá 7 ngày để xác nhận.');
    const nhanPhong = ms(c.ngayNhanDuKien) || Date.now();
    tx.update(ref, {
      nguoiCocXacNhanLuc: Timestamp.now(), nguoiCocUid: uid,
      danhGia: { nhan: 'da_thue', tinhDiem: true, han: Timestamp.fromMillis(nhanPhong + cfg.danhGiaThoiHanPhut * PHUT) },
    });
    return { ok: true };
  });
}

/** Định kỳ: quá ngày nhận phòng dự kiến 3 ngày chưa cập nhật → nhắc chủ trọ (không tự đổi trạng thái). */
async function nhacChuaCapNhat(now = Date.now()) {
  const cfg = await layCauHinh();
  const snap = await db.collection(COL).where('ketQua', '==', 'dang_cho').where('daNhac', '==', false)
    .where('ngayNhanDuKien', '<=', Timestamp.fromMillis(now - cfg.cocTrucTiepNhacSauPhut * PHUT)).get();
  for (const doc of snap.docs) {
    const c = doc.data();
    await thongBao([{
      khoa: `coc_truc_tiep_nhac_${doc.id}_${ms(c.ngayNhanDuKien)}`, nguoiNhan: c.chuTroId, loai: 'nhac_coc_truc_tiep', nhom: 'giao_dich',
      tieuDe: 'Cập nhật cọc trực tiếp', noiDung: `Đã quá ngày nhận dự kiến 3 ngày. Hãy cập nhật ${c.tenPhong}: "Đã cho thuê" hoặc "Người cọc không thuê nữa".`,
      moTrang: { loai: 'quan_ly_coc_truc_tiep', id: doc.id },
    }]);
    await doc.ref.update({ daNhac: true });
  }
}

module.exports = { COL, xacNhan, capNhat, nguoiCocXacNhan, nhacChuaCapNhat, chuanSdt };
