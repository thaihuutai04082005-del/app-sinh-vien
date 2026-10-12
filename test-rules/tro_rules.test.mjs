// Kiểm thử rules của module Tìm trọ (và phần tài khoản) trên Firebase Emulator.
// Chạy từ thư mục gốc repo:
//   npx firebase emulators:exec --only firestore,storage --project demo-rules "node test-rules/tro_rules.test.mjs"
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, orderBy, GeoPoint, serverTimestamp, Timestamp,
} from 'firebase/firestore';
import { ref, uploadBytes, getBytes } from 'firebase/storage';

const goc = join(dirname(fileURLToPath(import.meta.url)), '..');
const env = await initializeTestEnvironment({
  projectId: 'demo-rules',
  firestore: { rules: readFileSync(join(goc, 'firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8080 },
  storage: { rules: readFileSync(join(goc, 'storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 },
});

let pass = 0;
let fail = 0;
const kiem = async (ten, p) => {
  try {
    await p;
    pass++;
    console.log('  OK  ', ten);
  } catch (e) {
    fail++;
    console.log('  LỖI ', ten, '->', String(e.message).split('\n')[0]);
  }
};

const nguoi = (uid) => env.authenticatedContext(uid, { email: `${uid}@x.com`, firebase: { sign_in_provider: 'password' } });
const anDanh = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } });
const khach = () => env.unauthenticatedContext();
const db = (ctx) => ctx.firestore();

// ---- Dữ liệu mẫu (ghi bằng quyền admin, bỏ qua rules) ----
await env.withSecurityRulesDisabled(async (ctx) => {
  const f = ctx.firestore();
  await setDoc(doc(f, 'admins/ad'), { tro: true, danhTinh: true });
  await setDoc(doc(f, 'xac_thuc/sv'), { sdt: '0902000002', sdtDaXacThuc: true });
  await setDoc(doc(f, 'xac_thuc/sv2'), { sdt: '0903000003', sdtDaXacThuc: true });
  await setDoc(doc(f, 'nha_tro/active'), { chuTroId: 'chu', trangThai: 'active', ten: 'Nhà A' });
  await setDoc(doc(f, 'nha_tro/nhap'), { chuTroId: 'chu', trangThai: 'draft', ten: 'Nháp' });
  await setDoc(doc(f, 'nha_tro/cho'), { chuTroId: 'chu', trangThai: 'pending_review', ten: 'Chờ duyệt' });
  await setDoc(doc(f, 'nha_tro/nhap/rieng/giay_to'), { giayTo: ['https://x.com/g.jpg'] });
  await setDoc(doc(f, 'phong_tro/trong'), { nhaTroId: 'active', chuTroId: 'chu', trangThai: 'available', daXoa: false, ten: 'P1', nhaTro: { trangThai: 'active' } });
  await setDoc(doc(f, 'phong_tro/an'), { nhaTroId: 'active', chuTroId: 'chu', trangThai: 'hidden', daXoa: false, ten: 'P2' });
  await setDoc(doc(f, 'phong_tro/nhap'), { nhaTroId: 'active', chuTroId: 'chu', trangThai: 'draft', daXoa: false, ten: 'P3' });
  await setDoc(doc(f, 'tro_dat_coc/c1'), { sinhVienId: 'sv', chuTroId: 'chu', status: 'held', soTien: 1 });
  await setDoc(doc(f, 'tro_khoan_tien/c1'), { nguoiTra: 'sv', nguoiNhan: 'chu', trangThai: 'dang_giu' });
  await setDoc(doc(f, 'tro_vi/chu'), { dangGiu: 1, daNhan: 0 });
  await setDoc(doc(f, 'tro_coc_truc_tiep/t1'), { chuTroId: 'chu', sdtNguoiCoc: '0902000002', ketQua: 'dang_cho' });
  await setDoc(doc(f, 'tro_chat/chu_sv'), { thanhVien: ['chu', 'sv'], chanBoi: [] });
  await setDoc(doc(f, 'tro_chat/chu_sv/tin_nhan/m1'), { nguoiGui: 'sv', noiDung: 'Alo' });
  await setDoc(doc(f, 'tro_danh_gia/d1'), { nhaTroId: 'active', nguoiViet: 'sv', hienThi: 'hien' });
  await setDoc(doc(f, 'tro_danh_gia/d2'), { nhaTroId: 'active', nguoiViet: 'sv', hienThi: 'an_tam' });
  await setDoc(doc(f, 'tro_thong_bao/tb1'), { nguoiNhan: 'sv', tieuDe: 'x', docLuc: null, taoLuc: Timestamp.now() });
  await setDoc(doc(f, 'tro_vi_pham/v1'), { uid: 'chu', sdt: '0901', loai: 'huy_coc' });
  await setDoc(doc(f, 'tro_khoa/0902000002'), { khoaCocDen: null });
  await setDoc(doc(f, 'tro_bao_cao/b1'), { nguoiBao: 'sv', trangThai: 'cho_xu_ly' });
  await setDoc(doc(f, 'quota/chu'), { day: Math.floor(Date.now() / 86400000), posts: 0, uploads: 1 });
});

const nhaNhap = (uid, them = {}) => ({
  chuTroId: uid, trangThai: 'draft', ten: 'Nhà trọ mới', loaiHinh: 'phong', tongSoPhong: 3, soTang: 1, tienIchChung: [],
  noiQuy: null, moTa: '', diaChi: '', phuong: '', searchText: '', viTri: new GeoPoint(10, 105), anh: [], video: [], anhBia: '',
  camKet: false, taoLuc: serverTimestamp(), capNhatLuc: serverTimestamp(), ...them,
});

console.log('--- Nhà trọ ---');
await kiem('khách đọc được nhà trọ đang hiển thị', assertSucceeds(getDoc(doc(db(khach()), 'nha_tro/active'))));
await kiem('khách KHÔNG đọc được bản nháp / chờ duyệt', assertFails(getDoc(doc(db(khach()), 'nha_tro/nhap'))));
await kiem('người khác KHÔNG đọc được nhà trọ chờ duyệt', assertFails(getDoc(doc(db(nguoi('sv')), 'nha_tro/cho'))));
await kiem('chủ đọc được bản nháp của mình', assertSucceeds(getDoc(doc(db(nguoi('chu')), 'nha_tro/nhap'))));
await kiem('admin Tìm trọ đọc được hàng chờ', assertSucceeds(getDocs(query(collection(db(nguoi('ad')), 'nha_tro'), where('trangThai', '==', 'pending_review')))));
await kiem('chủ tạo bản nháp của mình', assertSucceeds(setDoc(doc(db(nguoi('chu')), 'nha_tro/moi'), nhaNhap('chu'))));
await kiem('tạo bản nháp đứng tên người khác → chặn', assertFails(setDoc(doc(db(nguoi('sv')), 'nha_tro/gia'), nhaNhap('chu'))));
await kiem('tự tạo nhà trọ "active" → chặn', assertFails(setDoc(doc(db(nguoi('chu')), 'nha_tro/lach'), nhaNhap('chu', { trangThai: 'active' }))));
await kiem('tự gắn "đã xác thực nhà" → chặn', assertFails(setDoc(doc(db(nguoi('chu')), 'nha_tro/lach2'), nhaNhap('chu', { daXacThucNha: true }))));
await kiem('chủ sửa bản nháp', assertSucceeds(updateDoc(doc(db(nguoi('chu')), 'nha_tro/nhap'), { ten: 'Đổi tên', capNhatLuc: serverTimestamp() })));
await kiem('chủ tự đổi nháp sang chờ duyệt → chặn (phải gửi qua hệ thống)', assertFails(updateDoc(doc(db(nguoi('chu')), 'nha_tro/nhap'), { trangThai: 'pending_review' })));
await kiem('chủ sửa thẳng nhà trọ đang hiển thị → chặn', assertFails(updateDoc(doc(db(nguoi('chu')), 'nha_tro/active'), { ten: 'x', trangThai: 'draft' })));
await kiem('chủ tự ghi số liệu / hạn hiển thị → chặn', assertFails(updateDoc(doc(db(nguoi('chu')), 'nha_tro/nhap'), { soLieu: { diem: 5 } })));
await kiem('giấy tờ nhà: chủ đọc được', assertSucceeds(getDoc(doc(db(nguoi('chu')), 'nha_tro/nhap/rieng/giay_to'))));
await kiem('giấy tờ nhà: admin đọc được', assertSucceeds(getDoc(doc(db(nguoi('ad')), 'nha_tro/nhap/rieng/giay_to'))));
await kiem('giấy tờ nhà: người khác KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv')), 'nha_tro/nhap/rieng/giay_to'))));
await kiem('đăng nhập ẩn danh không tạo được nhà trọ', assertFails(setDoc(doc(db(anDanh('chu')), 'nha_tro/an_danh'), nhaNhap('chu'))));

console.log('--- Phòng ---');
await kiem('khách đọc được phòng còn trống', assertSucceeds(getDoc(doc(db(khach()), 'phong_tro/trong'))));
await kiem('khách KHÔNG đọc được phòng tạm ẩn / nháp', assertFails(getDoc(doc(db(khach()), 'phong_tro/an'))));
await kiem('sảnh: truy vấn phòng còn trống của nhà trọ đang hiển thị', assertSucceeds(getDocs(query(collection(db(khach()), 'phong_tro'),
  where('trangThai', '==', 'available'), where('nhaTro.trangThai', '==', 'active')))));
await kiem('trang nhà trọ: truy vấn phòng hiển thị', assertSucceeds(getDocs(query(collection(db(nguoi('sv')), 'phong_tro'),
  where('nhaTroId', '==', 'active'), where('trangThai', 'in', ['available', 'reserved', 'rented'])))));
await kiem('chủ: truy vấn tất cả phòng của nhà mình (kèm chuTroId)', assertSucceeds(getDocs(query(collection(db(nguoi('chu')), 'phong_tro'),
  where('nhaTroId', '==', 'active'), where('chuTroId', '==', 'chu')))));
const phongNhap = { nhaTroId: 'active', chuTroId: 'chu', ten: 'P9', trangThai: 'draft', daXoa: false, giaThue: 1000000, tienCoc: 1000000 };
await kiem('chủ tạo phòng nháp trong nhà của mình', assertSucceeds(setDoc(doc(db(nguoi('chu')), 'phong_tro/p9'), phongNhap)));
await kiem('tạo phòng vào nhà trọ của người khác → chặn', assertFails(setDoc(doc(db(nguoi('sv')), 'phong_tro/p10'), { ...phongNhap, chuTroId: 'sv' })));
await kiem('tự tạo phòng "available" → chặn', assertFails(setDoc(doc(db(nguoi('chu')), 'phong_tro/p11'), { ...phongNhap, trangThai: 'available' })));
await kiem('chủ tự đổi phòng đang trống sang "đã cho thuê" → chặn (phải qua hệ thống)', assertFails(updateDoc(doc(db(nguoi('chu')), 'phong_tro/trong'), { trangThai: 'rented' })));
await kiem('chủ tự gỡ khóa thanh toán / giữ phòng → chặn', assertFails(updateDoc(doc(db(nguoi('chu')), 'phong_tro/nhap'), { khoaThanhToan: null })));
await kiem('chủ xóa phòng nháp', assertSucceeds(deleteDoc(doc(db(nguoi('chu')), 'phong_tro/p9'))));

console.log('--- Khoản cọc, tiền, ví ---');
await kiem('sinh viên đọc khoản cọc của mình', assertSucceeds(getDoc(doc(db(nguoi('sv')), 'tro_dat_coc/c1'))));
await kiem('chủ trọ đọc khoản cọc của phòng mình', assertSucceeds(getDoc(doc(db(nguoi('chu')), 'tro_dat_coc/c1'))));
await kiem('người ngoài KHÔNG đọc được khoản cọc', assertFails(getDoc(doc(db(nguoi('sv2')), 'tro_dat_coc/c1'))));
await kiem('không ai tự sửa khoản cọc (kể cả sinh viên)', assertFails(updateDoc(doc(db(nguoi('sv')), 'tro_dat_coc/c1'), { status: 'refunded' })));
await kiem('không ai tự tạo khoản cọc', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_dat_coc/c9'), { sinhVienId: 'sv', status: 'held' })));
await kiem('khoản tiền: người ngoài KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv2')), 'tro_khoan_tien/c1'))));
await kiem('ví: chủ đọc ví mình, không sửa được', assertSucceeds(getDoc(doc(db(nguoi('chu')), 'tro_vi/chu'))));
await kiem('ví: tự cộng tiền → chặn', assertFails(setDoc(doc(db(nguoi('chu')), 'tro_vi/chu'), { daNhan: 999999999 })));
await kiem('ví người khác KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv')), 'tro_vi/chu'))));
await kiem('cổng thanh toán giả lập: app KHÔNG đọc / ghi được', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_cong_gia_lap/c1'), { trangThai: 'thanh_cong' })));

console.log('--- Cọc trực tiếp, vi phạm, khóa ---');
await kiem('người cọc (đúng SĐT đã OTP) đọc được', assertSucceeds(getDoc(doc(db(nguoi('sv')), 'tro_coc_truc_tiep/t1'))));
await kiem('người cọc truy vấn theo SĐT của mình', assertSucceeds(getDocs(query(collection(db(nguoi('sv')), 'tro_coc_truc_tiep'), where('sdtNguoiCoc', '==', '0902000002')))));
await kiem('người khác số KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv2')), 'tro_coc_truc_tiep/t1'))));
await kiem('vi phạm: người bị ghi đọc của mình', assertSucceeds(getDocs(query(collection(db(nguoi('chu')), 'tro_vi_pham'), where('uid', '==', 'chu')))));
await kiem('vi phạm: người khác KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv')), 'tro_vi_pham/v1'))));
await kiem('khóa: đọc khóa theo SĐT của mình', assertSucceeds(getDoc(doc(db(nguoi('sv')), 'tro_khoa/0902000002'))));
await kiem('khóa: tự gỡ khóa → chặn', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_khoa/0902000002'), { khoaCocDen: null })));

console.log('--- Chat, đánh giá, lưu, thông báo, báo cáo ---');
await kiem('chat: người trong cuộc đọc tin nhắn', assertSucceeds(getDocs(collection(db(nguoi('chu')), 'tro_chat/chu_sv/tin_nhan'))));
await kiem('chat: người ngoài KHÔNG đọc được', assertFails(getDocs(collection(db(nguoi('sv2')), 'tro_chat/chu_sv/tin_nhan'))));
await kiem('chat: không tự ghi tin nhắn (phải qua hệ thống để chặn / cảnh báo)', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_chat/chu_sv/tin_nhan/m9'), { nguoiGui: 'sv', noiDung: 'x' })));
await kiem('chat: danh sách cuộc trò chuyện của mình', assertSucceeds(getDocs(query(collection(db(nguoi('sv')), 'tro_chat'), where('thanhVien', 'array-contains', 'sv')))));
await kiem('chat: mở cuộc chưa có (doc không tồn tại) không lỗi quyền', assertSucceeds(getDoc(doc(db(nguoi('sv2')), 'tro_chat/chu_sv2'))));
await kiem('đánh giá đang hiện: ai cũng đọc', assertSucceeds(getDocs(query(collection(db(khach()), 'tro_danh_gia'), where('nhaTroId', '==', 'active'), where('hienThi', '==', 'hien')))));
await kiem('đánh giá bị ẩn tạm: người ngoài KHÔNG đọc', assertFails(getDoc(doc(db(nguoi('sv2')), 'tro_danh_gia/d2'))));
await kiem('đánh giá: không tự viết thẳng (phải qua hệ thống)', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_danh_gia/d9'), { nhaTroId: 'active', nguoiViet: 'sv', diemTB: 5 })));
await kiem('lưu ❤️ nhà trọ người khác', assertSucceeds(setDoc(doc(db(nguoi('sv')), 'tro_luu/sv_active'), { uid: 'sv', nhaTroId: 'active', nhanThongBao: true, luc: serverTimestamp() })));
await kiem('lưu ❤️ nhà trọ của chính mình → chặn', assertFails(setDoc(doc(db(nguoi('chu')), 'tro_luu/chu_active'), { uid: 'chu', nhaTroId: 'active', nhanThongBao: true, luc: serverTimestamp() })));
await kiem('lưu ❤️ hộ người khác → chặn', assertFails(setDoc(doc(db(nguoi('sv2')), 'tro_luu/sv_active'), { uid: 'sv', nhaTroId: 'active', nhanThongBao: true, luc: serverTimestamp() })));
await kiem('thông báo: người nhận đọc, đánh dấu đã đọc', assertSucceeds(updateDoc(doc(db(nguoi('sv')), 'tro_thong_bao/tb1'), { docLuc: serverTimestamp() })));
await kiem('thông báo: truy vấn của mình, mới nhất trước', assertSucceeds(getDocs(query(collection(db(nguoi('sv')), 'tro_thong_bao'), where('nguoiNhan', '==', 'sv'), orderBy('taoLuc', 'desc')))));
await kiem('thông báo: sửa nội dung → chặn', assertFails(updateDoc(doc(db(nguoi('sv')), 'tro_thong_bao/tb1'), { tieuDe: 'giả' })));
await kiem('thông báo người khác KHÔNG đọc được', assertFails(getDoc(doc(db(nguoi('sv2')), 'tro_thong_bao/tb1'))));
await kiem('cài đặt thông báo: tự tắt nhóm tin nhắn', assertSucceeds(setDoc(doc(db(nguoi('sv')), 'tro_ho_so/sv'), { caiDatThongBao: { tin_nhan: false } }, { merge: true })));
await kiem('hồ sơ module: tự ghi chỉ số / khóa → chặn', assertFails(setDoc(doc(db(nguoi('sv')), 'tro_ho_so/sv'), { chiSo: { tyLeCamKet: 100 } }, { merge: true })));
await kiem('báo cáo: chỉ admin đọc', assertFails(getDoc(doc(db(nguoi('sv')), 'tro_bao_cao/b1'))));
await kiem('chỉ số uy tín chủ trọ: ai cũng đọc, không ai sửa', assertFails(setDoc(doc(db(nguoi('chu')), 'tro_chi_so_chu/chu'), { tyLeCamKet: 100 })));

console.log('--- Tài khoản ---');
await kiem('xác thực: tự đọc của mình', assertSucceeds(getDoc(doc(db(nguoi('sv')), 'xac_thuc/sv'))));
await kiem('xác thực: tự gắn "đã OTP" / "đã xác thực danh tính" → chặn', assertFails(setDoc(doc(db(nguoi('sv2')), 'xac_thuc/sv2'), { danhTinh: 'da_xac_thuc' })));
await kiem('xác thực: người khác KHÔNG đọc (lộ SĐT)', assertFails(getDoc(doc(db(nguoi('sv2')), 'xac_thuc/sv'))));
await kiem('admin danh tính đọc hàng chờ duyệt', assertSucceeds(getDocs(query(collection(db(nguoi('ad')), 'xac_thuc'), where('danhTinh', '==', 'cho_duyet')))));
await kiem('tự cấp quyền admin → chặn', assertFails(setDoc(doc(db(nguoi('sv')), 'admins/sv'), { tro: true })));
await kiem('bảng SĐT, OTP: app không đọc được', assertFails(getDoc(doc(db(nguoi('sv')), 'so_dien_thoai/0902000002'))));

console.log('--- Storage ---');
const anh = new Uint8Array([137, 80, 78, 71]);
await kiem('ảnh tin (tro_anh) ai cũng xem', assertSucceeds((async () => {
  await env.withSecurityRulesDisabled(async (ctx) => uploadBytes(ref(ctx.storage(), 'tro_anh/chu/1_1.png'), anh, { contentType: 'image/png' }));
  return getBytes(ref(khach().storage(), 'tro_anh/chu/1_1.png'));
})()));
await env.withSecurityRulesDisabled(async (ctx) => uploadBytes(ref(ctx.storage(), 'tro_rieng/chu/1_1.png'), anh, { contentType: 'image/png' }));
await kiem('giấy tờ (tro_rieng): chủ xem được', assertSucceeds(getBytes(ref(nguoi('chu').storage(), 'tro_rieng/chu/1_1.png'))));
// Admin Tìm trọ xem giấy tờ dùng rules đọc chéo Firestore (firestore.get) — giống rules quota của Shop.
// Storage emulator trong môi trường CI không đọc chéo được nên ca này kiểm tra trên Firebase thật.
await kiem('giấy tờ (tro_rieng): người khác KHÔNG xem được', assertFails(getBytes(ref(nguoi('sv').storage(), 'tro_rieng/chu/1_1.png'))));
await kiem('giấy tờ (tro_rieng): khách KHÔNG xem được', assertFails(getBytes(ref(khach().storage(), 'tro_rieng/chu/1_1.png'))));

console.log(`\nKết quả: ${pass} qua, ${fail} lỗi`);
await env.cleanup();
process.exit(fail ? 1 : 0);
