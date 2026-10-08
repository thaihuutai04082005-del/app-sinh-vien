'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const L = require('../src/quan_an/logic/don_mon');
const { MAC_DINH, PHUT, GIO } = require('../src/quan_an/config');

const cfg = MAC_DINH;
const T0 = Date.UTC(2026, 9, 7, 5, 0); // 12:00 giờ Việt Nam
const phut = (n) => n * PHUT;

const tao = (o = {}) => L.taoDon({ now: T0, cachNhan: 'den_lay', cachTra: 'app', gio: 'asap', gioHen: null, tong: 85000, ...o }, cfg);
const ap = (d, su, now, c = cfg) => L.apDung(d, su, now, c);
const tien = (r) => r.tien;

/** Đưa đơn tới trạng thái mong muốn bằng các sự kiện hợp lệ. */
function toi(trangThai, { cachNhan = 'den_lay', cachTra = 'app', gio = 'asap', gioHen = null } = {}) {
  let d = tao({ cachNhan, cachTra, gio, gioHen });
  let now = T0;
  const chay = (su, dt = 0) => {
    now += phut(dt);
    const r = ap(d, su, now);
    assert.ok(!r.loi, `${su.loai}: ${r.loi}`);
    d = r.d;
  };
  if (cachTra === 'app') chay({ loai: 'THANH_TOAN_OK', ghiNhanLuc: now }, 1);
  if (trangThai === 'placed') return { d, now };
  chay({ loai: 'QUAN_NHAN', chuanBiPhut: 15 }, 1);
  if (trangThai === 'accepted') return { d, now };
  if (cachNhan === 'den_lay') chay({ loai: 'QUAN_SAN_SANG' }, 15);
  else chay({ loai: 'QUAN_DANG_GIAO' }, 15);
  return { d, now };
}

// ------------------------------------------------------------------ Thanh toán, hết hạn

test('tạo đơn: trả trên app → chờ thanh toán 15 phút; tiền mặt → gửi quán ngay', () => {
  const a = tao();
  assert.equal(a.status, 'pending_payment');
  assert.equal(a.hanThanhToan, T0 + phut(15));
  const m = tao({ cachTra: 'tien_mat' });
  assert.equal(m.status, 'placed');
  assert.equal(m.hanQuanNhan, T0 + phut(5));
});

test('pending_payment → placed khi cổng ghi nhận đúng hạn: giữ tiền, báo quán', () => {
  const r = ap(tao(), { loai: 'THANH_TOAN_OK', ghiNhanLuc: T0 + phut(3) }, T0 + phut(3));
  assert.equal(r.d.status, 'placed');
  assert.deepEqual(tien(r), ['giu']);
  assert.equal(r.d.hanQuanNhan, T0 + phut(3) + phut(5));
  assert.ok(r.thongBao.some((t) => t.toi === 'chu' && t.loai === 'don_moi'));
});

test('cổng báo "đã trả" lần 2: chỉ ghi nhận lần đầu', () => {
  const r1 = ap(tao(), { loai: 'THANH_TOAN_OK', ghiNhanLuc: T0 }, T0);
  const r2 = ap(r1.d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: T0 }, T0 + 1000);
  assert.ok(r2.boQua);
});

test('quá 15 phút chưa trả → expired, không gửi quán', () => {
  const { d, tacDong } = L.xuLyHan(tao(), T0 + phut(16), cfg);
  assert.equal(d.status, 'expired');
  assert.deepEqual(tacDong[0].tien, ['het_han']);
});

test('tiền đến muộn sau khi hết hạn → refunded, hoàn 100%', () => {
  const { d } = L.xuLyHan(tao(), T0 + phut(16), cfg);
  const r = ap(d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: T0 + phut(20) }, T0 + phut(21));
  assert.equal(r.d.status, 'refunded');
  assert.deepEqual(tien(r), ['hoan']);
  assert.ok(r.thongBao.some((t) => t.loai === 'tien_den_muon_da_hoan'));
});

test('cổng ghi nhận trước hạn nhưng báo về sau hạn → vẫn đúng hạn', () => {
  const { d } = L.xuLyHan(tao(), T0 + phut(16), cfg, { congDaThu: { ghiNhanLuc: T0 + phut(14) } });
  assert.equal(d.status, 'placed'); // hỏi lại cổng trước khi cho hết hạn
  const r2 = ap(L.xuLyHan(tao(), T0 + phut(16), cfg).d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: T0 + phut(14) }, T0 + phut(16));
  assert.equal(r2.d.status, 'placed');
});

test('thanh toán lỗi → expired', () => {
  const r = ap(tao(), { loai: 'THANH_TOAN_LOI' }, T0 + phut(2));
  assert.equal(r.d.status, 'expired');
  assert.deepEqual(tien(r), ['that_bai']);
});

// ------------------------------------------------------------------ Quán xác nhận / từ chối / hủy

test('SV hủy khi quán chưa nhận → cancelled_student, hoàn 100%', () => {
  const { d, now } = toi('placed');
  const r = ap(d, { loai: 'SV_HUY' }, now + 1);
  assert.equal(r.d.status, 'cancelled_student');
  assert.deepEqual(tien(r), ['hoan']);
});

test('quán đã nhận: SV không hủy thường được nữa', () => {
  const { d, now } = toi('accepted');
  assert.match(ap(d, { loai: 'SV_HUY' }, now + 1).loi, /không hủy được/);
});

test('quán từ chối → rejected, hoàn 100%', () => {
  const { d, now } = toi('placed');
  const r = ap(d, { loai: 'QUAN_TU_CHOI' }, now + 1);
  assert.equal(r.d.status, 'rejected');
  assert.deepEqual(tien(r), ['hoan']);
});

test('quán không xác nhận trong 5 phút → expired_accept, hoàn 100%, ghi lỗi quán', () => {
  const { d, now } = toi('placed');
  const { d: d2, tacDong } = L.xuLyHan(d, now + phut(6), cfg);
  assert.equal(d2.status, 'expired_accept');
  assert.deepEqual(tacDong.find((t) => t.khoa === 'HET_HAN_XAC_NHAN').tien, ['hoan']);
  assert.deepEqual(tacDong.find((t) => t.khoa === 'HET_HAN_XAC_NHAN').viPhamQuan, ['quan_cham_xac_nhan']);
});

test('chuông nhắc lại sau 2 phút nếu quán chưa nhận, chỉ nhắc 1 lần', () => {
  const { d, now } = toi('placed');
  const a = L.xuLyHan(d, now + phut(2), cfg);
  assert.equal(a.tacDong.length, 1);
  assert.ok(a.tacDong[0].laNhac);
  assert.equal(L.xuLyHan(a.d, now + phut(3), cfg).tacDong.length, 0);
});

test('quán nhận: ghi giờ dự kiến sẵn sàng, mốc hủy vì quán chậm và T_lấy', () => {
  const { d, now } = toi('placed');
  const r = ap(d, { loai: 'QUAN_NHAN', chuanBiPhut: 20 }, now + phut(1));
  assert.equal(r.d.status, 'accepted');
  assert.equal(r.d.gioDuKienSanSang, now + phut(21));
  assert.equal(r.d.moHuyChamLuc, now + phut(21) + phut(30));
  assert.equal(r.d.tNhanMonDuKien, now + phut(21)); // đơn "càng sớm càng tốt" đến lấy: không bao giờ để trống
});

test('đơn hẹn giờ: giờ dự kiến sẵn sàng = giờ hẹn; T_lấy = giờ hẹn', () => {
  const gioHen = T0 + phut(90);
  const { d, now } = toi('placed', { gio: 'hen', gioHen });
  const r = ap(d, { loai: 'QUAN_NHAN', chuanBiPhut: 15 }, now);
  assert.equal(r.d.gioDuKienSanSang, gioHen);
  assert.equal(r.d.tNhanMonDuKien, gioHen);
});

test('quán hủy sau khi đã nhận → cancelled_restaurant, hoàn 100%', () => {
  const { d, now } = toi('accepted');
  const r = ap(d, { loai: 'QUAN_HUY' }, now + 1);
  assert.equal(r.d.status, 'cancelled_restaurant');
  assert.equal(r.d.lyDoKetThuc, 'restaurant_cancelled');
  assert.deepEqual(tien(r), ['hoan']);
});

test('hủy vì quán chậm: chỉ từ giờ dự kiến + 30 phút, hoàn 100%, tính là quán hủy', () => {
  const { d, now } = toi('accepted');
  assert.match(ap(d, { loai: 'SV_HUY_QUAN_CHAM' }, d.moHuyChamLuc - 1).loi, /Chưa tới/);
  const r = ap(d, { loai: 'SV_HUY_QUAN_CHAM' }, d.moHuyChamLuc);
  assert.equal(r.d.status, 'cancelled_restaurant');
  assert.equal(r.d.lyDoKetThuc, 'restaurant_late');
  assert.deepEqual(tien(r), ['hoan']);
  assert.ok(now < d.moHuyChamLuc);
});

// ------------------------------------------------------------------ Đến lấy: mã 4 số

test('đến lấy, trả app: quán nhập đúng mã → delivered (tiền vẫn giữ); sai mã → không ghi nhận', () => {
  const { d, now } = toi('ready');
  assert.equal(d.status, 'ready');
  assert.match(ap(d, { loai: 'QUAN_NHAP_MA', maNhap: '0000', maDung: '4821' }, now + 1).loi, /không đúng/);
  const r = ap(d, { loai: 'QUAN_NHAP_MA', maNhap: '4821', maDung: '4821' }, now + 1);
  assert.equal(r.d.status, 'delivered');
  assert.deepEqual(tien(r), []); // chưa chuyển tiền, vẫn giữ
  assert.equal(r.d.hanKhieuNai, now + 1 + phut(24 * 60));
  assert.equal(r.d.daXacMinh, false);
});

test('đến lấy, tiền mặt: nhập đúng mã → completed ngay, có nhãn 🛵, không có tiền qua app', () => {
  const { d, now } = toi('ready', { cachTra: 'tien_mat' });
  const r = ap(d, { loai: 'QUAN_NHAP_MA', maNhap: '4821', maDung: '4821' }, now + 1);
  assert.equal(r.d.status, 'completed');
  assert.equal(r.d.daXacMinh, true);
  assert.deepEqual(tien(r), []);
  assert.equal(r.d.danhGia.nhan, 'dat_mon');
});

// ------------------------------------------------------------------ T_lấy: "Chưa nhận được món"

test('đến lấy T_lấy: quán báo sẵn sàng sớm → nút mờ tới T_lấy, từ T_lấy bấm được ngay → disputed, tiền giữ', () => {
  const acc = toi('accepted');
  const { d } = { d: ap(acc.d, { loai: 'QUAN_SAN_SANG' }, acc.now + phut(5)).d }; // sẵn sàng sớm 10 phút
  assert.ok(d.sanSangLuc < d.tNhanMonDuKien);
  const som = ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.tNhanMonDuKien - 1);
  assert.match(som.loi, /từ thời điểm nhận món dự kiến/);
  const r = ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.tNhanMonDuKien);
  assert.equal(r.d.status, 'disputed');
  assert.deepEqual(tien(r), []); // KHÔNG tự hoàn
  assert.equal(r.d.khieuNai.loai, 'chua_nhan_mon');
});

test('đơn tiền mặt: "Chưa nhận được món" → tranh chấp giao nhận để admin xác minh, không có tiền', () => {
  const { d } = toi('ready', { cachTra: 'tien_mat' });
  const r = ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.tNhanMonDuKien);
  assert.equal(r.d.status, 'disputed');
  assert.deepEqual(tien(r), []);
});

test('đang giao quá 60 phút mới báo "Chưa nhận được món" được', () => {
  const { d } = toi('delivering', { cachNhan: 'giao' });
  assert.match(ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.batDauGiaoLuc + phut(59)).loi, /60 phút/);
  assert.equal(ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.batDauGiaoLuc + phut(60)).d.status, 'disputed');
});

// ------------------------------------------------------------------ Giao tận nơi: ảnh GPS

test('đơn giao: không có ảnh hoặc GPS lệch quá 200 m → không ghi nhận', () => {
  const { d, now } = toi('delivering', { cachNhan: 'giao' });
  assert.match(ap(d, { loai: 'QUAN_DA_GIAO', coAnh: false, khoangCachM: 10 }, now + 1).loi, /ảnh giao hàng/);
  assert.match(ap(d, { loai: 'QUAN_DA_GIAO', coAnh: true, khoangCachM: 350 }, now + 1).loi, /GPS/);
});

test('đơn giao trả app: ảnh GPS hợp lệ → delivered, tiền vẫn giữ, mở 24 giờ', () => {
  const { d, now } = toi('delivering', { cachNhan: 'giao' });
  const r = ap(d, { loai: 'QUAN_DA_GIAO', coAnh: true, khoangCachM: 40 }, now + 1);
  assert.equal(r.d.status, 'delivered');
  assert.deepEqual(tien(r), []);
  assert.equal(r.d.bangChungLoai, 'anh');
});

test('đơn giao TIỀN MẶT có ảnh GPS: delivered, KHÔNG hoàn tất ngay và chưa có nhãn 🛵', () => {
  const { d, now } = toi('delivering', { cachNhan: 'giao', cachTra: 'tien_mat' });
  const r = ap(d, { loai: 'QUAN_DA_GIAO', coAnh: true, khoangCachM: 40 }, now + 1);
  assert.equal(r.d.status, 'delivered');
  assert.equal(r.d.daXacMinh, false);
  assert.equal(r.d.danhGia, null);
});

// ------------------------------------------------------------------ delivered → hoàn tất / khiếu nại

function giaoXong(o = {}) {
  const { d, now } = toi('delivering', { cachNhan: 'giao', ...o });
  const r = ap(d, { loai: 'QUAN_DA_GIAO', coAnh: true, khoangCachM: 40 }, now + 1);
  return { d: r.d, now: now + 1 };
}

test('SV bấm "Đã nhận món" → completed, chuyển tiền cho quán, có nhãn 🛵 và mở đánh giá', () => {
  const { d, now } = giaoXong();
  const r = ap(d, { loai: 'SV_DA_NHAN' }, now + 5);
  assert.equal(r.d.status, 'completed');
  assert.deepEqual(tien(r), ['chuyen']);
  assert.equal(r.d.daXacMinh, true);
  assert.equal(r.d.danhGia.nhan, 'dat_mon');
});

test('SV bấm "Đã nhận món" trước khi quán ghi nhận bằng chứng → hoàn tất luôn', () => {
  const { d, now } = toi('delivering', { cachNhan: 'giao' });
  const r = ap(d, { loai: 'SV_DA_NHAN' }, now + 5);
  assert.equal(r.d.status, 'completed');
  assert.deepEqual(tien(r), ['chuyen']);
});

test('hết 24 giờ không phản đối → tự hoàn tất, chuyển tiền, có nhãn; đơn tiền mặt thì không có tiền', () => {
  const { d } = giaoXong();
  const { d: d2, tacDong } = L.xuLyHan(d, d.hanKhieuNai, cfg);
  assert.equal(d2.status, 'completed');
  assert.equal(d2.daXacMinh, true);
  assert.deepEqual(tacDong.find((t) => t.khoa === 'TU_HOAN_TAT').tien, ['chuyen']);
  const m = giaoXong({ cachTra: 'tien_mat' });
  const { d: d3, tacDong: td3 } = L.xuLyHan(m.d, m.d.hanKhieuNai, cfg);
  assert.equal(d3.status, 'completed');
  assert.deepEqual(td3.find((t) => t.khoa === 'TU_HOAN_TAT').tien, []);
  assert.equal(d3.daXacMinh, true);
});

test('nhắc xác nhận nhận món sau 1 giờ và khi còn 1 giờ, mỗi lần 1 thông báo', () => {
  const { d } = giaoXong();
  const a = L.xuLyHan(d, d.bangChungLuc + phut(60), cfg);
  assert.equal(a.tacDong.filter((t) => t.laNhac).length, 1);
  assert.equal(L.xuLyHan(a.d, d.bangChungLuc + phut(61), cfg).tacDong.length, 0);
  const b = L.xuLyHan(a.d, d.hanKhieuNai - phut(60), cfg);
  assert.equal(b.tacDong.filter((t) => t.laNhac).length, 1);
});

test('chạy xử lý hạn 2 lần không làm 2 lần (không chuyển tiền 2 lần)', () => {
  const { d } = giaoXong();
  const a = L.xuLyHan(d, d.hanKhieuNai + 1000, cfg);
  const b = L.xuLyHan(a.d, d.hanKhieuNai + 2000, cfg);
  assert.equal(b.tacDong.length, 0);
  assert.equal(a.tacDong.flatMap((t) => t.tien).filter((x) => x === 'chuyen').length, 1);
});

// ------------------------------------------------------------------ Khiếu nại

test('khiếu nại: thiếu / sai món phải có ảnh; "không nhận được món" không cần ảnh → disputed, tiền giữ', () => {
  const { d, now } = giaoXong();
  assert.match(ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'thieu_mon', moTa: 'thiếu 1 món', anh: [] }, now + 5).loi, /ảnh/);
  const r = ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'thieu_mon', moTa: 'thiếu 1 món', anh: ['https://x/a.jpg'] }, now + 5);
  assert.equal(r.d.status, 'disputed');
  assert.deepEqual(tien(r), []);
  assert.equal(r.d.khieuNai.hanChuTraLoi, now + 5 + phut(120));
  assert.equal(ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'khong_nhan_duoc' }, now + 5).d.status, 'disputed');
});

test('đơn tiền mặt không mở khiếu nại tiền', () => {
  const { d, now } = giaoXong({ cachTra: 'tien_mat' });
  assert.match(ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'sai_mon', anh: ['https://x/a.jpg'] }, now + 5).loi, /Đơn tiền mặt/);
});

test('hết 24 giờ rồi thì không khiếu nại được (tự hoàn tất thắng)', () => {
  const { d } = giaoXong();
  const { d: d2 } = L.xuLyHan(d, d.hanKhieuNai, cfg);
  assert.match(ap(d2, { loai: 'SV_KHIEU_NAI', lyDo: 'khac', anh: ['https://x/a.jpg'] }, d.hanKhieuNai).loi, /khi quán đã ghi nhận/);
});

test('quán không trả lời khiếu nại trong 2 giờ → chuyển admin; treo 72 giờ → cờ khẩn (chỉ 1 lần)', () => {
  const { d, now } = giaoXong();
  const r = ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'sai_mon', moTa: 'sai món rồi', anh: ['https://x/a.jpg'] }, now + 5);
  const a = L.xuLyHan(r.d, now + 5 + phut(121), cfg);
  assert.equal(a.d.khieuNai.chuyenAdmin, true);
  const b = L.xuLyHan(a.d, now + 5 + phut(72 * 60), cfg);
  assert.equal(b.d.khieuNai.coKhan, true);
  assert.equal(b.d.status, 'disputed'); // không bao giờ tự giải ngân khi đang khiếu nại
  assert.equal(L.xuLyHan(b.d, now + 5 + phut(80 * 60), cfg).tacDong.length, 0);
});

test('quán đồng ý hoàn toàn phần / một phần ngay khi trả lời khiếu nại', () => {
  const { d, now } = giaoXong();
  const kn = ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'sai_mon', moTa: 'sai món rồi', anh: ['https://x/a.jpg'] }, now + 5).d;
  const toan = ap(kn, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'Xin lỗi bạn', deNghiHoan: { loai: 'toan_phan' } }, now + 10);
  assert.equal(toan.d.status, 'refunded');
  assert.deepEqual(tien(toan), ['hoan']);
  const mot = ap(kn, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'Xin lỗi bạn', deNghiHoan: { loai: 'mot_phan', soTien: 20000 } }, now + 10);
  assert.equal(mot.d.status, 'partially_refunded');
  assert.deepEqual(tien(mot), ['hoan_mot_phan']);
  assert.equal(mot.soTienHoan, 20000);
  assert.match(ap(kn, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'ok ok', deNghiHoan: { loai: 'mot_phan', soTien: 85000 } }, now + 10).loi, /không hợp lệ/);
  const khongHoan = ap(kn, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'Món đúng mà bạn' }, now + 10);
  assert.equal(khongHoan.d.status, 'disputed');
  assert.match(ap(khongHoan.d, { loai: 'QUAN_TRA_LOI_KHIEU_NAI', noiDung: 'lần nữa' }, now + 11).loi, /đã trả lời/);
});

test('admin quyết khiếu nại: hoàn toàn phần / một phần / chuyển tiền cho quán (khiếu nại bị tính sai)', () => {
  const { d, now } = giaoXong();
  const kn = ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'sai_mon', moTa: 'sai món rồi', anh: ['https://x/a.jpg'] }, now + 5).d;
  const toan = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_toan', lyDo: 'sai' }, now + 100);
  assert.equal(toan.d.status, 'refunded');
  assert.deepEqual(tien(toan), ['hoan']);
  const mot = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_mot_phan', soTienHoan: 30000, lyDo: 'thiếu 1 món' }, now + 100);
  assert.equal(mot.d.status, 'partially_refunded');
  assert.equal(mot.soTienHoan, 30000);
  assert.match(ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_mot_phan', soTienHoan: 85000, lyDo: 'x' }, now + 100).loi, /nhỏ hơn/);
  const bac = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'chuyen_cho_quan', lyDo: 'khiếu nại sai' }, now + 100);
  assert.equal(bac.d.status, 'completed');
  assert.deepEqual(tien(bac), ['chuyen']);
  assert.equal(bac.khieuNaiSai, true);
  assert.equal(bac.d.daXacMinh, true); // có bằng chứng giao nhận → đơn đã xác minh
});

test('admin kết luận đã giao sau "Chưa nhận được món" → completed, đơn đã xác minh (nhãn 🛵)', () => {
  const { d } = toi('ready');
  const kn = ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.tNhanMonDuKien).d;
  const r = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'da_giao', lyDo: 'camera quán thấy khách lấy' }, d.tNhanMonDuKien + 100);
  assert.equal(r.d.status, 'completed');
  assert.equal(r.d.daXacMinh, true);
  assert.equal(r.d.danhGia.nhan, 'dat_mon');
  assert.deepEqual(tien(r), ['chuyen']);
  const k = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'khong_giao', lyDo: 'không giao' }, d.tNhanMonDuKien + 100);
  assert.equal(k.d.status, 'refunded');
});

test('đơn tiền mặt tranh chấp giao nhận: đã giao → completed + nhãn; không giao → cancelled_restaurant; không có tiền', () => {
  const { d } = toi('ready', { cachTra: 'tien_mat' });
  const kn = ap(d, { loai: 'SV_CHUA_NHAN_MON' }, d.tNhanMonDuKien).d;
  const a = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'da_giao', lyDo: 'ok' }, d.tNhanMonDuKien + 5);
  assert.equal(a.d.status, 'completed');
  assert.equal(a.d.daXacMinh, true);
  assert.deepEqual(tien(a), []);
  const b = ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'khong_giao', lyDo: 'không' }, d.tNhanMonDuKien + 5);
  assert.equal(b.d.status, 'cancelled_restaurant');
  assert.deepEqual(tien(b), []);
  assert.match(ap(kn, { loai: 'ADMIN_QUYET', quyetDinh: 'hoan_mot_phan', soTienHoan: 1000, lyDo: 'x' }, d.tNhanMonDuKien + 5).loi, /tiền mặt/);
});

// ------------------------------------------------------------------ Khách không nhận (bom hàng)

test('"Khách không nhận" đến lấy: chỉ sau 30 phút kể từ "Sẵn sàng", bắt buộc ảnh GPS', () => {
  const { d } = toi('ready');
  assert.match(ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 10 }, d.sanSangLuc + phut(29)).loi, /30 phút/);
  assert.match(ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: false, khoangCachM: 10 }, d.sanSangLuc + phut(31)).loi, /ảnh/);
  const r = ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 10 }, d.sanSangLuc + phut(31));
  assert.equal(r.d.status, 'not_received');
  assert.deepEqual(tien(r), []); // tiền giữ thêm 24 giờ
  assert.equal(r.d.khongNhan.hanPhanDoi, d.sanSangLuc + phut(31) + phut(24 * 60));
  assert.deepEqual(r.viPham, []); // chưa tính bom hàng
});

test('"Khách không nhận" đơn giao: bấm khi đang giao, ảnh tại điểm giao', () => {
  const { d, now } = toi('delivering', { cachNhan: 'giao' });
  assert.equal(ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 30 }, now + 5).d.status, 'not_received');
  assert.match(ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 900 }, now + 5).loi, /GPS/);
});

test('không phản đối trong 24 giờ → completed, chuyển tiền, lúc đó mới tính 1 lần bom hàng, không có nhãn', () => {
  const { d } = toi('ready');
  const kn = ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 10 }, d.sanSangLuc + phut(31)).d;
  const { d: d2, tacDong } = L.xuLyHan(kn, kn.khongNhan.hanPhanDoi, cfg);
  assert.equal(d2.status, 'completed');
  assert.equal(d2.daXacMinh, false);
  assert.equal(d2.danhGia, null);
  const t = tacDong.find((x) => x.khoa === 'HET_HAN_PHAN_DOI');
  assert.deepEqual(t.tien, ['chuyen']);
  assert.deepEqual(t.viPham, ['bom_hang']);
});

test('SV phản đối trong 24 giờ → disputed; admin chấp nhận → hoàn, không bom; bác → completed + bom', () => {
  const { d } = toi('ready');
  const kn = ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 10 }, d.sanSangLuc + phut(31)).d;
  const pd = ap(kn, { loai: 'SV_PHAN_DOI', moTa: 'tôi có đến', anh: [] }, kn.khongNhan.luc + phut(60));
  assert.equal(pd.d.status, 'disputed');
  assert.equal(pd.d.khieuNai.loai, 'phan_doi_khong_nhan');
  const chap = ap(pd.d, { loai: 'ADMIN_QUYET', quyetDinh: 'chap_nhan_phan_doi', lyDo: 'khách đúng' }, kn.khongNhan.luc + phut(600));
  assert.equal(chap.d.status, 'refunded');
  assert.deepEqual(chap.viPham, []);
  const bac = ap(pd.d, { loai: 'ADMIN_QUYET', quyetDinh: 'bac_phan_doi', lyDo: 'khách sai' }, kn.khongNhan.luc + phut(600));
  assert.equal(bac.d.status, 'completed');
  assert.deepEqual(bac.viPham, ['bom_hang']);
  assert.deepEqual(tien(bac), ['chuyen']);
  // Quá 24 giờ thì không phản đối được.
  assert.match(ap(kn, { loai: 'SV_PHAN_DOI', moTa: 'trễ' }, kn.khongNhan.hanPhanDoi + 1).loi, /24 giờ/);
});

test('đơn tiền mặt bị "Khách không nhận" + phản đối: admin tính bom → completed; không tính → cancelled_restaurant', () => {
  const { d } = toi('ready', { cachTra: 'tien_mat' });
  const kn = ap(d, { loai: 'QUAN_KHONG_NHAN', coAnh: true, khoangCachM: 10 }, d.sanSangLuc + phut(31)).d;
  const pd = ap(kn, { loai: 'SV_PHAN_DOI', moTa: 'tôi có đến' }, kn.khongNhan.luc + phut(10)).d;
  const a = ap(pd, { loai: 'ADMIN_QUYET', quyetDinh: 'bac_phan_doi', lyDo: 'x' }, kn.khongNhan.luc + phut(60));
  assert.equal(a.d.status, 'completed');
  assert.deepEqual(tien(a), []);
  const b = ap(pd, { loai: 'ADMIN_QUYET', quyetDinh: 'chap_nhan_phan_doi', lyDo: 'x' }, kn.khongNhan.luc + phut(60));
  assert.equal(b.d.status, 'cancelled_restaurant');
});

// ------------------------------------------------------------------ Quá 6 giờ không có bằng chứng

test('quá 6 giờ ở "Sẵn sàng" / "Đang giao" không bằng chứng, không ai bấm → gắn cờ admin; KHÔNG tự hoàn, KHÔNG tự giải ngân', () => {
  const { d } = toi('ready');
  const a = L.xuLyHan(d, d.hanQuaHan6h - 1, cfg);
  assert.equal(a.tacDong.length, 0);
  const b = L.xuLyHan(d, d.hanQuaHan6h, cfg);
  assert.equal(b.d.status, 'ready');
  assert.equal(b.d.coQuaHan, true);
  assert.deepEqual(b.tacDong.flatMap((t) => t.tien), []);
  assert.ok(b.tacDong[0].thongBao.some((t) => t.toi === 'admin'));
  assert.equal(L.xuLyHan(b.d, d.hanQuaHan6h + phut(500), cfg).tacDong.length, 0); // chỉ gắn cờ 1 lần
});

test('admin quyết đơn quá 6 giờ: đã giao → completed + nhãn; không giao → hoàn 100% (tiền mặt: cancelled_restaurant)', () => {
  const { d } = toi('delivering', { cachNhan: 'giao' });
  const co = L.xuLyHan(d, d.hanQuaHan6h, cfg).d;
  const a = ap(co, { loai: 'ADMIN_QUA_HAN', quyetDinh: 'da_giao', lyDo: 'khách xác nhận' }, d.hanQuaHan6h + 5);
  assert.equal(a.d.status, 'completed');
  assert.equal(a.d.daXacMinh, true);
  assert.deepEqual(tien(a), ['chuyen']);
  const b = ap(co, { loai: 'ADMIN_QUA_HAN', quyetDinh: 'khong_giao', lyDo: 'không giao' }, d.hanQuaHan6h + 5);
  assert.equal(b.d.status, 'refunded');
  const m = toi('delivering', { cachNhan: 'giao', cachTra: 'tien_mat' }).d;
  const mc = L.xuLyHan(m, m.hanQuaHan6h, cfg).d;
  assert.equal(ap(mc, { loai: 'ADMIN_QUA_HAN', quyetDinh: 'khong_giao', lyDo: 'x' }, m.hanQuaHan6h + 5).d.status, 'cancelled_restaurant');
  // Đơn chưa quá hạn thì admin không quyết kiểu này được.
  assert.match(ap(d, { loai: 'ADMIN_QUA_HAN', quyetDinh: 'da_giao', lyDo: 'x' }, d.hanQuaHan6h - 5).loi, /cần admin/);
});

// ------------------------------------------------------------------ Quán ngừng nhận / lừa đảo (3.14)

test('quán tạm nghỉ / ẩn / đình chỉ: đơn chờ xác nhận bị hủy và hoàn; đơn đã nhận đi tiếp', () => {
  const { d } = toi('placed');
  const r = ap(d, { loai: 'QUAN_NGUNG_NHAN' }, T0 + phut(30));
  assert.equal(r.d.status, 'cancelled_restaurant');
  assert.deepEqual(tien(r), ['hoan']);
  const acc = toi('accepted').d;
  assert.ok(ap(acc, { loai: 'QUAN_NGUNG_NHAN' }, T0 + phut(30)).boQua);
});

test('quán bị kết luận lừa đảo: đơn chờ xác nhận hoàn; đã nhận / có bằng chứng thì GIỮ tiền, gắn cờ rà soát; đã hoàn tất không đổi', () => {
  const placed = toi('placed').d;
  assert.equal(ap(placed, { loai: 'LUA_DAO_GAN_CO' }, T0 + phut(30)).d.status, 'cancelled_restaurant');
  const ready = toi('ready').d;
  const r = ap(ready, { loai: 'LUA_DAO_GAN_CO' }, T0 + phut(30));
  assert.equal(r.d.status, 'ready');
  assert.equal(r.d.ruaSoatLuaDao, true);
  assert.deepEqual(tien(r), []); // không tự hoàn, không tự giải ngân
  const g = giaoXong();
  const rd = ap(g.d, { loai: 'LUA_DAO_GAN_CO' }, g.now + 10);
  assert.equal(rd.d.status, 'delivered');
  assert.equal(rd.d.ruaSoatLuaDao, true);
  const xong = ap(g.d, { loai: 'SV_DA_NHAN' }, g.now + 5).d;
  assert.ok(ap(xong, { loai: 'LUA_DAO_GAN_CO' }, g.now + 10).boQua); // hoàn tất trước đó: không đảo ngược
});

test('rà soát lừa đảo từng đơn: đã giao thật → completed; bằng chứng giả → refunded; chưa đủ căn cứ → disputed', () => {
  const g = giaoXong();
  const co = ap(g.d, { loai: 'LUA_DAO_GAN_CO' }, g.now + 10).d;
  const a = ap(co, { loai: 'ADMIN_LUA_DAO', quyetDinh: 'da_giao', lyDo: 'khách xác nhận nhận món' }, g.now + 20);
  assert.equal(a.d.status, 'completed');
  assert.equal(a.d.daXacMinh, true);
  const b = ap(co, { loai: 'ADMIN_LUA_DAO', quyetDinh: 'khong_giao', lyDo: 'ảnh giả' }, g.now + 20);
  assert.equal(b.d.status, 'refunded');
  assert.deepEqual(tien(b), ['hoan']);
  const c = ap(co, { loai: 'ADMIN_LUA_DAO', quyetDinh: 'giu_tranh_chap', lyDo: 'chưa đủ căn cứ' }, g.now + 20);
  assert.equal(c.d.status, 'disputed');
  assert.deepEqual(tien(c), []);
  assert.equal(c.d.ruaSoatLuaDao, false);
});

// ------------------------------------------------------------------ Hạn kế tiếp + hai người thao tác cùng lúc

test('hanKeTiep: mốc xử lý sớm nhất theo từng trạng thái', () => {
  assert.equal(L.hanKeTiep(tao()), T0 + phut(15));
  const { d } = toi('placed');
  assert.equal(L.hanKeTiep(d), Math.min(d.hanQuanNhan + 1, d.datLuc + phut(2)));
  const g = giaoXong();
  assert.equal(L.hanKeTiep(g.d), g.d.bangChungLuc + phut(60));
  const hoanTat = ap(g.d, { loai: 'SV_DA_NHAN' }, g.now + 5).d;
  assert.equal(L.hanKeTiep(hoanTat), null);
});

test('tự hoàn tất đúng lúc SV khiếu nại: chỉ một bên thắng (khiếu nại trong hạn thắng; quá hạn thì đơn đã hoàn tất)', () => {
  const { d } = giaoXong();
  const trongHan = ap(d, { loai: 'SV_KHIEU_NAI', lyDo: 'khong_nhan_duoc' }, d.hanKhieuNai - 1);
  assert.equal(trongHan.d.status, 'disputed');
  const { d: xong } = L.xuLyHan(d, d.hanKhieuNai, cfg);
  assert.ok(ap(xong, { loai: 'SV_KHIEU_NAI', lyDo: 'khong_nhan_duoc' }, d.hanKhieuNai).loi);
});

test('hẹn giờ: dưới 30 phút, quá 2 giờ, sau giờ đóng ca, hoặc quán đang tạm nghỉ đều bị chặn', () => {
  const ca = T0 + phut(180);
  const k = (gioHen, extra = {}) => L.kiemTraGioNhan({ gio: 'hen', gioHen, now: T0, caDangMoDenLuc: ca, ...extra }, cfg);
  assert.match(k(T0 + phut(29)), /ít nhất 30 phút/);
  assert.match(k(T0 + phut(125)), /2 giờ/);
  assert.match(k(T0 + phut(100), { caDangMoDenLuc: T0 + phut(90) }), /đóng cửa/);
  assert.match(k(T0 + phut(60), { dangTamNghi: true }), /tạm nghỉ/);
  assert.equal(k(T0 + phut(60)), null);
  assert.equal(L.kiemTraGioNhan({ gio: 'asap', now: T0 }, cfg), null);
  assert.ok(GIO);
});
