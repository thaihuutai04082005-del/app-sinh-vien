'use strict';

/**
 * Quán: gửi duyệt, admin duyệt, sửa (hiện ngay / chờ duyệt), nâng cấp loại, tạm nghỉ, ẩn, ngừng kinh doanh,
 * nhắc "quán còn hoạt động", số liệu tự tính (mục 3.2, 3.3, 3.5f, 3.14). Chủ quán chỉ ghi trực tiếp BẢN NHÁP.
 */

const { db, FieldValue, Timestamp, GeoPoint, ms, ts } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { canOtp, canDanhTinh } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const K = require('./logic/kiem_tra');
const G = require('./logic/gia');
const H = require('./logic/gio_mo_cua');
const HA = require('./logic/hay_an');
const DG = require('./logic/danh_gia');
const { COL, ghiNhatKy, thongBao, cacAdminQuanAn, kiemTraKhoaBan, hetNgayVn } = require('./ho_tro');

// ---------------------------------------------------------------- Đọc

async function docGiayTo(quanId) {
  const s = await db.collection(COL.quan).doc(quanId).collection('rieng').doc('giay_to').get();
  return s.exists ? s.data() : {};
}

async function layQuanCuaChu(uid, quanId) {
  const ref = db.collection(COL.quan).doc(String(quanId || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Quán');
  if (snap.get('chuQuanId') !== uid) throw khongCoQuyen();
  return { ref, quan: snap.data(), id: snap.id };
}

const toLatLng = (gp) => (gp ? { lat: gp.latitude, lng: gp.longitude } : null);

const GIA_TRI_TRANG_THAI_HIEN = ['active'];

// ---------------------------------------------------------------- Số liệu tự tính

/** Tính lại số liệu của quán: số món, mức giá, chữ tìm kiếm, khuyến mãi, tỷ lệ (mục 3.17). */
async function capNhatSoLieuQuan(quanId) {
  const ref = db.collection(COL.quan).doc(quanId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const q = snap.data();
  const cfg = await layCauHinh();
  const now = Date.now();
  const [monSnap, kmSnap] = await Promise.all([
    db.collection(COL.mon).where('quanId', '==', quanId).get(),
    db.collection(COL.khuyenMai).where('quanId', '==', quanId).where('trangThai', '==', 'chay').get(),
  ]);
  const mon = monSnap.docs.map((d) => d.data()).filter((m) => !m.daXoa);
  const gia = G.thongKeGia(mon);
  const kmDangChay = kmSnap.docs.map((d) => d.data()).filter((k) => ms(k.batDau) <= now && now < ms(k.ketThuc));
  const capNhat = {
    'soLieu.soMon': gia.soMon,
    'soLieu.giaP25': gia.giaP25,
    'soLieu.giaTrungVi': gia.giaTrungVi,
    'soLieu.giaP75': gia.giaP75,
    'soLieu.coKhuyenMai': kmDangChay.length > 0,
    'soLieu.moiMo': !!q.duyetLuc && now - ms(q.duyetLuc) <= cfg.moiMoPhut * PHUT,
    searchText: K.chuTimKiem(q, mon.map((m) => m.ten)),
  };
  // Cảnh báo khai sai loại khi menu > 40 món (mục 3.5f).
  if (q.loaiQuan === 'ban_le' && q.trangThai === 'active' && !q.khaiSaiLoai) {
    const lyDo = K.canhBaoKhaiSai(q, gia.soMon, cfg);
    if (lyDo.length) {
      capNhat.khaiSaiLoai = { lyDo, hanChuyen: null, canhBaoLuc: Timestamp.now() };
      await thongBao((await cacAdminQuanAn()).map((a) => ({
        khoa: `khai_sai_${quanId}`, nguoiNhan: a, loai: 'quan_nghi_khai_sai', moTrang: { loai: 'admin_hang_cho' },
      })));
    }
  }
  await ref.update(capNhat);
}

/** Tỷ lệ nhận đơn / giữ bàn (30 ngày) của quán, ghi vào `soLieu` và chỉ số công khai của chủ quán. */
async function capNhatChiSoQuan(quanId) {
  const cfg = await layCauHinh();
  const tu = Timestamp.fromMillis(Date.now() - cfg.tyLeCuaSoPhut * PHUT);
  const ref = db.collection(COL.quan).doc(quanId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const [don, ban] = await Promise.all([
    db.collection(COL.don).where('quanId', '==', quanId).where('taoLuc', '>=', tu).get(),
    db.collection(COL.datBan).where('quanId', '==', quanId).where('taoLuc', '>=', tu).get(),
  ]);
  const tyLeNhanDon = HA.tyLeNhanDon(don.docs.map((d) => d.data()));
  const tyLeGiuBan = HA.tyLeGiuBan(ban.docs.map((d) => ({ ...d.data(), xacNhanLuc: ms(d.get('xacNhanLuc')) })));
  await ref.update({ 'soLieu.tyLeNhanDon': tyLeNhanDon, 'soLieu.tyLeGiuBan': tyLeGiuBan });
}

// ---------------------------------------------------------------- Gửi duyệt, admin duyệt

async function guiDuyetQuan(nd, { quanId }) {
  const cfg = await layCauHinh();
  canOtp(nd.xacThuc);
  canDanhTinh(nd.xacThuc);
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  kiemTraKhoaBan(quan);
  if (!['draft', 'rejected'].includes(quan.trangThai)) throw loiNguoiDung('Quán này không gửi duyệt được.');
  const giayTo = await docGiayTo(quanId);
  const loi = K.kiemTraQuan({ ...quan, gioMoCua: quan.gioMoCua, viTri: toLatLng(quan.viTri) }, giayTo, cfg);
  if (loi.length) throw thamSoSai(loi.join(' '));
  const khaiSai = K.canhBaoKhaiSai(quan, 0, cfg);
  await ref.update({
    trangThai: 'pending_review', lyDoTuChoi: null, guiLuc: Timestamp.now(), anhBia: quan.anhMatTien[0],
    khaiSaiLoai: khaiSai.length ? { lyDo: khaiSai, hanChuyen: null, canhBaoLuc: Timestamp.now() } : null,
    capNhatLuc: Timestamp.now(),
  });
  await thongBao((await cacAdminQuanAn()).map((a) => ({ khoa: `quan_cho_duyet_${quanId}_${Date.now()}`, nguoiNhan: a, loai: 'quan_cho_duyet', moTrang: { loai: 'admin_hang_cho' } })));
  return { ok: true };
}

/**
 * Admin duyệt quán / bản chỉnh sửa / nâng cấp loại.
 * `loai`: 'quan' | 'chinh_sua' | 'nang_cap'. Hộ kinh doanh: admin phải xác nhận đã đối chiếu mã số thuế (mục 3.12).
 */
async function adminDuyet(adminUid, { loai, id, dongY, lyDo = '', daDoiChieuMst = false }) {
  if (!['quan', 'chinh_sua', 'nang_cap'].includes(loai)) throw thamSoSai();
  const ref = db.collection(COL.quan).doc(String(id || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Quán');
  const q = snap.data();
  if (!dongY && String(lyDo).trim().length < 3) throw thamSoSai('Ghi lý do từ chối.');
  const bien = { quan: q.ten };
  const moTrang = { loai: 'quan_ly_quan', id };

  if (loai === 'quan') {
    if (q.trangThai !== 'pending_review') throw loiNguoiDung('Quán này không còn chờ duyệt.');
    if (dongY && q.loaiQuan === 'ho_kinh_doanh' && !daDoiChieuMst) {
      throw loiNguoiDung('Hộ kinh doanh: hãy đối chiếu mã số thuế (còn hoạt động, tên khớp CCCD, địa chỉ khớp) rồi tick xác nhận.');
    }
    if (dongY) {
      await ref.update({
        trangThai: 'active', lyDoTuChoi: null, duyetLuc: Timestamp.now(), hoatDongLuc: Timestamp.now(),
        hanXacNhanHoatDong: null, daDoiChieuMst: q.loaiQuan === 'ho_kinh_doanh' ? !!daDoiChieuMst : false,
      });
      await capNhatSoLieuQuan(id);
    } else {
      await ref.update({ trangThai: 'rejected', lyDoTuChoi: String(lyDo).trim() });
    }
    await ghiNhatKy(adminUid, dongY ? 'duyet_quan' : 'tu_choi_quan', { loai: 'quan', id }, lyDo);
    await thongBao([{ khoa: `ket_qua_duyet_${id}_${Date.now()}`, nguoiNhan: q.chuQuanId, loai: dongY ? 'quan_duoc_duyet' : 'quan_bi_tu_choi', bien, moTrang }]);
    return { ok: true };
  }

  const ban = q.banChinhSua;
  if (!ban || (loai === 'nang_cap') !== (ban.loai === 'nang_cap')) throw loiNguoiDung('Không có bản chỉnh sửa chờ duyệt.');
  if (dongY) {
    const capNhat = { banChinhSua: null, capNhatLuc: Timestamp.now() };
    const { guiLuc, loai: _loai, giayTo, ...truong } = ban; // eslint-disable-line no-unused-vars
    for (const [k, v] of Object.entries(truong)) capNhat[k] = v;
    if (truong.anhMatTien) capNhat.anhBia = truong.anhMatTien[0];
    if (ban.loai === 'nang_cap') {
      if (!daDoiChieuMst) throw loiNguoiDung('Hãy đối chiếu mã số thuế rồi tick xác nhận.');
      capNhat.loaiQuan = 'ho_kinh_doanh';
      capNhat.daDoiChieuMst = true;
      capNhat.khaiSaiLoai = null;
      await ref.collection('rieng').doc('giay_to').set({ maSoThue: giayTo.maSoThue, anhGiayChungNhan: giayTo.anhGiayChungNhan }, { merge: true });
    }
    await ref.update(capNhat);
    await capNhatSoLieuQuan(id);
  } else {
    await ref.update({ banChinhSua: null, lyDoTuChoiChinhSua: String(lyDo).trim() });
  }
  await ghiNhatKy(adminUid, `${dongY ? 'duyet' : 'tu_choi'}_${loai}`, { loai: 'quan', id }, lyDo);
  await thongBao([{ khoa: `ket_qua_chinh_sua_${id}_${Date.now()}`, nguoiNhan: q.chuQuanId, loai: dongY ? 'chinh_sua_duoc_duyet' : 'chinh_sua_bi_tu_choi', bien, moTrang }]);
  return { ok: true };
}

// ---------------------------------------------------------------- Sửa quán

// Trường hiện ngay vs trường tạo bản chỉnh sửa chờ duyệt (mục 3.3 Bước 6).
const TRUONG_HIEN_NGAY = ['gioMoCua', 'tienIch', 'phucVu', 'moTa', 'anhKhac', 'nhanDatBan', 'loaiMon', 'sdt'];
const TRUONG_CHO_DUYET = ['ten', 'diaChi', 'phuong', 'viTri', 'anhMatTien', 'luuDong', 'ghiChuViTri'];

function kiemTraTruongHienNgay(g, quan, cfg) {
  const loi = [];
  if ('gioMoCua' in g) { const l = H.kiemTraLich(g.gioMoCua, cfg.caMoiNgayToiDa); if (l) loi.push(l); }
  if ('tienIch' in g && (!Array.isArray(g.tienIch) || !g.tienIch.every((x) => K.TIEN_ICH.includes(x)))) loi.push('Tiện ích không hợp lệ.');
  if ('phucVu' in g) {
    const pv = g.phucVu || {};
    if (!pv.anTaiQuan && !pv.mangDi) loi.push('Chọn ít nhất 1 hình thức phục vụ (ăn tại quán / mang đi).');
  }
  if ('moTa' in g && String(g.moTa || '').trim().length < 10) loi.push('Mô tả quán ít nhất 10 ký tự.');
  if ('anhKhac' in g && (!Array.isArray(g.anhKhac) || g.anhKhac.length > cfg.anhKhacToiDa || !g.anhKhac.every(K.laHttps))) loi.push(`Tối đa ${cfg.anhKhacToiDa} ảnh khác.`);
  if ('nhanDatBan' in g && g.nhanDatBan && quan.loaiQuan !== 'ho_kinh_doanh') loi.push('Quán bán lẻ / vỉa hè không nhận đặt bàn.');
  if ('loaiMon' in g && (!Array.isArray(g.loaiMon) || g.loaiMon.length < 1 || g.loaiMon.length > cfg.loaiMonToiDa || !g.loaiMon.every((x) => K.LOAI_MON.includes(x)))) loi.push(`Chọn 1–${cfg.loaiMonToiDa} loại món.`);
  if ('sdt' in g && !/^0\d{9}$/.test(String(g.sdt || ''))) loi.push('Số điện thoại quán không hợp lệ.');
  return loi;
}

function kiemTraTruongChoDuyet(g, cfg) {
  const loi = [];
  if ('ten' in g) { const n = String(g.ten || '').trim().length; if (n < cfg.tenQuanToiThieu || n > cfg.tenQuanToiDa) loi.push(`Tên quán ${cfg.tenQuanToiThieu}–${cfg.tenQuanToiDa} ký tự.`); }
  if ('diaChi' in g && String(g.diaChi || '').trim().length < 5) loi.push('Nhập địa chỉ đầy đủ.');
  if ('viTri' in g && !(g.viTri && Number.isFinite(g.viTri.lat) && Number.isFinite(g.viTri.lng))) loi.push('Ghim vị trí quán trên bản đồ.');
  if ('anhMatTien' in g && (!Array.isArray(g.anhMatTien) || g.anhMatTien.length < cfg.anhMatTienToiThieu || g.anhMatTien.length > cfg.anhMatTienToiDa || !g.anhMatTien.every(K.laHttps))) loi.push(`Cần ${cfg.anhMatTienToiThieu}–${cfg.anhMatTienToiDa} ảnh mặt tiền.`);
  return loi;
}

/**
 * Sửa quán đang hoạt động: menu, giờ, tiện ích, mô tả, ảnh khác, đặt bàn → hiện ngay;
 * tên, địa chỉ, vị trí ghim, ảnh mặt tiền → bản chỉnh sửa chờ duyệt, bản cũ vẫn hiện.
 */
async function suaQuan(nd, { quanId, ...truong }) {
  const cfg = await layCauHinh();
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  kiemTraKhoaBan(quan);
  if (['draft', 'rejected', 'pending_review'].includes(quan.trangThai)) throw loiNguoiDung('Quán chưa được duyệt: hãy sửa trong form đăng quán.');
  if (['suspended', 'closed'].includes(quan.trangThai)) throw loiNguoiDung('Quán này không sửa được.');
  const ngay = Object.fromEntries(Object.entries(truong).filter(([k]) => TRUONG_HIEN_NGAY.includes(k)));
  const duyet = Object.fromEntries(Object.entries(truong).filter(([k]) => TRUONG_CHO_DUYET.includes(k)));
  if (!Object.keys(ngay).length && !Object.keys(duyet).length) throw thamSoSai('Không có thay đổi hợp lệ.');
  const loi = [...kiemTraTruongHienNgay(ngay, quan, cfg), ...kiemTraTruongChoDuyet(duyet, cfg)];
  // Đổi chỗ bán thường xuyên của quán lưu động: bắt buộc chụp lại ảnh mặt tiền và duyệt lại (mục 3.3).
  if (quan.luuDong && duyet.viTri && !duyet.anhMatTien) loi.push('Quán lưu động đổi chỗ bán thường xuyên: cần chụp lại ảnh mặt tiền để duyệt lại.');
  if (loi.length) throw thamSoSai(loi.join(' '));

  const capNhat = { ...ngay, capNhatLuc: Timestamp.now(), hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null };
  if (Object.keys(duyet).length) {
    const ban = { ...duyet, loai: 'sua', guiLuc: Timestamp.now() };
    if (ban.viTri) ban.viTri = new GeoPoint(ban.viTri.lat, ban.viTri.lng);
    capNhat.banChinhSua = ban;
  }
  await ref.update(capNhat);
  await capNhatSoLieuQuan(quanId);
  if (capNhat.banChinhSua) {
    await thongBao((await cacAdminQuanAn()).map((a) => ({ khoa: `chinh_sua_cho_duyet_${quanId}_${Date.now()}`, nguoiNhan: a, loai: 'quan_cho_duyet', moTrang: { loai: 'admin_hang_cho' } })));
  }
  return { ok: true, choDuyet: !!capNhat.banChinhSua };
}

async function nangCapLoaiQuan(nd, { quanId, maSoThue, anhGiayChungNhan }) {
  const cfg = await layCauHinh();
  canOtp(nd.xacThuc);
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  kiemTraKhoaBan(quan);
  if (quan.loaiQuan !== 'ban_le') throw loiNguoiDung('Quán này đã là hộ kinh doanh.');
  if (quan.trangThai !== 'active' && quan.trangThai !== 'hidden') throw loiNguoiDung('Chỉ nâng cấp khi quán đã được duyệt.');
  const mst = String(maSoThue || '').replace(/\s/g, '');
  if (!new RegExp(`^\\d{${cfg.mstChuSoToiThieu},${cfg.mstChuSoToiDa}}$`).test(mst)) throw thamSoSai('Nhập mã số thuế (chỉ gồm chữ số).');
  if (!Array.isArray(anhGiayChungNhan) || anhGiayChungNhan.length < 1 || !anhGiayChungNhan.every(K.laHttps)) throw thamSoSai('Tải lên ảnh giấy chứng nhận hộ kinh doanh.');
  await ref.update({ banChinhSua: { loai: 'nang_cap', giayTo: { maSoThue: mst, anhGiayChungNhan }, guiLuc: Timestamp.now() } });
  await thongBao((await cacAdminQuanAn()).map((a) => ({ khoa: `nang_cap_${quanId}_${Date.now()}`, nguoiNhan: a, loai: 'quan_cho_duyet', moTrang: { loai: 'admin_hang_cho' } })));
  return { ok: true };
}

async function caiDatDatMon(nd, { quanId, datMon }) {
  const cfg = await layCauHinh();
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  kiemTraKhoaBan(quan);
  if (quan.loaiQuan !== 'ho_kinh_doanh') throw loiNguoiDung('Chỉ quán hộ kinh doanh đã được duyệt mới bật được đặt món qua app.');
  if (quan.trangThai !== 'active' && quan.trangThai !== 'hidden') throw loiNguoiDung('Quán cần được duyệt trước.');
  const loi = K.kiemTraDatMon(datMon, cfg, quan.loaiQuan);
  if (loi.length) throw thamSoSai(loi.join(' '));
  const d = datMon || {};
  await ref.update({
    datMon: {
      bat: !!d.bat, denLay: !!d.denLay, giaoTanNoi: !!d.giaoTanNoi, banKinhKm: d.giaoTanNoi ? d.banKinhKm : 0,
      phiGiaoKieu: d.phiGiaoKieu || 'co_dinh', phiGiao: d.phiGiao || 0, phiMoiKm: d.phiMoiKm || 0,
      donToiThieu: d.donToiThieu || 0, chuanBiPhut: d.chuanBiPhut || 15, tienMat: !!d.tienMat,
    },
    capNhatLuc: Timestamp.now(),
  });
  return { ok: true };
}

// ---------------------------------------------------------------- Tạm nghỉ, ẩn, ngừng kinh doanh

/** Đơn / bàn bị ảnh hưởng khi quán ngừng nhận (mục 3.14): đơn chờ quán xác nhận, bàn chờ / đã xác nhận. */
async function demAnhHuong(quanId) {
  const [don, ban] = await Promise.all([
    db.collection(COL.don).where('quanId', '==', quanId).where('status', '==', 'placed').get(),
    db.collection(COL.datBan).where('quanId', '==', quanId).where('status', 'in', ['pending', 'confirmed']).get(),
  ]);
  return { don, ban };
}

/** Áp hệ quả ngừng nhận: đơn chờ xác nhận → hủy + hoàn; bàn → hủy / từ chối (không tính lỗi sinh viên). */
async function apHeQuaNgungNhan(quanId, { lyDoBan = 'quan_tam_nghi', loaiDon = 'QUAN_NGUNG_NHAN' } = {}) {
  const { chayTrenDon } = require('./don_mon_service');
  const { chayTrenBan } = require('./dat_ban_service');
  const { don, ban } = await demAnhHuong(quanId);
  for (const d of don.docs) await chayTrenDon(d.id, { su: { loai: loaiDon }, nguoiLam: { vaiTro: 'he_thong' } }).catch((e) => console.warn('Hủy đơn lỗi', d.id, e.message));
  for (const b of ban.docs) await chayTrenBan(b.id, { su: { loai: 'QUAN_NGUNG_NHAN', lyDo: lyDoBan }, nguoiLam: { vaiTro: 'he_thong' } }).catch((e) => console.warn('Hủy bàn lỗi', b.id, e.message));
  return { soDon: don.size, soBan: ban.size };
}

async function tamNghi(nd, { quanId, kieu, den = null, xacNhan = false }) {
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  if (quan.trangThai !== 'active') throw loiNguoiDung('Chỉ quán đang hoạt động mới đặt tạm nghỉ được.');
  const now = Date.now();
  if (kieu === 'mo_lai') {
    await ref.update({ tamNghiDen: null, tamNghiLoai: null });
    await baoNguoiDaLuu(quanId, quan, 'quan_da_luu_mo_lai');
    return { ok: true };
  }
  let han;
  if (kieu === 'hom_nay') han = H.hanTamNghiHomNay(quan.gioMoCua, now);
  else if (kieu === 'dai_ngay') {
    if (!Number.isFinite(den) || den <= now) throw thamSoSai('Chọn ngày mở lại ở tương lai.');
    if (den > now + 90 * 24 * 60 * PHUT) throw thamSoSai('Nghỉ tối đa 90 ngày.');
    han = H.hanNghiDenNgay(den);
    if (han <= now) throw thamSoSai('Chọn ngày mở lại sau hôm nay.');
  } else throw thamSoSai();
  if (!han) throw thamSoSai('Quán chưa có lịch mở cửa.');
  const { don, ban } = await demAnhHuong(quanId);
  if ((don.size || ban.size) && !xacNhan) return { canXacNhan: true, donAnhHuong: don.size, banAnhHuong: ban.size };
  await ref.update({ tamNghiDen: ts(han), tamNghiLoai: kieu });
  const kq = await apHeQuaNgungNhan(quanId, { lyDoBan: 'quan_tam_nghi' });
  await capNhatChiSoQuan(quanId).catch(() => {});
  return { ok: true, ...kq, tamNghiDen: han };
}

async function tamNgungNhanDon(nd, { quanId, bat }) {
  const { ref } = await layQuanCuaChu(nd.uid, quanId);
  await ref.update({ tamNgungNhanDon: !!bat, ...(bat ? {} : { tamNgungDen: null }) });
  return { ok: true };
}

async function anHienQuan(nd, { quanId, an, xacNhan = false }) {
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  if (an) {
    if (quan.trangThai !== 'active') throw loiNguoiDung('Chỉ quán đang hoạt động mới ẩn được.');
    const { don, ban } = await demAnhHuong(quanId);
    if ((don.size || ban.size) && !xacNhan) return { canXacNhan: true, donAnhHuong: don.size, banAnhHuong: ban.size };
    await ref.update({ trangThai: 'hidden', anBoi: 'chu' });
    const kq = await apHeQuaNgungNhan(quanId, { lyDoBan: 'quan_tam_nghi' });
    return { ok: true, ...kq };
  }
  if (quan.trangThai !== 'hidden') throw loiNguoiDung('Quán này không đang ẩn.');
  if (quan.anBoi === 'admin') throw loiNguoiDung('Admin đã ẩn quán này. Bạn có thể kháng nghị.');
  await ref.update({ trangThai: 'active', anBoi: null, hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null });
  return { ok: true };
}

/** Giao dịch còn đang chạy của quán (mục 3.14): chặn "Ngừng kinh doanh" khi còn. */
async function giaoDichDangChay(quanId, chuQuanId) {
  const { DANG_CHAY } = require('./logic/don_mon');
  const [don, ban, khieuNai, khangNghi, tien] = await Promise.all([
    db.collection(COL.don).where('quanId', '==', quanId).where('status', 'in', [...DANG_CHAY]).limit(1).get(),
    db.collection(COL.datBan).where('quanId', '==', quanId).where('status', 'in', ['pending', 'confirmed']).limit(1).get(),
    db.collection(COL.don).where('quanId', '==', quanId).where('status', '==', 'disputed').limit(1).get(),
    db.collection(COL.khangNghi).where('nguoiGui', '==', chuQuanId).where('trangThai', '==', 'cho_xu_ly').limit(1).get(),
    db.collection(COL.khoanTien).where('nguoiNhan', '==', chuQuanId).where('trangThai', '==', 'dang_giu').limit(1).get(),
  ]);
  const co = [];
  if (!don.empty) co.push('còn đơn chưa hoàn tất');
  if (!ban.empty) co.push('còn bàn đã đặt');
  if (!khieuNai.empty) co.push('còn khiếu nại');
  if (!khangNghi.empty) co.push('còn kháng nghị chưa xong');
  if (!tien.empty) co.push('còn tiền đang giữ');
  return co;
}

async function ngungKinhDoanh(nd, { quanId }) {
  const { ref, quan } = await layQuanCuaChu(nd.uid, quanId);
  if (['closed'].includes(quan.trangThai)) throw loiNguoiDung('Quán đã ngừng kinh doanh.');
  const co = await giaoDichDangChay(quanId, nd.uid);
  if (co.length) throw loiNguoiDung(`Chưa ngừng kinh doanh được vì ${co.join(', ')}. Hãy xử lý xong rồi thử lại.`);
  await ref.update({ trangThai: 'closed', anBoi: 'chu' });
  return { ok: true };
}

async function xacNhanConHoatDong(nd, { quanId }) {
  const { ref } = await layQuanCuaChu(nd.uid, quanId);
  await ref.update({ hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null });
  return { ok: true };
}

// ---------------------------------------------------------------- Quán đã lưu

async function baoNguoiDaLuu(quanId, quan, loai) {
  const luu = await db.collection(COL.luu).where('quanId', '==', quanId).get();
  const cacTin = luu.docs.filter((d) => d.get('nhanThongBao') !== false).map((d) => ({
    khoa: `${loai}_${quanId}_${Date.now()}`, nguoiNhan: d.get('uid'), loai, bien: { quan: quan.ten }, moTrang: { loai: 'quan', id: quanId },
  }));
  if (cacTin.length) await thongBao(cacTin);
}

// ---------------------------------------------------------------- Admin

async function adminYeuCauChuyenLoai(adminUid, { quanId, lyDo }) {
  const cfg = await layCauHinh();
  const ref = db.collection(COL.quan).doc(String(quanId || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Quán');
  const q = snap.data();
  if (q.loaiQuan !== 'ban_le') throw loiNguoiDung('Quán này không khai bán lẻ.');
  if (String(lyDo || '').trim().length < 3) throw thamSoSai('Ghi lý do.');
  await ref.update({ khaiSaiLoai: { ...(q.khaiSaiLoai || { lyDo: [] }), hanChuyen: ts(Date.now() + cfg.hanChuyenLoaiPhut * PHUT), yeuCauLuc: Timestamp.now(), lyDoAdmin: String(lyDo).trim() } });
  await ghiNhatKy(adminUid, 'yeu_cau_chuyen_loai', { loai: 'quan', id: quanId }, lyDo);
  await thongBao([{ khoa: `chuyen_loai_${quanId}_${Date.now()}`, nguoiNhan: q.chuQuanId, loai: 'yeu_cau_chuyen_loai', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: quanId } }]);
  return { ok: true };
}

/** Bỏ cờ nghi khai sai (admin xem lại thấy hợp lệ). */
async function adminBoCoKhaiSai(adminUid, { quanId, lyDo = '' }) {
  await db.collection(COL.quan).doc(String(quanId || '')).update({ khaiSaiLoai: null });
  await ghiNhatKy(adminUid, 'bo_co_khai_sai', { loai: 'quan', id: quanId }, lyDo);
  return { ok: true };
}

async function adminAnHien(adminUid, { quanId, an, lyDo = '' }) {
  const ref = db.collection(COL.quan).doc(String(quanId || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Quán');
  const q = snap.data();
  if (an) {
    if (String(lyDo).trim().length < 3) throw thamSoSai('Ghi lý do.');
    await ref.update({ trangThai: 'hidden', anBoi: 'admin', anLuc: Timestamp.now(), lyDoAn: lyDo });
    await apHeQuaNgungNhan(quanId, { lyDoBan: 'admin_an' }); // không tính lỗi sinh viên, không tính lỗi quán
  } else {
    await ref.update({ trangThai: 'active', anBoi: null, lyDoAn: null, hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null });
  }
  await ghiNhatKy(adminUid, an ? 'an_quan' : 'hien_quan', { loai: 'quan', id: quanId }, lyDo);
  await thongBao([{ khoa: `admin_an_${quanId}_${Date.now()}`, nguoiNhan: q.chuQuanId, loai: an ? 'quan_bi_an' : 'chinh_sua_duoc_duyet', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: quanId } }]);
  return { ok: true };
}

async function adminDinhChi(adminUid, { quanId, dinhChi, lyDo = '' }) {
  const ref = db.collection(COL.quan).doc(String(quanId || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Quán');
  const q = snap.data();
  if (dinhChi) {
    if (String(lyDo).trim().length < 3) throw thamSoSai('Ghi lý do.');
    await ref.update({ trangThai: 'suspended', anBoi: 'admin', anLuc: Timestamp.now(), lyDoAn: lyDo });
    await apHeQuaNgungNhan(quanId, { lyDoBan: 'admin_an' });
  } else {
    await ref.update({ trangThai: 'active', anBoi: null, lyDoAn: null });
  }
  await ghiNhatKy(adminUid, dinhChi ? 'dinh_chi_quan' : 'go_dinh_chi_quan', { loai: 'quan', id: quanId }, lyDo);
  await thongBao([{ khoa: `dinh_chi_${quanId}_${Date.now()}`, nguoiNhan: q.chuQuanId, loai: dinhChi ? 'quan_bi_dinh_chi' : 'chinh_sua_duoc_duyet', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: quanId } }]);
  return { ok: true };
}

/** Khóa bán vĩnh viễn: khóa đăng quán và nhận đơn trong Quán ăn, KHÔNG khóa cả tài khoản (mục 3.14). */
async function adminKhoaBan(adminUid, { chuQuanId, lyDo }) {
  if (String(lyDo || '').trim().length < 3) throw thamSoSai('Ghi lý do.');
  const quan = await db.collection(COL.quan).where('chuQuanId', '==', chuQuanId).get();
  for (const d of quan.docs) await d.ref.update({ khoaBan: true, trangThai: ['draft', 'rejected', 'pending_review'].includes(d.get('trangThai')) ? d.get('trangThai') : 'suspended', anBoi: 'admin', anLuc: Timestamp.now() });
  await db.collection(COL.chiSoChu).doc(chuQuanId).set({ khoaBan: true }, { merge: true });
  await ghiNhatKy(adminUid, 'khoa_ban', { loai: 'nguoi_dung', id: chuQuanId }, lyDo);
  await thongBao([{ khoa: `khoa_ban_${chuQuanId}`, nguoiNhan: chuQuanId, loai: 'quan_bi_khoa_ban', moTrang: { loai: 'cua_toi' } }]);
  return { soQuan: quan.size };
}

/**
 * Kết luận chủ quán lừa đảo / giấy tờ giả (mục 3.14): ngừng nhận đơn mới, KHÔNG tự hoàn / tự giải ngân đơn đang chạy
 * (đơn chờ xác nhận được hoàn; đơn đã nhận gắn cờ rà soát), bàn đã xác nhận bị hủy không tính lỗi sinh viên,
 * gửi đề nghị khóa cả tài khoản tới admin danh tính (mục 4.4).
 */
async function adminLuaDao(adminUid, { chuQuanId, lyDo }) {
  if (String(lyDo || '').trim().length < 3) throw thamSoSai('Ghi lý do.');
  const { chayTrenDon } = require('./don_mon_service');
  const quan = await db.collection(COL.quan).where('chuQuanId', '==', chuQuanId).get();
  let soDon = 0;
  for (const d of quan.docs) {
    await d.ref.update({ khoaBan: true, trangThai: ['draft', 'rejected', 'pending_review'].includes(d.get('trangThai')) ? d.get('trangThai') : 'suspended', anBoi: 'admin', anLuc: Timestamp.now(), lyDoAn: 'Lừa đảo / giấy tờ giả' });
    await apHeQuaNgungNhan(d.id, { lyDoBan: 'admin_an', loaiDon: 'LUA_DAO_GAN_CO' }).catch(() => {});
    const dangChay = await db.collection(COL.don).where('quanId', '==', d.id).where('status', 'in', ['accepted', 'ready', 'delivering', 'delivered', 'not_received']).get();
    for (const o of dangChay.docs) {
      await chayTrenDon(o.id, { su: { loai: 'LUA_DAO_GAN_CO' }, nguoiLam: { vaiTro: 'he_thong' } }).catch((e) => console.warn('Gắn cờ đơn lỗi', o.id, e.message));
      soDon++;
    }
  }
  await db.collection(COL.chiSoChu).doc(chuQuanId).set({ khoaBan: true, luaDao: true }, { merge: true });
  await db.collection('de_nghi_khoa_tai_khoan').add({ uid: chuQuanId, module: 'quan_an', lyDo, deNghiBoi: adminUid, luc: Timestamp.now(), trangThai: 'cho_xu_ly' });
  await ghiNhatKy(adminUid, 'ket_luan_lua_dao', { loai: 'nguoi_dung', id: chuQuanId }, lyDo);
  await thongBao([{ khoa: `lua_dao_${chuQuanId}`, nguoiNhan: chuQuanId, loai: 'quan_bi_khoa_ban', moTrang: { loai: 'cua_toi' } }]);
  return { soQuan: quan.size, soDonGanCo: soDon };
}

// ---------------------------------------------------------------- Định kỳ

/** Quán 90 ngày không hoạt động → nhắc; 7 ngày không bấm → ẩn. Quán khai bán lẻ quá hạn chuyển loại → ẩn. Khuyến mãi hết hạn tự ẩn. */
async function xuLyHetHanQuan(now = Date.now()) {
  const cfg = await layCauHinh();
  const active = await db.collection(COL.quan).where('trangThai', '==', 'active').get();
  for (const doc of active.docs) {
    const q = doc.data();
    try {
      if (!q.hanXacNhanHoatDong && ms(q.hoatDongLuc) && now - ms(q.hoatDongLuc) >= cfg.nhacHoatDongPhut * PHUT) {
        await doc.ref.update({ hanXacNhanHoatDong: ts(now + cfg.anSauNhacPhut * PHUT) });
        await thongBao([{ khoa: `nhac_hoat_dong_${doc.id}_${ms(q.hoatDongLuc)}`, nguoiNhan: q.chuQuanId, loai: 'nhac_con_hoat_dong', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: doc.id } }]);
      } else if (q.hanXacNhanHoatDong && ms(q.hanXacNhanHoatDong) <= now) {
        await doc.ref.update({ trangThai: 'hidden', anBoi: 'he_thong', lyDoAn: 'Không xác nhận còn hoạt động' });
        await apHeQuaNgungNhan(doc.id, { lyDoBan: 'admin_an' });
        await thongBao([{ khoa: `an_khong_xac_nhan_${doc.id}`, nguoiNhan: q.chuQuanId, loai: 'quan_bi_an_khong_xac_nhan', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: doc.id } }]);
      } else if (q.khaiSaiLoai && q.khaiSaiLoai.hanChuyen && ms(q.khaiSaiLoai.hanChuyen) <= now && q.loaiQuan === 'ban_le') {
        await doc.ref.update({ trangThai: 'hidden', anBoi: 'he_thong', lyDoAn: 'Không chuyển loại hình trong 7 ngày' });
        await apHeQuaNgungNhan(doc.id, { lyDoBan: 'admin_an' });
        await thongBao([{ khoa: `an_khong_chuyen_loai_${doc.id}`, nguoiNhan: q.chuQuanId, loai: 'quan_bi_an_khong_chuyen_loai', bien: { quan: q.ten }, moTrang: { loai: 'quan_ly_quan', id: doc.id } }]);
      }
    } catch (e) {
      console.error('Xử lý hạn quán lỗi', doc.id, e.message);
    }
  }
  const km = await db.collection(COL.khuyenMai).where('trangThai', '==', 'chay').where('ketThuc', '<=', Timestamp.fromMillis(now)).get();
  const quanDoi = new Set();
  for (const d of km.docs) { await d.ref.update({ trangThai: 'het_han' }); quanDoi.add(d.get('quanId')); }
  for (const id of quanDoi) await capNhatSoLieuQuan(id).catch(() => {});
  return { quanDoi: quanDoi.size };
}

/** Mỗi đêm: nhãn "Sinh viên hay ăn" + số người 30 ngày + tỷ lệ nhận đơn / giữ bàn (mục 3.4 Bước 1). */
async function tinhHangDem(now = Date.now()) {
  const cfg = await layCauHinh();
  const tu = now - cfg.hayAnCuaSoPhut * PHUT;
  const quanSnap = await db.collection(COL.quan).where('trangThai', '==', 'active').get();
  const quan = quanSnap.docs.map((d) => ({ id: d.id, chu: d.get('chuQuanId'), lat: d.get('viTri') && d.get('viTri').latitude, lng: d.get('viTri') && d.get('viTri').longitude }))
    .filter((q) => Number.isFinite(q.lat));
  const chuQuan = new Map(quan.map((q) => [q.id, q.chu]));
  const mocTu = Timestamp.fromMillis(tu);
  const [ci, don] = await Promise.all([
    db.collection(COL.checkIn).where('luc', '>=', mocTu).get(),
    db.collection(COL.don).where('ketThucLuc', '>=', mocTu).where('status', '==', 'completed').get(),
  ]);
  const luot = [
    ...ci.docs.filter((d) => d.get('tinhHayAn') !== false).map((d) => ({ quanId: d.get('quanId'), uid: d.get('svId'), luc: ms(d.get('luc')) })),
    ...don.docs.filter((d) => d.get('daXacMinh')).map((d) => ({ quanId: d.get('quanId'), uid: d.get('svId'), luc: ms(d.get('ketThucLuc')) })),
  ];
  const dem = HA.demNguoiTheoQuan(luot, chuQuan, tu, now);
  const co = HA.quanHayAn(quan, dem, { soNguoi: cfg.hayAnSoNguoi, topPhanTram: cfg.hayAnTopPhanTram, banKinhMet: cfg.hayAnBanKinhMet });
  for (const q of quan) {
    await db.collection(COL.quan).doc(q.id).update({ 'soLieu.soNguoi30Ngay': dem.get(q.id) || 0, 'soLieu.hayAn': co.has(q.id) });
    await capNhatChiSoQuan(q.id).catch(() => {});
    await capNhatSoLieuQuan(q.id).catch(() => {});
  }
  return { soQuan: quan.length, soHayAn: co.size };
}

module.exports = {
  GIA_TRI_TRANG_THAI_HIEN, docGiayTo, layQuanCuaChu, capNhatSoLieuQuan, capNhatChiSoQuan,
  guiDuyetQuan, adminDuyet, suaQuan, nangCapLoaiQuan, caiDatDatMon, tamNghi, tamNgungNhanDon, anHienQuan,
  ngungKinhDoanh, xacNhanConHoatDong, baoNguoiDaLuu, adminYeuCauChuyenLoai, adminBoCoKhaiSai, adminAnHien, adminDinhChi,
  adminKhoaBan, adminLuaDao, xuLyHetHanQuan, tinhHangDem, apHeQuaNgungNhan, giaoDichDangChay, DG, FieldValue, hetNgayVn,
};
