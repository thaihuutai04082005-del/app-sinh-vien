'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { MAC_DINH, gopCauHinh, PHUT } = require('../src/tro/config');
const L = require('../src/tro/logic/dat_coc');

const cfg = MAC_DINH;
const GIO = 60 * PHUT;
const NGAY = 24 * GIO;
// Mốc giờ Việt Nam (UTC+7) như ví dụ trong đặc tả.
const vn = (s) => Date.parse(`${s}+07:00`);

/** Tạo khoản cọc rồi cho thanh toán thành công lúc `heldAt`. */
function dangGiu({ now = vn('2026-10-01T09:00:00'), t = vn('2026-10-10T14:00:00'), quyen = true, ngayVaoO = null } = {}) {
  let d = L.taoKhoanCoc({ now, t, ngayVaoO, soTien: 1500000, coQuyenHuyMienPhi: quyen }, cfg);
  const r = L.apDung(d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: now + PHUT }, now + PHUT, cfg);
  return r.d;
}

const kiemTraLoi = (r, chuoi) => {
  assert.ok(r.loi, 'phải bị chặn');
  if (chuoi) assert.match(r.loi, chuoi);
};

test('tạo cọc: T phải ≥ lúc cọc + 2 giờ, ≥ ngày vào ở, ≤ 14 ngày, cọc ≤ 1 tháng', () => {
  const now = vn('2026-10-01T09:00:00');
  const base = { now, ngayVaoO: null, soTien: 1000000, giaThue: 1500000 };
  assert.match(L.kiemTraTaoCoc({ ...base, t: now + 2 * GIO - PHUT }, cfg), /2 giờ/);
  assert.equal(L.kiemTraTaoCoc({ ...base, t: now + 2 * GIO }, cfg), null);
  assert.match(L.kiemTraTaoCoc({ ...base, t: now + 3 * GIO, ngayVaoO: now + NGAY }, cfg), /ngày có thể vào ở/);
  assert.match(L.kiemTraTaoCoc({ ...base, t: now + 14 * NGAY + PHUT }, cfg), /14 ngày/);
  assert.equal(L.kiemTraTaoCoc({ ...base, t: now + 14 * NGAY }, cfg), null);
  assert.match(L.kiemTraTaoCoc({ ...base, t: now + 3 * GIO, soTien: 1500001 }, cfg), /1 tháng/);
});

test('(mới) → pending_payment, hạn thanh toán 15 phút', () => {
  const now = vn('2026-10-01T09:00:00');
  const d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  assert.equal(d.status, 'pending_payment');
  assert.equal(d.hanThanhToan, now + 15 * PHUT);
  assert.equal(L.hanKeTiep(d, cfg), d.hanThanhToan);
});

test('pending_payment + cổng báo đã trả trước hạn → held, phòng reserved, gỡ khóa, chụp thông tin', () => {
  const now = vn('2026-10-01T09:00:00');
  const d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  const r = L.apDung(d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: now + 5 * PHUT }, now + 5 * PHUT, cfg);
  assert.equal(r.d.status, 'held');
  assert.equal(r.phong, 'reserved');
  assert.ok(r.goKhoa && r.chupThongTin);
  assert.deepEqual(r.tien, ['giu']);
  assert.equal(r.d.hanHuyMienPhi, now + 35 * PHUT);
  // Cổng báo "đã trả" lần 2: chỉ ghi nhận lần đầu.
  assert.ok(L.apDung(r.d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: now + 5 * PHUT }, now + 6 * PHUT, cfg).boQua);
});

test('cổng ghi nhận trước hạn nhưng báo về sau hạn → vẫn đúng hạn, held', () => {
  const now = vn('2026-10-01T13:45:00');
  const d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  const ghiNhan = vn('2026-10-01T13:59:58');
  const r = L.apDung(d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: ghiNhan }, vn('2026-10-01T14:00:05'), cfg);
  assert.equal(r.d.status, 'held');
});

test('hết hạn chờ: hỏi lại cổng, cổng đã ghi nhận đúng hạn → held', () => {
  const now = vn('2026-10-01T13:45:00');
  const d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  const { d: sau } = L.xuLyHan(d, vn('2026-10-01T14:00:10'), cfg, { congDaThu: { ghiNhanLuc: vn('2026-10-01T13:59:58') } });
  assert.equal(sau.status, 'held');
});

test('pending_payment + hết hạn chờ / thất bại → expired, gỡ khóa', () => {
  const now = vn('2026-10-01T09:00:00');
  const d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  const { d: sau, tacDong } = L.xuLyHan(d, now + 15 * PHUT, cfg, {});
  assert.equal(sau.status, 'expired');
  assert.ok(tacDong[0].goKhoa);
  const loi = L.apDung(d, { loai: 'THANH_TOAN_LOI' }, now + PHUT, cfg);
  assert.equal(loi.d.status, 'expired');
  assert.ok(loi.goKhoa);
});

test('expired + tiền đến muộn → refunded (system_late_payment), phòng không đổi', () => {
  const now = vn('2026-10-01T09:00:00');
  let d = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  d = L.xuLyHan(d, now + 16 * PHUT, cfg).d;
  const r = L.apDung(d, { loai: 'THANH_TOAN_OK', ghiNhanLuc: now + 17 * PHUT }, now + 17 * PHUT, cfg);
  assert.equal(r.d.status, 'refunded');
  assert.equal(r.d.lyDoKetThuc, 'system_late_payment');
  assert.equal(r.phong, null);
  assert.deepEqual(r.tien, ['hoan']);
  // Chưa xử lý hạn nhưng cổng ghi nhận sau hạn cũng tự hoàn.
  const d2 = L.taoKhoanCoc({ now, t: now + 5 * GIO, soTien: 1, coQuyenHuyMienPhi: true }, cfg);
  const r2 = L.apDung(d2, { loai: 'THANH_TOAN_OK', ghiNhanLuc: now + 16 * PHUT }, now + 16 * PHUT, cfg);
  assert.equal(r2.d.lyDoKetThuc, 'system_late_payment');
  assert.ok(r2.goKhoa);
});

test('held + SV hủy trong 30 phút (còn quyền) → cancelled_grace, hoàn 100%', () => {
  const d = dangGiu();
  const r = L.apDung(d, { loai: 'SV_HUY' }, d.heldAt + 29 * PHUT, cfg);
  assert.equal(r.d.status, 'cancelled_grace');
  assert.equal(r.d.lyDoKetThuc, 'grace_cancel');
  assert.deepEqual(r.tien, ['hoan']);
  assert.equal(r.phong, 'available');
  assert.ok(r.ghiHuyMienPhi);
  kiemTraLoi(L.apDung(d, { loai: 'SV_HUY' }, d.heldAt + 31 * PHUT, cfg), /30 phút/);
  kiemTraLoi(L.apDung(dangGiu({ quyen: false }), { loai: 'SV_HUY' }, d.heldAt + PHUT, cfg), /hết lượt/);
});

test('held + SV "Không thuê nữa" (hết quyền hủy miễn phí, trước T) → forfeited, tiền cho chủ', () => {
  const d = dangGiu();
  kiemTraLoi(L.apDung(d, { loai: 'SV_KHONG_THUE' }, d.heldAt + 10 * PHUT, cfg), /30 phút/);
  const r = L.apDung(d, { loai: 'SV_KHONG_THUE' }, d.heldAt + 31 * PHUT, cfg);
  assert.equal(r.d.status, 'forfeited');
  assert.equal(r.d.lyDoKetThuc, 'student_changed_mind');
  assert.deepEqual(r.tien, ['chuyen']);
  assert.equal(r.phong, 'available');
  const khongQuyen = dangGiu({ quyen: false });
  assert.equal(L.apDung(khongQuyen, { loai: 'SV_KHONG_THUE' }, khongQuyen.heldAt + PHUT, cfg).d.status, 'forfeited');
  kiemTraLoi(L.apDung(d, { loai: 'SV_KHONG_THUE' }, d.t, cfg));
});

test('held + chủ "Hủy cọc" trước T → refunded (owner_cancelled), vi phạm, phòng available/hidden', () => {
  const d = dangGiu();
  const r = L.apDung(d, { loai: 'CT_HUY_COC', anPhong: true }, d.t - GIO, cfg);
  assert.equal(r.d.lyDoKetThuc, 'owner_cancelled');
  assert.deepEqual(r.viPham, ['huy_coc']);
  assert.equal(r.phong, 'hidden');
  assert.equal(L.apDung(d, { loai: 'CT_HUY_COC' }, d.t - GIO, cfg).phong, 'available');
  kiemTraLoi(L.apDung(d, { loai: 'CT_HUY_COC' }, d.t, cfg));
});

test('yêu cầu thay đổi: chỉ gửi khi còn > 24 giờ (ví dụ 09/10 13:59 được, 14:01 bị chặn)', () => {
  const d = dangGiu(); // T = 10/10 14:00
  const moi = vn('2026-10-12T14:00:00');
  assert.equal(L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: moi }, vn('2026-10-09T13:59:00'), cfg).d.doi.ketQua, 'cho');
  kiemTraLoi(L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: moi }, vn('2026-10-09T14:01:00'), cfg), /24 giờ/);
});

test('yêu cầu thay đổi: thời điểm mới ≥ lúc gửi + 24h, ≥ ngày vào ở, ≤ T ban đầu + 14 ngày', () => {
  const d = dangGiu({ ngayVaoO: vn('2026-10-09T00:00:00') });
  const gui = vn('2026-10-08T10:00:00');
  kiemTraLoi(L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: gui + 23 * GIO }, gui, cfg), /24 giờ/);
  kiemTraLoi(L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-08T23:00:00') + 12 * GIO - 13 * GIO }, gui, cfg));
  kiemTraLoi(L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: d.tBanDau + 14 * NGAY + PHUT }, gui, cfg), /14 ngày/);
  // Ví dụ nhận sớm hơn: T cũ 10/10 14:00, gửi 08/10 10:00, đề xuất 09/10 14:00.
  const r = L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-09T14:00:00') }, gui, cfg);
  assert.equal(r.d.doi.hanTraLoi, gui + 24 * GIO);
  assert.deepEqual(r.thongBao, [{ toi: 'chu', loai: 'co_yeu_cau_doi' }]);
});

test('chủ đồng ý → T mới, các mốc 3/24/48 giờ tính theo T mới; từ chối → giữ T cũ', () => {
  const d = dangGiu();
  const gui = vn('2026-10-08T10:00:00');
  const coYeuCau = L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-09T14:00:00') }, gui, cfg).d;
  const dongY = L.apDung(coYeuCau, { loai: 'CT_DONG_Y_DOI' }, gui + GIO, cfg).d;
  assert.equal(dongY.t, vn('2026-10-09T14:00:00'));
  const tuHoan = L.viecHeThong(dongY, cfg).find((v) => v.su.loai === 'TU_HOAN_TAT');
  assert.equal(tuHoan.at, vn('2026-10-09T14:00:00') + 48 * GIO);
  kiemTraLoi(L.apDung(dongY, { loai: 'CT_BAO_KHONG_DEN' }, vn('2026-10-09T16:59:00'), cfg), /3 giờ/);
  assert.ok(L.apDung(dongY, { loai: 'CT_BAO_KHONG_DEN' }, vn('2026-10-09T17:00:00'), cfg).d.khongDen);

  const tuChoi = L.apDung(coYeuCau, { loai: 'CT_TU_CHOI_DOI' }, gui + GIO, cfg).d;
  assert.equal(tuChoi.t, d.t);
  // Sau 1 lần gửi không gửi được lần 2.
  kiemTraLoi(L.apDung(tuChoi, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-12T14:00:00') }, gui + 2 * GIO, cfg), /1 lần/);
  kiemTraLoi(L.apDung(coYeuCau, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-12T14:00:00') }, gui + 2 * GIO, cfg));
});

test('chủ không trả lời yêu cầu thay đổi trong 24 giờ → refunded, vi phạm; được nhắc khi còn 6 giờ và 1 giờ', () => {
  const d = dangGiu();
  const gui = vn('2026-10-08T10:00:00');
  const coYeuCau = L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-12T14:00:00') }, gui, cfg).d;
  const nhac6 = L.xuLyHan(coYeuCau, gui + 18 * GIO, cfg);
  assert.deepEqual(nhac6.tacDong.map((t) => t.thongBao[0].loai), ['nhac_tra_loi_doi']);
  const nhac1 = L.xuLyHan(nhac6.d, gui + 23 * GIO, cfg);
  assert.deepEqual(nhac1.tacDong.map((t) => t.thongBao[0].loai), ['nhac_tra_loi_doi']);
  const { d: sau, tacDong } = L.xuLyHan(nhac1.d, gui + 24 * GIO, cfg);
  assert.equal(sau.status, 'refunded');
  assert.equal(sau.lyDoKetThuc, 'owner_no_reply_reschedule');
  assert.deepEqual(tacDong.at(-1).viPham, ['khong_tra_loi_doi']);
  // Chủ bấm đúng lúc hết hạn: hết hạn được ghi trước thì không trả lời được nữa.
  kiemTraLoi(L.apDung(coYeuCau, { loai: 'CT_DONG_Y_DOI' }, gui + 24 * GIO, cfg));
});

test('đang chờ trả lời mà SV "Không thuê nữa" / chủ "Hủy cọc": yêu cầu tự đóng, không vi phạm "không trả lời"', () => {
  const d = dangGiu({ quyen: false });
  const gui = vn('2026-10-08T10:00:00');
  const coYeuCau = L.apDung(d, { loai: 'SV_YEU_CAU_DOI', thoiDiemMoi: vn('2026-10-12T14:00:00') }, gui, cfg).d;
  const r = L.apDung(coYeuCau, { loai: 'SV_KHONG_THUE' }, gui + GIO, cfg);
  assert.equal(r.d.doi.ketQua, 'dong');
  assert.equal(L.xuLyHan(r.d, gui + 25 * GIO, cfg).tacDong.length, 0);
  const huy = L.apDung(coYeuCau, { loai: 'CT_HUY_COC' }, gui + GIO, cfg);
  assert.equal(huy.d.doi.ketQua, 'dong');
  assert.deepEqual(huy.viPham, ['huy_coc']);
});

test('nhắc SV hạn cuối gửi yêu cầu thay đổi lúc T − 36 giờ (chỉ khi chưa dùng quyền); nhắc trước 1 ngày cho cả hai', () => {
  const d = dangGiu();
  const { tacDong } = L.xuLyHan(d, d.t - 36 * GIO, cfg);
  assert.deepEqual(tacDong.map((x) => x.thongBao.map((tb) => tb.toi + ':' + tb.loai)).flat(), ['sv:sap_het_han_gui_doi']);
  const { tacDong: t2 } = L.xuLyHan(L.xuLyHan(d, d.t - 36 * GIO, cfg).d, d.t - 24 * GIO, cfg);
  assert.deepEqual(t2[0].thongBao.map((x) => x.toi), ['sv', 'chu']);
});

test('trước T: không có "Đã nhận phòng", khiếu nại, báo "không đến"', () => {
  const d = dangGiu();
  kiemTraLoi(L.apDung(d, { loai: 'SV_DA_NHAN' }, d.t - PHUT, cfg));
  kiemTraLoi(L.apDung(d, { loai: 'SV_KHIEU_NAI', moTa: 'x' }, d.t - PHUT, cfg));
  kiemTraLoi(L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t - PHUT, cfg));
});

test('held + SV "Đã nhận phòng" từ T → released (student_confirmed), rented, mở đánh giá có nhãn', () => {
  const d = dangGiu();
  const r = L.apDung(d, { loai: 'SV_DA_NHAN' }, d.t, cfg);
  assert.equal(r.d.status, 'released');
  assert.equal(r.d.lyDoKetThuc, 'student_confirmed');
  assert.equal(r.phong, 'rented');
  assert.deepEqual(r.tien, ['chuyen']);
  assert.deepEqual(r.d.danhGia, { nhan: 'da_thue', tinhDiem: true, han: d.t + 365 * NGAY });
});

test('held + SV khiếu nại từ T tới T + 48 giờ → disputed, tiền tạm giữ', () => {
  const d = dangGiu();
  const r = L.apDung(d, { loai: 'SV_KHIEU_NAI', lyDo: 'khong_giao_phong', moTa: 'Chủ không giao phòng' }, d.t + GIO, cfg);
  assert.equal(r.d.status, 'disputed');
  assert.equal(r.d.khieuNai.hanChuTraLoi, d.t + 25 * GIO);
  assert.deepEqual(r.tien, []);
  kiemTraLoi(L.apDung(d, { loai: 'SV_KHIEU_NAI' }, d.t + 48 * GIO + PHUT, cfg), /48 giờ/);
  // Đang khiếu nại: quá T + 48 giờ vẫn không tự hoàn tất.
  const { d: sau } = L.xuLyHan(r.d, d.t + 100 * GIO, cfg);
  assert.equal(sau.status, 'disputed');
});

test('chủ báo "không đến": từ T + 3 giờ tới T + 48 giờ (ví dụ T 14:00 → 17:00 mới được)', () => {
  const d = dangGiu();
  kiemTraLoi(L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, vn('2026-10-10T16:59:00'), cfg), /3 giờ/);
  const r = L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, vn('2026-10-10T17:00:00'), cfg);
  assert.equal(r.d.khongDen.hanPhanDoi, vn('2026-10-11T05:00:00'));
  assert.deepEqual(r.thongBao, [{ toi: 'sv', loai: 'chu_bao_khong_den' }]);
  kiemTraLoi(L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 48 * GIO + PHUT, cfg));
  // Trong ân hạn SV vẫn bấm "Đã nhận phòng" bình thường.
  assert.equal(L.apDung(d, { loai: 'SV_DA_NHAN' }, d.t + 2 * GIO, cfg).d.status, 'released');
  // Đã có báo "không đến": SV chỉ còn Phản đối.
  kiemTraLoi(L.apDung(r.d, { loai: 'SV_DA_NHAN' }, vn('2026-10-10T18:00:00'), cfg), /Phản đối/);
  kiemTraLoi(L.apDung(r.d, { loai: 'SV_KHIEU_NAI' }, vn('2026-10-10T18:00:00'), cfg), /Phản đối/);
});

test('có báo "không đến": SV phản đối trong 12 giờ → disputed; hết 12 giờ → forfeited (student_no_show); nhắc khi còn 2 giờ', () => {
  const d = dangGiu();
  const bao = L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 3 * GIO, cfg).d;
  const pd = L.apDung(bao, { loai: 'SV_PHAN_DOI', moTa: 'Tôi đã tới' }, d.t + 4 * GIO, cfg);
  assert.equal(pd.d.status, 'disputed');
  assert.equal(pd.d.khieuNai.loai, 'phan_doi');
  const nhac = L.xuLyHan(bao, d.t + 13 * GIO, cfg);
  assert.ok(nhac.tacDong.some((x) => x.thongBao[0].loai === 'nhac_phan_doi'));
  const { d: sau, tacDong } = L.xuLyHan(nhac.d, d.t + 15 * GIO, cfg);
  assert.equal(sau.status, 'forfeited');
  assert.equal(sau.lyDoKetThuc, 'student_no_show');
  assert.equal(tacDong.at(-1).phong, 'available');
  kiemTraLoi(L.apDung(bao, { loai: 'SV_PHAN_DOI' }, d.t + 15 * GIO + PHUT, cfg), /12 giờ/);
});

test('chủ báo "không đến" lúc T + 47 giờ: không tự hoàn tất lúc T + 48, xử lý lúc T + 59', () => {
  const d = dangGiu();
  const bao = L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 47 * GIO, cfg).d;
  assert.equal(L.xuLyHan(bao, d.t + 48 * GIO, cfg).d.status, 'held');
  assert.equal(L.xuLyHan(bao, d.t + 59 * GIO, cfg).d.status, 'forfeited');
});

test('T + 24 giờ: nhắc cuối cho cả hai (không gửi khi đang khiếu nại / có báo "không đến")', () => {
  const d = dangGiu();
  const daQuaT = L.xuLyHan(d, d.t + GIO, cfg).d;
  const { tacDong } = L.xuLyHan(daQuaT, d.t + 24 * GIO, cfg);
  assert.deepEqual(tacDong.map((x) => x.thongBao.map((tb) => tb.loai)).flat(), ['nhac_cuoi', 'nhac_cuoi']);
  const bao = L.apDung(daQuaT, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 3 * GIO, cfg).d;
  assert.equal(L.xuLyHan(bao, d.t + 24 * GIO, cfg).tacDong.filter((x) => x.thongBao[0]?.loai === 'nhac_cuoi').length, 0);
});

test('T + 48 giờ không ai làm gì → released (auto_complete), rented, đánh giá không nhãn, không tính điểm', () => {
  const d = dangGiu();
  const { d: sau, tacDong } = L.xuLyHan(d, d.t + 48 * GIO, cfg);
  assert.equal(sau.status, 'released');
  assert.equal(sau.lyDoKetThuc, 'auto_complete');
  assert.deepEqual(sau.danhGia, { nhan: null, tinhDiem: false, han: d.t + 365 * NGAY });
  assert.equal(tacDong.at(-1).phong, 'rented');
  // Nhắc đã quá thời điểm còn ý nghĩa thì không gửi khi xử lý trễ.
  const loaiNhac = tacDong.flatMap((x) => x.thongBao.map((tb) => tb.loai));
  assert.ok(!loaiNhac.includes('nhac_nhan_phong'));
  assert.ok(!loaiNhac.includes('nhac_cuoi'));
});

test('tự xử lý hạn chạy lại nhiều lần: không chuyển tiền 2 lần, không thông báo 2 lần', () => {
  const d = dangGiu();
  const lan1 = L.xuLyHan(d, d.t + 48 * GIO, cfg);
  const lan2 = L.xuLyHan(lan1.d, d.t + 50 * GIO, cfg);
  assert.equal(lan2.tacDong.length, 0);
  assert.equal(lan1.tacDong.filter((x) => x.tien.includes('chuyen')).length, 1);
});

test('tự hoàn tất trùng lúc khiếu nại: khiếu nại ghi trước thì không tự hoàn tất', () => {
  const d = dangGiu();
  const kn = L.apDung(d, { loai: 'SV_KHIEU_NAI', moTa: 'x' }, d.t + 48 * GIO, cfg);
  assert.equal(kn.d.status, 'disputed');
  assert.equal(L.xuLyHan(kn.d, d.t + 48 * GIO, cfg).d.status, 'disputed');
  // Hết hạn ghi trước thì khiếu nại bị chặn.
  const tuHoan = L.xuLyHan(d, d.t + 48 * GIO, cfg).d;
  kiemTraLoi(L.apDung(tuHoan, { loai: 'SV_KHIEU_NAI' }, d.t + 48 * GIO, cfg));
});

test('disputed: chủ trả lời 1 lần trong 24 giờ; quá 72 giờ → cờ khẩn', () => {
  const d = dangGiu();
  const kn = L.apDung(d, { loai: 'SV_KHIEU_NAI', moTa: 'x' }, d.t + GIO, cfg).d;
  const tl = L.apDung(kn, { loai: 'CT_TRA_LOI_KHIEU_NAI', noiDung: 'Phòng đã giao đúng hẹn' }, d.t + 2 * GIO, cfg);
  assert.ok(tl.d.khieuNai.chuTraLoi);
  kiemTraLoi(L.apDung(tl.d, { loai: 'CT_TRA_LOI_KHIEU_NAI', noiDung: 'Trả lời lần hai nhé' }, d.t + 3 * GIO, cfg), /đã trả lời/);
  kiemTraLoi(L.apDung(kn, { loai: 'CT_TRA_LOI_KHIEU_NAI', noiDung: 'Trả lời quá hạn rồi' }, d.t + 26 * GIO, cfg), /24 giờ/);
  const { d: khan, tacDong } = L.xuLyHan(kn, d.t + 73 * GIO, cfg);
  assert.ok(khan.khieuNai.coKhan);
  assert.deepEqual(tacDong[0].thongBao, [{ toi: 'admin', loai: 'khieu_nai_co_khan' }]);
});

test('admin quyết khiếu nại: chủ vi phạm / SV đã nhận phòng / SV không đến', () => {
  const d = dangGiu();
  const kn = L.apDung(d, { loai: 'SV_KHIEU_NAI', moTa: 'x' }, d.t + GIO, cfg).d;
  const cvp = L.apDung(kn, { loai: 'ADMIN_QUYET', ketLuan: 'chu_vi_pham', phongSau: 'hidden' }, d.t + 5 * GIO, cfg);
  assert.equal(cvp.d.lyDoKetThuc, 'owner_violation');
  assert.deepEqual(cvp.tien, ['hoan']);
  assert.deepEqual(cvp.viPham, ['khieu_nai_chap_nhan']);
  assert.equal(cvp.phong, 'hidden');
  assert.equal(cvp.d.danhGia.nhan, 'khieu_nai_chap_nhan');
  assert.equal(cvp.d.danhGia.han, d.t + 5 * GIO + 30 * NGAY);

  const daNhan = L.apDung(kn, { loai: 'ADMIN_QUYET', ketLuan: 'sv_da_nhan' }, d.t + 5 * GIO, cfg);
  assert.equal(daNhan.d.lyDoKetThuc, 'admin_released');
  assert.equal(daNhan.phong, 'rented');
  assert.ok(daNhan.khieuNaiSai, 'SV khiếu nại mà admin kết luận đã nhận phòng: tính khiếu nại sai');

  const khongDen = L.apDung(kn, { loai: 'ADMIN_QUYET', ketLuan: 'sv_khong_den' }, d.t + 5 * GIO, cfg);
  assert.equal(khongDen.d.status, 'forfeited');
  assert.equal(khongDen.d.lyDoKetThuc, 'student_no_show');
  assert.ok(khongDen.khieuNaiSai);
});

test('SV phản đối "không đến" mà admin kết luận đã nhận phòng: không tính khiếu nại sai', () => {
  const d = dangGiu();
  const bao = L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 3 * GIO, cfg).d;
  const pd = L.apDung(bao, { loai: 'SV_PHAN_DOI', moTa: 'x' }, d.t + 4 * GIO, cfg).d;
  assert.equal(L.apDung(pd, { loai: 'ADMIN_QUYET', ketLuan: 'sv_da_nhan' }, d.t + 5 * GIO, cfg).khieuNaiSai, false);
  assert.equal(L.apDung(pd, { loai: 'ADMIN_QUYET', ketLuan: 'sv_khong_den' }, d.t + 5 * GIO, cfg).khieuNaiSai, true);
});

test('admin kết luận chủ lừa đảo: held / disputed → refunded (admin_fraud), phòng hidden; released không đảo ngược', () => {
  const d = dangGiu();
  const r = L.apDung(d, { loai: 'ADMIN_LUA_DAO' }, d.t - GIO, cfg);
  assert.equal(r.d.lyDoKetThuc, 'admin_fraud');
  assert.equal(r.phong, 'hidden');
  const kn = L.apDung(d, { loai: 'SV_KHIEU_NAI', moTa: 'x' }, d.t + GIO, cfg).d;
  assert.equal(L.apDung(kn, { loai: 'ADMIN_LUA_DAO' }, d.t + 2 * GIO, cfg).d.status, 'refunded');
  const xong = L.apDung(d, { loai: 'SV_DA_NHAN' }, d.t, cfg).d;
  assert.ok(L.apDung(xong, { loai: 'ADMIN_LUA_DAO' }, d.t + GIO, cfg).boQua);
});

test('hai thao tác cùng lúc: thao tác đến trước thắng, thao tác sau báo đã thay đổi', () => {
  const d = dangGiu({ quyen: false });
  const chuHuy = L.apDung(d, { loai: 'CT_HUY_COC' }, d.t - GIO, cfg).d;
  kiemTraLoi(L.apDung(chuHuy, { loai: 'SV_KHONG_THUE' }, d.t - GIO, cfg), /đã thay đổi/);
  const bao = L.apDung(d, { loai: 'CT_BAO_KHONG_DEN' }, d.t + 3 * GIO, cfg).d;
  kiemTraLoi(L.apDung(bao, { loai: 'SV_DA_NHAN' }, d.t + 3 * GIO, cfg));
});

test('cấu hình ghi đè được để rút ngắn thời hạn khi test, bỏ qua khóa lạ', () => {
  const c = gopCauHinh({ tuHoanTatPhut: 5, khoaLa: 1, choThanhToanPhut: 'x' });
  assert.equal(c.tuHoanTatPhut, 5);
  assert.equal(c.choThanhToanPhut, 15);
  assert.ok(!('khoaLa' in c));
});
