/// Con số quy định và nhãn của module Tìm trọ (đặc tả mục 2.16).
///
/// Hệ thống (Cloud Functions) là nơi quyết định; app chỉ dùng các con số này để
/// hiển thị và chặn sớm trên giao diện. Giá trị thật được tải từ server qua
/// [TroConfig.fromMap] (admin có thể rút ngắn thời hạn khi test), không viết cứng ở màn hình.
class TroConfig {
  const TroConfig({
    this.anhToiThieu = 3,
    this.anhToiDa = 10,
    this.videoToiThieu = 1,
    this.videoToiDa = 2,
    this.choThanhToanPhut = 15,
    this.nhanPhongSauItNhatPhut = 120,
    this.nhanPhongToiDaPhut = 14 * 24 * 60,
    this.huyMienPhiPhut = 30,
    this.huyMienPhiSoLan = 2,
    this.doiPhaiTruocPhut = 24 * 60,
    this.doiCachLucGuiItNhatPhut = 24 * 60,
    this.doiToiDaSauTBanDauPhut = 14 * 24 * 60,
    this.anHanKhongDenPhut = 3 * 60,
    this.baoKhongDenDenPhut = 48 * 60,
    this.phanDoiPhut = 12 * 60,
    this.khieuNaiDenPhut = 48 * 60,
    this.tuHoanTatPhut = 48 * 60,
    this.danhGiaNhanXetToiThieu = 20,
    this.danhGiaAnhToiDa = 5,
    this.khangNghiBangChungToiDa = 3,
    this.banKinhMet = const [300, 500, 1000, 2000, 3000, 5000],
  });

  final int anhToiThieu;
  final int anhToiDa;
  final int videoToiThieu;
  final int videoToiDa;
  final num choThanhToanPhut;
  final num nhanPhongSauItNhatPhut;
  final num nhanPhongToiDaPhut;
  final num huyMienPhiPhut;
  final int huyMienPhiSoLan;
  final num doiPhaiTruocPhut;
  final num doiCachLucGuiItNhatPhut;
  final num doiToiDaSauTBanDauPhut;
  final num anHanKhongDenPhut;
  final num baoKhongDenDenPhut;
  final num phanDoiPhut;
  final num khieuNaiDenPhut;
  final num tuHoanTatPhut;
  final int danhGiaNhanXetToiThieu;
  final int danhGiaAnhToiDa;
  final int khangNghiBangChungToiDa;
  final List<int> banKinhMet;

  static Duration phut(num p) => Duration(milliseconds: (p * 60000).round());

  factory TroConfig.fromMap(Map<String, dynamic> m) {
    const d = TroConfig();
    num n(String k, num v) => m[k] is num ? m[k] as num : v;
    int i(String k, int v) => m[k] is num ? (m[k] as num).toInt() : v;
    return TroConfig(
      anhToiThieu: i('anhToiThieu', d.anhToiThieu),
      anhToiDa: i('anhToiDa', d.anhToiDa),
      videoToiThieu: i('videoToiThieu', d.videoToiThieu),
      videoToiDa: i('videoToiDa', d.videoToiDa),
      choThanhToanPhut: n('choThanhToanPhut', d.choThanhToanPhut),
      nhanPhongSauItNhatPhut: n(
        'nhanPhongSauItNhatPhut',
        d.nhanPhongSauItNhatPhut,
      ),
      nhanPhongToiDaPhut: n('nhanPhongToiDaPhut', d.nhanPhongToiDaPhut),
      huyMienPhiPhut: n('huyMienPhiPhut', d.huyMienPhiPhut),
      huyMienPhiSoLan: i('huyMienPhiSoLan', d.huyMienPhiSoLan),
      doiPhaiTruocPhut: n('doiPhaiTruocPhut', d.doiPhaiTruocPhut),
      doiCachLucGuiItNhatPhut: n(
        'doiCachLucGuiItNhatPhut',
        d.doiCachLucGuiItNhatPhut,
      ),
      doiToiDaSauTBanDauPhut: n(
        'doiToiDaSauTBanDauPhut',
        d.doiToiDaSauTBanDauPhut,
      ),
      anHanKhongDenPhut: n('anHanKhongDenPhut', d.anHanKhongDenPhut),
      baoKhongDenDenPhut: n('baoKhongDenDenPhut', d.baoKhongDenDenPhut),
      phanDoiPhut: n('phanDoiPhut', d.phanDoiPhut),
      khieuNaiDenPhut: n('khieuNaiDenPhut', d.khieuNaiDenPhut),
      tuHoanTatPhut: n('tuHoanTatPhut', d.tuHoanTatPhut),
      danhGiaNhanXetToiThieu: i(
        'danhGiaNhanXetToiThieu',
        d.danhGiaNhanXetToiThieu,
      ),
      danhGiaAnhToiDa: i('danhGiaAnhToiDa', d.danhGiaAnhToiDa),
      khangNghiBangChungToiDa: i(
        'khangNghiBangChungToiDa',
        d.khangNghiBangChungToiDa,
      ),
      banKinhMet: m['banKinhMet'] is List
          ? [for (final x in m['banKinhMet'] as List) (x as num).toInt()]
          : d.banKinhMet,
    );
  }
}

/// Tiện ích chung của nhà trọ (áp cho mọi phòng).
const tienIchChungLabels = {
  'wifi': 'Wifi',
  'cho_de_xe': 'Chỗ để xe',
  'camera': 'Camera an ninh',
  'may_giat': 'Máy giặt chung',
  'khoa_van_tay': 'Khóa vân tay / thẻ',
};

/// Tiện ích trong phòng.
const tienIchPhongLabels = {
  'may_lanh': 'Máy lạnh',
  'wc_rieng': 'WC riêng',
  'nong_lanh': 'Máy nước nóng',
  'tu_lanh': 'Tủ lạnh',
  'noi_that': 'Nội thất cơ bản',
  'ban_cong': 'Ban công / cửa sổ',
};

const loaiHinhLabels = {'phong': 'Cho thuê phòng', 'nguyen_can': 'Nguyên căn'};

const cachTinhDienLabels = {
  'theo_so': 'Theo số (đ/kWh)',
  'co_dinh': 'Cố định / tháng',
};
const cachTinhNuocLabels = {
  'theo_khoi': 'Theo khối (đ/m³)',
  'theo_nguoi': 'Theo người / tháng',
  'co_dinh': 'Cố định / tháng',
};

/// Mốc giá nhanh (mục 2.16): (nhãn, từ, đến) — đến null = không giới hạn.
const mocGiaNhanh = <(String, int?, int?)>[
  ('Dưới 1tr', null, 1000000),
  ('1–1,5tr', 1000000, 1500000),
  ('1,5–2tr', 1500000, 2000000),
  ('2–3tr', 2000000, 3000000),
  ('Trên 3tr', 3000000, null),
];

const theNhanhDanhGiaLabels = {
  'yen_tinh': 'Yên tĩnh',
  'chu_de_tinh': 'Chủ dễ tính',
  'dien_nuoc_on_dinh': 'Điện nước ổn định',
  'gan_cho': 'Gần chợ',
  'an_ninh_tot': 'An ninh tốt',
  'hay_cup_nuoc': 'Hay cúp nước',
  'on_ao': 'Ồn ào',
  'am_thap': 'Ẩm thấp',
};

const tieuChiDanhGiaLabels = {
  'dungMoTa': 'Đúng mô tả',
  'anNinh': 'An ninh',
  'veSinh': 'Vệ sinh',
  'chuTro': 'Chủ trọ',
  'giaHopLy': 'Giá hợp lý',
};

/// Lý do báo cáo (mục 2.5f + chung).
const lyDoBaoCaoLabels = {
  'khong_ton_tai': 'Phòng không tồn tại / ảnh không đúng',
  'sai_gia_mo_ta': 'Sai giá, sai mô tả',
  'noi_quy_sai':
      'Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch',
  'da_cho_thue_van_dang': 'Đã cho thuê / đã có người cọc vẫn đăng',
  'chuyen_coc_ngoai_app': 'Yêu cầu chuyển cọc ngoài app',
  'lua_dao': 'Lừa đảo',
  'xuc_pham': 'Xúc phạm / lộ thông tin cá nhân',
  'khac': 'Khác',
};

/// Lý do khiếu nại "Chủ trọ không thực hiện đúng cam kết" (mục 2.5c).
const lyDoKhieuNaiLabels = {
  'da_cho_nguoi_khac': 'Phòng đã cho người khác thuê / cọc',
  'khong_giao_phong': 'Chủ trọ không giao phòng',
  'sai_mo_ta': 'Phòng sai nghiêm trọng so với thông tin lúc cọc',
  'noi_quy_sai':
      'Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch',
  'khac': 'Vi phạm khác của chủ trọ',
};

const lyDoTuChoiLabels = [
  'Ảnh mờ',
  'Giấy tờ không khớp',
  'Video không đúng địa điểm',
  'Ảnh không đúng thực tế',
  'Thông tin sai lệch',
  'Nội dung quảng cáo',
  'Khác',
];

const trangThaiPhongLabels = {
  'draft': 'Nháp',
  'pending_review': 'Chờ duyệt',
  'rejected': 'Bị từ chối',
  'available': 'Còn trống',
  'reserved': 'Đã cọc',
  'rented': 'Đã cho thuê',
  'hidden': 'Tạm ẩn',
};

const trangThaiNhaTroLabels = {
  'draft': 'Nháp',
  'pending_review': 'Chờ duyệt',
  'rejected': 'Bị từ chối',
  'active': 'Đang hiển thị',
  'hidden': 'Tạm ẩn',
  'expired': 'Hết hạn',
};

const trangThaiCocLabels = {
  'pending_payment': 'Chờ thanh toán',
  'expired': 'Hết hạn thanh toán',
  'held': 'Đang giữ tiền',
  'cancelled_grace': 'Đã hủy trong 30 phút',
  'disputed': 'Đang khiếu nại',
  'released': 'Đã chuyển cho chủ trọ',
  'refunded': 'Đã hoàn',
  'forfeited': 'Mất cọc',
};

const lyDoKetThucLabels = {
  'grace_cancel': 'Hủy trong 30 phút đầu',
  'student_confirmed': 'Sinh viên xác nhận đã nhận phòng',
  'auto_complete': 'Tự hoàn tất sau 48 giờ',
  'student_changed_mind': 'Sinh viên không thuê nữa',
  'student_no_show': 'Sinh viên không đến nhận phòng',
  'owner_cancelled': 'Chủ trọ hủy cọc',
  'owner_no_reply_reschedule': 'Chủ trọ không trả lời yêu cầu thay đổi',
  'owner_violation': 'Chủ trọ vi phạm cam kết',
  'admin_released': 'Admin xác định sinh viên đã nhận phòng',
  'system_late_payment': 'Tiền về sau hạn thanh toán',
  'admin_fraud': 'Chủ trọ bị kết luận lừa đảo',
};

/// Câu điều khoản nhận phòng phải đồng ý trước khi cọc (đúng câu ở mục 2.4 Bước 3).
const dieuKhoanNhanPhong =
    "Sau thời điểm nhận phòng, nếu đã nhận phòng thành công, bạn cần xác nhận 'Đã nhận phòng'. "
    'Nếu chủ trọ không thực hiện đúng cam kết, bạn cần báo vấn đề trên hệ thống. '
    'Nếu sau 48 giờ kể từ thời điểm nhận phòng không bên nào báo có vấn đề hoặc tranh chấp, '
    'hệ thống sẽ tự động xác nhận giao dịch hoàn tất và giải ngân tiền cọc cho chủ trọ.';

/// Chính sách cọc (mục 2.5a), tóm tắt để hiện trước khi thanh toán.
const chinhSachCoc = [
  'Hủy trong 30 phút đầu (còn lượt hủy miễn phí): hoàn 100%.',
  'Báo "Không thuê nữa" trước thời điểm nhận phòng: không hoàn, tiền chuyển cho chủ trọ.',
  'Chủ trọ hủy cọc hoặc không trả lời yêu cầu thay đổi trong 24 giờ: hoàn 100%.',
  'Đã nhận phòng: tiền chuyển cho chủ trọ.',
  'Không đến nhận phòng và không phản đối trong 12 giờ: mất cọc.',
  'Chủ trọ không đúng cam kết (khiếu nại được chấp nhận): hoàn 100%.',
];

const nhacDiXemPhong =
    'Đi xem phòng không giữ phòng. Muốn chắc chắn giữ phòng, hãy đặt cọc trên app.';
