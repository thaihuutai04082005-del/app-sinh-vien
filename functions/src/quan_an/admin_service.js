'use strict';

/** Việc của admin Quán ăn (mục 3.12): quyết định đơn, khóa chức năng, chỉ số uy tín chủ quán. Mọi quyết định ghi nhật ký. */

const { db, Timestamp } = require('../chung/firebase');
const { thamSoSai, khongTimThay } = require('../chung/loi');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const { COL, ghiNhatKy } = require('./ho_tro');

/** Admin quyết đơn: khiếu nại, phản đối "khách không nhận", đơn quá 6 giờ, đơn rà soát do quán lừa đảo. */
async function quyetDon(adminUid, { donId, loai = 'ADMIN_QUYET', quyetDinh, soTienHoan, lyDo }) {
  const { chayTrenDon } = require('./don_mon_service');
  if (!['ADMIN_QUYET', 'ADMIN_QUA_HAN', 'ADMIN_LUA_DAO'].includes(loai)) throw thamSoSai();
  if (!String(lyDo || '').trim()) throw thamSoSai('Ghi lý do quyết định.');
  const kq = await chayTrenDon(donId, { su: { loai, quyetDinh, soTienHoan, lyDo }, nguoiLam: { uid: adminUid, vaiTro: 'admin' } });
  await ghiNhatKy(adminUid, `quyet_don_${quyetDinh}`, { loai: 'don', id: donId }, lyDo);
  return kq;
}

/** Khóa một chức năng của người dùng trong Quán ăn: 'dat_mon' | 'dat_ban' | 'tien_mat' | 'bao_cao' | 'dat_mon_app'. */
async function khoaChucNang(adminUid, { uid, chucNang, lyDo }) {
  const cfg = await layCauHinh();
  const truong = {
    dat_mon: ['khoaDatMonDen', 'khoaDatMonPhut'], dat_ban: ['khoaDatBanDen', 'khoaDatBanPhut'], tien_mat: ['khoaTienMatDen', 'khoaDatMonPhut'],
    bao_cao: ['khoaBaoCaoDen', 'khoaBaoCaoPhut'], dat_mon_app: ['khoaDatMonAppDen', 'khoaDatMonAppPhut'],
  }[chucNang];
  if (!truong) throw thamSoSai();
  const xt = await db.collection('xac_thuc').doc(uid).get();
  const khoa = (xt.exists && xt.get('sdt')) || uid;
  await db.collection(COL.khoa).doc(khoa).set({ [truong[0]]: Timestamp.fromMillis(Date.now() + cfg[truong[1]] * PHUT) }, { merge: true });
  await ghiNhatKy(adminUid, `khoa_${chucNang}`, { loai: 'nguoi_dung', id: uid }, lyDo || '');
  return { ok: true };
}

/** Chỉ số uy tín công khai của chủ quán: tỷ lệ phản hồi, tỷ lệ nhận đơn / giữ bàn (trung bình các quán), số cảnh cáo. */
async function capNhatChiSoChu(chuQuanId) {
  if (!chuQuanId) return;
  const { tinhTyLePhanHoi } = require('./tuong_tac_service');
  const quan = await db.collection(COL.quan).where('chuQuanId', '==', chuQuanId).get();
  const lay = (k) => {
    const ds = quan.docs.map((d) => (d.get('soLieu') || {})[k]).filter((x) => typeof x === 'number');
    return ds.length ? Math.round(ds.reduce((s, x) => s + x, 0) / ds.length) : null;
  };
  const xt = await db.collection('xac_thuc').doc(chuQuanId).get();
  const cu = await db.collection(COL.chiSoChu).doc(chuQuanId).get();
  await db.collection(COL.chiSoChu).doc(chuQuanId).set({
    tyLePhanHoi: await tinhTyLePhanHoi(chuQuanId), tyLeNhanDon: lay('tyLeNhanDon'), tyLeGiuBan: lay('tyLeGiuBan'),
    soCanhCao: cu.exists ? cu.get('soCanhCao') || 0 : 0, capNhatLuc: Timestamp.now(),
    hoTen: xt.exists ? xt.get('hoTenXacThuc') || null : null, daXacThucDanhTinh: xt.exists && xt.get('danhTinh') === 'da_xac_thuc',
  }, { merge: true });
}

module.exports = { quyetDon, khoaChucNang, capNhatChiSoChu, khongTimThay };
