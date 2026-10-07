'use strict';

/** Việc của admin Tìm trọ (mục 2.12). Mọi quyết định đều ghi nhật ký. */

const { db, Timestamp } = require('../chung/firebase');
const { thamSoSai, khongTimThay } = require('../chung/loi');
const { chayTrenKhoanCoc, hoanTatCaCuaChu } = require('./dat_coc_service');
const { ghiNhatKy, dongBoPhong, capNhatSoLieuNhaTro, thongBao } = require('./nha_tro_service');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');

async function quyetKhieuNai(adminUid, { datCocId, ketLuan, phongSau, lyDo }) {
  if (!String(lyDo || '').trim()) throw thamSoSai('Ghi lý do quyết định.');
  const kq = await chayTrenKhoanCoc(datCocId, {
    su: { loai: 'ADMIN_QUYET', ketLuan, phongSau, lyDo },
    nguoiLam: { uid: adminUid, vaiTro: 'admin' },
  });
  await ghiNhatKy(adminUid, `quyet_khieu_nai_${ketLuan}`, { loai: 'dat_coc', id: datCocId }, lyDo);
  await capNhatChiSoChu((await db.collection('tro_dat_coc').doc(datCocId).get()).get('chuTroId'));
  return kq;
}

/**
 * Kết luận chủ trọ lừa đảo / giấy tờ giả (mục 2.14): ẩn mọi nhà trọ của chủ, hoàn 100% mọi
 * khoản cọc app còn giữ (khoản đã hoàn tất không đảo ngược), gửi đề nghị khóa cả tài khoản
 * tới admin danh tính (chỉ admin danh tính được khóa, mục 4.4).
 */
async function ketLuanLuaDao(adminUid, { chuTroId, lyDo }) {
  if (!String(lyDo || '').trim()) throw thamSoSai('Ghi lý do.');
  const nha = await db.collection('nha_tro').where('chuTroId', '==', chuTroId).get();
  for (const d of nha.docs) {
    await d.ref.update({ trangThai: 'hidden', anBoi: 'admin', anLuc: Timestamp.now() });
  }
  const soHoan = await hoanTatCaCuaChu(chuTroId, adminUid);
  for (const d of nha.docs) await dongBoPhong(d.id);
  await db.collection('de_nghi_khoa_tai_khoan').add({
    uid: chuTroId, module: 'tro', lyDo, deNghiBoi: adminUid, luc: Timestamp.now(), trangThai: 'cho_xu_ly',
  });
  await ghiNhatKy(adminUid, 'ket_luan_lua_dao', { loai: 'nguoi_dung', id: chuTroId }, lyDo);
  return { soNhaTroAn: nha.size, soKhoanCocHoan: soHoan };
}

async function anHien(adminUid, { loai, id, an, lyDo = '' }) {
  if (!['nha_tro', 'phong'].includes(loai)) throw thamSoSai();
  const col = loai === 'nha_tro' ? 'nha_tro' : 'phong_tro';
  const ref = db.collection(col).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay();
  const x = snap.data();
  if (an) {
    // Ẩn chỉ chặn giao dịch mới; phòng đang có cọc vẫn đi tiếp (mục 2.14).
    if (loai === 'phong' && x.trangThai === 'reserved') {
      await ref.update({ anBoi: 'admin', anSauKhiXong: true, anLuc: Timestamp.now() });
    } else {
      await ref.update({ trangThai: 'hidden', anBoi: 'admin', anLuc: Timestamp.now() });
    }
  } else {
    await ref.update({ trangThai: loai === 'nha_tro' ? 'active' : 'available', anBoi: null, anSauKhiXong: false });
  }
  if (loai === 'nha_tro') await dongBoPhong(id);
  else await capNhatSoLieuNhaTro(x.nhaTroId);
  await ghiNhatKy(adminUid, an ? `an_${loai}` : `hien_${loai}`, { loai, id }, lyDo);
  await thongBao([{
    khoa: `admin_an_${id}_${Date.now()}`, nguoiNhan: x.chuTroId, loai: 'admin_an_tin', nhom: 'khang_nghi',
    tieuDe: an ? 'Tin của bạn bị ẩn' : 'Tin của bạn được hiện lại',
    noiDung: an ? `Admin đã ẩn tin "${x.ten}": ${lyDo}. Bạn có thể kháng nghị trong 7 ngày.` : `Tin "${x.ten}" đã hiển thị lại.`,
    moTrang: { loai: 'quan_ly_nha_tro', id: loai === 'nha_tro' ? id : x.nhaTroId },
  }]);
  return { ok: true };
}

/** Khóa một chức năng của người dùng trong Tìm trọ: 'coc' | 'bao_cao' | 'dang_tin'. */
async function khoaChucNang(adminUid, { uid, chucNang, lyDo }) {
  const cfg = await layCauHinh();
  const truong = { coc: ['khoaCocDen', 'khoaCocPhut'], bao_cao: ['khoaBaoCaoDen', 'khoaBaoCaoPhut'], dang_tin: ['khoaDangTinDen', 'khoaDangTinPhut'] }[chucNang];
  if (!truong) throw thamSoSai();
  const xt = await db.collection('xac_thuc').doc(uid).get();
  const khoa = (xt.exists && xt.get('sdt')) || uid;
  await db.collection('tro_khoa').doc(khoa).set({ [truong[0]]: Timestamp.fromMillis(Date.now() + cfg[truong[1]] * PHUT) }, { merge: true });
  await ghiNhatKy(adminUid, `khoa_${chucNang}`, { loai: 'nguoi_dung', id: uid }, lyDo || '');
  return { ok: true };
}

/**
 * Chỉ số uy tín công khai của chủ trọ (mục 2.3 Bước 4): tỷ lệ phản hồi, tỷ lệ giữ đúng cam kết (90 ngày),
 * số vi phạm còn hiệu lực trong 90 ngày.
 */
async function capNhatChiSoChu(chuTroId) {
  if (!chuTroId) return;
  const cfg = await layCauHinh();
  const tu = Timestamp.fromMillis(Date.now() - cfg.tyLeCamKetCuaSoPhut * PHUT);
  const coc = await db.collection('tro_dat_coc').where('chuTroId', '==', chuTroId).where('heldAt', '>=', tu).get();
  const ketThuc = coc.docs.map((d) => d.data()).filter((d) => d.heldAt);
  const viPhamLyDo = ['owner_cancelled', 'owner_violation', 'owner_no_reply_reschedule'];
  const tyLeCamKet = ketThuc.length
    ? Math.round((ketThuc.filter((d) => !viPhamLyDo.includes(d.lyDoKetThuc)).length / ketThuc.length) * 100)
    : null;
  const { tinhTyLePhanHoi } = require('./tuong_tac_service');
  const tyLePhanHoi = await tinhTyLePhanHoi(chuTroId);
  const xt = await db.collection('xac_thuc').doc(chuTroId).get();
  let soViPham = 0;
  if (xt.exists && xt.get('sdt')) {
    const vp = await db.collection('tro_vi_pham').where('sdt', '==', xt.get('sdt')).where('vaiTro', '==', 'chu').get();
    soViPham = vp.docs.filter((d) => !d.get('daGo') && d.get('luc').toMillis() > tu.toMillis()).length;
  }
  await db.collection('tro_chi_so_chu').doc(chuTroId).set({
    tyLeCamKet, tyLePhanHoi, soViPham90: soViPham, capNhatLuc: Timestamp.now(),
    hoTen: xt.exists ? xt.get('hoTenXacThuc') || null : null, daXacThucDanhTinh: xt.exists && xt.get('danhTinh') === 'da_xac_thuc',
  });
}

module.exports = { quyetKhieuNai, ketLuanLuaDao, anHien, khoaChucNang, capNhatChiSoChu };
