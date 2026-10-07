'use strict';

/**
 * Tương tác riêng của module Tìm trọ: chat (2.8), đánh giá (2.9), báo cáo (2.10), kháng nghị (2.15).
 * Không dùng chung với module khác.
 */

const { admin, db, FieldValue, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const { quet, CANH_BAO, boDau } = require('./logic/canh_bao_chat');
const V = require('./logic/vi_pham');
const { thongBao, cacAdminTro } = require('./nha_tro_service');

const COL = Object.freeze({
  chat: 'tro_chat', danhGia: 'tro_danh_gia', baoCao: 'tro_bao_cao', khangNghi: 'tro_khang_nghi',
  khoa: 'tro_khoa', viPham: 'tro_vi_pham', baoCaoSai: 'tro_bao_cao_sai',
});

// ---------------------------------------------------------------- Chat

const maCuocTroChuyen = (a, b) => [a, b].sort().join('_');

async function laChuCuaPhong(uid, phongId) {
  const p = await db.collection('phong_tro').doc(phongId).get();
  if (!p.exists) throw khongTimThay('Phòng');
  return { la: p.get('chuTroId') === uid, phong: p.data(), id: p.id };
}

async function guiTin({ uid }, { nguoiNhan, noiDung, loai = 'chu', the = null, anh = null }) {
  if (!nguoiNhan || nguoiNhan === uid) throw thamSoSai('Người nhận không hợp lệ.');
  const chu = String(noiDung || '').trim();
  if (loai === 'chu' && (!chu || chu.length > 2000)) throw thamSoSai('Tin nhắn 1–2000 ký tự.');
  if (loai === 'anh' && !(typeof anh === 'string' && anh.startsWith('https://'))) throw thamSoSai('Ảnh không hợp lệ.');
  let theTin = null;
  if (loai === 'the_tin') {
    const { la, phong, id } = await laChuCuaPhong(uid, the && the.phongId);
    // Chủ trọ không mở chat với nhà trọ của chính mình (mục 2.18 quy tắc 5).
    if (la && phong.chuTroId === nguoiNhan) throw khongCoQuyen();
    if (!la && phong.chuTroId !== nguoiNhan) throw thamSoSai();
    theTin = { phongId: id, nhaTroId: phong.nhaTroId, ten: phong.ten, gia: phong.giaThue, anh: phong.anhBia || '' };
  }
  const chatId = maCuocTroChuyen(uid, nguoiNhan);
  const refChat = db.collection(COL.chat).doc(chatId);
  const tuKhoa = loai === 'chu' ? quet(chu) : [];
  const refTin = refChat.collection('tin_nhan').doc();
  const now = Timestamp.now();
  const [u1, u2] = await Promise.all([db.collection('users').doc(uid).get(), db.collection('users').doc(nguoiNhan).get()]);
  if (!u2.exists) throw thamSoSai('Người nhận không tồn tại.');
  const ten = { [uid]: u1.get('name') || 'Người dùng', [nguoiNhan]: u2.get('name') || 'Người dùng' };
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(refChat);
    const c = snap.exists ? snap.data() : null;
    if (c && (c.chanBoi || []).length) throw loiNguoiDung('Không gửi được tin nhắn: cuộc trò chuyện đã bị chặn.', 'permission-denied');
    if (!c) {
      tx.set(refChat, {
        thanhVien: [uid, nguoiNhan].sort(), ten, nguoiMo: uid, taoLuc: now, daTraLoiLuc: null,
        chanBoi: [], chuaDoc: { [uid]: 0, [nguoiNhan]: 0 },
      });
    }
    tx.set(refTin, {
      nguoiGui: uid, loai, noiDung: loai === 'anh' ? anh : chu, noiDungBoDau: boDau(chu), tuKhoaCanhBao: tuKhoa,
      the: theTin, guiLuc: now, daXemLuc: null, hienThi: 'hien',
    });
    const cap = {
      tinCuoi: loai === 'chu' ? chu.slice(0, 120) : loai === 'anh' ? '[Ảnh]' : `[Phòng] ${theTin.ten}`,
      tinCuoiLuc: now, [`chuaDoc.${nguoiNhan}`]: FieldValue.increment(1),
    };
    // Tỷ lệ phản hồi: ghi lần đầu người kia trả lời (trong 24 giờ thì tính là có phản hồi).
    if (c && !c.daTraLoiLuc && c.nguoiMo !== uid) cap.daTraLoiLuc = now;
    if (!c) tx.update(refChat, cap); else tx.update(refChat, cap);
  });
  await thongBao([{
    khoa: `tin_${refTin.id}`, nguoiNhan, loai: 'tin_nhan', nhom: 'tin_nhan',
    tieuDe: 'Tin nhắn mới', noiDung: loai === 'chu' ? chu.slice(0, 100) : 'Bạn có tin nhắn mới.',
    moTrang: { loai: 'chat', id: chatId },
  }]);
  return { chatId, tinId: refTin.id, canhBao: tuKhoa.length ? CANH_BAO : null };
}

async function daXem({ uid }, { chatId }) {
  const ref = db.collection(COL.chat).doc(chatId);
  const snap = await ref.get();
  if (!snap.exists || !(snap.get('thanhVien') || []).includes(uid)) throw khongCoQuyen();
  const chuaXem = await ref.collection('tin_nhan').where('daXemLuc', '==', null).get();
  const batch = db.batch();
  chuaXem.docs.filter((d) => d.get('nguoiGui') !== uid).forEach((d) => batch.update(d.ref, { daXemLuc: Timestamp.now() }));
  batch.update(ref, { [`chuaDoc.${uid}`]: 0 });
  await batch.commit();
  return { ok: true };
}

async function chan({ uid }, { chatId, chan: coChan }) {
  const ref = db.collection(COL.chat).doc(chatId);
  const snap = await ref.get();
  if (!snap.exists || !(snap.get('thanhVien') || []).includes(uid)) throw khongCoQuyen();
  await ref.update({ chanBoi: coChan ? FieldValue.arrayUnion(uid) : FieldValue.arrayRemove(uid) });
  return { ok: true };
}

/** Tỷ lệ phản hồi của chủ trọ: % cuộc trò chuyện mới (30 ngày) được trả lời trong 24 giờ. */
async function tinhTyLePhanHoi(chuTroId) {
  const cfg = await layCauHinh();
  const tu = Date.now() - cfg.phanHoiCuaSoPhut * PHUT;
  const snap = await db.collection(COL.chat).where('thanhVien', 'array-contains', chuTroId).get();
  const moi = snap.docs.map((d) => d.data()).filter((c) => c.nguoiMo !== chuTroId && ms(c.taoLuc) >= tu);
  if (!moi.length) return null;
  const traLoi = moi.filter((c) => c.daTraLoiLuc && ms(c.daTraLoiLuc) - ms(c.taoLuc) <= cfg.phanHoiTrongPhut * PHUT);
  return Math.round((traLoi.length / moi.length) * 100);
}

// ---------------------------------------------------------------- Đánh giá

const TIEU_CHI = ['dungMoTa', 'anNinh', 'veSinh', 'chuTro', 'giaHopLy'];
const THE_NHANH = ['yen_tinh', 'chu_de_tinh', 'dien_nuoc_on_dinh', 'gan_cho', 'an_ninh_tot', 'hay_cup_nuoc', 'on_ao', 'am_thap'];

/** Tìm quyền đánh giá của người dùng từ khoản cọc hoặc cọc trực tiếp (mục 2.4 Bước 5). */
async function quyenDanhGia(uid, nguon) {
  if (!nguon || !['dat_coc', 'coc_truc_tiep'].includes(nguon.loai)) throw thamSoSai();
  const col = nguon.loai === 'dat_coc' ? 'tro_dat_coc' : 'tro_coc_truc_tiep';
  const snap = await db.collection(col).doc(nguon.id).get();
  if (!snap.exists) throw khongTimThay();
  const x = snap.data();
  const nguoi = nguon.loai === 'dat_coc' ? x.sinhVienId : x.nguoiCocUid;
  if (nguoi !== uid) throw khongCoQuyen();
  if (!x.danhGia) throw loiNguoiDung('Bạn chưa thể đánh giá giao dịch này.');
  if (Date.now() > ms(x.danhGia.han)) throw loiNguoiDung('Đã hết thời hạn viết / sửa đánh giá.');
  return { x, danhGia: x.danhGia };
}

async function guiDanhGia({ uid, xacThuc }, { nguon, diem, the = [], nhanXet, anh = [] }) {
  const cfg = await layCauHinh();
  const { x, danhGia } = await quyenDanhGia(uid, nguon);
  const cham = TIEU_CHI.filter((k) => Number.isInteger(diem && diem[k]) && diem[k] >= 1 && diem[k] <= 5);
  if (!cham.length) throw thamSoSai('Chấm ít nhất 1 tiêu chí (1–5 sao).');
  if (String(nhanXet || '').trim().length < cfg.danhGiaNhanXetToiThieu) throw thamSoSai('Nhận xét ít nhất 20 ký tự.');
  if (!Array.isArray(anh) || anh.length > cfg.danhGiaAnhToiDa || !anh.every((u) => typeof u === 'string' && u.startsWith('https://'))) {
    throw thamSoSai('Tối đa 5 ảnh.');
  }
  const ref = db.collection(COL.danhGia).doc(`${nguon.loai}_${nguon.id}`);
  const cu = await ref.get();
  const diemTB = cham.reduce((s, k) => s + diem[k], 0) / cham.length;
  // Nhãn xác minh chỉ tính khi người viết đã xác thực số điện thoại.
  const tinhDiem = !!danhGia.tinhDiem && !!xacThuc.sdtDaXacThuc;
  const hoTen = (await db.collection('users').doc(uid).get()).get('name') || 'Sinh viên';
  const duLieu = {
    nhaTroId: x.nhaTroId, nguoiViet: uid, tenNguoiViet: hoTen, tenPhong: x.tenPhong || '', nguon,
    nhan: danhGia.nhan, tinhDiem, diem: Object.fromEntries(cham.map((k) => [k, diem[k]])), diemTB,
    the: the.filter((t) => THE_NHANH.includes(t)), nhanXet: String(nhanXet).trim(), anh,
    capNhatLuc: Timestamp.now(), hienThi: cu.exists ? cu.get('hienThi') : 'hien',
    thoiDiemNhanPhong: x.t || x.ngayNhanDuKien || null,
  };
  if (cu.exists) await ref.update({ ...duLieu, daCapNhat: true });
  else await ref.set({ ...duLieu, taoLuc: Timestamp.now(), daCapNhat: false, chuTraLoi: null });
  await capNhatDiemNhaTro(x.nhaTroId);
  const nha = await db.collection('nha_tro').doc(x.nhaTroId).get();
  if (!cu.exists && nha.exists) {
    await thongBao([{
      khoa: `danh_gia_moi_${ref.id}`, nguoiNhan: nha.get('chuTroId'), loai: 'danh_gia_moi', nhom: 'danh_gia',
      tieuDe: 'Có đánh giá mới', noiDung: `"${nha.get('ten')}" có đánh giá mới.`, moTrang: { loai: 'nha_tro', id: x.nhaTroId },
    }]);
  }
  return { id: ref.id };
}

/** Điểm nhà trọ = trung bình các đánh giá có nhãn của người đã OTP (đánh giá "Chưa xác minh" không tính). */
async function capNhatDiemNhaTro(nhaTroId) {
  const snap = await db.collection(COL.danhGia).where('nhaTroId', '==', nhaTroId).get();
  const tinh = snap.docs.map((d) => d.data()).filter((d) => d.tinhDiem && d.hienThi !== 'an');
  const diem = tinh.length ? Math.round((tinh.reduce((s, d) => s + d.diemTB, 0) / tinh.length) * 10) / 10 : null;
  await db.collection('nha_tro').doc(nhaTroId).set({ soLieu: { diem, soDanhGia: tinh.length } }, { merge: true });
}

async function chuTraLoiDanhGia({ uid }, { danhGiaId, noiDung }) {
  const ref = db.collection(COL.danhGia).doc(danhGiaId);
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Đánh giá');
  const nha = await db.collection('nha_tro').doc(snap.get('nhaTroId')).get();
  if (!nha.exists || nha.get('chuTroId') !== uid) throw khongCoQuyen();
  if (snap.get('chuTraLoi')) throw loiNguoiDung('Mỗi đánh giá chỉ trả lời 1 lần.');
  const nd = String(noiDung || '').trim();
  if (nd.length < 2 || nd.length > 1000) throw thamSoSai('Trả lời 2–1000 ký tự.');
  await ref.update({ chuTraLoi: { noiDung: nd, luc: Timestamp.now() } });
  return { ok: true };
}

// ---------------------------------------------------------------- Báo cáo

const LY_DO_BAO_CAO = Object.freeze({
  khong_ton_tai: 'Phòng không tồn tại / ảnh không đúng',
  sai_gia_mo_ta: 'Sai giá, sai mô tả',
  noi_quy_sai: 'Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch',
  da_cho_thue_van_dang: 'Đã cho thuê / đã có người cọc vẫn đăng',
  chuyen_coc_ngoai_app: 'Yêu cầu chuyển cọc ngoài app',
  lua_dao: 'Lừa đảo',
  xuc_pham: 'Xúc phạm / lộ thông tin cá nhân',
  khac: 'Khác',
});
const UU_TIEN_CAO = ['chuyen_coc_ngoai_app', 'lua_dao'];
const LOAI_DOI_TUONG = ['nha_tro', 'phong', 'nguoi_dung', 'danh_gia', 'tin_nhan'];

async function guiBaoCao({ uid, xacThuc }, { doiTuong, lyDo, ghiChu = '', tieuChiSai = [], thoiDiemXayRa = null, bangChung = [], datCocId = null }) {
  const cfg = await layCauHinh();
  if (!doiTuong || !LOAI_DOI_TUONG.includes(doiTuong.loai) || !doiTuong.id) throw thamSoSai();
  if (!LY_DO_BAO_CAO[lyDo]) throw thamSoSai('Chọn lý do báo cáo.');
  if (lyDo === 'noi_quy_sai' && (!tieuChiSai.length || !Number.isFinite(thoiDiemXayRa))) {
    throw thamSoSai('Chọn tiêu chí nội quy bị sai và thời điểm xảy ra.');
  }
  const now = Date.now();
  const khoaKey = xacThuc.sdt || uid;
  const khoa = await db.collection(COL.khoa).doc(khoaKey).get();
  if (khoa.exists && ms(khoa.get('khoaBaoCaoDen')) > now) throw loiNguoiDung('Bạn đang bị khóa chức năng báo cáo.');
  const homNay = await db.collection(COL.baoCao).where('nguoiBao', '==', uid).where('luc', '>=', Timestamp.fromMillis(now - 24 * 60 * PHUT)).get();
  if (homNay.size >= cfg.baoCaoToiDaMoiNgay) throw loiNguoiDung('Bạn đã báo cáo tối đa 10 lần trong ngày.');
  const user = await admin.auth().getUser(uid);
  const tuoi = now - Date.parse(user.metadata.creationTime);
  // Báo cáo chỉ được TÍNH (vào ngưỡng gắn cờ) khi đã OTP và tài khoản ≥ 7 ngày tuổi.
  const duocTinh = !!xacThuc.sdtDaXacThuc && tuoi >= cfg.baoCaoTaiKhoanToiThieuPhut * PHUT;
  const ref = db.collection(COL.baoCao).doc();
  await ref.set({
    nguoiBao: uid, sdtNguoiBao: xacThuc.sdt || null, doiTuong, lyDo, ghiChu: String(ghiChu).slice(0, 1000),
    tieuChiSai, thoiDiemXayRa: thoiDiemXayRa ? Timestamp.fromMillis(thoiDiemXayRa) : null, bangChung, datCocId,
    uuTienCao: UU_TIEN_CAO.includes(lyDo), duocTinh, trangThai: 'cho_xu_ly', luc: Timestamp.fromMillis(now), xuLyBoi: null,
  });
  await danhGiaNguong(doiTuong, cfg);
  if (UU_TIEN_CAO.includes(lyDo)) {
    await thongBao((await cacAdminTro()).map((a) => ({
      khoa: `bao_cao_${ref.id}`, nguoiNhan: a, loai: 'bao_cao_uu_tien', nhom: 'bao_cao',
      tieuDe: 'Báo cáo ưu tiên cao', noiDung: LY_DO_BAO_CAO[lyDo], moTrang: { loai: 'admin_hang_cho' },
    })));
  }
  return { id: ref.id, duocTinh };
}

function refDoiTuong(dt) {
  if (dt.loai === 'nha_tro') return db.collection('nha_tro').doc(dt.id);
  if (dt.loai === 'phong') return db.collection('phong_tro').doc(dt.id);
  if (dt.loai === 'danh_gia') return db.collection(COL.danhGia).doc(dt.id);
  if (dt.loai === 'tin_nhan') return db.collection(COL.chat).doc(dt.chatId).collection('tin_nhan').doc(dt.id);
  return null;
}

/**
 * Không tự ẩn theo số báo cáo: 3 người khác số điện thoại → GẮN CỜ ưu tiên kiểm tra.
 * Ngoại lệ: đánh giá / tin nhắn có 3 báo cáo "xúc phạm / lộ thông tin" → ẩn tạm chờ admin.
 */
async function danhGiaNguong(doiTuong, cfg) {
  const snap = await db.collection(COL.baoCao).where('doiTuong.loai', '==', doiTuong.loai).where('doiTuong.id', '==', doiTuong.id)
    .where('trangThai', '==', 'cho_xu_ly').get();
  const tinh = snap.docs.map((d) => d.data()).filter((b) => b.duocTinh);
  const ref = refDoiTuong(doiTuong);
  if (!ref) return;
  const soSdt = new Set(tinh.map((b) => b.sdtNguoiBao).filter(Boolean)).size;
  if (soSdt >= cfg.baoCaoGanCoSoNguoi) await ref.set({ coGanCo: true }, { merge: true });
  if (['danh_gia', 'tin_nhan'].includes(doiTuong.loai)) {
    const xucPham = new Set(tinh.filter((b) => b.lyDo === 'xuc_pham').map((b) => b.sdtNguoiBao)).size;
    if (xucPham >= cfg.baoCaoAnTamSoLan) await ref.set({ hienThi: 'an_tam' }, { merge: true });
  }
}

/** Admin xử lý báo cáo: hợp lệ (có thể ẩn đối tượng / ghi vi phạm chủ) hoặc sai (tính báo cáo sai). */
async function xuLyBaoCao(adminUid, { id, hopLe, anDoiTuong = false, ghiViPhamChu = false, ghiChu = '' }) {
  const cfg = await layCauHinh();
  const ref = db.collection(COL.baoCao).doc(id);
  const snap = await ref.get();
  if (!snap.exists || snap.get('trangThai') !== 'cho_xu_ly') throw loiNguoiDung('Báo cáo đã được xử lý.');
  const b = snap.data();
  const refDT = refDoiTuong(b.doiTuong);
  await ref.update({ trangThai: hopLe ? 'hop_le' : 'bi_bac', xuLyBoi: adminUid, xuLyLuc: Timestamp.now(), ghiChuAdmin: ghiChu });
  if (refDT) {
    const dt = await refDT.get();
    if (dt.exists) {
      if (hopLe && anDoiTuong) {
        await refDT.update(b.doiTuong.loai === 'danh_gia' || b.doiTuong.loai === 'tin_nhan'
          ? { hienThi: 'an' } : { trangThai: 'hidden', anBoi: 'admin', anLuc: Timestamp.now() });
      } else if (!hopLe && dt.get('hienThi') === 'an_tam') {
        await refDT.update({ hienThi: 'hien' }); // Báo cáo không hợp lệ → khôi phục.
      }
      if (!hopLe) await refDT.set({ coGanCo: false }, { merge: true });
    }
    if (b.doiTuong.loai === 'danh_gia' && dt.exists) await capNhatDiemNhaTro(dt.get('nhaTroId'));
    if (['nha_tro', 'phong'].includes(b.doiTuong.loai) && hopLe && anDoiTuong) {
      const { dongBoPhong, capNhatSoLieuNhaTro } = require('./nha_tro_service');
      if (b.doiTuong.loai === 'nha_tro') await dongBoPhong(b.doiTuong.id);
      else if (dt.exists) await capNhatSoLieuNhaTro(dt.get('nhaTroId'));
    }
  }
  if (hopLe && ghiViPhamChu) await ghiViPhamChuTu(b, cfg);
  if (!hopLe && b.sdtNguoiBao) {
    await db.collection(COL.baoCaoSai).doc(id).set({ uid: b.nguoiBao, sdt: b.sdtNguoiBao, luc: Timestamp.now(), daGo: false });
    const ds = await db.collection(COL.baoCaoSai).where('sdt', '==', b.sdtNguoiBao).get();
    const han = V.hanKhoaMoi(ds.docs.map((d) => ({ luc: ms(d.get('luc')), daGo: d.get('daGo') })), Date.now(),
      { soLan: cfg.baoCaoSaiSoLan, cuaSoPhut: 30 * 24 * 60, khoaPhut: cfg.khoaBaoCaoPhut });
    if (han) await db.collection(COL.khoa).doc(b.sdtNguoiBao).set({ khoaBaoCaoDen: Timestamp.fromMillis(han) }, { merge: true });
  }
  const { ghiNhatKy } = require('./nha_tro_service');
  await ghiNhatKy(adminUid, hopLe ? 'bao_cao_hop_le' : 'bac_bao_cao', { loai: 'bao_cao', id }, ghiChu);
  await thongBao([{
    khoa: `ket_qua_bao_cao_${id}`, nguoiNhan: b.nguoiBao, loai: 'ket_qua_bao_cao', nhom: 'bao_cao',
    tieuDe: 'Kết quả báo cáo', noiDung: hopLe ? 'Báo cáo của bạn đã được xác nhận và xử lý. Cảm ơn bạn!' : 'Báo cáo của bạn không được chấp nhận.',
    moTrang: { loai: 'cua_toi' },
  }]);
  return { ok: true };
}

/** Ghi 1 vi phạm cho chủ trọ từ báo cáo hợp lệ (vd nội quy sai tại thời điểm giao dịch, mục 2.5k). */
async function ghiViPhamChuTu(b, cfg) {
  let chuTroId = null;
  if (b.doiTuong.loai === 'nha_tro') chuTroId = (await db.collection('nha_tro').doc(b.doiTuong.id).get()).get('chuTroId');
  if (b.doiTuong.loai === 'phong') chuTroId = (await db.collection('phong_tro').doc(b.doiTuong.id).get()).get('chuTroId');
  if (b.doiTuong.loai === 'nguoi_dung') chuTroId = b.doiTuong.id;
  if (!chuTroId) return;
  const xt = await db.collection('xac_thuc').doc(chuTroId).get();
  const sdt = xt.exists ? xt.get('sdt') : null;
  const loai = b.lyDo === 'noi_quy_sai' ? 'noi_quy_sai' : 'bao_cao_hop_le';
  await db.collection(COL.viPham).doc(`${b.datCocId || 'bc_' + b.doiTuong.id}_${loai}`).set({
    uid: chuTroId, sdt, vaiTro: 'chu', loai, nguon: { loai: 'bao_cao', id: b.doiTuong.id }, luc: Timestamp.now(), daGo: false,
  });
  if (sdt) await tinhLaiKhoaChu(sdt, cfg);
  await thongBao([{ khoa: `vi_pham_bc_${b.doiTuong.id}_${Date.now()}`, nguoiNhan: chuTroId, loai: 'bi_ghi_vi_pham', moTrang: { loai: 'cua_toi' } }]);
}

async function tinhLaiKhoaChu(sdt, cfg) {
  const ds = await db.collection(COL.viPham).where('sdt', '==', sdt).where('vaiTro', '==', 'chu').get();
  const lan = ds.docs.map((d) => ({ luc: ms(d.get('luc')), daGo: d.get('daGo') }));
  const now = Date.now();
  const dem = V.demTrongCuaSo(lan, now, cfg.viPhamChuCuaSoPhut);
  const ref = db.collection(COL.khoa).doc(sdt);
  if (dem >= cfg.viPhamChuSoLan) {
    const cu = await ref.get();
    if (!(cu.exists && ms(cu.get('khoaDangTinDen')) > now)) {
      await ref.set({ khoaDangTinDen: Timestamp.fromMillis(now + cfg.khoaDangTinPhut * PHUT) }, { merge: true });
    }
  } else {
    await ref.set({ khoaDangTinDen: null }, { merge: true });
  }
}

// ---------------------------------------------------------------- Kháng nghị

const LOAI_QUYET_DINH = ['vi_pham', 'khoa_coc', 'khieu_nai_sai', 'khoa_bao_cao', 'khoa_dang_tin', 'an_tin'];

async function guiKhangNghi({ uid }, { quyetDinh, lyDo, bangChung = [] }) {
  const cfg = await layCauHinh();
  if (!quyetDinh || !LOAI_QUYET_DINH.includes(quyetDinh.loai) || !quyetDinh.id) {
    throw thamSoSai('Quyết định này không kháng nghị được (quyết định về tiền là kết quả cuối cùng).');
  }
  if (String(lyDo || '').trim().length < 10) throw thamSoSai('Ghi lý do (ít nhất 10 ký tự).');
  if (!Array.isArray(bangChung) || bangChung.length > cfg.khangNghiBangChungToiDa) throw thamSoSai('Tối đa 3 bằng chứng.');
  const lucQuyetDinh = await kiemTraQuyetDinh(uid, quyetDinh);
  if (Date.now() - lucQuyetDinh > cfg.khangNghiTrongPhut * PHUT) throw loiNguoiDung('Đã quá 7 ngày kể từ quyết định.');
  const ref = db.collection(COL.khangNghi).doc(`${quyetDinh.loai}_${quyetDinh.id}`);
  await db.runTransaction(async (tx) => {
    const cu = await tx.get(ref);
    if (cu.exists) throw loiNguoiDung('Mỗi quyết định chỉ kháng nghị 1 lần.');
    tx.set(ref, {
      nguoiGui: uid, quyetDinh, lyDo: String(lyDo).trim(), bangChung, trangThai: 'cho_xu_ly', ketQua: null,
      guiLuc: Timestamp.now(), hanTraLoi: Timestamp.fromMillis(Date.now() + cfg.khangNghiTraLoiPhut * PHUT), xuLyBoi: null,
    });
  });
  await thongBao((await cacAdminTro()).map((a) => ({
    khoa: `khang_nghi_${ref.id}`, nguoiNhan: a, loai: 'khang_nghi_moi', nhom: 'khang_nghi',
    tieuDe: 'Kháng nghị mới', noiDung: 'Có kháng nghị mới cần xử lý trong 48 giờ.', moTrang: { loai: 'admin_hang_cho' },
  })));
  return { id: ref.id };
}

/** Trả về thời điểm ra quyết định (để tính hạn 7 ngày) sau khi kiểm tra người gửi đúng là người bị phạt. */
async function kiemTraQuyetDinh(uid, qd) {
  if (qd.loai === 'vi_pham' || qd.loai === 'khieu_nai_sai') {
    const col = qd.loai === 'vi_pham' ? COL.viPham : 'tro_khieu_nai_sai';
    const s = await db.collection(col).doc(qd.id).get();
    if (!s.exists || s.get('uid') !== uid) throw khongCoQuyen();
    return ms(s.get('luc'));
  }
  if (qd.loai === 'an_tin') {
    const s = await db.collection(qd.col === 'phong_tro' ? 'phong_tro' : 'nha_tro').doc(qd.id).get();
    if (!s.exists || s.get('chuTroId') !== uid || s.get('anBoi') !== 'admin') throw khongCoQuyen();
    return ms(s.get('anLuc')) || Date.now();
  }
  // Khóa chức năng: id = số điện thoại / uid bị khóa.
  const xt = await db.collection('xac_thuc').doc(uid).get();
  if (qd.id !== (xt.exists ? xt.get('sdt') : null) && qd.id !== uid) throw khongCoQuyen();
  const k = await db.collection(COL.khoa).doc(qd.id).get();
  if (!k.exists) throw khongTimThay('Quyết định');
  const truong = { khoa_coc: 'khoaCocDen', khoa_bao_cao: 'khoaBaoCaoDen', khoa_dang_tin: 'khoaDangTinDen' }[qd.loai];
  const den = ms(k.get(truong));
  if (!den || den < Date.now()) throw loiNguoiDung('Không còn khóa để kháng nghị.');
  const thoiHan = { khoa_coc: 'khoaCocPhut', khoa_bao_cao: 'khoaBaoCaoPhut', khoa_dang_tin: 'khoaDangTinPhut' }[qd.loai];
  const cfg = await layCauHinh();
  return den - cfg[thoiHan] * PHUT;
}

/** Admin xử lý kháng nghị: 'go_khoa' | 'giu_nguyen' | 'xoa_vi_pham'. Đang kháng nghị thì hình phạt vẫn hiệu lực. */
async function xuLyKhangNghi(adminUid, { id, ketQua, ghiChu = '' }) {
  if (!['go_khoa', 'giu_nguyen', 'xoa_vi_pham'].includes(ketQua)) throw thamSoSai();
  const cfg = await layCauHinh();
  const ref = db.collection(COL.khangNghi).doc(id);
  const snap = await ref.get();
  if (!snap.exists || snap.get('trangThai') !== 'cho_xu_ly') throw loiNguoiDung('Kháng nghị đã được xử lý.');
  const k = snap.data();
  const qd = k.quyetDinh;
  if (ketQua === 'xoa_vi_pham' && ['vi_pham', 'khieu_nai_sai'].includes(qd.loai)) {
    const col = qd.loai === 'vi_pham' ? COL.viPham : 'tro_khieu_nai_sai';
    const vp = db.collection(col).doc(qd.id);
    await vp.update({ daGo: true, goLuc: Timestamp.now() });
    const sdt = (await vp.get()).get('sdt');
    if (sdt && qd.loai === 'vi_pham') await tinhLaiKhoaChu(sdt, cfg);
    if (sdt && qd.loai === 'khieu_nai_sai') {
      const ds = await db.collection('tro_khieu_nai_sai').where('sdt', '==', sdt).get();
      const dem = V.demTrongCuaSo(ds.docs.map((d) => ({ luc: ms(d.get('luc')), daGo: d.get('daGo') })), Date.now(), cfg.khieuNaiSaiCuaSoPhut);
      if (dem < cfg.khieuNaiSaiSoLan) await db.collection(COL.khoa).doc(sdt).set({ khoaCocDen: null }, { merge: true });
    }
  }
  if (ketQua === 'go_khoa') {
    if (['khoa_coc', 'khoa_bao_cao', 'khoa_dang_tin'].includes(qd.loai)) {
      const truong = { khoa_coc: 'khoaCocDen', khoa_bao_cao: 'khoaBaoCaoDen', khoa_dang_tin: 'khoaDangTinDen' }[qd.loai];
      await db.collection(COL.khoa).doc(qd.id).set({ [truong]: null }, { merge: true });
    }
    if (qd.loai === 'an_tin') {
      const col = qd.col === 'phong_tro' ? 'phong_tro' : 'nha_tro';
      await db.collection(col).doc(qd.id).update({ trangThai: col === 'phong_tro' ? 'available' : 'active', anBoi: null });
      const { dongBoPhong, capNhatSoLieuNhaTro } = require('./nha_tro_service');
      if (col === 'nha_tro') await dongBoPhong(qd.id);
      else await capNhatSoLieuNhaTro((await db.collection('phong_tro').doc(qd.id).get()).get('nhaTroId'));
    }
  }
  await ref.update({ trangThai: 'da_xu_ly', ketQua, ghiChuAdmin: ghiChu, xuLyBoi: adminUid, xuLyLuc: Timestamp.now() });
  const { ghiNhatKy } = require('./nha_tro_service');
  await ghiNhatKy(adminUid, `khang_nghi_${ketQua}`, { loai: 'khang_nghi', id }, ghiChu);
  await thongBao([{
    khoa: `ket_qua_khang_nghi_${id}`, nguoiNhan: k.nguoiGui, loai: 'ket_qua_khang_nghi', nhom: 'khang_nghi',
    tieuDe: 'Kết quả kháng nghị',
    noiDung: ketQua === 'giu_nguyen' ? 'Kháng nghị không được chấp nhận, quyết định giữ nguyên.' : 'Kháng nghị được chấp nhận.',
    moTrang: { loai: 'cua_toi' },
  }]);
  return { ok: true };
}

module.exports = {
  COL, TIEU_CHI, THE_NHANH, LY_DO_BAO_CAO, maCuocTroChuyen, guiTin, daXem, chan, tinhTyLePhanHoi,
  guiDanhGia, capNhatDiemNhaTro, chuTraLoiDanhGia, guiBaoCao, xuLyBaoCao, guiKhangNghi, xuLyKhangNghi, tinhLaiKhoaChu,
};
