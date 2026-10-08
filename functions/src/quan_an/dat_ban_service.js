'use strict';

/**
 * Lớp Firestore cho đặt bàn: đọc đủ dữ liệu trong 1 transaction, chạy logic thuần (logic/dat_ban.js),
 * ghi mọi tác động (bàn, vi phạm, khóa, thông báo). Mọi thao tác tự xử lý hạn đã tới trước (mục 3.18 quy tắc 6).
 */

const { db, FieldValue, Timestamp, ms, ts } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { canOtp } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const L = require('./logic/dat_ban');
const V = require('./logic/vi_pham');
const H = require('./logic/gio_mo_cua');
const { ghiThongBao, dayThongBao } = require('./thong_bao');
const { COL, kiemTraKhoaBan, docKhoa, conKhoa, fmtGio } = require('./ho_tro');

const LOI_DA_THAY_DOI = 'Thông tin đã thay đổi, vui lòng tải lại.';
const KHOA_THOI_GIAN = ['gio', 'taoLuc', 'hanXacNhan', 'hanGiuBan', 'hanTuDong', 'xacNhanLuc', 'ketThucLuc'];
const LOGIC_KHOA = ['status', 'version', 'gio', 'taoLuc', 'hanXacNhan', 'hanGiuBan', 'hanTuDong', 'huySatGio', 'ghiNhanDen', 'xacNhanLuc', 'daXuLy', 'lyDoKetThuc', 'ketThucLuc'];

function tuDoc(data) {
  const d = {};
  for (const k of LOGIC_KHOA) d[k] = data[k] === undefined ? null : data[k];
  for (const k of KHOA_THOI_GIAN) d[k] = ms(d[k]);
  d.daXuLy = d.daXuLy || {};
  d.huySatGio = !!d.huySatGio;
  return d;
}

function raDoc(d, cfg) {
  const kq = {};
  for (const k of LOGIC_KHOA) kq[k] = d[k] === undefined ? null : d[k];
  for (const k of KHOA_THOI_GIAN) kq[k] = ts(kq[k]);
  kq.hanKeTiep = ts(L.hanKeTiep(d, cfg));
  return kq;
}

const VAI_TRO = Object.freeze({
  QUAN_XAC_NHAN: 'chu', QUAN_TU_CHOI: 'chu', QUAN_HUY: 'chu', QUAN_KHACH_DEN: 'chu', QUAN_KHONG_DEN: 'chu', SV_HUY: 'sv',
});

/**
 * Chạy một sự kiện (hoặc chỉ xử lý hạn nếu `su` null) trên bàn trong transaction.
 * `nguoiLam` = { uid, vaiTro } (vaiTro: 'sv' | 'chu' | 'he_thong'). `versionDaThay`: chống thao tác trên dữ liệu cũ.
 */
async function chayTrenBan(banId, { su = null, nguoiLam = { vaiTro: 'he_thong' }, versionDaThay = null, now = Date.now() } = {}) {
  const cfg = await layCauHinh();
  const refBan = db.collection(COL.datBan).doc(banId);
  const thongBaoIds = [];

  const kq = await db.runTransaction(async (tx) => {
    thongBaoIds.length = 0;
    const snap = await tx.get(refBan);
    if (!snap.exists) throw khongTimThay('Đặt bàn');
    const goc = snap.data();
    if (su) {
      const vai = VAI_TRO[su.loai];
      if (vai === 'sv' && nguoiLam.uid !== goc.svId) throw khongCoQuyen();
      if (vai === 'chu' && nguoiLam.uid !== goc.chuQuanId) throw khongCoQuyen();
      if (!vai && nguoiLam.vaiTro !== 'he_thong') throw khongCoQuyen();
      if (versionDaThay != null && versionDaThay !== goc.version) throw loiNguoiDung(LOI_DA_THAY_DOI, 'aborted');
    }
    const [hoSoSv, hoSoChu, viPhamSv] = await Promise.all([
      tx.get(db.collection(COL.hoSo).doc(goc.svId)),
      tx.get(db.collection(COL.hoSo).doc(goc.chuQuanId)),
      tx.get(db.collection(COL.viPham).where('sdt', '==', goc.svSdt).where('vaiTro', '==', 'sv')),
    ]);

    let d = tuDoc(goc);
    const han = L.xuLyHan(d, now, cfg);
    d = han.d;
    const tacDong = han.tacDong.map((t) => ({ ...t }));
    let loiSuKien = null;
    let daCheckIn = false;
    if (su) {
      const r = L.apDung(d, su, now, cfg);
      if (r.loi) loiSuKien = r.loi;
      else {
        d = r.d;
        if (!r.boQua) {
          tacDong.push({ ...r, d: undefined, khoa: `${su.loai}_${(goc.version || 0) + 1}`, status: r.d.status });
          if (su.loai === 'SV_CHECK_IN') daCheckIn = true;
        }
      }
    }
    d.version = tacDong.some((t) => !t.laNhac) ? (goc.version || 1) + 1 : goc.version || 1;

    const capNhat = { ...raDoc(d, cfg), capNhatLuc: Timestamp.fromMillis(now) };
    if (su && su.checkInId && daCheckIn) capNhat.checkInId = su.checkInId;
    const lich = tacDong.filter((t) => !t.laNhac).map((t) => ({ luc: Timestamp.fromMillis(now), su: t.khoa, status: t.status || d.status, nguoiLam: su && t.khoa.startsWith(su.loai) ? nguoiLam.vaiTro : 'he_thong' }));
    if (lich.length) capNhat.lichSu = FieldValue.arrayUnion(...lich);

    const caiDat = { sv: (hoSoSv.exists && hoSoSv.get('caiDatThongBao')) || {}, chu: (hoSoChu.exists && hoSoChu.get('caiDatThongBao')) || {} };
    const bien = { quan: goc.tenQuan || 'quán' };
    const moTrang = { loai: 'dat_ban', id: banId };
    const dsViPham = viPhamSv.docs.map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') }));

    for (const t of tacDong) {
      for (const loai of t.viPham || []) {
        tx.set(db.collection(COL.viPham).doc(`${banId}_${loai}`), {
          uid: goc.svId, sdt: goc.svSdt, vaiTro: 'sv', loai, nguon: { loai: 'dat_ban', id: banId }, luc: Timestamp.fromMillis(now), daGo: false,
        });
        const han2 = V.hanKhoaMoi(dsViPham.concat([{ luc: now }]), now, { soLan: cfg.khoaDatBanSoLan, cuaSoPhut: cfg.khoaDatBanCuaSoPhut, khoaPhut: cfg.khoaDatBanPhut });
        if (han2) tx.set(db.collection(COL.khoa).doc(goc.svSdt), { khoaDatBanDen: Timestamp.fromMillis(han2), uidSv: goc.svId }, { merge: true });
      }
      for (const tb of t.thongBao || []) {
        const nguoiNhan = tb.toi === 'sv' ? goc.svId : goc.chuQuanId;
        const id = ghiThongBao(tx, { khoa: `${banId}_${t.khoa}_${tb.loai}`, nguoiNhan, loai: tb.loai, bien, moTrang, caiDat: caiDat[tb.toi] });
        if (id) thongBaoIds.push(id);
      }
    }
    tx.update(refBan, capNhat);
    return { loi: loiSuKien, status: d.status, version: d.version, daCheckIn, ghiNhanDen: d.ghiNhanDen, quanId: goc.quanId, doiTrangThai: d.status !== goc.status };
  });

  await dayThongBao(thongBaoIds);
  if (kq.doiTrangThai && ['cancelled_restaurant', 'arrived', 'no_show'].includes(kq.status)) {
    const { capNhatChiSoQuan } = require('./quan_service');
    await capNhatChiSoQuan(kq.quanId).catch(() => {});
  }
  if (kq.loi) throw loiNguoiDung(kq.loi);
  return kq;
}

/** Sinh viên đặt bàn (quán hộ kinh doanh có bật). Không thu tiền. */
async function datBan({ uid, xacThuc }, { quanId, gio, soNguoi, ghiChu = '' }) {
  const cfg = await layCauHinh();
  const sdt = canOtp(xacThuc);
  const now = Date.now();
  const qSnap = await db.collection(COL.quan).doc(String(quanId || '')).get();
  if (!qSnap.exists) throw khongTimThay('Quán');
  const q = qSnap.data();
  if (q.chuQuanId === uid) throw loiNguoiDung('Bạn không thể đặt bàn tại quán của chính mình.', 'permission-denied');
  kiemTraKhoaBan(q);
  if (q.trangThai !== 'active') throw loiNguoiDung('Quán này hiện không nhận đặt bàn.');
  if (q.loaiQuan !== 'ho_kinh_doanh' || !q.nhanDatBan) throw loiNguoiDung('Quán này không nhận đặt bàn.');
  const khoa = await docKhoa(sdt);
  if (conKhoa(khoa, 'khoaDatBanDen', now)) throw loiNguoiDung(`Bạn đang bị khóa đặt bàn tới ${fmtGio(ms(khoa.khoaDatBanDen))}.`);
  const tamNghiDen = ms(q.tamNghiDen);
  if (tamNghiDen && gio < tamNghiDen) throw loiNguoiDung('Quán đang tạm nghỉ vào thời gian này.');
  const loi = L.kiemTraDatBan({ now, gio, soNguoi, trongGioMoCua: !!H.caDangMo(q.gioMoCua, gio) }, cfg);
  if (loi) throw thamSoSai(loi);
  const trung = await db.collection(COL.datBan).where('svId', '==', uid).where('quanId', '==', quanId).where('status', 'in', ['pending', 'confirmed']).get();
  if (trung.docs.some((b) => Math.abs(ms(b.get('gio')) - gio) < 60 * PHUT)) throw loiNguoiDung('Bạn đã có yêu cầu đặt bàn gần giờ này ở quán.');

  const d = L.taoBan({ now, gio }, cfg);
  const ref = db.collection(COL.datBan).doc();
  const tenSv = ((await db.collection('users').doc(uid).get()).get('name')) || 'Sinh viên';
  await ref.set({
    ...raDoc(d, cfg), quanId, chuQuanId: q.chuQuanId, svId: uid, svSdt: sdt, tenSv, tenQuan: q.ten, anhBia: q.anhBia || '',
    soNguoi, ghiChu: String(ghiChu || '').slice(0, 300), lichSu: [{ luc: Timestamp.fromMillis(now), su: 'TAO', nguoiLam: 'sv' }], checkInId: null,
  });
  const batch = db.batch();
  const id = ghiThongBao(batch, { khoa: `${ref.id}_ban_moi`, nguoiNhan: q.chuQuanId, loai: 'ban_moi', bien: { quan: q.ten }, moTrang: { loai: 'dat_ban', id: ref.id } });
  await batch.commit();
  await dayThongBao([id].filter(Boolean));
  return { banId: ref.id, hanXacNhan: d.hanXacNhan };
}

module.exports = { chayTrenBan, datBan, tuDoc, raDoc, VAI_TRO };
