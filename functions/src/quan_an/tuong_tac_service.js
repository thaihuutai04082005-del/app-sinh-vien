'use strict';

/**
 * Tương tác riêng của module Quán ăn: chat (3.8), đánh giá 4 tiêu chí (3.9), báo cáo (3.10), kháng nghị (3.15).
 * Không dùng chung với module khác.
 */

const { admin, db, FieldValue, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen, thamSoSai } = require('../chung/loi');
const { layCauHinh } = require('./cau_hinh');
const { PHUT } = require('./config');
const { quet, CANH_BAO, boDau } = require('./logic/canh_bao_chat');
const V = require('./logic/vi_pham');
const DG = require('./logic/danh_gia');
const H = require('./logic/gio_mo_cua');
const K = require('./logic/kiem_tra');
const { COL, thongBao, cacAdminQuanAn, ghiNhatKy } = require('./ho_tro');

// ---------------------------------------------------------------- Chat

const maCuocChat = (a, b) => [a, b].sort().join('_');

async function dungTheTin(uid, nguoiNhan, the) {
  if (!the || !['quan', 'don'].includes(the.loai) || !the.id) throw thamSoSai('Thẻ tin không hợp lệ.');
  if (the.loai === 'quan') {
    const q = await db.collection(COL.quan).doc(the.id).get();
    if (!q.exists) throw khongTimThay('Quán');
    const laChu = q.get('chuQuanId') === uid;
    // Chủ quán không mở chat với quán của chính mình (mục 3.18 quy tắc 5).
    if (laChu && q.get('chuQuanId') === nguoiNhan) throw khongCoQuyen();
    if (!laChu && q.get('chuQuanId') !== nguoiNhan) throw thamSoSai();
    return { loai: 'quan', id: q.id, tieuDe: q.get('ten'), anh: q.get('anhBia') || '', gia: (q.get('soLieu') || {}).giaTrungVi || null };
  }
  const d = await db.collection(COL.don).doc(the.id).get();
  if (!d.exists) throw khongTimThay('Đơn');
  const hai = [d.get('svId'), d.get('chuQuanId')];
  if (!hai.includes(uid) || !hai.includes(nguoiNhan) || uid === nguoiNhan) throw khongCoQuyen();
  return { loai: 'don', id: d.id, tieuDe: `Đơn tại ${d.get('tenQuan')}`, anh: d.get('anhBia') || '', gia: d.get('tong') };
}

async function guiTin({ uid }, { nguoiNhan, noiDung, loai = 'chu', the = null, anh = null }) {
  if (!nguoiNhan || nguoiNhan === uid) throw thamSoSai('Người nhận không hợp lệ.');
  const chu = String(noiDung || '').trim();
  if (loai === 'chu' && (!chu || chu.length > 2000)) throw thamSoSai('Tin nhắn 1–2000 ký tự.');
  if (loai === 'anh' && !K.laHttps(anh)) throw thamSoSai('Ảnh không hợp lệ.');
  const theTin = loai === 'the_tin' ? await dungTheTin(uid, nguoiNhan, the) : null;
  const chatId = maCuocChat(uid, nguoiNhan);
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
      tx.set(refChat, { thanhVien: [uid, nguoiNhan].sort(), ten, nguoiMo: uid, taoLuc: now, daTraLoiLuc: null, chanBoi: [], chuaDoc: { [uid]: 0, [nguoiNhan]: 0 } });
    }
    tx.set(refTin, {
      nguoiGui: uid, loai, noiDung: loai === 'anh' ? anh : chu, noiDungBoDau: boDau(chu), tuKhoaCanhBao: tuKhoa,
      the: theTin, guiLuc: now, daXemLuc: null, hienThi: 'hien',
    });
    const cap = {
      tinCuoi: loai === 'chu' ? chu.slice(0, 120) : loai === 'anh' ? '[Ảnh]' : `[${theTin.loai === 'quan' ? 'Quán' : 'Đơn'}] ${theTin.tieuDe}`,
      tinCuoiLuc: now, [`chuaDoc.${nguoiNhan}`]: FieldValue.increment(1),
    };
    if (c && !c.daTraLoiLuc && c.nguoiMo !== uid) cap.daTraLoiLuc = now; // tỷ lệ phản hồi: người kia trả lời lần đầu
    tx.update(refChat, cap);
  });
  await thongBao([{
    khoa: `tin_${refTin.id}`, nguoiNhan, loai: 'tin_nhan', nhom: 'tin_nhan', tieuDe: 'Tin nhắn mới',
    noiDung: loai === 'chu' ? chu.slice(0, 100) : 'Bạn có tin nhắn mới.', moTrang: { loai: 'chat', id: chatId },
  }]);
  return { chatId, tinId: refTin.id, canhBao: tuKhoa.length ? CANH_BAO : null };
}

async function daXem({ uid }, { chatId }) {
  const ref = db.collection(COL.chat).doc(String(chatId || ''));
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
  const ref = db.collection(COL.chat).doc(String(chatId || ''));
  const snap = await ref.get();
  if (!snap.exists || !(snap.get('thanhVien') || []).includes(uid)) throw khongCoQuyen();
  await ref.update({ chanBoi: coChan ? FieldValue.arrayUnion(uid) : FieldValue.arrayRemove(uid) });
  return { ok: true };
}

/** Tỷ lệ phản hồi của chủ quán: % cuộc trò chuyện mới (30 ngày) được trả lời trong 24 giờ. */
async function tinhTyLePhanHoi(chuQuanId) {
  const cfg = await layCauHinh();
  const tu = Date.now() - cfg.phanHoiCuaSoPhut * PHUT;
  const snap = await db.collection(COL.chat).where('thanhVien', 'array-contains', chuQuanId).get();
  const moi = snap.docs.map((d) => d.data()).filter((c) => c.nguoiMo !== chuQuanId && ms(c.taoLuc) >= tu);
  if (!moi.length) return null;
  const traLoi = moi.filter((c) => c.daTraLoiLuc && ms(c.daTraLoiLuc) - ms(c.taoLuc) <= cfg.phanHoiTrongPhut * PHUT);
  return Math.round((traLoi.length / moi.length) * 100);
}

// ---------------------------------------------------------------- Đánh giá

/** Nhãn mạnh nhất người dùng có tại quán: đơn đã xác minh 🛵 > đặt bàn có check-in 🍽 > check-in 📍. */
async function tinhNhan(uid, quanId) {
  const [don, ban, ci] = await Promise.all([
    db.collection(COL.don).where('svId', '==', uid).where('quanId', '==', quanId).where('status', '==', 'completed').get(),
    db.collection(COL.datBan).where('svId', '==', uid).where('quanId', '==', quanId).where('status', '==', 'arrived').get(),
    db.collection(COL.checkIn).where('svId', '==', uid).where('quanId', '==', quanId).limit(1).get(),
  ]);
  return DG.nhanManhNhat({
    dat_mon: don.docs.some((d) => d.get('daXacMinh')),
    dat_ban: ban.docs.some((d) => d.get('ghiNhanDen') === 'check_in'),
    check_in: !ci.empty,
  });
}

async function guiDanhGia({ uid, xacThuc }, { quanId, diem, the = [], nhanXet, anh = [] }) {
  const cfg = await layCauHinh();
  const qSnap = await db.collection(COL.quan).doc(String(quanId || '')).get();
  if (!qSnap.exists) throw khongTimThay('Quán');
  const q = qSnap.data();
  if (q.chuQuanId === uid) throw loiNguoiDung('Chủ quán không đánh giá quán của chính mình.', 'permission-denied');
  // Đồ án: chấp nhận đã xác nhận email HOẶC đã OTP (app chưa có luồng xác nhận email riêng).
  const user = await admin.auth().getUser(uid);
  if (!user.emailVerified && !xacThuc.sdtDaXacThuc) throw loiNguoiDung('Bạn cần xác nhận email hoặc xác thực số điện thoại để đánh giá.');
  const diemTong = DG.diemTong(diem);
  if (diemTong == null) throw thamSoSai('Chấm đủ 4 tiêu chí (món ăn, giá cả, vệ sinh, phục vụ), mỗi tiêu chí 1–5 sao.');
  if (String(nhanXet || '').trim().length < cfg.danhGiaNhanXetToiThieu) throw thamSoSai(`Nhận xét ít nhất ${cfg.danhGiaNhanXetToiThieu} ký tự.`);
  if (!Array.isArray(anh) || anh.length > cfg.danhGiaAnhToiDa || !anh.every(K.laHttps)) throw thamSoSai(`Tối đa ${cfg.danhGiaAnhToiDa} ảnh.`);
  const ref = db.collection(COL.danhGia).doc(`${uid}_${quanId}`); // mỗi người 1 đánh giá / quán, sửa được
  const cu = await ref.get();
  if (!cu.exists) {
    const dauNgay = Timestamp.fromMillis(H.dauNgayVn(Date.now()));
    const homNay = await db.collection(COL.danhGia).where('svId', '==', uid).where('taoLuc', '>=', dauNgay).get();
    if (homNay.size >= cfg.danhGiaToiDaMoiNgay) throw loiNguoiDung(`Bạn đã viết tối đa ${cfg.danhGiaToiDaMoiNgay} đánh giá trong ngày.`);
  }
  const nhan = await tinhNhan(uid, quanId);
  // Nhãn xác minh chỉ được tính vào điểm khi người viết đã xác thực số điện thoại.
  const tinhDiem = !!nhan && !!xacThuc.sdtDaXacThuc;
  const tenSv = ((await db.collection('users').doc(uid).get()).get('name')) || 'Sinh viên';
  const duLieu = {
    quanId, svId: uid, tenSv, diem: Object.fromEntries(DG.TIEU_CHI.map((k) => [k, diem[k]])), diemTong,
    the: (the || []).filter((t) => DG.THE_NHANH.includes(t)), nhanXet: String(nhanXet).trim(), anh, nhan, tinhDiem,
    capNhatLuc: Timestamp.now(), trangThaiHienThi: cu.exists ? cu.get('trangThaiHienThi') || 'hien' : 'hien',
  };
  if (cu.exists) await ref.update({ ...duLieu, daCapNhat: true });
  else await ref.set({ ...duLieu, taoLuc: Timestamp.now(), daCapNhat: false, chuTraLoi: null });
  await capNhatDiemQuan(quanId);
  if (!cu.exists) {
    await thongBao([{ khoa: `danh_gia_moi_${ref.id}`, nguoiNhan: q.chuQuanId, loai: 'danh_gia_moi', bien: { quan: q.ten }, moTrang: { loai: 'quan', id: quanId } }]);
  }
  return { id: ref.id, nhan, tinhDiem, diemTong };
}

/** Điểm quán = trung bình điểm tổng thể các đánh giá có nhãn của người đã OTP; đồng thời điểm từng tiêu chí. */
async function capNhatDiemQuan(quanId) {
  const snap = await db.collection(COL.danhGia).where('quanId', '==', quanId).get();
  const r = DG.tinhDiemQuan(snap.docs.map((d) => d.data()));
  await db.collection(COL.quan).doc(quanId).update({
    'soLieu.diemTong': r.diemTong, 'soLieu.soDanhGia': r.soDanhGia, 'soLieu.diemTieuChi': r.diemTieuChi,
    'soLieu.diemChuaXm': r.diemChuaXm, 'soLieu.soDanhGiaChuaXm': r.soDanhGiaChuaXm,
  });
}

async function chuTraLoiDanhGia({ uid }, { danhGiaId, noiDung }) {
  const ref = db.collection(COL.danhGia).doc(String(danhGiaId || ''));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Đánh giá');
  const q = await db.collection(COL.quan).doc(snap.get('quanId')).get();
  if (!q.exists || q.get('chuQuanId') !== uid) throw khongCoQuyen();
  if (snap.get('chuTraLoi')) throw loiNguoiDung('Mỗi đánh giá chỉ trả lời 1 lần.');
  const nd = String(noiDung || '').trim();
  if (nd.length < 2 || nd.length > 1000) throw thamSoSai('Trả lời 2–1000 ký tự.');
  await ref.update({ chuTraLoi: { noiDung: nd, luc: Timestamp.now() } });
  return { ok: true };
}

// ---------------------------------------------------------------- Báo cáo

const LY_DO_BAO_CAO = Object.freeze({
  quan_khong_ton_tai: 'Quán không tồn tại / đã đóng', sai_gio: 'Sai giờ mở cửa', sai_gia: 'Sai giá', khuyen_mai_sai: 'Khuyến mãi không đúng thực tế',
  khai_sai_loai: 'Khai sai loại hình', mat_ve_sinh: 'Mất vệ sinh an toàn thực phẩm', chuyen_khoan_ngoai_app: 'Yêu cầu chuyển khoản ngoài app',
  lua_dao: 'Lừa đảo', xuc_pham: 'Xúc phạm / lộ thông tin cá nhân', spam: 'Spam / quảng cáo', khac: 'Khác',
});
const UU_TIEN_CAO = ['mat_ve_sinh', 'chuyen_khoan_ngoai_app', 'lua_dao'];
const LOAI_DOI_TUONG = ['quan', 'mon', 'nguoi_dung', 'danh_gia', 'tin_nhan'];

async function guiBaoCao({ uid, xacThuc }, { doiTuong, lyDo, ghiChu = '', bangChung = [] }) {
  const cfg = await layCauHinh();
  if (!doiTuong || !LOAI_DOI_TUONG.includes(doiTuong.loai) || !doiTuong.id) throw thamSoSai();
  if (!LY_DO_BAO_CAO[lyDo]) throw thamSoSai('Chọn lý do báo cáo.');
  const now = Date.now();
  const khoaKey = xacThuc.sdt || uid;
  const khoa = await db.collection(COL.khoa).doc(khoaKey).get();
  if (khoa.exists && ms(khoa.get('khoaBaoCaoDen')) > now) throw loiNguoiDung('Bạn đang bị khóa chức năng báo cáo.');
  const homNay = await db.collection(COL.baoCao).where('nguoiBao', '==', uid).where('luc', '>=', Timestamp.fromMillis(now - 24 * 60 * PHUT)).get();
  if (homNay.size >= cfg.baoCaoToiDaMoiNgay) throw loiNguoiDung(`Bạn đã báo cáo tối đa ${cfg.baoCaoToiDaMoiNgay} lần trong ngày.`);
  const user = await admin.auth().getUser(uid);
  const tuoi = now - Date.parse(user.metadata.creationTime);
  // Báo cáo chỉ được TÍNH (vào ngưỡng gắn cờ) khi đã OTP và tài khoản ≥ 7 ngày tuổi.
  const duocTinh = !!xacThuc.sdtDaXacThuc && tuoi >= cfg.baoCaoTaiKhoanToiThieuPhut * PHUT;
  const ref = db.collection(COL.baoCao).doc();
  await ref.set({
    nguoiBao: uid, sdtNguoiBao: xacThuc.sdt || null, doiTuong, lyDo, ghiChu: String(ghiChu).slice(0, 1000), bangChung,
    uuTienCao: UU_TIEN_CAO.includes(lyDo), duocTinh, trangThai: 'cho_xu_ly', luc: Timestamp.fromMillis(now), xuLyBoi: null,
  });
  await danhGiaNguong(doiTuong, cfg);
  if (UU_TIEN_CAO.includes(lyDo)) {
    await thongBao((await cacAdminQuanAn()).map((a) => ({
      khoa: `bao_cao_${ref.id}`, nguoiNhan: a, loai: 'bao_cao_uu_tien', nhom: 'bao_cao', tieuDe: 'Báo cáo ưu tiên cao',
      noiDung: LY_DO_BAO_CAO[lyDo], moTrang: { loai: 'admin_hang_cho' },
    })));
  }
  return { id: ref.id, duocTinh };
}

function refDoiTuong(dt) {
  if (dt.loai === 'quan') return db.collection(COL.quan).doc(dt.id);
  if (dt.loai === 'mon') return db.collection(COL.mon).doc(dt.id);
  if (dt.loai === 'danh_gia') return db.collection(COL.danhGia).doc(dt.id);
  if (dt.loai === 'tin_nhan' && dt.chatId) return db.collection(COL.chat).doc(dt.chatId).collection('tin_nhan').doc(dt.id);
  return null;
}

/**
 * Không tự ẩn theo số báo cáo: 3 người khác số điện thoại → GẮN CỜ ưu tiên kiểm tra (quán / món).
 * Ngoại lệ: đánh giá / tin nhắn có 3 báo cáo "xúc phạm / lộ thông tin" → ẩn tạm chờ admin (không phải xác nhận vi phạm).
 */
async function danhGiaNguong(doiTuong, cfg) {
  const snap = await db.collection(COL.baoCao).where('doiTuong.loai', '==', doiTuong.loai).where('doiTuong.id', '==', doiTuong.id).where('trangThai', '==', 'cho_xu_ly').get();
  const tinh = snap.docs.map((d) => d.data()).filter((b) => b.duocTinh);
  const ref = refDoiTuong(doiTuong);
  if (!ref) return;
  const soSdt = new Set(tinh.map((b) => b.sdtNguoiBao).filter(Boolean)).size;
  if (soSdt >= cfg.baoCaoGanCoSoNguoi && ['quan', 'mon'].includes(doiTuong.loai)) {
    await ref.set({ coGanCo: true }, { merge: true });
    await thongBao((await cacAdminQuanAn()).map((a) => ({ khoa: `gan_co_${doiTuong.id}`, nguoiNhan: a, loai: 'quan_nghi_khai_sai', tieuDe: 'Quán / món bị gắn cờ', noiDung: 'Có quán / món bị nhiều người báo cáo, cần kiểm tra.', nhom: 'bao_cao', moTrang: { loai: 'admin_hang_cho' } })));
  }
  if (['danh_gia', 'tin_nhan'].includes(doiTuong.loai)) {
    const xucPham = new Set(tinh.filter((b) => b.lyDo === 'xuc_pham').map((b) => b.sdtNguoiBao)).size;
    if (xucPham >= cfg.baoCaoAnTamSoLan) await ref.set(doiTuong.loai === 'danh_gia' ? { trangThaiHienThi: 'an_tam' } : { hienThi: 'an_tam' }, { merge: true });
  }
}

/** Admin xử lý báo cáo: hợp lệ (có thể ẩn đối tượng) hoặc sai (tính báo cáo sai, khôi phục nếu đang ẩn tạm). */
async function xuLyBaoCao(adminUid, { id, hopLe, anDoiTuong = false, ghiChu = '' }) {
  const cfg = await layCauHinh();
  const ref = db.collection(COL.baoCao).doc(String(id || ''));
  const snap = await ref.get();
  if (!snap.exists || snap.get('trangThai') !== 'cho_xu_ly') throw loiNguoiDung('Báo cáo đã được xử lý.');
  const b = snap.data();
  const refDT = refDoiTuong(b.doiTuong);
  await ref.update({ trangThai: hopLe ? 'hop_le' : 'bi_bac', xuLyBoi: adminUid, xuLyLuc: Timestamp.now(), ghiChuAdmin: ghiChu });
  const truongHienThi = b.doiTuong.loai === 'danh_gia' ? 'trangThaiHienThi' : 'hienThi';
  if (refDT) {
    const dt = await refDT.get();
    if (dt.exists) {
      if (hopLe && anDoiTuong) {
        if (['danh_gia', 'tin_nhan'].includes(b.doiTuong.loai)) await refDT.update({ [truongHienThi]: 'an' });
        else if (b.doiTuong.loai === 'mon') await refDT.update({ conHang: false, noiBat: false });
        else if (b.doiTuong.loai === 'quan') {
          const { adminAnHien } = require('./quan_service');
          await adminAnHien(adminUid, { quanId: b.doiTuong.id, an: true, lyDo: `Báo cáo hợp lệ: ${LY_DO_BAO_CAO[b.lyDo]}` });
        }
      } else if (!hopLe && dt.get(truongHienThi) === 'an_tam') {
        await refDT.update({ [truongHienThi]: 'hien' }); // báo cáo không hợp lệ → khôi phục
      }
      if (!hopLe) await refDT.set({ coGanCo: false }, { merge: true });
      if (b.doiTuong.loai === 'danh_gia' && dt.exists) await capNhatDiemQuan(dt.get('quanId'));
    }
  }
  if (!hopLe && b.sdtNguoiBao) {
    await db.collection(COL.baoCaoSai).doc(id).set({ uid: b.nguoiBao, sdt: b.sdtNguoiBao, luc: Timestamp.now(), daGo: false });
    await db.collection(COL.viPham).doc(`${id}_bao_cao_sai`).set({ uid: b.nguoiBao, sdt: b.sdtNguoiBao, vaiTro: 'sv', loai: 'bao_cao_sai', nguon: { loai: 'bao_cao', id }, luc: Timestamp.now(), daGo: false });
    await tinhLaiKhoa(b.sdtNguoiBao, cfg);
  }
  await ghiNhatKy(adminUid, hopLe ? 'bao_cao_hop_le' : 'bac_bao_cao', { loai: 'bao_cao', id }, ghiChu);
  await thongBao([{
    khoa: `ket_qua_bao_cao_${id}`, nguoiNhan: b.nguoiBao, loai: 'ket_qua_bao_cao', nhom: 'bao_cao', tieuDe: 'Kết quả báo cáo',
    noiDung: hopLe ? 'Báo cáo của bạn đã được xác nhận và xử lý. Cảm ơn bạn!' : 'Báo cáo của bạn không được chấp nhận.', moTrang: { loai: 'cua_toi' },
  }]);
  return { ok: true };
}

/**
 * Tính lại các khóa của một số điện thoại từ các lần vi phạm còn hiệu lực (cửa sổ trượt):
 * bom hàng ≥ 3 → khóa đặt món; bỏ hẹn ≥ 3 → khóa đặt bàn; báo cáo sai ≥ 3 → khóa báo cáo; khiếu nại sai ≥ 3 → khóa đặt món app.
 * Gỡ khóa khi số lần còn hiệu lực xuống dưới ngưỡng (sau kháng nghị); không tự gia hạn khóa đang có.
 */
async function tinhLaiKhoa(sdt, cfg) {
  const now = Date.now();
  const [vp, kn] = await Promise.all([
    db.collection(COL.viPham).where('sdt', '==', sdt).get(),
    db.collection(COL.khieuNaiSai).where('sdt', '==', sdt).get(),
  ]);
  const lan = (loai) => vp.docs.filter((d) => d.get('loai') === loai).map((d) => ({ luc: ms(d.get('luc')), daGo: d.get('daGo') }));
  const cauHinh = [
    ['khoaDatMonDen', lan('bom_hang'), cfg.bomHangCuaSoPhut, cfg.bomHangKhoaSoLan, cfg.khoaDatMonPhut],
    ['khoaDatBanDen', lan('bo_hen_dat_ban'), cfg.khoaDatBanCuaSoPhut, cfg.khoaDatBanSoLan, cfg.khoaDatBanPhut],
    ['khoaBaoCaoDen', lan('bao_cao_sai'), 30 * 24 * 60, cfg.baoCaoSaiSoLan, cfg.khoaBaoCaoPhut],
    ['khoaDatMonAppDen', kn.docs.map((d) => ({ luc: ms(d.get('luc')), daGo: d.get('daGo') })), cfg.khieuNaiSaiCuaSoPhut, cfg.khieuNaiSaiSoLan, cfg.khoaDatMonAppPhut],
  ];
  const ref = db.collection(COL.khoa).doc(sdt);
  const cu = await ref.get();
  const capNhat = {};
  for (const [truong, ds, cuaSo, soLan, khoaPhut] of cauHinh) {
    const dem = V.demTrongCuaSo(ds, now, cuaSo);
    if (dem < soLan) { if (cu.exists && cu.get(truong)) capNhat[truong] = null; } else if (!(cu.exists && ms(cu.get(truong)) > now)) capNhat[truong] = Timestamp.fromMillis(now + khoaPhut * PHUT);
  }
  if (Object.keys(capNhat).length) await ref.set(capNhat, { merge: true });
}

// ---------------------------------------------------------------- Kháng nghị

const LOAI_QUYET_DINH = ['vi_pham', 'khieu_nai_sai', 'khoa_dat_mon', 'khoa_dat_ban', 'khoa_tien_mat', 'khoa_bao_cao', 'khoa_dat_mon_app', 'an_quan', 'khoa_ban'];
const TRUONG_KHOA = { khoa_dat_mon: 'khoaDatMonDen', khoa_dat_ban: 'khoaDatBanDen', khoa_tien_mat: 'khoaTienMatDen', khoa_bao_cao: 'khoaBaoCaoDen', khoa_dat_mon_app: 'khoaDatMonAppDen' };
const THOI_HAN_KHOA = { khoa_dat_mon: 'khoaDatMonPhut', khoa_dat_ban: 'khoaDatBanPhut', khoa_tien_mat: 'khoaDatMonPhut', khoa_bao_cao: 'khoaBaoCaoPhut', khoa_dat_mon_app: 'khoaDatMonAppPhut' };

async function guiKhangNghi({ uid }, { quyetDinh, lyDo, bangChung = [] }) {
  const cfg = await layCauHinh();
  if (!quyetDinh || !LOAI_QUYET_DINH.includes(quyetDinh.loai) || !quyetDinh.id) throw thamSoSai('Quyết định này không kháng nghị được (quyết định về tiền là kết quả cuối cùng).');
  if (String(lyDo || '').trim().length < 3) throw thamSoSai('Ghi lý do kháng nghị.');
  if (!Array.isArray(bangChung) || bangChung.length > cfg.khangNghiBangChungToiDa || !bangChung.every(K.laHttps)) throw thamSoSai(`Tối đa ${cfg.khangNghiBangChungToiDa} bằng chứng.`);
  const lucQuyetDinh = await kiemTraQuyetDinh(uid, quyetDinh, cfg);
  if (Date.now() - lucQuyetDinh > cfg.khangNghiTrongPhut * PHUT) throw loiNguoiDung('Đã quá 7 ngày kể từ quyết định.');
  const ref = db.collection(COL.khangNghi).doc(`${quyetDinh.loai}_${quyetDinh.id}`);
  await db.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) throw loiNguoiDung('Mỗi quyết định chỉ kháng nghị 1 lần.');
    tx.set(ref, {
      nguoiGui: uid, quyetDinh, lyDo: String(lyDo).trim(), bangChung, trangThai: 'cho_xu_ly', ketQua: null, guiLuc: Timestamp.now(),
      hanTraLoi: Timestamp.fromMillis(Date.now() + cfg.khangNghiTraLoiPhut * PHUT), xuLyBoi: null,
    });
  });
  await thongBao((await cacAdminQuanAn()).map((a) => ({
    khoa: `khang_nghi_${ref.id}`, nguoiNhan: a, loai: 'khang_nghi_moi', nhom: 'khang_nghi', tieuDe: 'Kháng nghị mới',
    noiDung: 'Có kháng nghị mới cần xử lý trong 48 giờ.', moTrang: { loai: 'admin_hang_cho' },
  })));
  return { id: ref.id };
}

/** Trả về thời điểm ra quyết định (để tính hạn 7 ngày) sau khi kiểm tra người gửi đúng là người bị phạt. */
async function kiemTraQuyetDinh(uid, qd, cfg) {
  if (qd.loai === 'vi_pham' || qd.loai === 'khieu_nai_sai') {
    const s = await db.collection(qd.loai === 'vi_pham' ? COL.viPham : COL.khieuNaiSai).doc(qd.id).get();
    if (!s.exists || s.get('uid') !== uid) throw khongCoQuyen();
    if (s.get('daGo')) throw loiNguoiDung('Lần vi phạm này đã được gỡ.');
    return ms(s.get('luc'));
  }
  if (qd.loai === 'an_quan') {
    const s = await db.collection(COL.quan).doc(qd.id).get();
    if (!s.exists || s.get('chuQuanId') !== uid || s.get('anBoi') !== 'admin') throw khongCoQuyen();
    return ms(s.get('anLuc')) || Date.now();
  }
  if (qd.loai === 'khoa_ban') {
    if (qd.id !== uid) throw khongCoQuyen();
    const s = await db.collection(COL.chiSoChu).doc(uid).get();
    if (!s.exists || !s.get('khoaBan')) throw loiNguoiDung('Không còn khóa bán để kháng nghị.');
    return Date.now();
  }
  const xt = await db.collection('xac_thuc').doc(uid).get();
  if (qd.id !== (xt.exists ? xt.get('sdt') : null) && qd.id !== uid) throw khongCoQuyen();
  const k = await db.collection(COL.khoa).doc(qd.id).get();
  const den = k.exists ? ms(k.get(TRUONG_KHOA[qd.loai])) : null;
  if (!den || den < Date.now()) throw loiNguoiDung('Không còn khóa để kháng nghị.');
  return den - cfg[THOI_HAN_KHOA[qd.loai]] * PHUT;
}

/** Admin xử lý kháng nghị: 'go_khoa' | 'giu_nguyen' | 'xoa_vi_pham'. Đang kháng nghị thì hình phạt vẫn hiệu lực tới lúc này. */
async function xuLyKhangNghi(adminUid, { id, ketQua, ghiChu = '' }) {
  if (!['go_khoa', 'giu_nguyen', 'xoa_vi_pham'].includes(ketQua)) throw thamSoSai();
  const cfg = await layCauHinh();
  const ref = db.collection(COL.khangNghi).doc(String(id || ''));
  const snap = await ref.get();
  if (!snap.exists || snap.get('trangThai') !== 'cho_xu_ly') throw loiNguoiDung('Kháng nghị đã được xử lý.');
  const k = snap.data();
  const qd = k.quyetDinh;
  if (ketQua === 'xoa_vi_pham' && ['vi_pham', 'khieu_nai_sai'].includes(qd.loai)) {
    const vp = db.collection(qd.loai === 'vi_pham' ? COL.viPham : COL.khieuNaiSai).doc(qd.id);
    await vp.update({ daGo: true, goLuc: Timestamp.now() });
    const sdt = (await vp.get()).get('sdt');
    if (sdt) await tinhLaiKhoa(sdt, cfg);
  }
  if (ketQua === 'go_khoa') {
    if (TRUONG_KHOA[qd.loai]) await db.collection(COL.khoa).doc(qd.id).set({ [TRUONG_KHOA[qd.loai]]: null }, { merge: true });
    if (qd.loai === 'an_quan') {
      await db.collection(COL.quan).doc(qd.id).update({ trangThai: 'active', anBoi: null, lyDoAn: null, hoatDongLuc: Timestamp.now(), hanXacNhanHoatDong: null });
    }
    if (qd.loai === 'khoa_ban') {
      await db.collection(COL.chiSoChu).doc(qd.id).set({ khoaBan: false }, { merge: true });
      const quan = await db.collection(COL.quan).where('chuQuanId', '==', qd.id).get();
      for (const d of quan.docs) if (d.get('khoaBan')) await d.ref.update({ khoaBan: false, trangThai: 'hidden' });
    }
  }
  await ref.update({ trangThai: 'da_xu_ly', ketQua, ghiChuAdmin: ghiChu, xuLyBoi: adminUid, xuLyLuc: Timestamp.now() });
  await ghiNhatKy(adminUid, `khang_nghi_${ketQua}`, { loai: 'khang_nghi', id }, ghiChu);
  await thongBao([{
    khoa: `ket_qua_khang_nghi_${id}`, nguoiNhan: k.nguoiGui, loai: 'ket_qua_khang_nghi', nhom: 'khang_nghi', tieuDe: 'Kết quả kháng nghị',
    noiDung: ketQua === 'giu_nguyen' ? 'Kháng nghị không được chấp nhận, quyết định giữ nguyên.' : 'Kháng nghị được chấp nhận.', moTrang: { loai: 'cua_toi' },
  }]);
  return { ok: true };
}

module.exports = {
  LY_DO_BAO_CAO, maCuocChat, guiTin, daXem, chan, tinhTyLePhanHoi, guiDanhGia, capNhatDiemQuan, chuTraLoiDanhGia,
  guiBaoCao, xuLyBaoCao, guiKhangNghi, xuLyKhangNghi, tinhLaiKhoa,
};
