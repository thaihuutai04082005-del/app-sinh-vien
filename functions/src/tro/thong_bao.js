'use strict';

const { admin, db, Timestamp } = require('../chung/firebase');

/**
 * Thông báo riêng của module Tìm trọ (mục 2.11).
 * Nhóm có `khoa: true` không tắt được (tiền cọc, nhận phòng, yêu cầu thay đổi, khiếu nại, kháng nghị).
 */
const NHOM = Object.freeze({
  giao_dich: { ten: 'Tiền cọc và nhận phòng', khoa: true },
  khieu_nai: { ten: 'Khiếu nại', khoa: true },
  khang_nghi: { ten: 'Kháng nghị và vi phạm', khoa: true },
  quan_ly_tin: { ten: 'Duyệt tin, tin sắp hết hạn', khoa: false },
  tin_nhan: { ten: 'Tin nhắn', khoa: false },
  nha_tro_da_luu: { ten: 'Nhà trọ đã lưu có phòng trống / giảm giá', khoa: false },
  danh_gia: { ten: 'Nhắc đánh giá, đánh giá mới', khoa: false },
  bao_cao: { ten: 'Kết quả báo cáo', khoa: false },
});

/** loai → [nhóm, tiêu đề, nội dung]. `{phong}` được thay bằng tên phòng. */
const MAU = Object.freeze({
  coc_thanh_cong: ['giao_dich', 'Đặt cọc thành công', 'Bạn đã cọc giữ {phong}. Xem thời điểm nhận phòng và hạn hủy miễn phí trong khoản cọc.'],
  co_nguoi_coc: ['giao_dich', 'Có người đặt cọc', 'Có sinh viên vừa cọc giữ {phong}. Xem thời điểm nhận phòng trong Quản lý tiền cọc.'],
  thanh_toan_het_han: ['giao_dich', 'Thanh toán hết hạn', 'Khoản cọc {phong} đã hết hạn thanh toán, phòng không được giữ.'],
  thanh_toan_that_bai: ['giao_dich', 'Thanh toán không thành công', 'Thanh toán cọc {phong} không thành công, bạn chưa bị trừ tiền.'],
  tien_den_muon_da_hoan: ['giao_dich', 'Đã hoàn tiền', 'Tiền cọc {phong} về sau hạn thanh toán nên không được nhận. Đã hoàn 100%.'],
  huy_mien_phi_da_hoan: ['giao_dich', 'Đã hủy và hoàn 100%', 'Bạn đã hủy cọc {phong} trong 30 phút đầu. Tiền cọc đã được hoàn 100%.'],
  sv_huy_trong_30_phut: ['giao_dich', 'Sinh viên đã hủy cọc', 'Sinh viên đã hủy cọc {phong} trong 30 phút đầu. Phòng mở lại.'],
  mat_coc_khong_thue: ['giao_dich', 'Đã báo không thuê nữa', 'Bạn đã báo không thuê {phong}. Tiền cọc được chuyển cho chủ trọ theo chính sách cọc.'],
  sv_khong_thue_da_nhan_tien: ['giao_dich', 'Sinh viên không thuê nữa', 'Sinh viên đã báo không thuê {phong}. Bạn đã nhận tiền cọc, phòng mở lại.'],
  chu_huy_coc_da_hoan: ['giao_dich', 'Chủ trọ đã hủy cọc', 'Chủ trọ đã hủy cọc {phong}. Bạn được hoàn 100% tiền cọc.'],
  bi_ghi_vi_pham: ['khang_nghi', 'Bạn bị ghi 1 vi phạm', 'Bạn bị ghi 1 vi phạm trong Tìm trọ. 3 vi phạm trong 90 ngày sẽ bị khóa đăng tin / nhận cọc 30 ngày. Bạn có thể kháng nghị trong 7 ngày.'],
  co_yeu_cau_doi: ['giao_dich', 'Yêu cầu thay đổi thời điểm nhận phòng', 'Sinh viên xin đổi thời điểm nhận phòng {phong}. Trả lời trong 24 giờ, nếu không sẽ hoàn 100% cho sinh viên và bạn bị ghi vi phạm.'],
  nhac_tra_loi_doi: ['giao_dich', 'Sắp hết hạn trả lời yêu cầu thay đổi', 'Bạn chưa trả lời yêu cầu đổi thời điểm nhận phòng {phong}. Quá hạn sẽ hoàn 100% cho sinh viên và bạn bị ghi vi phạm.'],
  chu_dong_y_doi: ['giao_dich', 'Chủ trọ đồng ý đổi thời điểm', 'Chủ trọ đã đồng ý thời điểm nhận phòng mới cho {phong}.'],
  chu_tu_choi_doi: ['giao_dich', 'Chủ trọ từ chối đổi thời điểm', 'Chủ trọ từ chối đổi thời điểm nhận phòng {phong}. Thời điểm cũ vẫn hiệu lực.'],
  doi_qua_han_da_hoan: ['giao_dich', 'Đã hoàn 100% tiền cọc', 'Chủ trọ không trả lời yêu cầu thay đổi {phong} trong 24 giờ. Giao dịch đã hủy và bạn được hoàn 100%.'],
  sap_het_han_gui_doi: ['giao_dich', 'Sắp hết hạn gửi yêu cầu thay đổi', 'Còn 12 giờ để gửi yêu cầu đổi thời điểm nhận phòng {phong} (nếu cần).'],
  nhac_nhan_phong: ['giao_dich', 'Ngày mai nhận phòng', 'Còn 1 ngày tới thời điểm nhận phòng {phong}.'],
  toi_thoi_diem_nhan_phong: ['giao_dich', 'Đã tới thời điểm nhận phòng', 'Nhận phòng {phong} xong hãy bấm "Đã nhận phòng". Chủ trọ không đúng cam kết thì báo vấn đề trong 48 giờ.'],
  chu_bao_khong_den: ['giao_dich', 'Chủ trọ báo bạn không đến nhận phòng', 'Chủ trọ báo bạn không đến nhận {phong}. Bạn có 12 giờ để phản đối, không phản đối sẽ mất cọc.'],
  nhac_phan_doi: ['giao_dich', 'Còn 2 giờ để phản đối', 'Còn 2 giờ để phản đối báo "không đến nhận phòng" {phong}.'],
  sv_phan_doi_khong_den: ['khieu_nai', 'Sinh viên phản đối', 'Sinh viên phản đối báo "không đến" {phong}. Admin sẽ xem xét, bạn có thể trả lời kèm bằng chứng trong 24 giờ.'],
  bo_coc_khong_den: ['giao_dich', 'Mất cọc do không đến nhận phòng', 'Bạn không phản đối trong 12 giờ nên khoản cọc {phong} chuyển cho chủ trọ.'],
  bo_coc_da_nhan_tien: ['giao_dich', 'Đã nhận tiền cọc', 'Sinh viên không đến nhận {phong} và không phản đối. Bạn đã nhận tiền cọc, phòng mở lại.'],
  nhac_cuoi: ['giao_dich', 'Nhắc lần cuối', 'Đã 24 giờ từ thời điểm nhận phòng {phong}. Sau 48 giờ, nếu không ai báo vấn đề, giao dịch tự hoàn tất và tiền cọc chuyển cho chủ trọ.'],
  tu_hoan_tat: ['giao_dich', 'Giao dịch đã tự hoàn tất', 'Hết 48 giờ không ai báo vấn đề, khoản cọc {phong} đã tự hoàn tất.'],
  tu_hoan_tat_da_nhan_tien: ['giao_dich', 'Đã nhận tiền cọc', 'Khoản cọc {phong} đã tự hoàn tất sau 48 giờ. Bạn đã nhận tiền.'],
  sv_da_nhan_phong: ['giao_dich', 'Sinh viên đã nhận phòng', 'Sinh viên đã xác nhận nhận {phong}. Bạn đã nhận tiền cọc.'],
  duoc_viet_danh_gia: ['danh_gia', 'Bạn có thể đánh giá', 'Hãy viết đánh giá cho nhà trọ của {phong} để giúp các bạn sinh viên khác.'],
  co_khieu_nai: ['khieu_nai', 'Có khiếu nại', 'Sinh viên khiếu nại khoản cọc {phong}. Trả lời kèm bằng chứng trong 24 giờ.'],
  khieu_nai_moi: ['khieu_nai', 'Khiếu nại cọc mới', 'Có khiếu nại cọc mới cần xử lý ({phong}).'],
  khieu_nai_co_khan: ['khieu_nai', 'Khiếu nại có cờ khẩn', 'Khiếu nại cọc {phong} đã treo quá 72 giờ.'],
  chu_tra_loi_khieu_nai: ['khieu_nai', 'Chủ trọ đã trả lời khiếu nại', 'Chủ trọ đã trả lời khiếu nại {phong}.'],
  ket_qua_khieu_nai: ['khieu_nai', 'Có kết quả khiếu nại', 'Admin đã quyết định khiếu nại khoản cọc {phong}. Xem chi tiết trong khoản cọc.'],
  chu_lua_dao_da_hoan: ['giao_dich', 'Đã hoàn 100% tiền cọc', 'Chủ trọ của {phong} bị kết luận vi phạm nghiêm trọng. Bạn được hoàn 100% tiền cọc.'],
  ket_luan_lua_dao: ['khang_nghi', 'Nhà trọ bị ẩn', 'Admin kết luận vi phạm nghiêm trọng với {phong}. Các khoản cọc đang giữ đã được hoàn cho sinh viên.'],
});

function thayThe(s, bien) {
  return s.replace(/\{(\w+)\}/g, (_, k) => (bien[k] != null ? bien[k] : ''));
}

/**
 * Ghi thông báo trong transaction `tx` (hoặc batch). Id cố định theo `khoa` nên chạy lại
 * không tạo 2 thông báo (mục 2.18 quy tắc 6). `caiDat` = cài đặt thông báo của người nhận.
 */
function ghiThongBao(tx, { khoa, nguoiNhan, loai, bien = {}, moTrang = null, caiDat = {}, tieuDe, noiDung, nhom }) {
  if (!nguoiNhan) return null;
  const mau = MAU[loai];
  const n = nhom || (mau && mau[0]) || 'quan_ly_tin';
  const nhomInfo = NHOM[n] || { khoa: false };
  if (!nhomInfo.khoa && caiDat[n] === false) return null;
  const id = `${khoa}_${nguoiNhan}`.replace(/\//g, '_');
  const ref = db.collection('tro_thong_bao').doc(id);
  tx.set(ref, {
    nguoiNhan,
    loai,
    nhom: n,
    tieuDe: tieuDe || (mau ? mau[1] : loai),
    noiDung: noiDung || (mau ? thayThe(mau[2], bien) : ''),
    moTrang,
    taoLuc: Timestamp.now(),
    docLuc: null,
    daDay: false,
  });
  return id;
}

/** Gửi thông báo đẩy cho các thông báo chưa đẩy (gọi sau khi transaction xong). */
async function dayThongBao(ids) {
  for (const id of ids) {
    try {
      const ref = db.collection('tro_thong_bao').doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.get('daDay')) continue;
      const tb = snap.data();
      const tb2 = await db.collection('thiet_bi').where('uid', '==', tb.nguoiNhan).get();
      const tokens = tb2.docs.map((d) => d.get('token')).filter(Boolean);
      if (tokens.length) {
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: { title: tb.tieuDe, body: tb.noiDung },
          data: { module: 'tro', thongBaoId: id },
        });
      }
      await ref.update({ daDay: true });
    } catch (e) {
      console.warn('Không đẩy được thông báo', id, e.message);
    }
  }
}

module.exports = { NHOM, MAU, ghiThongBao, dayThongBao };
