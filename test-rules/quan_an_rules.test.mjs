// Kiểm thử rules của module Quán ăn trên Firebase Emulator.
// Chạy từ thư mục gốc repo:
//   npx firebase emulators:exec --only firestore,storage --project demo-rules "node test-rules/quan_an_rules.test.mjs"
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, GeoPoint, serverTimestamp, Timestamp } from 'firebase/firestore';

const goc = join(dirname(fileURLToPath(import.meta.url)), '..');
const env = await initializeTestEnvironment({
  projectId: 'demo-rules',
  firestore: { rules: readFileSync(join(goc, 'firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8080 },
  storage: { rules: readFileSync(join(goc, 'storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 },
});

let pass = 0;
let fail = 0;
const kiem = async (ten, p) => {
  try { await p; pass++; console.log('  OK  ', ten); } catch (e) { fail++; console.log('  LỖI ', ten, '->', String(e.message).split('\n')[0]); }
};

const nguoi = (uid) => env.authenticatedContext(uid, { email: `${uid}@x.com`, firebase: { sign_in_provider: 'password' } });
const khach = () => env.unauthenticatedContext();
const db = (ctx) => ctx.firestore();

await env.withSecurityRulesDisabled(async (ctx) => {
  const f = ctx.firestore();
  await setDoc(doc(f, 'admins/ad'), { quanAn: true });
  await setDoc(doc(f, 'admins/adTro'), { tro: true });
  await setDoc(doc(f, 'xac_thuc/sv'), { sdt: '0902000002', sdtDaXacThuc: true });
  await setDoc(doc(f, 'qa_quan/active'), { chuQuanId: 'chu', trangThai: 'active', ten: 'Cơm A' });
  await setDoc(doc(f, 'qa_quan/nhap'), { chuQuanId: 'chu', trangThai: 'draft', ten: 'Nháp' });
  await setDoc(doc(f, 'qa_quan/cho'), { chuQuanId: 'chu', trangThai: 'pending_review', ten: 'Chờ duyệt' });
  await setDoc(doc(f, 'qa_quan/nhap/rieng/giay_to'), { maSoThue: '0312345678', anhGiayChungNhan: ['https://x.com/g.jpg'] });
  await setDoc(doc(f, 'qa_quan/cho/rieng/giay_to'), { maSoThue: '0312345678', anhGiayChungNhan: ['https://x.com/g.jpg'] });
  await setDoc(doc(f, 'qa_mon/m1'), { quanId: 'active', ten: 'Cơm', gia: 30000 });
  await setDoc(doc(f, 'qa_check_in/ci1'), { svId: 'sv', quanId: 'active', congKhai: true });
  await setDoc(doc(f, 'qa_check_in/ci2'), { svId: 'sv', quanId: 'active', congKhai: false });
  await setDoc(doc(f, 'qa_dat_ban/b1'), { svId: 'sv', chuQuanId: 'chu', status: 'pending' });
  await setDoc(doc(f, 'qa_don/d1'), { svId: 'sv', chuQuanId: 'chu', status: 'placed', tong: 1 });
  await setDoc(doc(f, 'qa_don/d1/rieng/ma'), { ma: '4821' });
  await setDoc(doc(f, 'qa_khoan_tien/d1'), { nguoiTra: 'sv', nguoiNhan: 'chu', trangThai: 'dang_giu' });
  await setDoc(doc(f, 'qa_cong_gia_lap/d1'), { nguoiTra: 'sv' });
  await setDoc(doc(f, 'qa_vi/chu'), { dangGiu: 1, daNhan: 0 });
  await setDoc(doc(f, 'qa_chat/chu_sv'), { thanhVien: ['chu', 'sv'], chanBoi: [] });
  await setDoc(doc(f, 'qa_chat/chu_sv/tin_nhan/m1'), { nguoiGui: 'sv', noiDung: 'Alo' });
  await setDoc(doc(f, 'qa_danh_gia/sv_active'), { quanId: 'active', svId: 'sv', trangThaiHienThi: 'hien' });
  await setDoc(doc(f, 'qa_danh_gia/sv2_active'), { quanId: 'active', svId: 'sv2', trangThaiHienThi: 'an_tam' });
  await setDoc(doc(f, 'qa_thong_bao/tb1'), { nguoiNhan: 'sv', tieuDe: 'x', docLuc: null, taoLuc: Timestamp.now() });
  await setDoc(doc(f, 'qa_vi_pham/v1'), { uid: 'sv', sdt: '0902000002', loai: 'bom_hang' });
  await setDoc(doc(f, 'qa_khoa/0902000002'), { khoaDatMonDen: null });
  await setDoc(doc(f, 'qa_bao_cao/b1'), { nguoiBao: 'sv', trangThai: 'cho_xu_ly' });
  await setDoc(doc(f, 'qa_khang_nghi/k1'), { nguoiGui: 'sv', trangThai: 'cho_xu_ly' });
  await setDoc(doc(f, 'qa_chi_so_chu/chu'), { tyLePhanHoi: 90 });
  await setDoc(doc(f, 'qa_cau_hinh/hien_hanh'), { giuBanPhut: 1 });
  await setDoc(doc(f, 'qa_nhat_ky_admin/n1'), { viec: 'x' });
});

const quanNhap = (uid, them = {}) => ({
  chuQuanId: uid, trangThai: 'draft', ten: 'Quán mới', loaiQuan: 'ban_le', loaiMon: ['com'], moTa: '', sdt: '', diaChi: '', phuong: '',
  viTri: new GeoPoint(10, 105), luuDong: false, ghiChuViTri: '', gioMoCua: {}, phucVu: { anTaiQuan: true, mangDi: false }, tienIch: [],
  nhanDatBan: false, datMon: { bat: false }, anhMatTien: [], anhBia: '', anhKhac: [], camKet: false, taoLuc: serverTimestamp(), capNhatLuc: serverTimestamp(), ...them,
});

console.log('--- Quán ---');
await kiem('khách xem được quán đang hoạt động, không xem được bản nháp / chờ duyệt', async () => {
  await assertSucceeds(getDoc(doc(db(khach()), 'qa_quan/active')));
  await assertFails(getDoc(doc(db(khach()), 'qa_quan/nhap')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_quan/cho')));
});
await kiem('chủ xem quán của mình; admin Quán ăn xem tất cả; admin Tìm trọ không xem được', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('chu')), 'qa_quan/cho')));
  await assertSucceeds(getDoc(doc(db(nguoi('ad')), 'qa_quan/cho')));
  await assertFails(getDoc(doc(db(nguoi('adTro')), 'qa_quan/cho')));
});
await kiem('chủ tạo bản nháp (chuQuanId của mình); không tạo quán ở trạng thái active / cho người khác', async () => {
  await assertSucceeds(setDoc(doc(db(nguoi('chu2')), 'qa_quan/moi'), quanNhap('chu2')));
  await assertFails(setDoc(doc(db(nguoi('chu2')), 'qa_quan/moi2'), quanNhap('chu2', { trangThai: 'active' })));
  await assertFails(setDoc(doc(db(nguoi('chu2')), 'qa_quan/moi3'), quanNhap('chu')));
  await assertFails(setDoc(doc(db(nguoi('chu2')), 'qa_quan/moi4'), quanNhap('chu2', { khoaBan: true })));
});
await kiem('sửa bản nháp được; quán chờ duyệt / đang hoạt động không tự sửa trực tiếp; không tự đổi trạng thái', async () => {
  await assertSucceeds(updateDoc(doc(db(nguoi('chu')), 'qa_quan/nhap'), { ten: 'Tên mới đủ dài', capNhatLuc: serverTimestamp() }));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_quan/nhap'), { trangThai: 'active' }));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_quan/cho'), { ten: 'Đổi tên khi chờ duyệt' }));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_quan/active'), { ten: 'Đổi tên trực tiếp' }));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_quan/nhap'), { soLieu: { diemTong: 5 } }));
});
await kiem('chủ xóa bản nháp được, xóa quán đang hoạt động thì không', async () => {
  await assertFails(deleteDoc(doc(db(nguoi('chu')), 'qa_quan/active')));
  await assertSucceeds(deleteDoc(doc(db(nguoi('chu2')), 'qa_quan/moi')));
});
await kiem('giấy tờ: chủ và admin Quán ăn đọc; người khác thì không; chủ chỉ ghi khi còn nháp', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('chu')), 'qa_quan/nhap/rieng/giay_to')));
  await assertSucceeds(getDoc(doc(db(nguoi('ad')), 'qa_quan/nhap/rieng/giay_to')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_quan/nhap/rieng/giay_to')));
  await assertFails(getDoc(doc(db(khach()), 'qa_quan/nhap/rieng/giay_to')));
  await assertSucceeds(setDoc(doc(db(nguoi('chu')), 'qa_quan/nhap/rieng/giay_to'), { maSoThue: '0312345678', anhGiayChungNhan: ['https://x.com/g.jpg'] }));
  await assertFails(setDoc(doc(db(nguoi('chu')), 'qa_quan/cho/rieng/giay_to'), { maSoThue: '0399999999', anhGiayChungNhan: [] }));
  await assertFails(setDoc(doc(db(nguoi('chu')), 'qa_quan/nhap/rieng/giay_to'), { maSoThue: '0312345678', khac: 1 }));
});

console.log('--- Menu, check-in ---');
await kiem('menu công khai nhưng không ai ghi qua app (kể cả chủ quán)', async () => {
  await assertSucceeds(getDoc(doc(db(khach()), 'qa_mon/m1')));
  await assertFails(setDoc(doc(db(nguoi('chu')), 'qa_mon/m2'), { quanId: 'active', ten: 'Món', gia: 1 }));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_mon/m1'), { gia: 1 }));
});
await kiem('check-in: công khai xem được; riêng tư chỉ người check-in; không ai tự ghi', async () => {
  await assertSucceeds(getDoc(doc(db(khach()), 'qa_check_in/ci1')));
  await assertFails(getDoc(doc(db(khach()), 'qa_check_in/ci2')));
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_check_in/ci2')));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_check_in/ci3'), { svId: 'sv', congKhai: true }));
});

console.log('--- Đặt bàn, đơn món, tiền ---');
await kiem('bàn / đơn: chỉ sinh viên, chủ quán và admin xem; không ai ghi qua app', async () => {
  for (const [uid, ok] of [['sv', true], ['chu', true], ['ad', true], ['sv2', false]]) {
    const f = db(nguoi(uid));
    await (ok ? assertSucceeds : assertFails)(getDoc(doc(f, 'qa_dat_ban/b1')));
    await (ok ? assertSucceeds : assertFails)(getDoc(doc(f, 'qa_don/d1')));
  }
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_don/d1'), { status: 'completed' }));
  await assertFails(updateDoc(doc(db(nguoi('sv')), 'qa_don/d1'), { tong: 0 }));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_dat_ban/b2'), { svId: 'sv', chuQuanId: 'chu', status: 'confirmed' }));
});
await kiem('truy vấn đơn của tôi (theo svId / chuQuanId) chạy được; truy vấn đơn của người khác bị chặn', async () => {
  await assertSucceeds(getDocs(query(collection(db(nguoi('sv')), 'qa_don'), where('svId', '==', 'sv'))));
  await assertSucceeds(getDocs(query(collection(db(nguoi('chu')), 'qa_don'), where('chuQuanId', '==', 'chu'), where('status', '==', 'placed'))));
  await assertFails(getDocs(query(collection(db(nguoi('sv2')), 'qa_don'), where('svId', '==', 'sv'))));
  await assertSucceeds(getDocs(query(collection(db(nguoi('ad')), 'qa_don'), where('status', '==', 'disputed'))));
});
await kiem('mã nhận món 4 số: CHỈ sinh viên của đơn đọc được; chủ quán và người khác không', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_don/d1/rieng/ma')));
  await assertFails(getDoc(doc(db(nguoi('chu')), 'qa_don/d1/rieng/ma')));
  await assertFails(getDoc(doc(db(nguoi('ad')), 'qa_don/d1/rieng/ma')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_don/d1/rieng/ma')));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_don/d1/rieng/ma'), { ma: '0000' }));
});
await kiem('khoản tiền: người trả, người nhận, admin xem; cổng giả lập không ai đọc / ghi; ví chỉ chủ quán', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_khoan_tien/d1')));
  await assertSucceeds(getDoc(doc(db(nguoi('chu')), 'qa_khoan_tien/d1')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_khoan_tien/d1')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_cong_gia_lap/d1')));
  await assertFails(updateDoc(doc(db(nguoi('sv')), 'qa_khoan_tien/d1'), { trangThai: 'da_hoan' }));
  await assertSucceeds(getDoc(doc(db(nguoi('chu')), 'qa_vi/chu')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_vi/chu')));
  await assertFails(updateDoc(doc(db(nguoi('chu')), 'qa_vi/chu'), { daNhan: 999 }));
});

console.log('--- Chat, đánh giá, báo cáo, thông báo ---');
await kiem('chat: chỉ 2 người trong cuộc và admin đọc; không ai ghi trực tiếp', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_chat/chu_sv')));
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_chat/chu_sv/tin_nhan/m1')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_chat/chu_sv/tin_nhan/m1')));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_chat/chu_sv/tin_nhan/m2'), { nguoiGui: 'sv', noiDung: 'x' }));
});
await kiem('đánh giá: công khai trừ bị ẩn tạm; người viết xem của mình; không ai ghi trực tiếp', async () => {
  await assertSucceeds(getDoc(doc(db(khach()), 'qa_danh_gia/sv_active')));
  await assertFails(getDoc(doc(db(khach()), 'qa_danh_gia/sv2_active')));
  await assertSucceeds(getDoc(doc(db(nguoi('sv2')), 'qa_danh_gia/sv2_active')));
  await assertSucceeds(getDocs(query(collection(db(khach()), 'qa_danh_gia'), where('quanId', '==', 'active'), where('trangThaiHienThi', '==', 'hien'))));
  await assertFails(getDocs(query(collection(db(khach()), 'qa_danh_gia'), where('quanId', '==', 'active'))));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_danh_gia/sv_x'), { quanId: 'x', svId: 'sv', trangThaiHienThi: 'hien' }));
});
await kiem('báo cáo: chỉ admin Quán ăn đọc; kháng nghị: người gửi và admin; vi phạm: người bị ghi', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('ad')), 'qa_bao_cao/b1')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_bao_cao/b1')));
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_khang_nghi/k1')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_khang_nghi/k1')));
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_vi_pham/v1')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_vi_pham/v1')));
  await assertFails(updateDoc(doc(db(nguoi('sv')), 'qa_vi_pham/v1'), { daGo: true }));
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_khoa/0902000002')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_khoa/0902000002')));
});
await kiem('thông báo: người nhận đọc và chỉ đánh dấu đã đọc; chỉ số chủ quán công khai; cấu hình / nhật ký đóng', async () => {
  await assertSucceeds(getDoc(doc(db(nguoi('sv')), 'qa_thong_bao/tb1')));
  await assertFails(getDoc(doc(db(nguoi('sv2')), 'qa_thong_bao/tb1')));
  await assertSucceeds(updateDoc(doc(db(nguoi('sv')), 'qa_thong_bao/tb1'), { docLuc: Timestamp.now() }));
  await assertFails(updateDoc(doc(db(nguoi('sv')), 'qa_thong_bao/tb1'), { tieuDe: 'đổi' }));
  await assertSucceeds(getDoc(doc(db(khach()), 'qa_chi_so_chu/chu')));
  await assertFails(getDoc(doc(db(nguoi('ad')), 'qa_cau_hinh/hien_hanh')));
  await assertFails(setDoc(doc(db(nguoi('ad')), 'qa_cau_hinh/hien_hanh'), { giuBanPhut: 0 }));
  await assertSucceeds(getDoc(doc(db(nguoi('ad')), 'qa_nhat_ky_admin/n1')));
  await assertFails(getDoc(doc(db(nguoi('sv')), 'qa_nhat_ky_admin/n1')));
});

console.log('--- Lưu ❤️, hồ sơ ---');
await kiem('lưu quán: lưu được quán người khác, không lưu quán của mình; bỏ lưu được', async () => {
  await assertSucceeds(setDoc(doc(db(nguoi('sv')), 'qa_luu/sv_active'), { uid: 'sv', quanId: 'active', nhanThongBao: true, luc: serverTimestamp() }));
  await assertFails(setDoc(doc(db(nguoi('chu')), 'qa_luu/chu_active'), { uid: 'chu', quanId: 'active', nhanThongBao: true, luc: serverTimestamp() }));
  await assertFails(setDoc(doc(db(nguoi('sv2')), 'qa_luu/sv_active2'), { uid: 'sv', quanId: 'active', nhanThongBao: true, luc: serverTimestamp() }));
  await assertSucceeds(deleteDoc(doc(db(nguoi('sv')), 'qa_luu/sv_active')));
});
await kiem('hồ sơ: chỉ tự sửa cài đặt thông báo', async () => {
  await assertSucceeds(setDoc(doc(db(nguoi('sv')), 'qa_ho_so/sv'), { caiDatThongBao: { tin_nhan: false } }));
  await assertFails(setDoc(doc(db(nguoi('sv')), 'qa_ho_so/sv'), { caiDatThongBao: {}, quyen: 'admin' }));
  await assertFails(setDoc(doc(db(nguoi('sv2')), 'qa_ho_so/sv'), { caiDatThongBao: {} }));
});

await env.cleanup();
console.log(`\nKết quả: ${pass} qua, ${fail} lỗi`);
process.exit(fail ? 1 : 0);
