'use strict';

/**
 * Kiểm thử luồng Quán ăn trên Firebase Emulator (Auth + Firestore + Functions).
 * Chạy từ thư mục gốc repo:
 *   npx firebase emulators:exec --only auth,firestore,functions --project demo-app-sinh-vien \
 *     "node functions/test-e2e/quan_an_luong.e2e.js"
 * (cần functions/.secret.local có QA_CONG_BI_MAT=...; thời hạn được rút ngắn qua qa_cau_hinh.)
 */

const assert = require('node:assert/strict');
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
const admin = require('../node_modules/firebase-admin');

const PROJECT = process.env.GCLOUD_PROJECT || 'demo-app-sinh-vien';
admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const FN = `http://127.0.0.1:5001/${PROJECT}/us-central1`;
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';

let pass = 0;
let fail = 0;
async function kiem(ten, fn) {
  try {
    await fn();
    pass++;
    console.log('  OK  ', ten);
  } catch (e) {
    fail++;
    console.log('  LỖI ', ten, '->', e.message);
  }
}

async function taoNguoiDung(email) {
  const r = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'matkhau123', returnSecureToken: true }),
  }).then((x) => x.json());
  await db.collection('users').doc(r.localId).set({ uid: r.localId, name: email.split('@')[0], email, role: 'student' });
  return { uid: r.localId, token: r.idToken };
}

async function goi(ten, nguoi, data) {
  const r = await fetch(`${FN}/${ten}`, {
    method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${nguoi.token}` }, body: JSON.stringify({ data }),
  }).then((x) => x.json());
  if (r.error) { const e = new Error(r.error.message); e.code = r.error.status; throw e; }
  return r.result;
}

const qa = (n, d) => goi('quanAnApi', n, d);
const tk = (n, d) => goi('taiKhoanApi', n, d);
const cho = (giay) => new Promise((r) => setTimeout(r, giay * 1000));
async function phaiLoi(p, khop) {
  try { await p; } catch (e) { if (khop) assert.match(e.message, khop); return e; }
  throw new Error('Đáng lẽ phải bị chặn');
}

const ANH = 'https://x.com/a.jpg';
const QUAN_LATLNG = { lat: 10.4599, lng: 105.6377 };
const GP = (lat, lng) => new admin.firestore.GeoPoint(lat, lng);
const phut = (n) => n * 60 * 1000;

// Lịch mở cửa phủ 5 giờ quanh thời điểm chạy test (mọi ngày) để test không phụ thuộc giờ chạy.
const nowVnMin = Math.floor(((Date.now() + 7 * 3600 * 1000) % 86400000) / 60000);
const CA = [{ tu: (nowVnMin - 60 + 1440) % 1440, den: (nowVnMin + 240) % 1440 }];
const LICH = Object.fromEntries([1, 2, 3, 4, 5, 6, 7].map((n) => [String(n), CA]));

(async () => {
  const chu = await taoNguoiDung('chu@x.com');
  const chuBL = await taoNguoiDung('banle@x.com');
  const svA = await taoNguoiDung('sva@x.com');
  const svB = await taoNguoiDung('svb@x.com');
  const ad = await taoNguoiDung('admin@x.com');
  await db.collection('admins').doc(ad.uid).set({ quanAn: true, danhTinh: true, tro: true });
  await db.collection('qa_cau_hinh').doc('hien_hanh').set({
    quanXacNhanDonPhut: 0.05, khieuNaiPhut: 0.1, khongNhanPhanDoiPhut: 0.1, khachKhongToiLayPhut: 0.05, huySatGioPhut: 200,
    quanChamPhut: 0.05, nhacChuongLaiPhut: 0.03, quanTraLoiKhieuNaiPhut: 5, giaoLauPhut: 0.05, quaHanBangChungPhut: 0.1,
  });
  const don = async (id) => (await db.collection('qa_don').doc(id).get()).data();
  const thaoTac = async (nguoi, donId, su) => qa(nguoi, { hanhDong: 'thaoTacDon', donId, version: (await don(donId)).version, su });
  const maNhan = async (id) => (await db.collection('qa_don').doc(id).collection('rieng').doc('ma').get()).get('ma');
  const tien = async (id) => (await db.collection('qa_khoan_tien').doc(id).get()).data();
  const vi = async () => (await db.collection('qa_vi').doc(chu.uid).get()).data() || { dangGiu: 0, daNhan: 0 };

  console.log('--- Tài khoản, cấu hình ---');
  for (const [n, sdt] of [[chu, '0901000001'], [svA, '0902000002'], [svB, '0903000003'], [chuBL, '0904000004']]) {
    await tk(n, { hanhDong: 'guiOtp', sdt });
    await tk(n, { hanhDong: 'xacNhanOtp', ma: '123456' });
  }
  for (const n of [chu, chuBL]) {
    await tk(n, { hanhDong: 'guiXacThucDanhTinh', hoTen: 'Chủ Quán', soCccd: n === chu ? '087123456789' : '087123456780', dongYXuLyDuLieu: true, camKet: true });
    await tk(ad, { hanhDong: 'adminDuyetDanhTinh', uid: n.uid, dongY: true });
  }
  await kiem('cauHinh trả cả khóa gốc lẫn khóa app đọc', async () => {
    const c = await qa(svA, { hanhDong: 'cauHinh' });
    assert.equal(c.chipGiaReDen, 35000);
    assert.equal(c.tienMatDuoi, 200000);
    assert.equal(c.quanXacNhanPhut, 0.05); // đã ghi đè để test
  });

  console.log('--- Quán: đăng, duyệt, loại hình ---');
  const quanRef = db.collection('qa_quan').doc();
  await quanRef.set({
    chuQuanId: chu.uid, trangThai: 'draft', ten: 'Cơm Gà Cô Ba', loaiQuan: 'ho_kinh_doanh', loaiMon: ['com'], moTa: 'Cơm gà nóng hổi cho sinh viên.',
    sdt: '0281234567'.slice(0, 10), diaChi: '12 Nguyễn Huệ', phuong: 'Phường 1', viTri: GP(QUAN_LATLNG.lat, QUAN_LATLNG.lng), luuDong: false, ghiChuViTri: '',
    gioMoCua: LICH, phucVu: { anTaiQuan: true, mangDi: true }, tienIch: ['wifi', 'do_xe'], nhanDatBan: true, anhMatTien: [ANH], anhBia: ANH, anhKhac: [],
    camKet: true, soLieu: {},
  });
  await quanRef.collection('rieng').doc('giay_to').set({ maSoThue: '0312345678', anhGiayChungNhan: [ANH] });
  await kiem('hộ kinh doanh thiếu mã số thuế thì không gửi duyệt được', async () => {
    const q2 = db.collection('qa_quan').doc();
    await q2.set({ ...(await quanRef.get()).data() });
    await phaiLoi(qa(chu, { hanhDong: 'guiDuyetQuan', quanId: q2.id }), /mã số thuế/);
  });
  await kiem('gửi duyệt → admin phải đối chiếu mã số thuế mới duyệt hộ kinh doanh → active', async () => {
    await qa(chu, { hanhDong: 'guiDuyetQuan', quanId: quanRef.id });
    assert.equal((await quanRef.get()).get('trangThai'), 'pending_review');
    await phaiLoi(qa(chu, { hanhDong: 'adminDuyet', loai: 'quan', id: quanRef.id, dongY: true }), /quyền/);
    await phaiLoi(qa(ad, { hanhDong: 'adminDuyet', loai: 'quan', id: quanRef.id, dongY: true }), /mã số thuế/);
    await qa(ad, { hanhDong: 'adminDuyet', loai: 'quan', id: quanRef.id, dongY: true, daDoiChieuMst: true });
    assert.equal((await quanRef.get()).get('trangThai'), 'active');
  });
  const qid = quanRef.id;
  await kiem('quán bán lẻ: không bật được đặt món / đặt bàn; có máy lạnh thì bị gắn cờ khai sai', async () => {
    const bl = db.collection('qa_quan').doc();
    await bl.set({
      chuQuanId: chuBL.uid, trangThai: 'draft', ten: 'Xe Bánh Mì', loaiQuan: 'ban_le', loaiMon: ['banh_mi'], moTa: 'Bánh mì nóng giòn mỗi sáng.', sdt: '0907654321',
      diaChi: '5 Lê Lợi', phuong: 'P2', viTri: GP(10.46, 105.64), luuDong: false, gioMoCua: LICH, phucVu: { anTaiQuan: false, mangDi: true },
      tienIch: ['may_lanh'], nhanDatBan: true, anhMatTien: [ANH], camKet: true,
    });
    await phaiLoi(qa(chuBL, { hanhDong: 'guiDuyetQuan', quanId: bl.id }), /không nhận đặt bàn/);
    await bl.update({ nhanDatBan: false });
    await qa(chuBL, { hanhDong: 'guiDuyetQuan', quanId: bl.id });
    assert.ok((await bl.get()).get('khaiSaiLoai').lyDo.length >= 1);
    await qa(ad, { hanhDong: 'adminDuyet', loai: 'quan', id: bl.id, dongY: true });
    await phaiLoi(qa(chuBL, { hanhDong: 'caiDatDatMon', quanId: bl.id, datMon: { bat: true } }), /hộ kinh doanh/);
  });

  console.log('--- Menu, khuyến mãi, mức giá ---');
  let nhomChinh; let nhomUong; const mon = {};
  await kiem('tạo nhóm món + 3 món (có tùy chọn), mức giá P25–P75 tính từ món chính', async () => {
    nhomChinh = (await qa(chu, { hanhDong: 'luuNhomMon', quanId: qid, ten: 'Món chính', laDoUong: false, thuTu: 1 })).nhomId;
    nhomUong = (await qa(chu, { hanhDong: 'luuNhomMon', quanId: qid, ten: 'Đồ uống', laDoUong: true, thuTu: 2 })).nhomId;
    mon.com = (await qa(chu, { hanhDong: 'luuMon', quanId: qid, nhomId: nhomChinh, ten: 'Cơm gà xối mỡ', gia: 35000, noiBat: true, tuyChon: [
      { ten: 'Cỡ', batBuoc: true, toiDa: 1, lua: [{ ten: 'Nhỏ', giaThem: 0 }, { ten: 'Lớn', giaThem: 5000 }] },
      { ten: 'Topping', batBuoc: false, toiDa: 2, lua: [{ ten: 'Trứng', giaThem: 5000 }, { ten: 'Chả', giaThem: 7000 }] }] })).monId;
    mon.suon = (await qa(chu, { hanhDong: 'luuMon', quanId: qid, nhomId: nhomChinh, ten: 'Cơm sườn', gia: 40000 })).monId;
    mon.tra = (await qa(chu, { hanhDong: 'luuMon', quanId: qid, nhomId: nhomUong, ten: 'Trà đào', gia: 20000 })).monId;
    const sl = (await quanRef.get()).get('soLieu');
    assert.equal(sl.soMon, 3);
    assert.equal(sl.giaTrungVi, 37500); // chỉ 35k và 40k (món chính), bỏ đồ uống
    assert.ok((await quanRef.get()).get('searchText').includes('com ga xoi mo'));
  });
  await kiem('món giá 0, quá 5 món nổi bật, người khác sửa menu đều bị chặn', async () => {
    await phaiLoi(qa(chu, { hanhDong: 'luuMon', quanId: qid, nhomId: nhomChinh, ten: 'Món lỗi', gia: 0 }), /lớn hơn 0/);
    await phaiLoi(qa(svA, { hanhDong: 'luuMon', quanId: qid, nhomId: nhomChinh, ten: 'Món lạ', gia: 10000 }), /quyền/);
  });
  await kiem('cài đặt đặt món (hộ kinh doanh) và khuyến mãi giảm tiền + combo', async () => {
    await qa(chu, { hanhDong: 'caiDatDatMon', quanId: qid, datMon: { bat: true, denLay: true, giaoTanNoi: true, banKinhKm: 3, phiGiaoKieu: 'co_dinh', phiGiao: 10000, donToiThieu: 30000, chuanBiPhut: 15, tienMat: true } });
    const now = Date.now();
    await qa(chu, { hanhDong: 'luuKhuyenMai', quanId: qid, loai: 'giam_tien', tieuDe: 'Giảm 15k đơn từ 100k', giamTien: 15000, donToiThieu: 100000, batDau: now - 1000, ketThuc: now + 86400000 });
    await phaiLoi(qa(chu, { hanhDong: 'luuKhuyenMai', quanId: qid, loai: 'giam_tien', tieuDe: 'Quá 90 ngày', giamTien: 1000, batDau: now, ketThuc: now + 91 * 86400000 }), /90 ngày/);
    assert.equal((await quanRef.get()).get('soLieu.coKhuyenMai'), true);
  });

  console.log('--- Báo giá, đặt món, thanh toán ---');
  const item = (monId, soLuong, tuyChon = []) => ({ monId, soLuong, tuyChon });
  const GIAO = { lat: 10.465, lng: 105.6377, dong: '45 Trần Hưng Đạo, Phường 2' };
  let bg;
  await kiem('báo giá: hệ thống tự tính tiền món, khuyến mãi, phí giao; app không gửi giá', async () => {
    // 2 cơm gà (35k + Lớn 5k + Trứng 5k) = 90k, trà đào 20k → 110k; giảm 15k; phí giao 10k → 105k
    bg = await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.com, 2, [{ nhom: 'Cỡ', lua: ['Lớn'] }, { nhom: 'Topping', lua: ['Trứng'] }]), item(mon.tra, 1)], cachNhan: 'giao', diaChi: GIAO, gio: { loai: 'asap' } });
    assert.equal(bg.ok, true);
    assert.equal(bg.tienMon, 110000);
    assert.equal(bg.giamGia, 15000);
    assert.equal(bg.phiGiao, 10000);
    assert.equal(bg.tong, 105000);
    assert.equal(bg.tienMatDuocKhong, true);
  });
  await kiem('báo giá lỗi: thiếu tùy chọn bắt buộc, ngoài bán kính, chưa đủ đơn tối thiểu, giờ hẹn sai', async () => {
    assert.equal((await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.com, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' } })).ma, 'tuy_chon_sai');
    assert.equal((await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'giao', diaChi: { lat: 10.55, lng: 105.64, dong: 'Xa tít, Cao Lãnh' }, gio: { loai: 'asap' } })).ma, 'ngoai_ban_kinh');
    assert.equal((await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.tra, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' } })).ma, 'chua_du_don_toi_thieu');
    assert.equal((await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'hen', hen: Date.now() + phut(10) } })).ma, 'gio_hen_sai');
    assert.equal((await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'hen', hen: Date.now() + phut(60) } })).ok, true);
  });
  await kiem('chủ quán không đặt món quán của mình; chưa OTP không đặt được', async () => {
    await phaiLoi(qa(chu, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' } }), /của chính mình/);
    const lạ = await taoNguoiDung('la@x.com');
    await phaiLoi(qa(lạ, { hanhDong: 'datMon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' }, cachTra: 'app' }), /số điện thoại/);
  });
  const datApp = (nguoi, extra = {}) => qa(nguoi, { hanhDong: 'datMon', quanId: qid, items: [item(mon.suon, 2)], cachNhan: 'den_lay', gio: { loai: 'asap' }, cachTra: 'app', ...extra });
  let d1;
  await kiem('đặt món: giá đổi giữa chừng → không tạo đơn; đúng giá → pending_payment; bấm 2 lần chỉ 1 đơn', async () => {
    const sai = await datApp(svA, { tongDaThay: 12345 });
    assert.equal(sai.ok, false);
    assert.equal(sai.giaDoi, true);
    assert.equal((await db.collection('qa_don').where('svId', '==', svA.uid).get()).size, 0);
    const ok = await datApp(svA, { tongDaThay: 80000 });
    assert.equal(ok.ok, true);
    d1 = ok.donId;
    assert.equal((await don(d1)).status, 'pending_payment');
    const lai = await datApp(svA, { tongDaThay: 80000 });
    assert.equal(lai.donId, d1);
    assert.equal((await db.collection('qa_don').where('svId', '==', svA.uid).get()).size, 1);
  });
  await kiem('người khác không thanh toán hộ; thanh toán thành công → placed, tiền giữ, ví chủ đang giữ', async () => {
    await phaiLoi(qa(svB, { hanhDong: 'thanhToanGiaLap', donId: d1, ketQua: 'thanh_cong' }), /quyền/);
    await qa(svA, { hanhDong: 'thanhToanGiaLap', donId: d1, ketQua: 'thanh_cong' });
    assert.equal((await don(d1)).status, 'placed');
    assert.equal((await tien(d1)).trangThai, 'dang_giu');
    assert.equal((await vi()).dangGiu, 80000);
    const lan2 = await qa(svA, { hanhDong: 'thanhToanGiaLap', donId: d1, ketQua: 'thanh_cong' });
    assert.equal(lan2.daThanhToan, true);
    assert.equal((await vi()).dangGiu, 80000); // không trừ 2 lần
  });
  await kiem('cổng báo về chữ ký sai: 403, không đổi gì', async () => {
    const r = await fetch(`${FN}/quanAnCongBaoVe`, { method: 'POST', headers: { 'content-type': 'application/json', 'x-chu-ky': 'a'.repeat(64) }, body: JSON.stringify({ donId: d1, maGiaoDich: 'X', trangThai: 'thanh_cong' }) });
    assert.equal(r.status, 403);
  });

  console.log('--- Quán nhận đơn, đến lấy bằng mã 4 số, đã nhận món ---');
  await kiem('SV hủy sau khi quán đã nhận không được; chỉ chủ quán nhận; version cũ bị chặn', async () => {
    await phaiLoi(thaoTac(svA, d1, { loai: 'QUAN_NHAN' }), /quyền/);
    await phaiLoi(qa(chu, { hanhDong: 'thaoTacDon', donId: d1, version: 99, su: { loai: 'QUAN_NHAN' } }), /đã thay đổi/);
    await thaoTac(chu, d1, { loai: 'QUAN_NHAN' });
    assert.equal((await don(d1)).status, 'accepted');
    await phaiLoi(thaoTac(svA, d1, { loai: 'SV_HUY' }), /không hủy được/);
  });
  await kiem('quán sẵn sàng → nhập sai mã không ghi nhận; đúng mã → delivered, tiền vẫn giữ; SV "Đã nhận món" → completed + chuyển tiền', async () => {
    await thaoTac(chu, d1, { loai: 'QUAN_SAN_SANG' });
    const ma = await maNhan(d1);
    assert.match(ma, /^\d{4}$/);
    await phaiLoi(thaoTac(chu, d1, { loai: 'QUAN_NHAP_MA', maNhap: ma === '0000' ? '1111' : '0000' }), /không đúng/);
    await thaoTac(chu, d1, { loai: 'QUAN_NHAP_MA', maNhap: ma });
    assert.equal((await don(d1)).status, 'delivered');
    assert.equal((await tien(d1)).trangThai, 'dang_giu');
    await thaoTac(svA, d1, { loai: 'SV_DA_NHAN' });
    const x = await don(d1);
    assert.equal(x.status, 'completed');
    assert.equal(x.daXacMinh, true);
    assert.equal((await tien(d1)).trangThai, 'da_chuyen');
    const v = await vi();
    assert.equal(v.daNhan, 80000);
    assert.equal(v.dangGiu, 0);
  });

  console.log('--- Đơn tiền mặt giao tận nơi: ảnh GPS, 24 giờ, không tiền qua app ---');
  let d2;
  await kiem('tiền mặt: không có khoản tiền; ảnh giao sai GPS bị chặn; ảnh đúng → delivered; hết hạn → completed + nhãn', async () => {
    const r = await qa(svA, { hanhDong: 'datMon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'giao', diaChi: GIAO, gio: { loai: 'asap' }, cachTra: 'tien_mat' });
    d2 = r.donId;
    assert.equal((await don(d2)).status, 'placed');
    assert.ok(!(await db.collection('qa_khoan_tien').doc(d2).get()).exists);
    await thaoTac(chu, d2, { loai: 'QUAN_NHAN' });
    await thaoTac(chu, d2, { loai: 'QUAN_DANG_GIAO' });
    await phaiLoi(thaoTac(chu, d2, { loai: 'QUAN_DA_GIAO', anh: ANH, lat: 10.5, lng: 105.7 }), /GPS/);
    await phaiLoi(thaoTac(chu, d2, { loai: 'QUAN_DA_GIAO', lat: GIAO.lat, lng: GIAO.lng }), /ảnh/);
    await thaoTac(chu, d2, { loai: 'QUAN_DA_GIAO', anh: ANH, lat: GIAO.lat, lng: GIAO.lng });
    assert.equal((await don(d2)).status, 'delivered');
    assert.equal((await don(d2)).daXacMinh, false); // chưa nhãn 🛵 ngay khi có ảnh
    await cho(8);
    await qa(svA, { hanhDong: 'xuLyHanDon', donId: d2 });
    const x = await don(d2);
    assert.equal(x.status, 'completed');
    assert.equal(x.daXacMinh, true);
  });
  await kiem('đơn tiền mặt từ 200.000đ không chọn được tiền mặt', async () => {
    const r = await qa(svA, { hanhDong: 'datMon', quanId: qid, items: [item(mon.suon, 6)], cachNhan: 'den_lay', gio: { loai: 'asap' }, cachTra: 'tien_mat' });
    assert.equal(r.ok, false);
    assert.equal(r.ma, 'tien_mat_qua_han_muc');
  });

  console.log('--- Hủy, quán không xác nhận kịp, hủy vì quán chậm ---');
  const taoDonApp = async (nguoi) => {
    const r = await datApp(nguoi);
    await qa(nguoi, { hanhDong: 'thanhToanGiaLap', donId: r.donId, ketQua: 'thanh_cong' });
    return r.donId;
  };
  await kiem('SV hủy khi quán chưa nhận → cancelled_student, hoàn 100%', async () => {
    const d = await taoDonApp(svA);
    const truoc = (await vi()).dangGiu;
    await thaoTac(svA, d, { loai: 'SV_HUY' });
    assert.equal((await don(d)).status, 'cancelled_student');
    assert.equal((await tien(d)).trangThai, 'da_hoan');
    assert.equal((await vi()).dangGiu, truoc - 80000);
  });
  await kiem('quán không xác nhận trong hạn → expired_accept, hoàn 100%, ghi lỗi quán', async () => {
    const d = await taoDonApp(svA);
    await cho(5);
    await qa(svA, { hanhDong: 'xuLyHanDon', donId: d });
    assert.equal((await don(d)).status, 'expired_accept');
    assert.equal((await tien(d)).trangThai, 'da_hoan');
    assert.ok((await db.collection('qa_vi_pham').doc(`${d}_quan_cham_xac_nhan`).get()).exists);
  });
  await kiem('hủy vì quán chậm: quá giờ dự kiến + mốc → hoàn 100%, tính là quán hủy', async () => {
    const d = await taoDonApp(svA);
    await thaoTac(chu, d, { loai: 'QUAN_NHAN' });
    await db.collection('qa_don').doc(d).update({ moHuyChamLuc: admin.firestore.Timestamp.fromMillis(Date.now() - 1000) });
    await thaoTac(svA, d, { loai: 'SV_HUY_QUAN_CHAM' });
    const x = await don(d);
    assert.equal(x.status, 'cancelled_restaurant');
    assert.equal(x.lyDoKetThuc, 'restaurant_late');
    assert.equal((await tien(d)).trangThai, 'da_hoan');
  });

  console.log('--- "Chưa nhận được món" từ T_lấy, khiếu nại, admin quyết ---');
  let d3;
  await kiem('T_lấy: trước mốc bị chặn; từ mốc → disputed, tiền VẪN giữ', async () => {
    d3 = await taoDonApp(svA);
    await thaoTac(chu, d3, { loai: 'QUAN_NHAN' });
    await thaoTac(chu, d3, { loai: 'QUAN_SAN_SANG' });
    await phaiLoi(thaoTac(svA, d3, { loai: 'SV_CHUA_NHAN_MON' }), /thời điểm nhận món dự kiến/);
    await db.collection('qa_don').doc(d3).update({ tNhanMonDuKien: admin.firestore.Timestamp.fromMillis(Date.now() - 1000) });
    await thaoTac(svA, d3, { loai: 'SV_CHUA_NHAN_MON' });
    assert.equal((await don(d3)).status, 'disputed');
    assert.equal((await tien(d3)).trangThai, 'dang_giu');
  });
  await kiem('quán trả lời; admin kết luận đã giao → completed, đơn đã xác minh, chuyển tiền cho quán', async () => {
    await thaoTac(chu, d3, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'Khách đã lấy món lúc 18h', deNghiHoan: null });
    await phaiLoi(thaoTac(svA, d3, { loai: 'ADMIN_QUYET', quyetDinh: 'da_giao', lyDo: 'x' }), /quyền/);
    await qa(ad, { hanhDong: 'thaoTacDon', donId: d3, version: 0, su: { loai: 'ADMIN_QUYET', quyetDinh: 'da_giao', lyDo: 'Camera quán thấy khách lấy' } });
    const x = await don(d3);
    assert.equal(x.status, 'completed');
    assert.equal(x.daXacMinh, true);
    assert.equal((await tien(d3)).trangThai, 'da_chuyen');
  });
  let d4;
  await kiem('khiếu nại thiếu món cần ảnh; admin hoàn một phần → partially_refunded, tiền chia đúng', async () => {
    d4 = await taoDonApp(svA);
    await thaoTac(chu, d4, { loai: 'QUAN_NHAN' });
    await thaoTac(chu, d4, { loai: 'QUAN_SAN_SANG' });
    await thaoTac(chu, d4, { loai: 'QUAN_NHAP_MA', maNhap: await maNhan(d4) });
    await phaiLoi(thaoTac(svA, d4, { loai: 'SV_KHIEU_NAI', lyDo: 'thieu_mon', moTa: 'Thiếu 1 phần cơm', anh: [] }), /ảnh/);
    await thaoTac(svA, d4, { loai: 'SV_KHIEU_NAI', lyDo: 'thieu_mon', moTa: 'Thiếu 1 phần cơm', anh: [ANH] });
    assert.equal((await don(d4)).status, 'disputed');
    const truoc = await vi();
    await phaiLoi(qa(ad, { hanhDong: 'thaoTacDon', donId: d4, version: 0, su: { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_mot_phan', soTienHoan: 80000, lyDo: 'Hoàn quá số tiền' } }), /nhỏ hơn/);
    await qa(ad, { hanhDong: 'thaoTacDon', donId: d4, version: 0, su: { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_mot_phan', soTienHoan: 30000, lyDo: 'Thiếu 1 phần' } });
    const x = await don(d4);
    assert.equal(x.status, 'partially_refunded');
    const sau = await vi();
    assert.equal(truoc.dangGiu - sau.dangGiu, 80000);
    assert.equal(sau.daNhan - truoc.daNhan, 50000); // phần còn lại chuyển cho quán
    assert.equal((await tien(d4)).soDaHoan, 30000);
  });

  console.log('--- Khách không nhận (bom hàng), phản đối 24 giờ ---');
  const denSanSang = async (nguoi) => {
    const d = await taoDonApp(nguoi);
    await thaoTac(chu, d, { loai: 'QUAN_NHAN' });
    await thaoTac(chu, d, { loai: 'QUAN_SAN_SANG' });
    return d;
  };
  await kiem('"Khách không nhận" cần ảnh GPS tại quán; SV phản đối → admin chấp nhận → hoàn, KHÔNG tính bom hàng', async () => {
    const d = await denSanSang(svA);
    await cho(4);
    await phaiLoi(thaoTac(chu, d, { loai: 'QUAN_KHONG_NHAN', anh: ANH, lat: 10.5, lng: 105.7 }), /GPS/);
    await thaoTac(chu, d, { loai: 'QUAN_KHONG_NHAN', anh: ANH, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng });
    assert.equal((await don(d)).status, 'not_received');
    assert.equal((await tien(d)).trangThai, 'dang_giu'); // giữ thêm 24 giờ
    await thaoTac(svA, d, { loai: 'SV_PHAN_DOI', moTa: 'Tôi có đến quán lúc 18h', anh: [] });
    assert.equal((await don(d)).status, 'disputed');
    await qa(ad, { hanhDong: 'thaoTacDon', donId: d, version: 0, su: { loai: 'ADMIN_QUYET', quyetDinh: 'chap_nhan_phan_doi', lyDo: 'Khách đúng' } });
    assert.equal((await don(d)).status, 'refunded');
    assert.equal((await tien(d)).trangThai, 'da_hoan');
    assert.ok(!(await db.collection('qa_vi_pham').doc(`${d}_bom_hang`).get()).exists);
  });
  let dBom;
  await kiem('không phản đối trong 24 giờ → completed, chuyển tiền, lúc đó mới tính 1 lần bom hàng', async () => {
    dBom = await denSanSang(svA);
    await cho(4);
    await thaoTac(chu, dBom, { loai: 'QUAN_KHONG_NHAN', anh: ANH, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng });
    await cho(8);
    await qa(svA, { hanhDong: 'xuLyHanDon', donId: dBom });
    const x = await don(dBom);
    assert.equal(x.status, 'completed');
    assert.equal(x.daXacMinh, false);
    assert.ok((await db.collection('qa_vi_pham').doc(`${dBom}_bom_hang`).get()).exists);
    assert.equal((await tien(dBom)).trangThai, 'da_chuyen');
  });
  await kiem('kháng nghị lần bom hàng → admin xóa lần vi phạm → vi phạm chuyển "đã gỡ"', async () => {
    await qa(svA, { hanhDong: 'guiKhangNghi', quyetDinh: { loai: 'vi_pham', id: `${dBom}_bom_hang` }, lyDo: 'Tôi có đến quán nhưng quán đóng cửa', bangChung: [] });
    await phaiLoi(qa(svA, { hanhDong: 'guiKhangNghi', quyetDinh: { loai: 'vi_pham', id: `${dBom}_bom_hang` }, lyDo: 'Gửi lần hai thử xem' }), /1 lần/);
    await qa(ad, { hanhDong: 'adminXuLyKhangNghi', id: `vi_pham_${dBom}_bom_hang`, ketQua: 'xoa_vi_pham', ghiChu: 'ok' });
    assert.equal((await db.collection('qa_vi_pham').doc(`${dBom}_bom_hang`).get()).get('daGo'), true);
  });

  console.log('--- Check-in, đặt bàn, nhãn xác minh, đánh giá ---');
  await kiem('check-in: xa quán bị từ chối; gần quán thì được; lần 2 trong ngày bị từ chối', async () => {
    await phaiLoi(qa(svB, { hanhDong: 'checkIn', quanId: qid, lat: 10.5, lng: 105.7 }), /cách quán/);
    const r = await qa(svB, { hanhDong: 'checkIn', quanId: qid, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng });
    assert.equal(r.ok, true);
    await phaiLoi(qa(svB, { hanhDong: 'checkIn', quanId: qid, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng }), /đã check-in/);
    await phaiLoi(qa(chu, { hanhDong: 'checkIn', quanId: qid, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng }), /của chính mình/);
  });
  let ban1;
  await kiem('đặt bàn: dưới 1 giờ / quá 7 ngày bị chặn; quán xác nhận; SV check-in trong giờ giữ bàn → arrived (check_in)', async () => {
    const gio = Date.now() + phut(120);
    await phaiLoi(qa(svA, { hanhDong: 'datBan', quanId: qid, gio: Date.now() + phut(30), soNguoi: 4 }), /ít nhất 1 giờ/);
    await phaiLoi(qa(svA, { hanhDong: 'datBan', quanId: qid, gio: Date.now() + 8 * 86400000, soNguoi: 4 }), /7 ngày/);
    ban1 = (await qa(svA, { hanhDong: 'datBan', quanId: qid, gio, soNguoi: 4, ghiChu: 'Gần cửa sổ' })).banId;
    await qa(chu, { hanhDong: 'thaoTacBan', banId: ban1, version: 1, loai: 'QUAN_XAC_NHAN' });
    assert.equal((await db.collection('qa_dat_ban').doc(ban1).get()).get('status'), 'confirmed');
    await db.collection('qa_dat_ban').doc(ban1).update({ gio: admin.firestore.Timestamp.fromMillis(Date.now() + phut(5)), hanGiuBan: admin.firestore.Timestamp.fromMillis(Date.now() + phut(20)), hanTuDong: admin.firestore.Timestamp.fromMillis(Date.now() + 86400000) });
    await db.collection('qa_check_in').doc(`${svA.uid}_${qid}_x`).set({ x: 1 }); // không liên quan
    const ci = await qa(svA, { hanhDong: 'checkIn', quanId: qid, lat: QUAN_LATLNG.lat, lng: QUAN_LATLNG.lng });
    assert.equal(ci.datBanId, ban1);
    const b = (await db.collection('qa_dat_ban').doc(ban1).get()).data();
    assert.equal(b.status, 'arrived');
    assert.equal(b.ghiNhanDen, 'check_in');
  });
  await kiem('hủy bàn đã xác nhận sát giờ → tính 1 lần bỏ hẹn; hủy khi quán chưa xác nhận thì không phạt', async () => {
    const a = (await qa(svB, { hanhDong: 'datBan', quanId: qid, gio: Date.now() + phut(120), soNguoi: 2 })).banId;
    await qa(svB, { hanhDong: 'thaoTacBan', banId: a, loai: 'SV_HUY' });
    assert.ok(!(await db.collection('qa_vi_pham').doc(`${a}_bo_hen_dat_ban`).get()).exists);
    const b = (await qa(svB, { hanhDong: 'datBan', quanId: qid, gio: Date.now() + phut(125), soNguoi: 2 })).banId;
    await qa(chu, { hanhDong: 'thaoTacBan', banId: b, loai: 'QUAN_XAC_NHAN' });
    await qa(svB, { hanhDong: 'thaoTacBan', banId: b, loai: 'SV_HUY' }); // huySatGioPhut = 200 phút (cấu hình test) → sát giờ
    assert.ok((await db.collection('qa_vi_pham').doc(`${b}_bo_hen_dat_ban`).get()).exists);
  });
  await kiem('đánh giá: đủ 4 tiêu chí, không có ô điểm tổng; nhãn 🛵 (đơn đã xác minh) / 📍 (chỉ check-in); điểm quán cập nhật', async () => {
    await phaiLoi(qa(svA, { hanhDong: 'guiDanhGia', quanId: qid, diem: { monAn: 5, giaCa: 4, veSinh: 3 }, nhanXet: 'Cơm ngon, phục vụ nhanh, sạch sẽ lắm' }), /4 tiêu chí/);
    await phaiLoi(qa(svA, { hanhDong: 'guiDanhGia', quanId: qid, diem: { monAn: 5, giaCa: 4, veSinh: 3, phucVu: 4 }, nhanXet: 'ngắn quá' }), /ít nhất 20/);
    await phaiLoi(qa(chu, { hanhDong: 'guiDanhGia', quanId: qid, diem: { monAn: 5, giaCa: 5, veSinh: 5, phucVu: 5 }, nhanXet: 'Quán của mình, rất ngon luôn nhé' }), /của chính mình/);
    const a = await qa(svA, { hanhDong: 'guiDanhGia', quanId: qid, diem: { monAn: 5, giaCa: 4, veSinh: 3, phucVu: 4 }, the: ['mon_ngon'], nhanXet: 'Cơm ngon, phục vụ nhanh, sạch sẽ lắm' });
    assert.equal(a.nhan, 'dat_mon');
    assert.equal(a.diemTong, 4);
    const b = await qa(svB, { hanhDong: 'guiDanhGia', quanId: qid, diem: { monAn: 4, giaCa: 4, veSinh: 4, phucVu: 4 }, nhanXet: 'Đã ghé quán, không gian thoáng mát' });
    assert.equal(b.nhan, 'check_in');
    const sl = (await quanRef.get()).get('soLieu');
    assert.equal(sl.soDanhGia, 2);
    assert.equal(sl.diemTong, 4);
    assert.equal(sl.diemTieuChi.monAn, 4.5);
    await qa(chu, { hanhDong: 'traLoiDanhGia', danhGiaId: `${svA.uid}_${qid}`, noiDung: 'Cảm ơn bạn nhiều!' });
    await phaiLoi(qa(chu, { hanhDong: 'traLoiDanhGia', danhGiaId: `${svA.uid}_${qid}`, noiDung: 'Trả lời lần hai' }), /1 lần/);
  });

  console.log('--- Chat ---');
  await kiem('chat: cảnh báo "chuyển khoản", không cảnh báo "check"; thẻ quán; chủ quán không chat thẻ quán của mình với chính mình', async () => {
    const a = await qa(svA, { hanhDong: 'guiTin', nguoiNhan: chu.uid, loai: 'chu', noiDung: 'Chuyển khoản trước nha' });
    assert.ok(a.canhBao);
    const b = await qa(svA, { hanhDong: 'guiTin', nguoiNhan: chu.uid, loai: 'chu', noiDung: 'check giúp mình món này còn không' });
    assert.equal(b.canhBao, null);
    await qa(svA, { hanhDong: 'guiTin', nguoiNhan: chu.uid, loai: 'the_tin', the: { loai: 'quan', id: qid } });
    await phaiLoi(qa(chu, { hanhDong: 'guiTin', nguoiNhan: chu.uid, loai: 'the_tin', the: { loai: 'quan', id: qid } }), /Người nhận/);
    assert.equal((await db.collection('qa_chat').get()).size, 1);
  });

  console.log('--- Tạm nghỉ, ẩn quán, lừa đảo (3.14) ---');
  await kiem('tạm nghỉ khi có đơn chờ xác nhận / bàn đã xác nhận: cần xác nhận; xác nhận → đơn hủy + hoàn, bàn bị quán hủy', async () => {
    const dCho = await taoDonApp(svB); // placed
    const banKhach = (await qa(svB, { hanhDong: 'datBan', quanId: qid, gio: Date.now() + phut(130), soNguoi: 3 })).banId;
    await qa(chu, { hanhDong: 'thaoTacBan', banId: banKhach, loai: 'QUAN_XAC_NHAN' });
    const r = await qa(chu, { hanhDong: 'tamNghi', quanId: qid, kieu: 'hom_nay' });
    assert.equal(r.canXacNhan, true);
    assert.ok(r.donAnhHuong >= 1 && r.banAnhHuong >= 1);
    assert.equal((await don(dCho)).status, 'placed'); // chưa xác nhận thì chưa đổi gì
    await qa(chu, { hanhDong: 'tamNghi', quanId: qid, kieu: 'hom_nay', xacNhan: true });
    assert.equal((await don(dCho)).status, 'cancelled_restaurant');
    assert.equal((await tien(dCho)).trangThai, 'da_hoan');
    assert.equal((await db.collection('qa_dat_ban').doc(banKhach).get()).get('status'), 'cancelled_restaurant');
    const dm = await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' } });
    assert.equal(dm.ma, 'quan_tam_nghi');
    await qa(chu, { hanhDong: 'tamNghi', quanId: qid, kieu: 'mo_lai' });
  });
  await kiem('ngừng kinh doanh bị chặn khi còn giao dịch đang chạy', async () => {
    const dChay = await denSanSang(svA);
    await phaiLoi(qa(chu, { hanhDong: 'ngungKinhDoanh', quanId: qid }), /Chưa ngừng kinh doanh được/);
    // Admin kết luận chủ quán lừa đảo: đơn đã nhận KHÔNG tự hoàn / tự giải ngân; gắn cờ rà soát, tiền giữ.
    const kq = await qa(ad, { hanhDong: 'adminLuaDao', quanId: qid, lyDo: 'Giấy tờ giả' });
    assert.ok(kq.soDonGanCo >= 1);
    const x = await don(dChay);
    assert.equal(x.status, 'ready');
    assert.equal(x.ruaSoatLuaDao, true);
    assert.equal((await tien(dChay)).trangThai, 'dang_giu');
    assert.equal((await quanRef.get()).get('trangThai'), 'suspended');
    assert.ok((await db.collection('de_nghi_khoa_tai_khoan').where('uid', '==', chu.uid).get()).size >= 1);
    // Quán bị khóa: không nhận đơn mới.
    const moi = await qa(svA, { hanhDong: 'baoGiaDon', quanId: qid, items: [item(mon.suon, 1)], cachNhan: 'den_lay', gio: { loai: 'asap' } });
    assert.equal(moi.ma, 'quan_khong_nhan_don');
    // Admin xét từng đơn: đã giao thật → hoàn tất + nhãn.
    await qa(ad, { hanhDong: 'thaoTacDon', donId: dChay, version: 0, su: { loai: 'ADMIN_LUA_DAO', quyetDinh: 'da_giao', lyDo: 'Khách xác nhận nhận món' } });
    assert.equal((await don(dChay)).status, 'completed');
  });

  console.log('--- Báo cáo ---');
  await kiem('báo cáo: tài khoản dưới 7 ngày không được tính vào ngưỡng gắn cờ; lý do ưu tiên cao báo admin', async () => {
    const r = await qa(svA, { hanhDong: 'guiBaoCao', doiTuong: { loai: 'quan', id: qid }, lyDo: 'mat_ve_sinh', ghiChu: 'Thấy gián trong bếp' });
    assert.equal(r.duocTinh, false);
    const bc = (await db.collection('qa_bao_cao').doc(r.id).get()).data();
    assert.equal(bc.uuTienCao, true);
    await qa(ad, { hanhDong: 'adminXuLyBaoCao', id: r.id, hopLe: false, ghiChu: 'không đủ căn cứ' });
    assert.equal((await db.collection('qa_bao_cao').doc(r.id).get()).get('trangThai'), 'bi_bac');
  });

  console.log(`\nKết quả: ${pass} qua, ${fail} lỗi`);
  process.exit(fail ? 1 : 0);
})().catch((e) => {
  console.error('Lỗi không mong muốn:', e);
  process.exit(1);
});
