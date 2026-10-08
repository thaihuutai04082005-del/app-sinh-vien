'use strict';

/**
 * Lớp Firestore cho đơn món: báo giá, đặt món, và chạy máy trạng thái (logic/don_mon.js) trong 1 transaction —
 * ghi mọi tác động (đơn, tiền, ví, vi phạm, khóa, thông báo). Mọi thao tác đều tự xử lý hạn đã tới trước
 * (mục 3.18 quy tắc 6). Hệ thống quyết định, không tin app: giá, khoảng cách GPS, giờ, quyền người bấm.
 */

const crypto = require('node:crypto');
const { db, FieldValue, Timestamp, GeoPoint, ms, ts } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { canOtp } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const L = require('./logic/don_mon');
const V = require('./logic/vi_pham');
const G = require('./logic/gia');
const H = require('./logic/gio_mo_cua');
const K = require('./logic/kiem_tra');
const { ghiThongBao, dayThongBao } = require('./thong_bao');
const { COL, kiemTraKhoaBan, docKhoa, conKhoa, fmtGio, hetNgayVn } = require('./ho_tro');

// ---------------------------------------------------------------- Chuyển đổi thời gian

const KHOA_THOI_GIAN = new Set([
  'taoLuc', 'hanThanhToan', 'datLuc', 'hanQuanNhan', 'gioDuKienSanSang', 'moHuyChamLuc', 'batDauGiaoLuc', 'tNhanMonDuKien',
  'sanSangLuc', 'bangChungLuc', 'hanKhieuNai', 'hanQuaHan6h', 'gioHen', 'ketThucLuc', 'luc', 'hanPhanDoi', 'phanDoiLuc',
  'hanChuTraLoi', 'coKhanLuc', 'chuTraLoiLuc', 'quyetLuc', 'moLuc', 'hanKeTiep',
]);

function doiThoiGian(v, ham) {
  if (Array.isArray(v)) return v.map((x) => doiThoiGian(x, ham));
  if (v && typeof v === 'object' && !(v instanceof Timestamp) && !(v instanceof GeoPoint)) {
    const kq = {};
    for (const [k, x] of Object.entries(v)) {
      kq[k] = KHOA_THOI_GIAN.has(k) && (typeof x === 'number' || x instanceof Timestamp || x == null) ? ham(x) : doiThoiGian(x, ham);
    }
    return kq;
  }
  return v;
}

const LOGIC_KHOA = [
  'status', 'version', 'cachNhan', 'cachTra', 'gio', 'gioHen', 'tong', 'taoLuc', 'hanThanhToan', 'datLuc', 'hanQuanNhan',
  'gioDuKienSanSang', 'moHuyChamLuc', 'batDauGiaoLuc', 'tNhanMonDuKien', 'sanSangLuc', 'bangChungLuc', 'bangChungLoai',
  'hanKhieuNai', 'hanQuaHan6h', 'coQuaHan', 'ruaSoatLuaDao', 'khongNhan', 'khieuNai', 'daXacMinh', 'danhGia', 'lyDoKetThuc',
  'ketThucLuc', 'daNhanTien', 'daXuLy', 'truocKhiKhieuNai', 'anhGiao',
];

function tuDoc(data) {
  const d = {};
  for (const k of LOGIC_KHOA) d[k] = data[k] === undefined ? null : data[k];
  d.daXuLy = d.daXuLy || {};
  d.coQuaHan = !!d.coQuaHan;
  d.ruaSoatLuaDao = !!d.ruaSoatLuaDao;
  d.daXacMinh = !!d.daXacMinh;
  d.daNhanTien = !!d.daNhanTien;
  return doiThoiGian(d, ms);
}

function raDoc(d) {
  const kq = {};
  for (const k of LOGIC_KHOA) kq[k] = d[k] === undefined ? null : d[k];
  kq.hanKeTiep = L.hanKeTiep(d);
  return doiThoiGian(kq, ts);
}

const VAI_TRO = Object.freeze({
  SV_HUY: 'sv', SV_HUY_QUAN_CHAM: 'sv', SV_DA_NHAN: 'sv', SV_CHUA_NHAN_MON: 'sv', SV_KHIEU_NAI: 'sv', SV_PHAN_DOI: 'sv',
  QUAN_NHAN: 'chu', QUAN_TU_CHOI: 'chu', QUAN_HUY: 'chu', QUAN_SAN_SANG: 'chu', QUAN_DANG_GIAO: 'chu', QUAN_NHAP_MA: 'chu',
  QUAN_DA_GIAO: 'chu', QUAN_KHONG_NHAN: 'chu', QUAN_TRA_LOI_KHIEU_NAI: 'chu',
  ADMIN_QUYET: 'admin', ADMIN_QUA_HAN: 'admin', ADMIN_LUA_DAO: 'admin',
});

const TIEN_SANG = Object.freeze({ giu: 'dang_giu', chuyen: 'da_chuyen', hoan: 'da_hoan', hoan_mot_phan: 'hoan_mot_phan', het_han: 'het_han', that_bai: 'that_bai' });

const laHttps = (u) => typeof u === 'string' && /^https:\/\/[^\s]+$/.test(u) && u.length <= 2000;

// ---------------------------------------------------------------- Chạy sự kiện trên đơn

/**
 * Chạy một sự kiện (hoặc chỉ xử lý hạn nếu `su` null) trên đơn trong transaction.
 * `nguoiLam` = { uid, vaiTro } (vaiTro: 'sv' | 'chu' | 'admin' | 'he_thong').
 */
async function chayTrenDon(donId, { su = null, nguoiLam = { vaiTro: 'he_thong' }, versionDaThay = null, now = Date.now() } = {}) {
  const cfg = await layCauHinh();
  const refDon = db.collection(COL.don).doc(donId);
  const thongBaoIds = [];

  const ketQua = await db.runTransaction(async (tx) => {
    thongBaoIds.length = 0;
    const snap = await tx.get(refDon);
    if (!snap.exists) throw khongTimThay('Đơn');
    const goc = snap.data();

    if (su) {
      const vai = VAI_TRO[su.loai];
      if (vai === 'sv' && nguoiLam.uid !== goc.svId) throw khongCoQuyen();
      if (vai === 'chu' && nguoiLam.uid !== goc.chuQuanId) throw khongCoQuyen();
      if (vai === 'admin' && nguoiLam.vaiTro !== 'admin') throw khongCoQuyen();
      if (!vai && nguoiLam.vaiTro !== 'he_thong') throw khongCoQuyen();
      if (versionDaThay != null && versionDaThay !== goc.version) throw loiNguoiDung(L.LOI_DA_THAY_DOI, 'aborted');
    }

    // ---- Đọc trước mọi thứ có thể cần (transaction: đọc hết rồi mới ghi) ----
    const refQuan = db.collection(COL.quan).doc(goc.quanId);
    const refTien = db.collection(COL.khoanTien).doc(donId);
    const [quanSnap, tienSnap, congSnap, maSnap, hoSoSv, hoSoChu, admins] = await Promise.all([
      tx.get(refQuan), tx.get(refTien), tx.get(db.collection(COL.cong).doc(donId)),
      tx.get(refDon.collection('rieng').doc('ma')),
      tx.get(db.collection(COL.hoSo).doc(goc.svId)), tx.get(db.collection(COL.hoSo).doc(goc.chuQuanId)),
      tx.get(db.collection('admins').where('quanAn', '==', true)),
    ]);
    const [bomHang, khieuNaiSai, chamXacNhan] = await Promise.all([
      tx.get(db.collection(COL.viPham).where('sdt', '==', goc.svSdt).where('vaiTro', '==', 'sv')),
      tx.get(db.collection(COL.khieuNaiSai).where('sdt', '==', goc.svSdt)),
      tx.get(db.collection(COL.viPham).where('uid', '==', goc.chuQuanId).where('loai', '==', 'quan_cham_xac_nhan')),
    ]);
    const quan = quanSnap.exists ? quanSnap.data() : {};
    const cong = congSnap.exists ? congSnap.data() : null;
    const congDaThu = cong && cong.trangThai === 'thanh_cong' ? { ghiNhanLuc: ms(cong.ghiNhanLuc) } : null;

    // ---- Chạy logic: xử lý hạn trước, rồi sự kiện ----
    let d = tuDoc(goc);
    const han = L.xuLyHan(d, now, cfg, { congDaThu });
    d = han.d;
    const cacTacDong = han.tacDong.map((t) => ({ ...t }));
    let loiSuKien = null;
    if (su) {
      const suDay = boSungSuKien(su, goc, quan, maSnap, cfg);
      if (suDay.loi) loiSuKien = suDay.loi;
      else {
        const r = L.apDung(d, suDay.su, now, cfg);
        if (r.loi) loiSuKien = r.loi;
        else {
          d = r.d;
          if (!r.boQua) cacTacDong.push({ ...r, d: undefined, khoa: `${su.loai}_${(goc.version || 0) + 1}` });
        }
      }
    }
    d.version = cacTacDong.some((t) => !t.laNhac) ? (goc.version || 0) + 1 : goc.version || 1;

    // ---- Ghi ----
    const capNhat = { ...raDoc(d), capNhatLuc: Timestamp.fromMillis(now) };
    if (su && su.loai === 'QUAN_KHONG_NHAN' && !loiSuKien && su.anh) capNhat['khongNhan.anh'] = su.anh;
    if (su && su.loai === 'QUAN_DA_GIAO' && !loiSuKien && d.anhGiao && su.anh) capNhat.anhGiao = { ...d.anhGiao, url: su.anh, lat: su.lat, lng: su.lng };
    if (su && su.loai === 'QUAN_NHAP_MA' && !loiSuKien && d.bangChungLuc) capNhat.maNhanMonDaNhapLuc = Timestamp.fromMillis(now);
    const lich = cacTacDong.filter((t) => !t.laNhac).map((t) => ({ luc: Timestamp.fromMillis(now), su: t.khoa, nguoiLam: su && t.khoa.startsWith(su.loai) ? nguoiLam.vaiTro : 'he_thong' }));
    if (lich.length) capNhat.lichSu = FieldValue.arrayUnion(...lich);

    const caiDat = { sv: (hoSoSv.exists && hoSoSv.get('caiDatThongBao')) || {}, chu: (hoSoChu.exists && hoSoChu.get('caiDatThongBao')) || {} };
    const bien = { quan: goc.tenQuan || 'quán' };
    const tien = tienSnap.exists ? tienSnap.data() : null;
    let trangThaiTien = tien ? tien.trangThai : null;
    const viCapNhat = { dangGiu: 0, daNhan: 0 };
    const lichSuTien = [];
    let soDaHoan = tien ? tien.soDaHoan || 0 : 0;
    let tamNgungQuan = false;
    const dsBom = bomHang.docs.filter((x) => x.get('loai') === 'bom_hang').map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));
    const dsSai = khieuNaiSai.docs.map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));
    const dauNgay = H.dauNgayVn(now);
    const soChamHomNay = chamXacNhan.docs.filter((x) => ms(x.get('luc')) >= dauNgay).length;

    for (const t of cacTacDong) {
      for (const loaiTien of t.tien || []) {
        const truoc = trangThaiTien;
        if (loaiTien === 'giu') viCapNhat.dangGiu += goc.tong;
        if (loaiTien === 'chuyen' && truoc === 'dang_giu') { viCapNhat.dangGiu -= goc.tong; viCapNhat.daNhan += goc.tong; }
        if (loaiTien === 'hoan' && truoc === 'dang_giu') { viCapNhat.dangGiu -= goc.tong; soDaHoan = goc.tong; }
        if (loaiTien === 'hoan' && truoc !== 'dang_giu') soDaHoan = goc.tong; // tiền đến muộn: hoàn ngay khi về
        if (loaiTien === 'hoan_mot_phan' && truoc === 'dang_giu') {
          viCapNhat.dangGiu -= goc.tong;
          viCapNhat.daNhan += goc.tong - t.soTienHoan;
          soDaHoan = t.soTienHoan;
        }
        trangThaiTien = TIEN_SANG[loaiTien];
        lichSuTien.push({ trangThai: trangThaiTien, luc: Timestamp.fromMillis(now) });
      }
      for (const loai of t.viPham || []) {
        tx.set(db.collection(COL.viPham).doc(`${donId}_${loai}`), {
          uid: goc.svId, sdt: goc.svSdt, vaiTro: 'sv', loai, nguon: { loai: 'don', id: donId }, luc: Timestamp.fromMillis(now), daGo: false,
        });
        const han2 = V.hanKhoaMoi(dsBom.concat([{ luc: now }]), now, { soLan: cfg.bomHangKhoaSoLan, cuaSoPhut: cfg.bomHangCuaSoPhut, khoaPhut: cfg.khoaDatMonPhut });
        if (han2) tx.set(db.collection(COL.khoa).doc(goc.svSdt), { khoaDatMonDen: Timestamp.fromMillis(han2), uidSv: goc.svId }, { merge: true });
      }
      for (const loai of t.viPhamQuan || []) {
        tx.set(db.collection(COL.viPham).doc(`${donId}_${loai}`), {
          uid: goc.chuQuanId, vaiTro: 'quan', loai, nguon: { loai: 'don', id: donId }, luc: Timestamp.fromMillis(now), daGo: false, chiDeDem: true,
        });
        if (soChamHomNay + 1 >= cfg.tuTamNgungSoLan) tamNgungQuan = true;
      }
      if (t.khieuNaiSai) {
        tx.set(db.collection(COL.khieuNaiSai).doc(donId), { uid: goc.svId, sdt: goc.svSdt, luc: Timestamp.fromMillis(now), daGo: false, donId });
        const han2 = V.hanKhoaMoi(dsSai.concat([{ luc: now }]), now, { soLan: cfg.khieuNaiSaiSoLan, cuaSoPhut: cfg.khieuNaiSaiCuaSoPhut, khoaPhut: cfg.khoaDatMonAppPhut });
        if (han2) tx.set(db.collection(COL.khoa).doc(goc.svSdt), { khoaDatMonAppDen: Timestamp.fromMillis(han2), uidSv: goc.svId }, { merge: true });
      }
      for (const tb of t.thongBao || []) {
        const nguoiNhan = tb.toi === 'sv' ? [goc.svId] : tb.toi === 'chu' ? [goc.chuQuanId] : admins.docs.map((a) => a.id);
        const moTrang = tb.toi === 'admin' ? { loai: 'admin_hang_cho' } : tb.loai === 'duoc_viet_danh_gia' ? { loai: 'danh_gia', id: goc.quanId } : { loai: 'don', id: donId };
        for (const uidNhan of nguoiNhan) {
          const id = ghiThongBao(tx, { khoa: `${donId}_${t.khoa}_${tb.loai}`, nguoiNhan: uidNhan, loai: tb.loai, bien, moTrang, caiDat: tb.toi === 'admin' ? {} : caiDat[tb.toi] });
          if (id) thongBaoIds.push(id);
        }
      }
    }

    tx.update(refDon, capNhat);
    if (tien && lichSuTien.length) {
      tx.update(refTien, { trangThai: trangThaiTien, soDaHoan, lichSu: FieldValue.arrayUnion(...lichSuTien) });
    }
    if (viCapNhat.dangGiu || viCapNhat.daNhan) {
      tx.set(db.collection(COL.vi).doc(goc.chuQuanId), { dangGiu: FieldValue.increment(viCapNhat.dangGiu), daNhan: FieldValue.increment(viCapNhat.daNhan) }, { merge: true });
    }
    const batDauLanDau = goc.status === 'pending_payment' && d.status === 'placed';
    if (tamNgungQuan) {
      tx.update(refQuan, { tamNgungDen: Timestamp.fromMillis(hetNgayVn(now)) });
      const id = ghiThongBao(tx, { khoa: `tam_ngung_${goc.quanId}_${H.maNgayVn(now)}`, nguoiNhan: goc.chuQuanId, loai: 'quan_tu_tam_ngung', bien, moTrang: { loai: 'quan_ly_quan', id: goc.quanId }, caiDat: caiDat.chu });
      if (id) thongBaoIds.push(id);
    } else if (batDauLanDau || (su && su.loai === 'QUAN_NHAN' && !loiSuKien)) {
      tx.update(refQuan, { hoatDongLuc: Timestamp.fromMillis(now), hanXacNhanHoatDong: null });
    }
    return {
      loi: loiSuKien, status: d.status, version: d.version, quanId: goc.quanId, chuQuanId: goc.chuQuanId,
      ketThuc: !L.DANG_CHAY.has(d.status) && L.DANG_CHAY.has(goc.status), daDoiTrangThai: d.status !== goc.status,
    };
  });

  await dayThongBao(thongBaoIds);
  if (ketQua.daDoiTrangThai && !L.DANG_CHAY.has(ketQua.status)) {
    const { capNhatChiSoQuan } = require('./quan_service');
    const { capNhatChiSoChu } = require('./admin_service');
    await capNhatChiSoQuan(ketQua.quanId).catch(() => {});
    await capNhatChiSoChu(ketQua.chuQuanId).catch((e) => console.warn('Không cập nhật chỉ số chủ', e.message));
  }
  if (ketQua.loi) throw loiNguoiDung(ketQua.loi);
  return ketQua;
}

/** Bổ sung cho sự kiện các dữ kiện do HỆ THỐNG tính (mã nhận món, khoảng cách GPS, thời gian chuẩn bị). */
function boSungSuKien(su, goc, quan, maSnap, cfg) {
  const kq = { ...su };
  if (su.loai === 'QUAN_NHAN') kq.chuanBiPhut = (quan.datMon && quan.datMon.chuanBiPhut) || 15;
  if (su.loai === 'QUAN_NHAP_MA') kq.maDung = maSnap.exists ? maSnap.get('ma') : null;
  if (su.loai === 'QUAN_DA_GIAO' || su.loai === 'QUAN_KHONG_NHAN') {
    kq.coAnh = laHttps(su.anh);
    kq.anhUrl = su.anh || null;
    if (!Number.isFinite(su.lat) || !Number.isFinite(su.lng)) return { loi: 'Không lấy được vị trí GPS lúc chụp ảnh.' };
    // Đơn giao: so với điểm giao; đơn đến lấy "Khách không nhận": so với quán.
    const diem = goc.cachNhan === 'giao' ? goc.diaChiGiao && goc.diaChiGiao.viTri : quan.viTri;
    if (!diem) return { loi: 'Thiếu vị trí để đối chiếu GPS.' };
    kq.khoangCachM = Math.round(G.khoangCachMet({ lat: su.lat, lng: su.lng }, { lat: diem.latitude, lng: diem.longitude }));
  }
  if (su.loai === 'SV_KHIEU_NAI' || su.loai === 'SV_PHAN_DOI') {
    if (su.anh && (!Array.isArray(su.anh) || su.anh.length > 5 || !su.anh.every(laHttps))) return { loi: 'Tối đa 5 ảnh, đúng định dạng.' };
    if (su.loai === 'SV_KHIEU_NAI' && String(su.moTa || '').trim().length < 5) return { loi: 'Mô tả vấn đề (ít nhất 5 ký tự).' };
  }
  if (su.loai === 'ADMIN_QUYET' || su.loai === 'ADMIN_QUA_HAN' || su.loai === 'ADMIN_LUA_DAO') {
    if (String(su.lyDo || '').trim().length < 3) return { loi: 'Ghi lý do quyết định.' };
  }
  void cfg;
  return { su: kq };
}

// ---------------------------------------------------------------- Báo giá + đặt món

function loiBaoGia(ma, thongDiep, them = {}) {
  return { ok: false, ma, thongDiep, ...them };
}

/**
 * Dựng dòng đơn từ menu HIỆN TẠI (không lấy giá từ app) và tính tiền. Trả về { ok: true, ... } hoặc { ok: false, ma, thongDiep }.
 * `doc` / `truyVan`: đọc qua transaction (để kiểm tra lúc tạo đơn) hoặc đọc thường (báo giá).
 */
async function tinhBaoGia({ uid, xacThuc }, tham, cfg, { tx = null, now = Date.now() } = {}) {
  const doc = (ref) => (tx ? tx.get(ref) : ref.get());
  const { quanId, items, cachNhan, diaChi, gio } = tham;
  if (!quanId) return loiBaoGia('thieu_thong_tin', 'Thiếu quán.');
  const qSnap = await doc(db.collection(COL.quan).doc(String(quanId)));
  if (!qSnap.exists) return loiBaoGia('quan_khong_ton_tai', 'Quán không tồn tại.');
  const q = qSnap.data();
  if (q.chuQuanId === uid) throw loiNguoiDung('Bạn không thể đặt món tại quán của chính mình.', 'permission-denied');
  const dm = q.datMon || {};
  if (q.khoaBan || q.trangThai !== 'active' || q.loaiQuan !== 'ho_kinh_doanh' || !dm.bat) return loiBaoGia('quan_khong_nhan_don', 'Quán này hiện không nhận đặt món qua app.');
  if (q.tamNgungNhanDon || (ms(q.tamNgungDen) && ms(q.tamNgungDen) > now)) return loiBaoGia('quan_tam_ngung', 'Quán đang tạm ngưng nhận đơn. Bạn có thể nhắn tin hoặc đặt bàn.');
  const tt = H.trangThaiMoCua({ gioMoCua: q.gioMoCua, tamNghiDen: ms(q.tamNghiDen) }, now, { sapDongPhut: cfg.sapDongPhut });
  if (tt.trangThai === 'tam_nghi') return loiBaoGia('quan_tam_nghi', `Quán đang tạm nghỉ tới ${fmtGio(tt.moLuc)}.`);
  if (tt.trangThai === 'dong') return loiBaoGia('quan_dong', tt.moLuc ? `Quán đang đóng cửa, mở lúc ${fmtGio(tt.moLuc)}.` : 'Quán đang đóng cửa.');

  if (!Array.isArray(items) || !items.length || items.length > 50) return loiBaoGia('gio_rong', 'Giỏ hàng trống.');
  const ids = [...new Set(items.map((i) => String(i.monId || '')))];
  const monSnaps = await Promise.all(ids.map((id) => doc(db.collection(COL.mon).doc(id))));
  const mon = new Map();
  for (const s of monSnaps) if (s.exists) mon.set(s.id, s.data());
  const dong = [];
  for (const it of items) {
    const m = mon.get(String(it.monId));
    if (!m || m.quanId !== quanId || m.daXoa) return loiBaoGia('mon_khong_ton_tai', 'Có món không còn trong menu. Hãy xem lại giỏ hàng.');
    if (!m.conHang) return loiBaoGia('mon_het', `Món "${m.ten}" vừa hết. Hãy bỏ món này khỏi giỏ.`, { monId: String(it.monId) });
    const sl = it.soLuong;
    if (!Number.isInteger(sl) || sl < 1 || sl > 99) return loiBaoGia('so_luong_sai', `Số lượng món "${m.ten}" từ 1 đến 99.`);
    const chon = [];
    for (const nhom of m.tuyChon || []) {
      const c = (it.tuyChon || []).find((t) => t.nhom === nhom.ten);
      const ds = c ? (Array.isArray(c.lua) ? c.lua : [c.lua]).filter((x) => x != null && x !== '') : [];
      if (nhom.batBuoc && !ds.length) return loiBaoGia('tuy_chon_sai', `Món "${m.ten}": chọn "${nhom.ten}".`);
      if (ds.length > nhom.toiDa) return loiBaoGia('tuy_chon_sai', `Món "${m.ten}": "${nhom.ten}" chọn tối đa ${nhom.toiDa}.`);
      if (new Set(ds).size !== ds.length) return loiBaoGia('tuy_chon_sai', `Món "${m.ten}": lựa chọn bị trùng.`);
      for (const ten of ds) {
        const l = (nhom.lua || []).find((x) => x.ten === ten);
        if (!l) return loiBaoGia('tuy_chon_sai', `Món "${m.ten}": lựa chọn "${ten}" không còn.`);
        chon.push({ nhom: nhom.ten, ten: l.ten, giaThem: l.giaThem });
      }
    }
    const loaiLa = (it.tuyChon || []).find((t) => !(m.tuyChon || []).some((n) => n.ten === t.nhom));
    if (loaiLa) return loiBaoGia('tuy_chon_sai', `Món "${m.ten}": tùy chọn "${loaiLa.nhom}" không tồn tại.`);
    dong.push({ monId: String(it.monId), ten: m.ten, gia: m.gia, soLuong: sl, tuyChon: chon, ghiChu: String(it.ghiChu || '').slice(0, 200) });
  }

  if (!['den_lay', 'giao'].includes(cachNhan)) return loiBaoGia('cach_nhan_sai', 'Chọn Đến lấy hoặc Giao tận nơi.');
  let diaChiGiao = null;
  let km = 0;
  if (cachNhan === 'den_lay') {
    if (!dm.denLay) return loiBaoGia('khong_den_lay', 'Quán này không cho đến lấy.');
  } else {
    if (!dm.giaoTanNoi) return loiBaoGia('khong_giao', 'Quán này không giao tận nơi.');
    if (!diaChi || !Number.isFinite(diaChi.lat) || !Number.isFinite(diaChi.lng) || String(diaChi.dong || '').trim().length < 5) return loiBaoGia('thieu_dia_chi', 'Chọn địa chỉ giao hàng.');
    km = G.khoangCachMet({ lat: diaChi.lat, lng: diaChi.lng }, { lat: q.viTri.latitude, lng: q.viTri.longitude }) / 1000;
    if (km > dm.banKinhKm) return loiBaoGia('ngoai_ban_kinh', `Địa chỉ nằm ngoài bán kính giao ${dm.banKinhKm} km của quán.`);
    diaChiGiao = { dong: String(diaChi.dong).trim(), viTri: new GeoPoint(diaChi.lat, diaChi.lng), khoangCachKm: Math.round(km * 10) / 10 };
  }

  const loaiGio = gio && gio.loai ? gio.loai : 'asap';
  const loiGio = L.kiemTraGioNhan({ gio: loaiGio, gioHen: gio && gio.hen, now, caDangMoDenLuc: tt.dongLuc, dangTamNghi: false }, cfg);
  if (loiGio) return loiBaoGia('gio_hen_sai', loiGio);

  const tienMonTruoc = dong.reduce((s, d) => s + G.thanhTienDong(d), 0);
  if (tienMonTruoc < (dm.donToiThieu || 0)) return loiBaoGia('chua_du_don_toi_thieu', `Chưa đủ đơn tối thiểu ${(dm.donToiThieu).toLocaleString('vi-VN')}đ (không tính phí giao).`, { donToiThieu: dm.donToiThieu });

  const kmSnap = await (tx ? tx.get(db.collection(COL.khuyenMai).where('quanId', '==', quanId).where('trangThai', '==', 'chay')) : db.collection(COL.khuyenMai).where('quanId', '==', quanId).where('trangThai', '==', 'chay').get());
  const khuyenMai = kmSnap.docs.map((x) => ({ id: x.id, ...x.data(), batDau: ms(x.get('batDau')), ketThuc: ms(x.get('ketThuc')) }));
  const tinh = G.tinhDon({
    dong, khuyenMai, now, phiGiaoDon: cachNhan === 'giao' ? G.phiGiao(dm, km) : 0, coHuyHieuSinhVien: !!(xacThuc && xacThuc.emailTruong),
  });
  const gioDuKienSanSang = loaiGio === 'hen' ? gio.hen : now + (dm.chuanBiPhut || 15) * PHUT;
  return {
    ok: true, quan: q, quanId, cachNhan, diaChiGiao, gio: loaiGio, gioHen: loaiGio === 'hen' ? gio.hen : null, dm, ...tinh, gioDuKienSanSang,
  };
}

/** Sinh viên có được chọn tiền mặt không (mục 3.5c, 3.5b): quán cho phép, đơn < 200.000đ, đã OTP, chưa bom hàng 2 lần / 30 ngày. */
async function tienMatDuoc({ sdt }, dm, tong, cfg, now = Date.now()) {
  if (!sdt || !dm.tienMat || tong >= cfg.tienMatToiDa) return false;
  const snap = await db.collection(COL.viPham).where('sdt', '==', sdt).where('vaiTro', '==', 'sv').get();
  const lan = snap.docs.filter((x) => x.get('loai') === 'bom_hang').map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));
  if (V.demTrongCuaSo(lan, now, cfg.bomHangCuaSoPhut) >= cfg.bomHangMatTienMatSoLan) return false;
  return true;
}

function ketQuaBaoGia(r, tienMat) {
  return {
    ok: true, monAn: r.monAn, tienMon: r.tienMon, giamCombo: r.giamCombo, giamGia: r.giamGia, khuyenMaiApDung: r.khuyenMaiApDung,
    phiGiao: r.phiGiao, tong: r.tong, gioDuKienSanSang: r.gioDuKienSanSang, tienMatDuocKhong: tienMat, khoangCachKm: r.diaChiGiao ? r.diaChiGiao.khoangCachKm : null,
  };
}

async function baoGiaDon(nd, tham) {
  const cfg = await layCauHinh();
  const r = await tinhBaoGia(nd, tham, cfg);
  if (!r.ok) return r;
  return ketQuaBaoGia(r, await tienMatDuoc({ sdt: nd.xacThuc.sdtDaXacThuc ? nd.xacThuc.sdt : null }, r.dm, r.tong, cfg));
}

async function thongTinSinhVien(nd) {
  const cfg = await layCauHinh();
  const sdt = nd.xacThuc.sdtDaXacThuc ? nd.xacThuc.sdt : null;
  const khoa = sdt ? await docKhoa(sdt) : {};
  const snap = sdt ? await db.collection(COL.viPham).where('sdt', '==', sdt).where('vaiTro', '==', 'sv').get() : { docs: [] };
  const dsLan = (loai) => snap.docs.filter((x) => x.get('loai') === loai).map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));
  const now = Date.now();
  const soBom = V.demTrongCuaSo(dsLan('bom_hang'), now, cfg.bomHangCuaSoPhut);
  return {
    khoaDatMonDen: conKhoa(khoa, 'khoaDatMonDen', now) ? ms(khoa.khoaDatMonDen) : null,
    khoaDatMonAppDen: conKhoa(khoa, 'khoaDatMonAppDen', now) ? ms(khoa.khoaDatMonAppDen) : null,
    khoaDatBanDen: conKhoa(khoa, 'khoaDatBanDen', now) ? ms(khoa.khoaDatBanDen) : null,
    soLanBomHang: soBom,
    soLanBoHen: V.demTrongCuaSo(dsLan('bo_hen_dat_ban'), now, cfg.khoaDatBanCuaSoPhut),
    coTienMat: soBom < cfg.bomHangMatTienMatSoLan,
  };
}

/** Đặt món: tính lại toàn bộ giá trong transaction, chốt giá vào đơn. Giá / món / quán đổi giữa chừng → không tạo gì. */
async function datMon(nd, tham) {
  const cfg = await layCauHinh();
  const { uid, xacThuc } = nd;
  const sdt = canOtp(xacThuc);
  const cachTra = tham.cachTra;
  if (!['app', 'tien_mat'].includes(cachTra)) return loiBaoGia('cach_tra_sai', 'Chọn cách thanh toán.');
  const sdtNhan = String(tham.sdtNhan || sdt);
  if (!/^0\d{9}$/.test(sdtNhan)) return loiBaoGia('sdt_nhan_sai', 'Nhập số điện thoại người nhận (10 số).');
  const now = Date.now();
  const khoa = await docKhoa(sdt);
  if (conKhoa(khoa, 'khoaDatMonDen', now)) throw loiNguoiDung(`Bạn đang bị khóa đặt món tới ${fmtGio(ms(khoa.khoaDatMonDen))}.`);
  if (cachTra === 'app' && conKhoa(khoa, 'khoaDatMonAppDen', now)) throw loiNguoiDung(`Bạn đang bị khóa đặt món trả trên app tới ${fmtGio(ms(khoa.khoaDatMonAppDen))}.`);

  // Bấm 2 lần: trả lại đúng đơn đang chờ thanh toán, không tạo thêm.
  if (cachTra === 'app') {
    const cu = await db.collection(COL.don).where('svId', '==', uid).where('quanId', '==', tham.quanId).where('status', '==', 'pending_payment').get();
    const dangCho = cu.docs.find((x) => ms(x.get('hanThanhToan')) > now && x.get('tong') === tham.tongDaThay);
    if (dangCho) return { ok: true, donId: dangCho.id, daCo: true };
  }

  const ketQua = await db.runTransaction(async (tx) => {
    const r = await tinhBaoGia(nd, tham, cfg, { tx, now });
    if (!r.ok) return r;
    if (Number.isFinite(tham.tongDaThay) && tham.tongDaThay !== r.tong) {
      return { ok: false, giaDoi: true, ma: 'gia_doi', thongDiep: 'Giá đã thay đổi. Hãy xem lại tổng tiền mới rồi đặt lại.', ...ketQuaBaoGia(r, false), ok: false };
    }
    if (cachTra === 'tien_mat') {
      if (!r.dm.tienMat) return loiBaoGia('khong_tien_mat', 'Quán này không nhận tiền mặt khi nhận hàng.');
      if (r.tong >= cfg.tienMatToiDa) return loiBaoGia('tien_mat_qua_han_muc', `Tiền mặt chỉ cho đơn dưới ${cfg.tienMatToiDa.toLocaleString('vi-VN')}đ.`);
      const bom = await tx.get(db.collection(COL.viPham).where('sdt', '==', sdt).where('vaiTro', '==', 'sv'));
      const lan = bom.docs.filter((x) => x.get('loai') === 'bom_hang').map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));
      if (V.demTrongCuaSo(lan, now, cfg.bomHangCuaSoPhut) >= cfg.bomHangMatTienMatSoLan) return loiBaoGia('mat_tien_mat', 'Bạn đã bị tính bom hàng nhiều lần nên không chọn được tiền mặt.');
    }
    const refDon = db.collection(COL.don).doc();
    const d = L.taoDon({ now, cachNhan: r.cachNhan, cachTra, gio: r.gio, gioHen: r.gioHen, tong: r.tong }, cfg);
    const ma = String(crypto.randomInt(0, 10000)).padStart(4, '0');
    const tenSv = ((await tx.get(db.collection('users').doc(uid))).get('name')) || 'Sinh viên';
    tx.set(refDon, {
      ...raDoc(d), quanId: r.quanId, chuQuanId: r.quan.chuQuanId, svId: uid, svSdt: sdt, tenSv, tenQuan: r.quan.ten, anhBia: r.quan.anhBia || '',
      monAn: r.monAn, diaChiGiao: r.diaChiGiao, sdtNhan, ghiChuQuan: String(tham.ghiChuQuan || '').slice(0, 300),
      tienMon: r.tienMon, giamCombo: r.giamCombo, giamGia: r.giamGia, khuyenMaiApDung: r.khuyenMaiApDung, phiGiao: r.phiGiao,
      lichSu: [{ luc: Timestamp.fromMillis(now), su: 'TAO', nguoiLam: 'sv' }], capNhatLuc: Timestamp.fromMillis(now),
    });
    tx.set(refDon.collection('rieng').doc('ma'), { ma });
    const dsThongBao = [];
    if (cachTra === 'app') {
      tx.set(db.collection(COL.khoanTien).doc(refDon.id), {
        nguoiTra: uid, nguoiNhan: r.quan.chuQuanId, donId: refDon.id, cong: 'gia_lap', maGiaoDichCong: null, maChongTrung: refDon.id,
        soTienVnd: r.tong, trangThai: 'cho_tra', soDaHoan: 0, hetHanLuc: Timestamp.fromMillis(d.hanThanhToan),
        lichSu: [{ trangThai: 'cho_tra', luc: Timestamp.fromMillis(now) }],
      });
      tx.set(db.collection(COL.cong).doc(refDon.id), { donId: refDon.id, nguoiTra: uid, soTien: r.tong, trangThai: 'cho', taoLuc: Timestamp.fromMillis(now) });
    } else {
      // Tiền mặt: đơn tới quán ngay, không có khoản tiền qua app.
      const hs = await tx.get(db.collection(COL.hoSo).doc(r.quan.chuQuanId));
      const id = ghiThongBao(tx, { khoa: `${refDon.id}_TAO_don_moi`, nguoiNhan: r.quan.chuQuanId, loai: 'don_moi', bien: { quan: r.quan.ten }, moTrang: { loai: 'don', id: refDon.id }, caiDat: (hs.exists && hs.get('caiDatThongBao')) || {} });
      if (id) dsThongBao.push(id);
      tx.update(db.collection(COL.quan).doc(r.quanId), { hoatDongLuc: Timestamp.fromMillis(now), hanXacNhanHoatDong: null });
    }
    return { ok: true, donId: refDon.id, cachTra, tong: r.tong, hanThanhToan: d.hanThanhToan, dsThongBao };
  });
  if (ketQua.dsThongBao) { await dayThongBao(ketQua.dsThongBao); delete ketQua.dsThongBao; }
  return ketQua;
}

/** Mở lại đơn: tự xử lý hạn đã tới để thấy đúng trạng thái sau hạn. */
async function xuLyHanDon(nd, { donId }, laAdmin) {
  const s = await db.collection(COL.don).doc(String(donId || '')).get();
  if (!s.exists) throw thamSoSai();
  if (![s.get('svId'), s.get('chuQuanId')].includes(nd.uid) && !laAdmin) throw khongCoQuyen();
  return chayTrenDon(donId);
}

module.exports = {
  tuDoc, raDoc, VAI_TRO, chayTrenDon, baoGiaDon, datMon, thongTinSinhVien, xuLyHanDon, tinhBaoGia, K,
};
