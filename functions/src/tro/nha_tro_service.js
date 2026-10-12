'use strict';

/**
 * Nhà trọ và phòng (mục 2.2, 2.3): gửi duyệt, admin duyệt, sửa tin (sửa ngay / bản chỉnh sửa
 * chờ duyệt), ẩn / hiện, xóa mềm, đăng lại, gia hạn, "Đã cho thuê ngoài app", hết hạn.
 * Bản nháp do chủ trọ tự lưu thẳng vào Firestore (rules chỉ cho sửa bản nháp của mình);
 * mọi chuyển trạng thái đi qua đây.
 */

const { db, FieldValue, Timestamp, GeoPoint, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { canOtp, canDanhTinh } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const K = require('./logic/kiem_tra_tin');
const { ghiThongBao, dayThongBao } = require('./thong_bao');
const { PHUT } = require('./config');

const COL = Object.freeze({ nhaTro: 'nha_tro', phong: 'phong_tro', datCoc: 'tro_dat_coc', khoa: 'tro_khoa', nhatKy: 'tro_nhat_ky_admin' });

const viTriTu = (g) => (g && typeof g.latitude === 'number' ? { lat: g.latitude, lng: g.longitude } : g || null);

/** Các trường của nhà trọ được chép sang từng phòng để lọc nhanh ở sảnh (mục 2.17). */
function banSaoNhaTro(n, id) {
  return {
    id,
    trangThai: n.trangThai || 'draft',
    ten: n.ten || '',
    loaiHinh: n.loaiHinh || 'phong',
    tienIchChung: n.tienIchChung || [],
    noiQuy: n.noiQuy || null,
    viTri: n.viTri || null,
    diaChi: n.diaChi || '',
    phuong: n.phuong || '',
    searchText: n.searchText || K.chuTimKiem(n),
    anhBia: n.anhBia || '',
    daXacThucNha: !!n.daXacThucNha,
  };
}

async function ghiNhatKy(adminUid, viec, doiTuong, ghiChu = '') {
  await db.collection(COL.nhatKy).add({ adminUid, viec, doiTuong, ghiChu, luc: Timestamp.now() });
}

async function thongBao(cacTin) {
  const batch = db.batch();
  const ids = [];
  for (const tin of cacTin) {
    const caiDatSnap = tin.nguoiNhan ? await db.collection('tro_ho_so').doc(tin.nguoiNhan).get() : null;
    const id = ghiThongBao(batch, { ...tin, caiDat: (caiDatSnap && caiDatSnap.exists && caiDatSnap.get('caiDatThongBao')) || {} });
    if (id) ids.push(id);
  }
  await batch.commit();
  await dayThongBao(ids);
}

async function cacAdminTro() {
  const snap = await db.collection('admins').where('tro', '==', true).get();
  return snap.docs.map((d) => d.id);
}

/** Chủ trọ đang bị khóa đăng tin / nhận cọc trong Tìm trọ (3 vi phạm / 90 ngày). */
async function kiemTraKhoaDangTin(sdt) {
  const snap = await db.collection(COL.khoa).doc(sdt).get();
  const den = snap.exists ? ms(snap.get('khoaDangTinDen')) : null;
  if (den && den > Date.now()) {
    throw loiNguoiDung('Bạn đang bị khóa đăng tin / nhận cọc trong Tìm trọ tới ' + new Date(den).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }) + '.');
  }
}

/** Giấy tờ nhà nằm ở `nha_tro/{id}/rieng/giay_to` (chỉ chủ trọ và admin đọc được), không nằm trong tin công khai. */
async function docGiayTo(nhaTroId) {
  const s = await db.collection(COL.nhaTro).doc(nhaTroId).collection('rieng').doc('giay_to').get();
  return s.exists ? s.get('giayTo') || [] : [];
}

async function layNhaCuaChu(uid, nhaTroId) {
  const ref = db.collection(COL.nhaTro).doc(nhaTroId);
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Nhà trọ');
  if (snap.get('chuTroId') !== uid) throw khongCoQuyen();
  return { ref, n: snap.data() };
}

async function layPhongCuaChu(uid, phongId) {
  const ref = db.collection(COL.phong).doc(phongId);
  const snap = await ref.get();
  if (!snap.exists || snap.get('daXoa')) throw khongTimThay('Phòng');
  if (snap.get('chuTroId') !== uid) throw khongCoQuyen();
  return { ref, p: snap.data() };
}

const dangKhoaThanhToan = (p) => p.khoaThanhToan && ms(p.khoaThanhToan.den) > Date.now();

function chanKhiDangCoc(p, viec) {
  if (p.trangThai === 'reserved') {
    throw loiNguoiDung(`Không thể ${viec} khi phòng đã có người cọc. Muốn bỏ cọc qua app hãy dùng "Hủy cọc".`);
  }
  if (dangKhoaThanhToan(p)) throw loiNguoiDung(`Không thể ${viec} khi đang có người thanh toán cọc, thử lại sau ít phút.`);
}

// ---------------------------------------------------------------- Gửi duyệt

async function guiDuyetNhaTro({ uid, xacThuc }, { nhaTroId }) {
  const sdt = canOtp(xacThuc);
  canDanhTinh(xacThuc);
  await kiemTraKhoaDangTin(sdt);
  const cfg = await layCauHinh();
  const { ref, n } = await layNhaCuaChu(uid, nhaTroId);
  if (!['draft', 'rejected'].includes(n.trangThai)) throw loiNguoiDung('Nhà trọ này không ở trạng thái nháp.');
  const loi = K.kiemTraNhaTro({ ...n, viTri: viTriTu(n.viTri), giayTo: await docGiayTo(nhaTroId) }, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  await ref.update({
    trangThai: 'pending_review', lyDoTuChoi: null, guiDuyetLuc: Timestamp.now(),
    searchText: K.chuTimKiem(n), capNhatLuc: Timestamp.now(),
  });
  await thongBao((await cacAdminTro()).map((a) => ({
    khoa: `duyet_nha_${nhaTroId}_${Date.now()}`, nguoiNhan: a, loai: 'cho_duyet', nhom: 'quan_ly_tin',
    tieuDe: 'Nhà trọ chờ duyệt', noiDung: `"${n.ten}" đang chờ duyệt.`, moTrang: { loai: 'admin_hang_cho' },
  })));
  return { ok: true };
}

async function guiDuyetPhong({ uid, xacThuc }, { phongId }) {
  const sdt = canOtp(xacThuc);
  canDanhTinh(xacThuc);
  await kiemTraKhoaDangTin(sdt);
  const cfg = await layCauHinh();
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  if (!['draft', 'rejected'].includes(p.trangThai)) throw loiNguoiDung('Phòng này không ở trạng thái nháp.');
  const nhaSnap = await db.collection(COL.nhaTro).doc(p.nhaTroId).get();
  const n = nhaSnap.data() || {};
  if (n.trangThai !== 'active' && n.trangThai !== 'hidden') throw loiNguoiDung('Nhà trọ chưa được duyệt nên chưa thêm phòng được.');
  const khac = await db.collection(COL.phong).where('nhaTroId', '==', p.nhaTroId).get();
  const phongKhac = khac.docs.filter((d) => d.id !== phongId && !d.get('daXoa'));
  if (n.loaiHinh === 'nguyen_can' && phongKhac.some((d) => d.get('trangThai') !== 'draft')) {
    throw loiNguoiDung('Nhà cho thuê nguyên căn chỉ có 1 căn.');
  }
  const loi = K.kiemTraPhong(p, { loaiHinh: n.loaiHinh, tenKhac: phongKhac.map((d) => d.get('ten')) }, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  await ref.update({
    trangThai: 'pending_review', lyDoTuChoi: null, guiDuyetLuc: Timestamp.now(),
    videoQuayLuc: p.videoQuayLuc || Timestamp.now(), nhaTro: banSaoNhaTro(n, p.nhaTroId), capNhatLuc: Timestamp.now(),
  });
  await thongBao((await cacAdminTro()).map((a) => ({
    khoa: `duyet_phong_${phongId}_${Date.now()}`, nguoiNhan: a, loai: 'cho_duyet', nhom: 'quan_ly_tin',
    tieuDe: 'Phòng chờ duyệt', noiDung: `Phòng "${p.ten}" của "${n.ten}" đang chờ duyệt.`, moTrang: { loai: 'admin_hang_cho' },
  })));
  return { ok: true };
}

// ---------------------------------------------------------------- Admin duyệt

const LY_DO_TU_CHOI = ['Ảnh mờ', 'Giấy tờ không khớp', 'Video không đúng địa điểm', 'Ảnh không đúng thực tế', 'Thông tin sai lệch', 'Nội dung quảng cáo', 'Khác'];

async function adminDuyet(adminUid, { loai, id, dongY, lyDo }) {
  if (!dongY && !LY_DO_TU_CHOI.includes(lyDo)) throw thamSoSai('Chọn lý do từ chối.');
  const cfg = await layCauHinh();
  const now = Date.now();
  if (loai === 'nha_tro') {
    const ref = db.collection(COL.nhaTro).doc(id);
    const snap = await ref.get();
    if (!snap.exists || snap.get('trangThai') !== 'pending_review') throw loiNguoiDung('Hồ sơ không còn chờ duyệt.');
    const n = snap.data();
    if (dongY) {
      await ref.update({
        trangThai: 'active', daXacThucNha: true, duyetLuc: Timestamp.now(),
        hetHanLuc: Timestamp.fromMillis(now + cfg.nhaTroHetHanPhut * PHUT), daNhacHetHan: false,
      });
      await dongBoPhong(id);
    } else {
      await ref.update({ trangThai: 'rejected', lyDoTuChoi: lyDo });
    }
    await ghiNhatKy(adminUid, dongY ? 'duyet_nha_tro' : 'tu_choi_nha_tro', { loai, id }, lyDo || '');
    await thongBao([{
      khoa: `ket_qua_duyet_${id}_${now}`, nguoiNhan: n.chuTroId, loai: 'ket_qua_duyet', nhom: 'quan_ly_tin',
      tieuDe: dongY ? 'Nhà trọ đã được duyệt' : 'Nhà trọ bị từ chối',
      noiDung: dongY ? `"${n.ten}" đã có huy hiệu "Đã xác thực nhà". Bạn có thể thêm phòng.` : `"${n.ten}" bị từ chối: ${lyDo}. Sửa rồi gửi lại.`,
      moTrang: { loai: 'quan_ly_nha_tro', id },
    }]);
    return { ok: true };
  }
  if (loai === 'phong') {
    const ref = db.collection(COL.phong).doc(id);
    const snap = await ref.get();
    if (!snap.exists || snap.get('trangThai') !== 'pending_review') throw loiNguoiDung('Hồ sơ không còn chờ duyệt.');
    const p = snap.data();
    await ref.update(dongY ? { trangThai: 'available', duyetLuc: Timestamp.now() } : { trangThai: 'rejected', lyDoTuChoi: lyDo });
    await ghiNhatKy(adminUid, dongY ? 'duyet_phong' : 'tu_choi_phong', { loai, id }, lyDo || '');
    await capNhatSoLieuNhaTro(p.nhaTroId);
    await thongBao([{
      khoa: `ket_qua_duyet_${id}_${now}`, nguoiNhan: p.chuTroId, loai: 'ket_qua_duyet', nhom: 'quan_ly_tin',
      tieuDe: dongY ? 'Phòng đã được duyệt' : 'Phòng bị từ chối',
      noiDung: dongY ? `Phòng "${p.ten}" đã hiển thị và nhận cọc qua app.` : `Phòng "${p.ten}" bị từ chối: ${lyDo}.`,
      moTrang: { loai: 'quan_ly_nha_tro', id: p.nhaTroId },
    }]);
    if (dongY) await baoNguoiDaLuu(p.nhaTroId, 'co_phong_trong', `Nhà trọ bạn lưu có phòng trống mới: ${p.ten}.`);
    return { ok: true };
  }
  if (loai === 'chinh_sua_nha' || loai === 'chinh_sua_phong') {
    const col = loai === 'chinh_sua_nha' ? COL.nhaTro : COL.phong;
    const ref = db.collection(col).doc(id);
    const snap = await ref.get();
    const ban = snap.exists ? snap.get('banChinhSua') : null;
    if (!ban || ban.trangThai !== 'cho') throw loiNguoiDung('Không còn bản chỉnh sửa chờ duyệt.');
    const goc = snap.data();
    if (dongY) {
      const { trangThai, guiLuc, lyDoTuChoi, ...thayDoi } = ban;
      void trangThai; void guiLuc; void lyDoTuChoi;
      const cap = { ...thayDoi, banChinhSua: null, capNhatLuc: Timestamp.now() };
      if (loai === 'chinh_sua_nha') cap.searchText = K.chuTimKiem({ ...goc, ...thayDoi });
      if (loai === 'chinh_sua_phong' && thayDoi.video) cap.videoQuayLuc = Timestamp.now();
      await ref.update(cap);
      if (loai === 'chinh_sua_nha') await dongBoPhong(id);
    } else {
      await ref.update({ 'banChinhSua.trangThai': 'tu_choi', 'banChinhSua.lyDoTuChoi': lyDo });
    }
    await ghiNhatKy(adminUid, dongY ? `duyet_${loai}` : `tu_choi_${loai}`, { loai, id }, lyDo || '');
    await thongBao([{
      khoa: `ket_qua_chinh_sua_${id}_${now}`, nguoiNhan: goc.chuTroId, loai: 'ket_qua_duyet', nhom: 'quan_ly_tin',
      tieuDe: dongY ? 'Bản chỉnh sửa đã được duyệt' : 'Bản chỉnh sửa bị từ chối',
      noiDung: dongY ? 'Ảnh / video / vị trí mới đã hiển thị.' : `Bản chỉnh sửa bị từ chối: ${lyDo}. Bản cũ vẫn hiển thị.`,
      moTrang: { loai: 'quan_ly_nha_tro', id: loai === 'chinh_sua_nha' ? id : goc.nhaTroId },
    }]);
    return { ok: true };
  }
  throw thamSoSai();
}

// ---------------------------------------------------------------- Sửa tin

const NHA_SUA_NGAY = ['ten', 'moTa', 'tienIchChung', 'noiQuy', 'tongSoPhong', 'soTang'];
const NHA_CHO_DUYET = ['anh', 'video', 'anhBia', 'diaChi', 'duong', 'phuong', 'viTri'];
const PHONG_SUA_NGAY = ['giaThue', 'tienCoc', 'tienDien', 'tienNuoc', 'phiKhac', 'moTa', 'tienIch', 'soNguoiToiDa', 'ngayVaoO', 'hopDongToiThieu', 'khu', 'tang'];
const PHONG_CHO_DUYET = ['anh', 'video', 'anhBia'];

function tachThayDoi(thayDoi, suaNgay, choDuyet) {
  const ngay = {};
  const cho = {};
  for (const [k, v] of Object.entries(thayDoi || {})) {
    if (suaNgay.includes(k)) ngay[k] = v;
    else if (choDuyet.includes(k)) cho[k] = v;
  }
  return { ngay, cho };
}

/**
 * Sửa nhà trọ đang hiển thị: nội dung, tiện ích, nội quy → hiện ngay (khoản cọc cũ giữ bản chụp);
 * ảnh, video, địa chỉ, vị trí ghim → bản chỉnh sửa chờ duyệt, bản cũ vẫn hiện.
 */
async function suaNhaTro({ uid }, { nhaTroId, thayDoi }) {
  const cfg = await layCauHinh();
  const { ref, n } = await layNhaCuaChu(uid, nhaTroId);
  if (!['active', 'hidden', 'expired'].includes(n.trangThai)) throw loiNguoiDung('Nhà trọ chưa duyệt: sửa trực tiếp bản nháp.');
  const { ngay, cho } = tachThayDoi(thayDoi, NHA_SUA_NGAY, NHA_CHO_DUYET);
  if (cho.viTri) cho.viTri = new GeoPoint(cho.viTri.lat, cho.viTri.lng);
  const sau = { ...n, ...ngay, ...cho, viTri: viTriTu(cho.viTri || n.viTri) };
  const loi = K.kiemTraNhaTro({ ...sau, giayTo: await docGiayTo(nhaTroId), camKet: true }, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  const cap = { ...ngay, capNhatLuc: Timestamp.now() };
  if (Object.keys(ngay).length) cap.searchText = K.chuTimKiem({ ...n, ...ngay });
  if (Object.keys(cho).length) cap.banChinhSua = { ...cho, trangThai: 'cho', guiLuc: Timestamp.now(), lyDoTuChoi: null };
  await ref.update(cap);
  await dongBoPhong(nhaTroId);
  return { ok: true, choDuyet: Object.keys(cho).length > 0 };
}

async function suaPhong({ uid }, { phongId, thayDoi }) {
  const cfg = await layCauHinh();
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  if (['draft', 'rejected', 'pending_review'].includes(p.trangThai)) throw loiNguoiDung('Phòng chưa duyệt: sửa trực tiếp bản nháp.');
  const { ngay, cho } = tachThayDoi(thayDoi, PHONG_SUA_NGAY, PHONG_CHO_DUYET);
  if ('tienCoc' in ngay && ngay.tienCoc !== p.tienCoc) {
    if (p.trangThai === 'reserved') throw loiNguoiDung('Không đổi được tiền cọc khi phòng đã có người cọc.');
    if (dangKhoaThanhToan(p)) throw loiNguoiDung('Đang có người thanh toán cọc, thử lại sau ít phút.');
  }
  if (ngay.ngayVaoO != null) ngay.ngayVaoO = Timestamp.fromMillis(ngay.ngayVaoO);
  const n = (await db.collection(COL.nhaTro).doc(p.nhaTroId).get()).data() || {};
  const loi = K.kiemTraPhong({ ...p, ...ngay, ...cho }, { loaiHinh: n.loaiHinh }, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  const cap = { ...ngay, capNhatLuc: Timestamp.now() };
  if (Object.keys(cho).length) cap.banChinhSua = { ...cho, trangThai: 'cho', guiLuc: Timestamp.now(), lyDoTuChoi: null };
  await ref.update(cap);
  await capNhatSoLieuNhaTro(p.nhaTroId);
  if (typeof ngay.giaThue === 'number' && ngay.giaThue < p.giaThue && p.trangThai === 'available') {
    await baoNguoiDaLuu(p.nhaTroId, 'giam_gia', `Phòng ${p.ten} vừa giảm giá còn ${ngay.giaThue.toLocaleString('vi-VN')}đ.`);
  }
  return { ok: true, choDuyet: Object.keys(cho).length > 0 };
}

// ---------------------------------------------------------------- Ẩn / xóa / đăng lại / cho thuê ngoài app

async function anHienPhong({ uid }, { phongId, an }) {
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  chanKhiDangCoc(p, an ? 'ẩn phòng' : 'hiện phòng');
  if (an && p.trangThai !== 'available') throw loiNguoiDung('Chỉ ẩn được phòng đang còn trống.');
  if (!an && p.trangThai !== 'hidden') throw loiNguoiDung('Phòng không ở trạng thái ẩn.');
  await ref.update({ trangThai: an ? 'hidden' : 'available', anBoi: an ? 'chu' : null, capNhatLuc: Timestamp.now() });
  await capNhatSoLieuNhaTro(p.nhaTroId);
  return { ok: true };
}

async function xoaPhong({ uid }, { phongId }) {
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  chanKhiDangCoc(p, 'xóa phòng');
  await ref.update({ daXoa: true, trangThai: 'hidden', xoaLuc: Timestamp.now() });
  await capNhatSoLieuNhaTro(p.nhaTroId);
  return { ok: true };
}

async function daChoThueNgoaiApp({ uid }, { phongId }) {
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  chanKhiDangCoc(p, 'đánh dấu đã cho thuê');
  if (p.trangThai !== 'available') throw loiNguoiDung('Chỉ dùng được với phòng đang còn trống.');
  await ref.update({ trangThai: 'rented', choThueNgoaiAppLuc: Timestamp.now(), capNhatLuc: Timestamp.now() });
  await capNhatSoLieuNhaTro(p.nhaTroId);
  return { ok: true };
}

/** Đăng lại phòng đã cho thuê: video còn mới thì hiện ngay; video quá 90 ngày phải gửi video mới và duyệt lại. */
async function dangLaiPhong({ uid, xacThuc }, { phongId, videoMoi }) {
  await kiemTraKhoaDangTin(canOtp(xacThuc));
  const cfg = await layCauHinh();
  const { ref, p } = await layPhongCuaChu(uid, phongId);
  chanKhiDangCoc(p, 'đăng lại phòng');
  if (p.trangThai !== 'rented') throw loiNguoiDung('Chỉ đăng lại được phòng đã cho thuê.');
  const quayLuc = ms(p.videoQuayLuc) || 0;
  const conMoi = Date.now() - quayLuc < cfg.videoCuPhut * PHUT;
  if (conMoi) {
    await ref.update({ trangThai: 'available', capNhatLuc: Timestamp.now() });
    await capNhatSoLieuNhaTro(p.nhaTroId);
    await baoNguoiDaLuu(p.nhaTroId, 'co_phong_trong', `Nhà trọ bạn lưu có phòng trống: ${p.ten}.`);
    return { ok: true, choDuyet: false };
  }
  if (!Array.isArray(videoMoi) || videoMoi.length < cfg.videoToiThieu || videoMoi.length > cfg.videoToiDa || !videoMoi.every(K.laHttps)) {
    throw loiNguoiDung('Video phòng đã quá 90 ngày, cần quay video mới để đăng lại.', 'failed-precondition');
  }
  await ref.update({ trangThai: 'pending_review', video: videoMoi, videoQuayLuc: Timestamp.now(), guiDuyetLuc: Timestamp.now() });
  return { ok: true, choDuyet: true };
}

async function anHienNhaTro({ uid }, { nhaTroId, an }) {
  const { ref, n } = await layNhaCuaChu(uid, nhaTroId);
  if (an && n.trangThai !== 'active') throw loiNguoiDung('Chỉ ẩn được nhà trọ đang hiển thị.');
  if (!an && !(n.trangThai === 'hidden' && n.anBoi === 'chu')) throw loiNguoiDung('Nhà trọ không ở trạng thái tự ẩn.');
  await ref.update({ trangThai: an ? 'hidden' : 'active', anBoi: an ? 'chu' : null, capNhatLuc: Timestamp.now() });
  await dongBoPhong(nhaTroId);
  return { ok: true };
}

/** "Vẫn còn cho thuê": gia hạn 30 ngày, không cần duyệt lại (kể cả khi đã hết hạn). */
async function giaHanNhaTro({ uid, xacThuc }, { nhaTroId }) {
  await kiemTraKhoaDangTin(canOtp(xacThuc));
  const cfg = await layCauHinh();
  const { ref, n } = await layNhaCuaChu(uid, nhaTroId);
  if (!['active', 'expired'].includes(n.trangThai)) throw loiNguoiDung('Nhà trọ này không gia hạn được.');
  await ref.update({
    trangThai: 'active', hetHanLuc: Timestamp.fromMillis(Date.now() + cfg.nhaTroHetHanPhut * PHUT), daNhacHetHan: false,
  });
  if (n.trangThai === 'expired') await dongBoPhong(nhaTroId);
  return { ok: true };
}

// ---------------------------------------------------------------- Số liệu, đồng bộ, hết hạn

/** Chép thông tin nhà trọ sang các phòng (để lọc ở sảnh) và tính lại số liệu. */
async function dongBoPhong(nhaTroId) {
  const nSnap = await db.collection(COL.nhaTro).doc(nhaTroId).get();
  if (!nSnap.exists) return;
  const banSao = banSaoNhaTro(nSnap.data(), nhaTroId);
  const phong = await db.collection(COL.phong).where('nhaTroId', '==', nhaTroId).get();
  const batch = db.batch();
  phong.docs.forEach((d) => batch.update(d.ref, { nhaTro: banSao }));
  await batch.commit();
  await capNhatSoLieuNhaTro(nhaTroId);
}

/** Số phòng trống, khoảng giá: app tự tính từ các phòng (mục 2.2). */
async function capNhatSoLieuNhaTro(nhaTroId) {
  if (!nhaTroId) return;
  const phong = await db.collection(COL.phong).where('nhaTroId', '==', nhaTroId).get();
  const hien = phong.docs.map((d) => d.data()).filter((p) => !p.daXoa && ['available', 'reserved', 'rented'].includes(p.trangThai));
  const trong = hien.filter((p) => p.trangThai === 'available');
  const gia = (trong.length ? trong : hien).map((p) => p.giaThue).filter((x) => typeof x === 'number');
  await db.collection(COL.nhaTro).doc(nhaTroId).set({
    soLieu: {
      soPhong: hien.length,
      soPhongTrong: trong.length,
      giaMin: gia.length ? Math.min(...gia) : null,
      giaMax: gia.length ? Math.max(...gia) : null,
    },
  }, { merge: true });
}

async function baoNguoiDaLuu(nhaTroId, loai, noiDung) {
  const luu = await db.collection('tro_luu').where('nhaTroId', '==', nhaTroId).where('nhanThongBao', '==', true).get();
  if (luu.empty) return;
  const ngay = new Date().toISOString().slice(0, 10);
  await thongBao(luu.docs.map((d) => ({
    khoa: `luu_${loai}_${nhaTroId}_${ngay}`, nguoiNhan: d.get('uid'), loai, nhom: 'nha_tro_da_luu',
    tieuDe: loai === 'giam_gia' ? 'Nhà trọ đã lưu giảm giá' : 'Nhà trọ đã lưu có phòng trống', noiDung,
    moTrang: { loai: 'nha_tro', id: nhaTroId },
  })));
}

/**
 * Hết hạn nhà trọ (chạy định kỳ): nhắc trước 3 ngày; tới hạn thì `expired` — trừ khi còn
 * khoản cọc QUA APP chưa kết thúc (khi đó giữ hiển thị, nhắc chủ, xử lý sau). Cọc trực tiếp không được miễn.
 */
async function xuLyHetHanNhaTro(now = Date.now()) {
  const cfg = await layCauHinh();
  const sapHet = await db.collection(COL.nhaTro).where('trangThai', '==', 'active')
    .where('hetHanLuc', '<=', Timestamp.fromMillis(now + cfg.nhaTroNhacTruocPhut * PHUT)).get();
  for (const doc of sapHet.docs) {
    const n = doc.data();
    const het = ms(n.hetHanLuc);
    if (het > now) {
      if (!n.daNhacHetHan) {
        await thongBao([{
          khoa: `sap_het_han_${doc.id}_${het}`, nguoiNhan: n.chuTroId, loai: 'sap_het_han', nhom: 'quan_ly_tin',
          tieuDe: 'Tin sắp hết hạn', noiDung: `"${n.ten}" sẽ hết hạn sau 3 ngày. Bấm "Vẫn còn cho thuê" để gia hạn.`,
          moTrang: { loai: 'quan_ly_nha_tro', id: doc.id },
        }]);
        await doc.ref.update({ daNhacHetHan: true });
      }
      continue;
    }
    const conCoc = await db.collection(COL.datCoc).where('nhaTroId', '==', doc.id)
      .where('status', 'in', ['pending_payment', 'held', 'disputed']).limit(1).get();
    if (!conCoc.empty) continue;
    await doc.ref.update({ trangThai: 'expired', capNhatLuc: Timestamp.now() });
    await dongBoPhong(doc.id);
    await thongBao([{
      khoa: `het_han_${doc.id}_${het}`, nguoiNhan: n.chuTroId, loai: 'het_han', nhom: 'quan_ly_tin',
      tieuDe: 'Tin đã hết hạn', noiDung: `"${n.ten}" đã hết hạn và tạm ẩn. Bấm "Vẫn còn cho thuê" để hiện lại.`,
      moTrang: { loai: 'quan_ly_nha_tro', id: doc.id },
    }]);
  }
}

module.exports = {
  COL, LY_DO_TU_CHOI, banSaoNhaTro, guiDuyetNhaTro, guiDuyetPhong, adminDuyet, suaNhaTro, suaPhong, anHienPhong,
  xoaPhong, daChoThueNgoaiApp, dangLaiPhong, anHienNhaTro, giaHanNhaTro, dongBoPhong, capNhatSoLieuNhaTro,
  xuLyHetHanNhaTro, ghiNhatKy, thongBao, cacAdminTro, kiemTraKhoaDangTin, FieldValue,
};
