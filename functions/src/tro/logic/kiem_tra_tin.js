'use strict';

/**
 * Kiểm tra dữ liệu nhà trọ / phòng trước khi gửi duyệt (mục 2.3). Logic thuần, test được.
 * Trả về danh sách lỗi (rỗng = hợp lệ).
 */

const TIEN_ICH_CHUNG = ['wifi', 'cho_de_xe', 'camera', 'may_giat', 'khoa_van_tay'];
const TIEN_ICH_PHONG = ['may_lanh', 'wc_rieng', 'nong_lanh', 'tu_lanh', 'noi_that', 'ban_cong'];
const LOAI_HINH = ['phong', 'nguyen_can'];

function boDau(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

const laHttps = (u) => typeof u === 'string' && /^https:\/\/[^\s]+$/.test(u) && u.length <= 2000;
const laSo = (x) => typeof x === 'number' && Number.isFinite(x);

function kiemTraNoiQuy(nq) {
  const loi = [];
  if (!nq || typeof nq !== 'object') return ['Chọn đủ 4 tiêu chí nội quy.'];
  if (!['tu_do', 'gioi_han'].includes(nq.gioGiac)) loi.push('Chọn giờ giấc ra vào.');
  if (nq.gioGiac === 'gioi_han' && !/^([01]\d|2[0-3]):[0-5]\d$/.test(nq.gioDongCua || '')) {
    loi.push('Nhập giờ đóng cửa (ví dụ 22:00).');
  }
  if (typeof nq.thuCung !== 'boolean') loi.push('Chọn có cho nuôi thú cưng không.');
  if (typeof nq.oQuaDem !== 'boolean') loi.push('Chọn có cho ở qua đêm không.');
  if (![1, 2, 3].includes(nq.baoTruocTuan)) loi.push('Chọn thời gian báo trước khi trả phòng.');
  return loi;
}

function kiemTraAnhVideo(n, cfg) {
  const loi = [];
  const anh = Array.isArray(n.anh) ? n.anh : [];
  const video = Array.isArray(n.video) ? n.video : [];
  if (anh.length < cfg.anhToiThieu || anh.length > cfg.anhToiDa) {
    loi.push(`Cần ${cfg.anhToiThieu}–${cfg.anhToiDa} ảnh.`);
  }
  if (!anh.every(laHttps)) loi.push('Ảnh phải là link https hợp lệ.');
  if (video.length < cfg.videoToiThieu || video.length > cfg.videoToiDa) {
    loi.push(`Cần ${cfg.videoToiThieu}–${cfg.videoToiDa} video.`);
  }
  if (!video.every(laHttps)) loi.push('Video phải là link https hợp lệ.');
  if (!n.anhBia || ![...anh].includes(n.anhBia)) loi.push('Chọn ảnh bìa.');
  return loi;
}

function kiemTraNhaTro(n, cfg) {
  const loi = [];
  const ten = String(n.ten || '').trim();
  if (ten.length < 5 || ten.length > 80) loi.push('Tên nhà trọ 5–80 ký tự.');
  if (!LOAI_HINH.includes(n.loaiHinh)) loi.push('Chọn loại hình cho thuê.');
  if (!(Number.isInteger(n.tongSoPhong) && n.tongSoPhong >= 1)) loi.push('Nhập tổng số phòng.');
  if (!(Number.isInteger(n.soTang) && n.soTang >= 1)) loi.push('Nhập số tầng.');
  if (!Array.isArray(n.tienIchChung) || !n.tienIchChung.every((x) => TIEN_ICH_CHUNG.includes(x))) {
    loi.push('Tiện ích chung không hợp lệ.');
  }
  loi.push(...kiemTraNoiQuy(n.noiQuy));
  if (String(n.moTa || '').trim().length < 30) loi.push('Mô tả ít nhất 30 ký tự.');
  if (String(n.diaChi || '').trim().length < 5) loi.push('Nhập địa chỉ đầy đủ.');
  if (!n.viTri || !laSo(n.viTri.lat) || !laSo(n.viTri.lng) || Math.abs(n.viTri.lat) > 90 || Math.abs(n.viTri.lng) > 180) {
    loi.push('Ghim vị trí nhà trọ trên bản đồ.');
  }
  loi.push(...kiemTraAnhVideo(n, cfg));
  if (!Array.isArray(n.giayTo) || n.giayTo.length < 1) loi.push('Tải lên giấy tờ nhà (hoặc hợp đồng thuê nếu cho thuê lại).');
  if (n.camKet !== true) loi.push('Tick cam kết thông tin đúng sự thật.');
  return loi;
}

function kiemTraChiPhi(p) {
  const loi = [];
  if (!(laSo(p.giaThue) && p.giaThue > 0)) loi.push('Giá thuê phải lớn hơn 0.');
  if (!(laSo(p.tienCoc) && p.tienCoc > 0)) loi.push('Nhập số tiền cọc.');
  else if (laSo(p.giaThue) && p.tienCoc > p.giaThue) loi.push('Tiền cọc tối đa 1 tháng tiền thuê.');
  const dien = p.tienDien || {};
  if (!['theo_so', 'co_dinh'].includes(dien.cach) || !(laSo(dien.gia) && dien.gia >= 0)) loi.push('Nhập tiền điện.');
  const nuoc = p.tienNuoc || {};
  if (!['theo_khoi', 'theo_nguoi', 'co_dinh'].includes(nuoc.cach) || !(laSo(nuoc.gia) && nuoc.gia >= 0)) loi.push('Nhập tiền nước.');
  if (p.phiKhac != null && (!Array.isArray(p.phiKhac) || !p.phiKhac.every((x) => x && String(x.ten || '').trim() && laSo(x.gia) && x.gia >= 0))) {
    loi.push('Phí khác không hợp lệ.');
  }
  if (p.hopDongToiThieu != null && !(Number.isInteger(p.hopDongToiThieu) && p.hopDongToiThieu >= 1)) {
    loi.push('Hợp đồng tối thiểu (tháng) không hợp lệ.');
  }
  return loi;
}

/** `tenKhac` = tên các phòng khác trong cùng nhà trọ (không được trùng). */
function kiemTraPhong(p, { loaiHinh, tenKhac = [] }, cfg) {
  const loi = [];
  const ten = String(p.ten || '').trim();
  if (!ten) loi.push('Nhập tên / số phòng.');
  else if (tenKhac.map((x) => boDau(x)).includes(boDau(ten))) loi.push('Tên phòng bị trùng trong nhà trọ.');
  if (loaiHinh === 'phong' && typeof p.coGac !== 'boolean') loi.push('Chọn có gác hay không.');
  if (!(laSo(p.dienTich) && p.dienTich > 0)) loi.push('Diện tích sàn phải lớn hơn 0.');
  if (p.coGac && !(laSo(p.dienTichGac) && p.dienTichGac > 0)) loi.push('Nhập diện tích gác.');
  if (!(Number.isInteger(p.soNguoiToiDa) && p.soNguoiToiDa >= 1)) loi.push('Số người ở tối đa ít nhất 1.');
  if (loaiHinh === 'nguyen_can') {
    if (!(Number.isInteger(p.soPhongNgu) && p.soPhongNgu >= 1)) loi.push('Nhập số phòng ngủ.');
    if (!(Number.isInteger(p.soWc) && p.soWc >= 1)) loi.push('Nhập số WC.');
    if (typeof p.coBep !== 'boolean') loi.push('Chọn có bếp không.');
  }
  if (!Array.isArray(p.tienIch) || !p.tienIch.every((x) => TIEN_ICH_PHONG.includes(x))) loi.push('Tiện ích phòng không hợp lệ.');
  loi.push(...kiemTraChiPhi(p));
  loi.push(...kiemTraAnhVideo(p, cfg));
  return loi;
}

/** Chữ tìm kiếm không dấu: tên + địa chỉ (đường, phường). */
function chuTimKiem(n) {
  return boDau([n.ten, n.diaChi, n.duong, n.phuong].filter(Boolean).join(' '));
}

module.exports = {
  TIEN_ICH_CHUNG, TIEN_ICH_PHONG, LOAI_HINH, boDau, laHttps, kiemTraNoiQuy, kiemTraNhaTro, kiemTraPhong, kiemTraChiPhi, chuTimKiem,
};
