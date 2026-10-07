'use strict';

/**
 * Kiểm thử luồng Tìm trọ trên Firebase Emulator (Auth + Firestore + Functions).
 * Chạy từ thư mục gốc repo:
 *   npx firebase emulators:exec --only auth,firestore,functions --project demo-app-sinh-vien \
 *     "node functions/test-e2e/tro_luong.e2e.js"
 */

const assert = require('node:assert/strict');
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
const admin = require('../node_modules/firebase-admin');

const PROJECT = process.env.GCLOUD_PROJECT || 'demo-app-sinh-vien';
admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const FN = `http://127.0.0.1:5001/${PROJECT}/us-central1`;
const AUTH = `http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1`;

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
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${nguoi.token}` },
    body: JSON.stringify({ data }),
  }).then((x) => x.json());
  if (r.error) {
    const e = new Error(r.error.message);
    e.code = r.error.status;
    throw e;
  }
  return r.result;
}

const tro = (n, d) => goi('troApi', n, d);
const tk = (n, d) => goi('taiKhoanApi', n, d);
const cho = (giay) => new Promise((r) => setTimeout(r, giay * 1000));
async function phaiLoi(p, khop) {
  try {
    await p;
  } catch (e) {
    if (khop) assert.match(e.message, khop);
    return e;
  }
  throw new Error('Đáng lẽ phải bị chặn');
}

const ANH = ['https://x.com/1.jpg', 'https://x.com/2.jpg', 'https://x.com/3.jpg'];

(async () => {
  const chu = await taoNguoiDung('chu@x.com');
  const svA = await taoNguoiDung('sva@x.com');
  const svB = await taoNguoiDung('svb@x.com');
  const ad = await taoNguoiDung('admin@x.com');
  await db.collection('admins').doc(ad.uid).set({ tro: true, danhTinh: true });
  // Rút ngắn thời hạn để test nhanh (mục 2.23: được rút ngắn qua cấu hình).
  await db.collection('tro_cau_hinh').doc('hien_hanh').set({ nhanPhongSauItNhatPhut: 0.05, tuHoanTatPhut: 0.15, anHanKhongDenPhut: 0 });

  console.log('--- Tài khoản: OTP thử nghiệm, xác nhận người thật ---');
  await kiem('chưa OTP thì không đặt cọc được', () => phaiLoi(tro(svA, { hanhDong: 'thongTinDatCoc' }), /số điện thoại/));
  await kiem('số điện thoại sai định dạng bị chặn', () => phaiLoi(tk(chu, { hanhDong: 'guiOtp', sdt: '123' }), /không hợp lệ/));
  await kiem('OTP: sai mã báo còn lượt, đúng mã 123456 thì xác thực', async () => {
    await tk(chu, { hanhDong: 'guiOtp', sdt: '0901000001' });
    await phaiLoi(tk(chu, { hanhDong: 'xacNhanOtp', ma: '000000' }), /còn 4 lần/);
    const r = await tk(chu, { hanhDong: 'xacNhanOtp', ma: '123456' });
    assert.equal(r.sdt, '0901000001');
  });
  await kiem('1 số điện thoại chỉ gắn 1 tài khoản', () => phaiLoi(tk(svA, { hanhDong: 'guiOtp', sdt: '0901000001' }), /tài khoản khác/));
  for (const [n, sdt] of [[svA, '0902000002'], [svB, '0903000003']]) {
    await tk(n, { hanhDong: 'guiOtp', sdt });
    await tk(n, { hanhDong: 'xacNhanOtp', ma: '123456' });
  }
  await kiem('xác nhận người thật: CCCD 12 số, chỉ lưu băm + 4 số cuối, admin duyệt', async () => {
    await phaiLoi(tk(chu, { hanhDong: 'guiXacThucDanhTinh', hoTen: 'Nguyễn Văn Chủ', soCccd: '123', dongYXuLyDuLieu: true, camKet: true }), /12 chữ số/);
    await tk(chu, { hanhDong: 'guiXacThucDanhTinh', hoTen: 'Nguyễn Văn Chủ', soCccd: '087123456789', dongYXuLyDuLieu: true, camKet: true });
    const xt = (await db.collection('xac_thuc').doc(chu.uid).get()).data();
    assert.equal(xt.cccd4, '6789');
    assert.ok(!JSON.stringify(xt).includes('087123456789'));
    await tk(ad, { hanhDong: 'adminDuyetDanhTinh', uid: chu.uid, dongY: true });
    assert.equal((await db.collection('xac_thuc').doc(chu.uid).get()).get('danhTinh'), 'da_xac_thuc');
  });

  console.log('--- Nhà trọ, phòng, duyệt ---');
  const nhaRef = db.collection('nha_tro').doc();
  await nhaRef.set({
    chuTroId: chu.uid, trangThai: 'draft', ten: 'Nhà trọ Hoàng Anh', loaiHinh: 'phong', tongSoPhong: 5, soTang: 2,
    tienIchChung: ['wifi', 'cho_de_xe'], noiQuy: { gioGiac: 'gioi_han', gioDongCua: '23:00', thuCung: true, oQuaDem: false, baoTruocTuan: 2 },
    moTa: 'Nhà trọ sạch sẽ, gần Đại học Đồng Tháp, an ninh tốt, có chỗ để xe.', diaChi: '12 Nguyễn Huệ, Phường 1, Cao Lãnh',
    phuong: 'Phường 1', viTri: new admin.firestore.GeoPoint(10.4599, 105.6377), anh: ANH, video: ['https://x.com/v.mp4'], anhBia: ANH[0],
    camKet: true,
  });
  await nhaRef.collection('rieng').doc('giay_to').set({ giayTo: ['https://x.com/giay.jpg'] });
  const phongRef = db.collection('phong_tro').doc();
  await phongRef.set({
    nhaTroId: nhaRef.id, chuTroId: chu.uid, trangThai: 'draft', ten: 'P.101', coGac: true, dienTich: 18, dienTichGac: 8,
    soNguoiToiDa: 2, tienIch: ['may_lanh'], giaThue: 1500000, tienCoc: 1000000, tienDien: { cach: 'theo_so', gia: 3500 },
    tienNuoc: { cach: 'theo_nguoi', gia: 50000 }, phiKhac: [], anh: ANH, video: ['https://x.com/p.mp4'], anhBia: ANH[1],
  });
  await kiem('nhà trọ chưa duyệt: không gửi duyệt phòng được', () => phaiLoi(tro(chu, { hanhDong: 'guiDuyetPhong', phongId: phongRef.id }), /chưa được duyệt/));
  await kiem('gửi duyệt nhà trọ → admin duyệt → active, huy hiệu xác thực nhà, có hạn 30 ngày', async () => {
    await tro(chu, { hanhDong: 'guiDuyetNhaTro', nhaTroId: nhaRef.id });
    assert.equal((await nhaRef.get()).get('trangThai'), 'pending_review');
    await phaiLoi(tro(chu, { hanhDong: 'adminDuyet', loai: 'nha_tro', id: nhaRef.id, dongY: true }), /quyền/);
    await tro(ad, { hanhDong: 'adminDuyet', loai: 'nha_tro', id: nhaRef.id, dongY: true });
    const n = (await nhaRef.get()).data();
    assert.equal(n.trangThai, 'active');
    assert.ok(n.daXacThucNha && n.hetHanLuc);
    assert.equal(n.searchText.includes('nguyen hue'), true);
  });
  await kiem('gửi duyệt phòng → admin duyệt → available, số liệu nhà trọ tự tính', async () => {
    await tro(chu, { hanhDong: 'guiDuyetPhong', phongId: phongRef.id });
    await tro(ad, { hanhDong: 'adminDuyet', loai: 'phong', id: phongRef.id, dongY: true });
    assert.equal((await phongRef.get()).get('trangThai'), 'available');
    assert.equal((await phongRef.get()).get('nhaTro.noiQuy.gioDongCua'), '23:00');
    const sl = (await nhaRef.get()).get('soLieu');
    assert.equal(sl.soPhongTrong, 1);
    assert.equal(sl.giaMin, 1500000);
  });

  console.log('--- Đặt cọc ---');
  const T = () => Date.now() + 5 * 1000;
  await kiem('chủ trọ không cọc phòng của mình', async () => {
    await tk(chu, { hanhDong: 'guiOtp', sdt: '0901000001' }).catch(() => {});
    await phaiLoi(tro(chu, { hanhDong: 'taoCoc', phongId: phongRef.id, t: T(), dongYChinhSach: true, dongYDieuKhoan: true }), /chính mình/);
  });
  await kiem('chưa đồng ý chính sách / điều khoản thì không cọc được', () =>
    phaiLoi(tro(svA, { hanhDong: 'taoCoc', phongId: phongRef.id, t: T(), dongYChinhSach: true, dongYDieuKhoan: false }), /đồng ý/));
  let coc1;
  await kiem('hai người cùng cọc: người sau báo "Đang có người thanh toán", không tạo giao dịch', async () => {
    coc1 = (await tro(svA, { hanhDong: 'taoCoc', phongId: phongRef.id, t: T(), dongYChinhSach: true, dongYDieuKhoan: true })).datCocId;
    await phaiLoi(tro(svB, { hanhDong: 'taoCoc', phongId: phongRef.id, t: T(), dongYChinhSach: true, dongYDieuKhoan: true }), /Đang có người thanh toán/);
    const cuaB = await db.collection('tro_dat_coc').where('sinhVienId', '==', svB.uid).get();
    assert.equal(cuaB.size, 0);
  });
  await kiem('bấm cọc 2 lần chỉ có 1 giao dịch', async () => {
    const lai = await tro(svA, { hanhDong: 'taoCoc', phongId: phongRef.id, t: T(), dongYChinhSach: true, dongYDieuKhoan: true });
    assert.equal(lai.datCocId, coc1);
    assert.equal(lai.daCo, true);
  });
  await kiem('người khác không thanh toán hộ được phiên của mình', () =>
    phaiLoi(tro(svB, { hanhDong: 'thanhToanGiaLap', datCocId: coc1, ketQua: 'thanh_cong' }), /quyền/));
  await kiem('thanh toán giả lập thành công → held, phòng reserved, ví chủ đang giữ, có bản chụp', async () => {
    await tro(svA, { hanhDong: 'thanhToanGiaLap', datCocId: coc1, ketQua: 'thanh_cong' });
    const d = (await db.collection('tro_dat_coc').doc(coc1).get()).data();
    assert.equal(d.status, 'held');
    assert.equal(d.chupThongTin.nhaTro.noiQuy.thuCung, true);
    assert.equal((await phongRef.get()).get('trangThai'), 'reserved');
    assert.equal((await db.collection('tro_vi').doc(chu.uid).get()).get('dangGiu'), 1000000);
    assert.equal((await db.collection('tro_khoan_tien').doc(coc1).get()).get('trangThai'), 'dang_giu');
    const tb = await db.collection('tro_thong_bao').where('nguoiNhan', '==', chu.uid).where('loai', '==', 'co_nguoi_coc').get();
    assert.equal(tb.size, 1);
  });
  await kiem('bấm thanh toán lần 2 không trừ tiền 2 lần', async () => {
    const r = await tro(svA, { hanhDong: 'thanhToanGiaLap', datCocId: coc1, ketQua: 'thanh_cong' });
    assert.equal(r.daThanhToan, true);
    assert.equal((await db.collection('tro_vi').doc(chu.uid).get()).get('dangGiu'), 1000000);
  });
  await kiem('chủ ẩn / đánh dấu cho thuê phòng đang có cọc bị chặn', async () => {
    await phaiLoi(tro(chu, { hanhDong: 'anHienPhong', phongId: phongRef.id, an: true }), /người cọc/);
    await phaiLoi(tro(chu, { hanhDong: 'daChoThueNgoaiApp', phongId: phongRef.id }), /người cọc/);
  });
  await kiem('version cũ: "Thông tin đã thay đổi, vui lòng tải lại"', () =>
    phaiLoi(tro(svA, { hanhDong: 'thaoTacCoc', datCocId: coc1, version: 1, su: { loai: 'SV_HUY' } }), /đã thay đổi/));
  await kiem('SV hủy trong 30 phút → cancelled_grace, hoàn 100%, phòng available, ví trừ đang giữ', async () => {
    const v = (await db.collection('tro_dat_coc').doc(coc1).get()).get('version');
    await tro(svA, { hanhDong: 'thaoTacCoc', datCocId: coc1, version: v, su: { loai: 'SV_HUY' } });
    assert.equal((await db.collection('tro_dat_coc').doc(coc1).get()).get('status'), 'cancelled_grace');
    assert.equal((await phongRef.get()).get('trangThai'), 'available');
    assert.equal((await db.collection('tro_vi').doc(chu.uid).get()).get('dangGiu'), 0);
    assert.equal((await db.collection('tro_khoan_tien').doc(coc1).get()).get('trangThai'), 'da_hoan');
  });
  await kiem('số lần hủy miễn phí còn lại giảm 1', async () => {
    assert.equal((await tro(svA, { hanhDong: 'thongTinDatCoc' })).conHuyMienPhi, 1);
  });

  let coc2;
  await kiem('cọc lại, tới T bấm "Đã nhận phòng" → released, rented, ví đã nhận, mở đánh giá', async () => {
    coc2 = (await tro(svB, { hanhDong: 'taoCoc', phongId: phongRef.id, t: Date.now() + 3500, dongYChinhSach: true, dongYDieuKhoan: true })).datCocId;
    await tro(svB, { hanhDong: 'thanhToanGiaLap', datCocId: coc2, ketQua: 'thanh_cong' });
    await phaiLoi(tro(svB, { hanhDong: 'thaoTacCoc', datCocId: coc2, su: { loai: 'SV_DA_NHAN' } }), /Chưa tới/);
    await cho(4);
    await tro(svB, { hanhDong: 'thaoTacCoc', datCocId: coc2, su: { loai: 'SV_DA_NHAN' } });
    const d = (await db.collection('tro_dat_coc').doc(coc2).get()).data();
    assert.equal(d.status, 'released');
    assert.equal(d.danhGia.nhan, 'da_thue');
    assert.equal((await phongRef.get()).get('trangThai'), 'rented');
    assert.equal((await db.collection('tro_vi').doc(chu.uid).get()).get('daNhan'), 1000000);
  });
  await kiem('đánh giá: nhận xét < 20 ký tự bị chặn; hợp lệ → điểm nhà trọ tính từ đánh giá có nhãn', async () => {
    await phaiLoi(tro(svB, { hanhDong: 'guiDanhGia', nguon: { loai: 'dat_coc', id: coc2 }, diem: { dungMoTa: 5 }, nhanXet: 'ngắn quá' }), /20 ký tự/);
    await tro(svB, { hanhDong: 'guiDanhGia', nguon: { loai: 'dat_coc', id: coc2 }, diem: { dungMoTa: 5, anNinh: 4 }, the: ['yen_tinh'], nhanXet: 'Phòng đúng mô tả, chủ trọ dễ tính, khu yên tĩnh.' });
    const sl = (await nhaRef.get()).get('soLieu');
    assert.equal(sl.diem, 4.5);
    assert.equal(sl.soDanhGia, 1);
    await phaiLoi(tro(svA, { hanhDong: 'guiDanhGia', nguon: { loai: 'dat_coc', id: coc2 }, diem: { dungMoTa: 1 }, nhanXet: 'Tôi không ở đây nhưng vẫn muốn chê.' }), /quyền/);
  });
  await kiem('chủ trả lời đánh giá đúng 1 lần', async () => {
    const id = `dat_coc_${coc2}`;
    await tro(chu, { hanhDong: 'traLoiDanhGia', danhGiaId: id, noiDung: 'Cảm ơn em!' });
    await phaiLoi(tro(chu, { hanhDong: 'traLoiDanhGia', danhGiaId: id, noiDung: 'Lần hai' }), /1 lần/);
  });

  console.log('--- Đăng lại, tự hoàn tất 48 giờ (rút ngắn) ---');
  await kiem('đăng lại phòng đã cho thuê (video còn mới) → available ngay', async () => {
    await tro(chu, { hanhDong: 'dangLaiPhong', phongId: phongRef.id });
    assert.equal((await phongRef.get()).get('trangThai'), 'available');
  });
  await kiem('không ai làm gì tới T + 48 giờ → tự hoàn tất, đánh giá không nhãn, không tính điểm', async () => {
    const id = (await tro(svA, { hanhDong: 'taoCoc', phongId: phongRef.id, t: Date.now() + 3500, dongYChinhSach: true, dongYDieuKhoan: true })).datCocId;
    await tro(svA, { hanhDong: 'thanhToanGiaLap', datCocId: id, ketQua: 'thanh_cong' });
    await cho(13);
    await tro(svA, { hanhDong: 'xuLyHanCoc', datCocId: id });
    const d = (await db.collection('tro_dat_coc').doc(id).get()).data();
    assert.equal(d.status, 'released');
    assert.equal(d.lyDoKetThuc, 'auto_complete');
    assert.equal(d.danhGia.tinhDiem, false);
  });

  console.log('--- Cổng thanh toán, chat ---');
  await kiem('cổng báo về với chữ ký sai → 403, không đổi gì', async () => {
    const r = await fetch(`${FN}/troCongBaoVe`, {
      method: 'POST', headers: { 'content-type': 'application/json', 'x-chu-ky': 'a'.repeat(64) },
      body: JSON.stringify({ datCocId: coc1, maGiaoDich: 'GIA', trangThai: 'thanh_cong', ghiNhanLuc: Date.now() }),
    });
    assert.equal(r.status, 403);
  });
  await kiem('chat: tin "chuyển khoản trước" có cảnh báo; "check" thì không; mỗi cặp 1 cuộc', async () => {
    const a = await tro(svA, { hanhDong: 'guiTin', nguoiNhan: chu.uid, noiDung: 'Anh cho em chuyển khoản trước nhé' });
    assert.ok(a.canhBao);
    const b = await tro(chu, { hanhDong: 'guiTin', nguoiNhan: svA.uid, noiDung: 'Em check lại lịch nhé' });
    assert.equal(b.canhBao, null);
    assert.equal(a.chatId, b.chatId);
  });
  await kiem('chặn: người bị chặn không gửi tin được nữa', async () => {
    const chatId = [svA.uid, chu.uid].sort().join('_');
    await tro(chu, { hanhDong: 'chanChat', chatId, chan: true });
    await phaiLoi(tro(svA, { hanhDong: 'guiTin', nguoiNhan: chu.uid, noiDung: 'Alo anh ơi' }), /chặn/);
  });
  await kiem('chủ trọ không mở chat thẻ tin với phòng của mình (chặn ở hệ thống)', () =>
    phaiLoi(tro(chu, { hanhDong: 'guiTin', nguoiNhan: chu.uid, loai: 'the_tin', the: { phongId: phongRef.id } })));

  console.log('--- Cọc trực tiếp ---');
  await kiem('xác nhận cọc trực tiếp → reserved, không có khoản tiền qua app; "Đã cho thuê" → rented; người cọc xác nhận trong 7 ngày', async () => {
    await tro(chu, { hanhDong: 'dangLaiPhong', phongId: phongRef.id });
    const r = await tro(chu, { hanhDong: 'xacNhanCocTrucTiep', phongId: phongRef.id, ngayNhanDuKien: Date.now() + 86400000, sdtNguoiCoc: '0903000003' });
    assert.equal((await phongRef.get()).get('trangThai'), 'reserved');
    await phaiLoi(tro(svA, { hanhDong: 'taoCoc', phongId: phongRef.id, t: Date.now() + 4000, dongYChinhSach: true, dongYDieuKhoan: true }), /không còn trống/);
    await tro(chu, { hanhDong: 'capNhatCocTrucTiep', id: r.cocTrucTiepId, ketQua: 'da_cho_thue' });
    assert.equal((await phongRef.get()).get('trangThai'), 'rented');
    await phaiLoi(tro(svA, { hanhDong: 'toiDaThuePhong', id: r.cocTrucTiepId }), /quyền/);
    await tro(svB, { hanhDong: 'toiDaThuePhong', id: r.cocTrucTiepId });
    const c = (await db.collection('tro_coc_truc_tiep').doc(r.cocTrucTiepId).get()).data();
    assert.equal(c.nguoiCocUid, svB.uid);
    assert.equal(c.danhGia.nhan, 'da_thue');
  });

  console.log(`\nKết quả: ${pass} qua, ${fail} lỗi`);
  process.exit(fail ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
