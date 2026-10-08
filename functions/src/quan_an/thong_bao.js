'use strict';

const { admin, db, Timestamp } = require('../chung/firebase');

/**
 * Thông báo riêng của module Quán ăn (mục 3.11).
 * Nhóm có `khoa: true` không tắt được (tiền, đơn hàng, đặt bàn, khiếu nại, kháng nghị).
 */
const NHOM = Object.freeze({
  giao_dich: { ten: 'Tiền và thanh toán', khoa: true },
  don_hang: { ten: 'Đơn hàng', khoa: true },
  dat_ban: { ten: 'Đặt bàn', khoa: true },
  khieu_nai: { ten: 'Khiếu nại', khoa: true },
  khang_nghi: { ten: 'Kháng nghị và vi phạm', khoa: true },
  quan_ly_quan: { ten: 'Duyệt quán, nhắc xác nhận quán còn hoạt động', khoa: false },
  tin_nhan: { ten: 'Tin nhắn', khoa: false },
  quan_da_luu: { ten: 'Quán đã lưu có khuyến mãi / mở lại', khoa: false },
  danh_gia: { ten: 'Đánh giá mới', khoa: false },
  nhac_danh_gia: { ten: 'Nhắc đánh giá', khoa: false },
  bao_cao: { ten: 'Kết quả báo cáo', khoa: false },
});

/** loai → [nhóm, tiêu đề, nội dung]. `{quan}` được thay bằng tên quán. */
const MAU = Object.freeze({
  // ---- Đơn món: sinh viên ----
  thanh_toan_thanh_cong: ['giao_dich', 'Thanh toán thành công', 'Đơn của bạn tại {quan} đã được gửi tới quán. Tiền được giữ tới khi bạn nhận món.'],
  thanh_toan_het_han: ['giao_dich', 'Thanh toán hết hạn', 'Đơn tại {quan} đã hết hạn thanh toán và không được gửi tới quán.'],
  thanh_toan_that_bai: ['giao_dich', 'Thanh toán không thành công', 'Thanh toán đơn tại {quan} không thành công, bạn chưa bị trừ tiền.'],
  tien_den_muon_da_hoan: ['giao_dich', 'Đã hoàn tiền', 'Tiền thanh toán đơn tại {quan} về sau hạn nên không được nhận. Đã hoàn 100%.'],
  quan_da_nhan: ['don_hang', 'Quán đã nhận đơn', '{quan} đã nhận đơn và đang chuẩn bị.'],
  quan_tu_choi_da_hoan: ['don_hang', 'Quán từ chối đơn', '{quan} từ chối đơn của bạn. Nếu đã trả trên app, bạn được hoàn 100%.'],
  quan_khong_xac_nhan_da_hoan: ['don_hang', 'Quán không xác nhận kịp', '{quan} không xác nhận đơn trong 5 phút nên đơn đã hủy. Nếu đã trả trên app, bạn được hoàn 100%.'],
  quan_huy_don_da_hoan: ['don_hang', 'Quán hủy đơn', '{quan} đã hủy đơn của bạn. Nếu đã trả trên app, bạn được hoàn 100%.'],
  quan_ngung_nhan_da_hoan: ['don_hang', 'Đơn đã bị hủy', '{quan} ngừng nhận đơn nên đơn của bạn đã hủy. Nếu đã trả trên app, bạn được hoàn 100%.'],
  huy_quan_cham_da_hoan: ['giao_dich', 'Đã hủy vì quán chậm', 'Bạn đã hủy đơn tại {quan} vì quán chậm. Nếu đã trả trên app, bạn được hoàn 100%.'],
  sv_huy_da_hoan: ['giao_dich', 'Đã hủy đơn', 'Bạn đã hủy đơn tại {quan}. Nếu đã trả trên app, bạn được hoàn 100%.'],
  don_san_sang_lay: ['don_hang', 'Món đã sẵn sàng', 'Đơn tại {quan} đã sẵn sàng. Đọc mã nhận món 4 số cho quán khi tới lấy.'],
  don_dang_giao: ['don_hang', 'Đơn đang được giao', 'Đơn tại {quan} đang trên đường giao tới bạn.'],
  quan_ghi_nhan_da_giao: ['don_hang', 'Quán đã ghi nhận giao / lấy món', 'Hãy kiểm tra món. Bạn có 24 giờ để báo nếu có vấn đề, sau đó đơn tự hoàn tất.'],
  nhac_xac_nhan_nhan_mon: ['don_hang', 'Nhắc xác nhận nhận món', 'Bạn nhận đủ món chưa? Bấm "Đã nhận món" hoặc báo vấn đề trước khi hết hạn.'],
  don_tu_hoan_tat: ['don_hang', 'Đơn đã hoàn tất', 'Hết 24 giờ không có phản đối, đơn tại {quan} đã tự hoàn tất.'],
  don_tu_hoan_tat_da_nhan_tien: ['giao_dich', 'Đơn hoàn tất', 'Đơn của {quan} đã hoàn tất. Nếu đơn trả trên app, bạn đã nhận tiền.'],
  sv_da_nhan_mon: ['giao_dich', 'Sinh viên đã nhận món', 'Sinh viên đã xác nhận nhận món. Đơn hoàn tất.'],
  duoc_viet_danh_gia: ['nhac_danh_gia', 'Bạn có thể đánh giá', 'Hãy đánh giá {quan} để giúp các bạn sinh viên khác.'],
  chu_bao_khong_nhan: ['khieu_nai', 'Quán báo bạn không nhận món', '{quan} báo khách không nhận món. Bạn có 24 giờ để phản đối, không phản đối sẽ bị tính 1 lần bom hàng.'],
  bi_tinh_bom_hang: ['khang_nghi', 'Bạn bị tính 1 lần bom hàng', 'Không phản đối trong 24 giờ nên bạn bị tính 1 lần bom hàng. 2 lần / 30 ngày mất tiền mặt, 3 lần khóa đặt món 7 ngày. Bạn có thể kháng nghị.'],
  ket_qua_khieu_nai: ['khieu_nai', 'Có kết quả khiếu nại', 'Khiếu nại đơn tại {quan} đã có quyết định. Xem chi tiết trong đơn.'],
  chu_tra_loi_khieu_nai: ['khieu_nai', 'Quán đã trả lời khiếu nại', '{quan} đã trả lời khiếu nại của bạn.'],
  don_qua_han_chuyen_admin: ['don_hang', 'Đơn chuyển admin xem xét', 'Đơn tại {quan} quá 6 giờ chưa có bằng chứng giao / nhận, đã chuyển admin. Tiền tiếp tục được giữ.'],
  don_dang_ra_soat: ['don_hang', 'Đơn đang được rà soát', 'Đơn tại {quan} đang được admin rà soát. Tiền tiếp tục được giữ tới khi có quyết định.'],
  // ---- Đơn món: chủ quán ----
  don_moi: ['don_hang', 'Có đơn mới', 'Có đơn mới tại {quan}. Nhận đơn trong 5 phút.'],
  nhac_don_moi: ['don_hang', 'Đơn mới chưa được nhận', 'Còn đơn mới chưa nhận tại {quan}. Quá 5 phút đơn sẽ tự hủy.'],
  don_het_han_xac_nhan: ['don_hang', 'Đơn hết hạn xác nhận', 'Bạn không xác nhận đơn kịp. 3 lần trong 1 ngày quán sẽ tự tạm ngưng nhận đơn.'],
  sv_huy_don: ['don_hang', 'Sinh viên hủy đơn', 'Sinh viên đã hủy đơn khi quán chưa nhận.'],
  sv_huy_quan_cham: ['don_hang', 'Sinh viên hủy vì quán chậm', 'Sinh viên đã hủy đơn vì quán chậm. Tỷ lệ nhận đơn của quán bị giảm.'],
  co_khieu_nai: ['khieu_nai', 'Có khiếu nại', 'Sinh viên khiếu nại / báo chưa nhận món. Trả lời kèm bằng chứng trong 2 giờ.'],
  sv_phan_doi_khong_nhan: ['khieu_nai', 'Sinh viên phản đối', 'Sinh viên phản đối báo "Khách không nhận". Admin sẽ xem xét.'],
  // ---- Admin ----
  khieu_nai_moi: ['khieu_nai', 'Khiếu nại đơn mới', 'Có khiếu nại đơn cần xử lý.'],
  khieu_nai_co_khan: ['khieu_nai', 'Khiếu nại có cờ khẩn', 'Một khiếu nại đơn đã treo quá 72 giờ.'],
  phan_doi_khong_nhan_moi: ['khieu_nai', 'Phản đối "khách không nhận"', 'Có phản đối "khách không nhận" cần xử lý.'],
  don_qua_han_6h: ['don_hang', 'Đơn quá 6 giờ chưa có bằng chứng', 'Có đơn quá 6 giờ chưa có bằng chứng giao / nhận. Tiền đang giữ.'],
  don_ra_soat_lua_dao: ['don_hang', 'Đơn cần rà soát', 'Có đơn cần rà soát do quán bị kết luận lừa đảo.'],
  // ---- Đặt bàn ----
  ban_moi: ['dat_ban', 'Yêu cầu đặt bàn mới', 'Có yêu cầu đặt bàn mới tại {quan}. Xác nhận trong hạn.'],
  ban_da_xac_nhan: ['dat_ban', 'Quán đã xác nhận bàn', '{quan} đã xác nhận bàn của bạn. Quán giữ bàn 15 phút.'],
  ban_bi_tu_choi: ['dat_ban', 'Đặt bàn không được nhận', '{quan} không nhận yêu cầu đặt bàn của bạn.'],
  ban_het_han: ['dat_ban', 'Đặt bàn hết hạn', '{quan} không trả lời yêu cầu đặt bàn, yêu cầu đã hết hạn.'],
  ban_bi_quan_huy: ['dat_ban', 'Quán hủy bàn', '{quan} đã hủy bàn của bạn. Bạn không bị tính lỗi.'],
  nhac_dat_ban: ['dat_ban', 'Sắp tới giờ đặt bàn', 'Còn 1 giờ tới giờ hẹn tại {quan}. Nhớ check-in khi tới.'],
  sv_huy_ban: ['dat_ban', 'Sinh viên hủy bàn', 'Sinh viên đã hủy bàn.'],
  huy_sat_gio_bi_ghi: ['khang_nghi', 'Hủy sát giờ', 'Hủy bàn đã xác nhận dưới 1 giờ trước giờ hẹn bị tính 1 lần bỏ hẹn. Bạn có thể kháng nghị.'],
  bi_ghi_bo_hen: ['khang_nghi', 'Bạn bị tính 1 lần bỏ hẹn', 'Quán báo bạn không đến. 3 lần / 30 ngày khóa đặt bàn 7 ngày. Bạn có thể kháng nghị.'],
  // ---- Quán ----
  quan_cho_duyet: ['quan_ly_quan', 'Quán chờ duyệt', 'Có quán / bản chỉnh sửa chờ duyệt.'],
  quan_duoc_duyet: ['quan_ly_quan', 'Quán đã được duyệt', 'Quán "{quan}" đã được duyệt và hiển thị khi có ít nhất 3 món.'],
  quan_bi_tu_choi: ['quan_ly_quan', 'Quán chưa được duyệt', 'Quán "{quan}" chưa được duyệt. Xem lý do, sửa và gửi lại.'],
  chinh_sua_duoc_duyet: ['quan_ly_quan', 'Bản chỉnh sửa đã được duyệt', 'Thay đổi của quán "{quan}" đã được duyệt.'],
  chinh_sua_bi_tu_choi: ['quan_ly_quan', 'Bản chỉnh sửa bị từ chối', 'Thay đổi của quán "{quan}" bị từ chối, quán giữ thông tin cũ.'],
  yeu_cau_chuyen_loai: ['quan_ly_quan', 'Yêu cầu chuyển loại quán', 'Admin yêu cầu quán "{quan}" chuyển sang hộ kinh doanh trong 7 ngày, nếu không quán sẽ bị ẩn.'],
  quan_nghi_khai_sai: ['quan_ly_quan', 'Quán nghi khai sai loại', 'Có quán bị cảnh báo nghi khai sai loại hình cần xem lại.'],
  nhac_con_hoat_dong: ['quan_ly_quan', 'Quán còn hoạt động không?', 'Quán "{quan}" lâu chưa có hoạt động. Bấm "Quán vẫn hoạt động" trong 7 ngày, nếu không quán sẽ bị ẩn.'],
  quan_bi_an_khong_xac_nhan: ['quan_ly_quan', 'Quán đã bị ẩn', 'Quán "{quan}" bị ẩn vì không xác nhận còn hoạt động.'],
  quan_bi_an_khong_chuyen_loai: ['quan_ly_quan', 'Quán đã bị ẩn', 'Quán "{quan}" bị ẩn vì chưa chuyển loại hình trong 7 ngày.'],
  quan_tu_tam_ngung: ['don_hang', 'Quán tự tạm ngưng nhận đơn', 'Quán "{quan}" quá hạn xác nhận 3 lần trong ngày nên tự tạm ngưng nhận đơn tới hết ngày.'],
  quan_bi_an: ['khang_nghi', 'Quán bị ẩn', 'Admin đã ẩn quán "{quan}". Bạn có thể kháng nghị trong 7 ngày.'],
  quan_bi_dinh_chi: ['khang_nghi', 'Quán bị đình chỉ', 'Admin đã đình chỉ quán "{quan}". Bạn có thể kháng nghị trong 7 ngày.'],
  quan_bi_khoa_ban: ['khang_nghi', 'Bị khóa bán trong Quán ăn', 'Bạn bị khóa đăng quán và nhận đơn trong Quán ăn. Bạn có thể kháng nghị trong 7 ngày.'],
  quan_da_luu_khuyen_mai: ['quan_da_luu', 'Quán bạn lưu có khuyến mãi', '{quan} vừa có khuyến mãi mới.'],
  quan_da_luu_mo_lai: ['quan_da_luu', 'Quán bạn lưu đã mở lại', '{quan} đã mở lại sau kỳ nghỉ.'],
  bi_ghi_vi_pham: ['khang_nghi', 'Bạn bị ghi 1 vi phạm', 'Bạn bị ghi 1 vi phạm trong Quán ăn. Bạn có thể kháng nghị trong 7 ngày.'],
  danh_gia_moi: ['danh_gia', 'Có đánh giá mới', '"{quan}" có đánh giá mới.'],
});

function thayThe(s, bien) {
  return s.replace(/\{(\w+)\}/g, (_, k) => (bien[k] != null ? bien[k] : ''));
}

/**
 * Ghi thông báo trong transaction `tx` (hoặc batch). Id cố định theo `khoa` nên chạy lại không tạo 2
 * thông báo (mục 3.18 quy tắc 6). `caiDat` = cài đặt thông báo của người nhận.
 */
function ghiThongBao(tx, { khoa, nguoiNhan, loai, bien = {}, moTrang = null, caiDat = {}, tieuDe, noiDung, nhom }) {
  if (!nguoiNhan) return null;
  const mau = MAU[loai];
  const n = nhom || (mau && mau[0]) || 'quan_ly_quan';
  const nhomInfo = NHOM[n] || { khoa: false };
  if (!nhomInfo.khoa && caiDat[n] === false) return null;
  const id = `${khoa}_${nguoiNhan}`.replace(/\//g, '_');
  tx.set(db.collection('qa_thong_bao').doc(id), {
    nguoiNhan, loai, nhom: n,
    tieuDe: tieuDe || (mau ? mau[1] : loai),
    noiDung: noiDung || (mau ? thayThe(mau[2], bien) : ''),
    moTrang, taoLuc: Timestamp.now(), docLuc: null, daDay: false,
  });
  return id;
}

/** Gửi thông báo đẩy cho các thông báo chưa đẩy (gọi sau khi transaction xong). */
async function dayThongBao(ids) {
  for (const id of ids) {
    try {
      const ref = db.collection('qa_thong_bao').doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.get('daDay')) continue;
      const tb = snap.data();
      const ds = await db.collection('thiet_bi').where('uid', '==', tb.nguoiNhan).get();
      const tokens = ds.docs.map((d) => d.get('token')).filter(Boolean);
      if (tokens.length) {
        await admin.messaging().sendEachForMulticast({
          tokens, notification: { title: tb.tieuDe, body: tb.noiDung }, data: { module: 'quan_an', thongBaoId: id },
        });
      }
      await ref.update({ daDay: true });
    } catch (e) {
      console.warn('Không đẩy được thông báo', id, e.message);
    }
  }
}

module.exports = { NHOM, MAU, ghiThongBao, dayThongBao };
