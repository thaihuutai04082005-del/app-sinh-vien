/// Con số quy định và nhãn của module Quán ăn (đặc tả mục 3.16).
///
/// Hệ thống (Cloud Functions) là nơi quyết định; app chỉ dùng các con số này để
/// hiển thị và chặn sớm trên giao diện. Giá trị thật được tải từ server qua
/// [QuanAnConfig.fromMap] (hành động `cauHinh`; admin có thể rút ngắn thời hạn khi test),
/// không viết cứng con số ở màn hình hay model khác.
class QuanAnConfig {
  const QuanAnConfig({
    this.anhMatTienToiThieu = 1,
    this.anhMatTienToiDa = 3,
    this.anhKhacToiDa = 10,
    this.monToiThieuHienThi = 3,
    this.nhomMonToiDa = 20,
    this.monToiDa = 200,
    this.monNoiBatToiDa = 5,
    this.caMoCuaToiDa = 2,
    this.sapDongPhut = 30,
    this.khuyenMaiToiDaHoKinhDoanh = 5,
    this.khuyenMaiToiDaBanLe = 1,
    this.khuyenMaiToiDaNgay = 90,
    this.mocGia = const [20000, 35000, 50000],
    this.chipGiaReDen = 35000,
    this.checkInMet = 100,
    this.hayAnToiThieuNguoi = 10,
    this.hayAnPhanTram = 20,
    this.hayAnBanKinhKm = 3,
    this.moiMoNgay = 30,
    this.nhacConHoatDongNgay = 90,
    this.hanXacNhanHoatDongNgay = 7,
    this.khaiSaiMenuTren = 40,
    this.khaiSaiGioMoTren = 14,
    this.hanChuyenLoaiNgay = 7,
    this.datBanCachItNhatPhut = 60,
    this.datBanTruocToiDaNgay = 7,
    this.datBanSoNguoiToiThieu = 1,
    this.datBanSoNguoiToiDa = 20,
    this.datBanQuanXacNhanPhut = 30,
    this.datBanTruocGioHenPhut = 30,
    this.giuBanPhut = 15,
    this.huySatGioPhut = 60,
    this.khoaDatBanSoLan = 3,
    this.khoaDatBanNgay = 7,
    this.tuDongDongBanPhut = 24 * 60,
    this.banKinhGiaoToiThieuKm = 1,
    this.banKinhGiaoToiDaKm = 5,
    this.quanXacNhanPhut = 5,
    this.chuongNhacLaiPhut = 2,
    this.tuTamNgungSoLan = 3,
    this.chiSoNgay = 30,
    this.quanChamPhut = 30,
    this.giaoLauPhut = 60,
    this.henGioToiThieuPhut = 30,
    this.henGioToiDaPhut = 120,
    this.khachKhongToiLayPhut = 30,
    this.phanDoiPhut = 24 * 60,
    this.giuThemPhut = 24 * 60,
    this.khieuNaiPhut = 24 * 60,
    this.quanTraLoiPhut = 2 * 60,
    this.tuHoanTatPhut = 24 * 60,
    this.nhacTuHoanTatSauPhut = 60,
    this.nhacTuHoanTatConLaiPhut = 60,
    this.maNhanMonSoChu = 4,
    this.quaHanPhut = 6 * 60,
    this.tienMatDuoi = 200000,
    this.bomHangMatTienMatSoLan = 2,
    this.bomHangKhoaSoLan = 3,
    this.bomHangKhoaNgay = 7,
    this.khieuNaiSaiSoLan = 3,
    this.khieuNaiSaiKhoaNgay = 30,
    this.danhGiaToiDaNgay = 10,
    this.danhGiaNhanXetToiThieu = 20,
    this.danhGiaAnhToiDa = 5,
    this.choThanhToanPhut = 15,
    this.gpsLechMet = 200,
    this.banKinhMet = const [300, 500, 1000, 2000, 3000, 5000],
    this.baoCaoTuoiTaiKhoanNgay = 7,
    this.baoCaoToiDaNgay = 10,
    this.khieuNaiKhanPhut = 72 * 60,
    this.khangNghiHanGuiNgay = 7,
    this.khangNghiBangChungToiDa = 3,
    this.tenQuanToiThieu = 3,
    this.tenQuanToiDa = 80,
    this.tenMonToiThieu = 2,
    this.tenMonToiDa = 60,
  });

  // ---- Quán, menu ----
  final int anhMatTienToiThieu;
  final int anhMatTienToiDa;
  final int anhKhacToiDa;

  /// Số món tối thiểu để quán hiện ở danh sách.
  final int monToiThieuHienThi;
  final int nhomMonToiDa;
  final int monToiDa;
  final int monNoiBatToiDa;
  final int caMoCuaToiDa;

  /// "Sắp đóng cửa" khi còn bấy nhiêu phút.
  final int sapDongPhut;
  final int khuyenMaiToiDaHoKinhDoanh;
  final int khuyenMaiToiDaBanLe;
  final int khuyenMaiToiDaNgay;

  /// Các mốc cắt của mức giá theo giá trung vị: dưới mốc 1 · mốc 1–2 · mốc 2–3 · trên mốc 3.
  final List<int> mocGia;

  /// Chip nhanh "Dưới 35k": giá trung vị dưới số này.
  final int chipGiaReDen;
  final int checkInMet;
  final int hayAnToiThieuNguoi;
  final int hayAnPhanTram;
  final int hayAnBanKinhKm;
  final int moiMoNgay;
  final int nhacConHoatDongNgay;
  final int hanXacNhanHoatDongNgay;
  final int khaiSaiMenuTren;
  final int khaiSaiGioMoTren;
  final int hanChuyenLoaiNgay;

  // ---- Đặt bàn ----
  final int datBanCachItNhatPhut;
  final int datBanTruocToiDaNgay;
  final int datBanSoNguoiToiThieu;
  final int datBanSoNguoiToiDa;

  /// Quán xác nhận trong min(bấy nhiêu phút, giờ hẹn − [datBanTruocGioHenPhut]).
  final int datBanQuanXacNhanPhut;
  final int datBanTruocGioHenPhut;
  final int giuBanPhut;
  final int huySatGioPhut;
  final int khoaDatBanSoLan;
  final int khoaDatBanNgay;

  /// Bàn đã xác nhận mà quán không bấm gì: hết giờ giữ bàn + bấy nhiêu phút thì tự đóng.
  final int tuDongDongBanPhut;

  // ---- Đặt món ----
  final int banKinhGiaoToiThieuKm;
  final int banKinhGiaoToiDaKm;
  final int quanXacNhanPhut;
  final int chuongNhacLaiPhut;
  final int tuTamNgungSoLan;

  /// Cửa sổ tính tỷ lệ nhận đơn / giữ bàn / phản hồi (ngày).
  final int chiSoNgay;

  /// Quán chậm: quá giờ dự kiến sẵn sàng + bấy nhiêu phút.
  final int quanChamPhut;

  /// "Đang giao" quá bấy nhiêu phút thì sinh viên báo được "Chưa nhận được món".
  final int giaoLauPhut;
  final int henGioToiThieuPhut;
  final int henGioToiDaPhut;
  final int khachKhongToiLayPhut;
  final int phanDoiPhut;
  final int giuThemPhut;
  final int khieuNaiPhut;
  final int quanTraLoiPhut;
  final int tuHoanTatPhut;
  final int nhacTuHoanTatSauPhut;
  final int nhacTuHoanTatConLaiPhut;
  final int maNhanMonSoChu;

  /// Chưa có bằng chứng giao / nhận sau bấy nhiêu phút kể từ "Sẵn sàng" / "Đang giao" → gắn cờ admin.
  final int quaHanPhut;

  /// Tiền mặt khi nhận: chỉ cho đơn DƯỚI số này.
  final int tienMatDuoi;
  final int bomHangMatTienMatSoLan;
  final int bomHangKhoaSoLan;
  final int bomHangKhoaNgay;
  final int khieuNaiSaiSoLan;
  final int khieuNaiSaiKhoaNgay;

  // ---- Đánh giá, thanh toán, báo cáo, kháng nghị ----
  final int danhGiaToiDaNgay;
  final int danhGiaNhanXetToiThieu;
  final int danhGiaAnhToiDa;
  final int choThanhToanPhut;
  final int gpsLechMet;
  final List<int> banKinhMet;
  final int baoCaoTuoiTaiKhoanNgay;
  final int baoCaoToiDaNgay;
  final int khieuNaiKhanPhut;
  final int khangNghiHanGuiNgay;
  final int khangNghiBangChungToiDa;

  // ---- Độ dài chữ ----
  final int tenQuanToiThieu;
  final int tenQuanToiDa;
  final int tenMonToiThieu;
  final int tenMonToiDa;

  static Duration phut(num p) => Duration(milliseconds: (p * 60000).round());

  /// Dựng từ kết quả hành động `cauHinh`. Khóa trùng tên trường; khóa thiếu thì dùng mặc định.
  factory QuanAnConfig.fromMap(Map<String, dynamic> m) {
    const d = QuanAnConfig();
    int i(String k, int v) => m[k] is num ? (m[k] as num).toInt() : v;
    List<int> l(String k, List<int> v) =>
        m[k] is List ? [for (final x in m[k] as List) (x as num).toInt()] : v;
    return QuanAnConfig(
      anhMatTienToiThieu: i('anhMatTienToiThieu', d.anhMatTienToiThieu),
      anhMatTienToiDa: i('anhMatTienToiDa', d.anhMatTienToiDa),
      anhKhacToiDa: i('anhKhacToiDa', d.anhKhacToiDa),
      monToiThieuHienThi: i('monToiThieuHienThi', d.monToiThieuHienThi),
      nhomMonToiDa: i('nhomMonToiDa', d.nhomMonToiDa),
      monToiDa: i('monToiDa', d.monToiDa),
      monNoiBatToiDa: i('monNoiBatToiDa', d.monNoiBatToiDa),
      caMoCuaToiDa: i('caMoCuaToiDa', d.caMoCuaToiDa),
      sapDongPhut: i('sapDongPhut', d.sapDongPhut),
      khuyenMaiToiDaHoKinhDoanh: i(
        'khuyenMaiToiDaHoKinhDoanh',
        d.khuyenMaiToiDaHoKinhDoanh,
      ),
      khuyenMaiToiDaBanLe: i('khuyenMaiToiDaBanLe', d.khuyenMaiToiDaBanLe),
      khuyenMaiToiDaNgay: i('khuyenMaiToiDaNgay', d.khuyenMaiToiDaNgay),
      mocGia: l('mocGia', d.mocGia),
      chipGiaReDen: i('chipGiaReDen', d.chipGiaReDen),
      checkInMet: i('checkInMet', d.checkInMet),
      hayAnToiThieuNguoi: i('hayAnToiThieuNguoi', d.hayAnToiThieuNguoi),
      hayAnPhanTram: i('hayAnPhanTram', d.hayAnPhanTram),
      hayAnBanKinhKm: i('hayAnBanKinhKm', d.hayAnBanKinhKm),
      moiMoNgay: i('moiMoNgay', d.moiMoNgay),
      nhacConHoatDongNgay: i('nhacConHoatDongNgay', d.nhacConHoatDongNgay),
      hanXacNhanHoatDongNgay: i(
        'hanXacNhanHoatDongNgay',
        d.hanXacNhanHoatDongNgay,
      ),
      khaiSaiMenuTren: i('khaiSaiMenuTren', d.khaiSaiMenuTren),
      khaiSaiGioMoTren: i('khaiSaiGioMoTren', d.khaiSaiGioMoTren),
      hanChuyenLoaiNgay: i('hanChuyenLoaiNgay', d.hanChuyenLoaiNgay),
      datBanCachItNhatPhut: i('datBanCachItNhatPhut', d.datBanCachItNhatPhut),
      datBanTruocToiDaNgay: i('datBanTruocToiDaNgay', d.datBanTruocToiDaNgay),
      datBanSoNguoiToiThieu: i(
        'datBanSoNguoiToiThieu',
        d.datBanSoNguoiToiThieu,
      ),
      datBanSoNguoiToiDa: i('datBanSoNguoiToiDa', d.datBanSoNguoiToiDa),
      datBanQuanXacNhanPhut: i(
        'datBanQuanXacNhanPhut',
        d.datBanQuanXacNhanPhut,
      ),
      datBanTruocGioHenPhut: i(
        'datBanTruocGioHenPhut',
        d.datBanTruocGioHenPhut,
      ),
      giuBanPhut: i('giuBanPhut', d.giuBanPhut),
      huySatGioPhut: i('huySatGioPhut', d.huySatGioPhut),
      khoaDatBanSoLan: i('khoaDatBanSoLan', d.khoaDatBanSoLan),
      khoaDatBanNgay: i('khoaDatBanNgay', d.khoaDatBanNgay),
      tuDongDongBanPhut: i('tuDongDongBanPhut', d.tuDongDongBanPhut),
      banKinhGiaoToiThieuKm: i(
        'banKinhGiaoToiThieuKm',
        d.banKinhGiaoToiThieuKm,
      ),
      banKinhGiaoToiDaKm: i('banKinhGiaoToiDaKm', d.banKinhGiaoToiDaKm),
      quanXacNhanPhut: i('quanXacNhanPhut', d.quanXacNhanPhut),
      chuongNhacLaiPhut: i('chuongNhacLaiPhut', d.chuongNhacLaiPhut),
      tuTamNgungSoLan: i('tuTamNgungSoLan', d.tuTamNgungSoLan),
      chiSoNgay: i('chiSoNgay', d.chiSoNgay),
      quanChamPhut: i('quanChamPhut', d.quanChamPhut),
      giaoLauPhut: i('giaoLauPhut', d.giaoLauPhut),
      henGioToiThieuPhut: i('henGioToiThieuPhut', d.henGioToiThieuPhut),
      henGioToiDaPhut: i('henGioToiDaPhut', d.henGioToiDaPhut),
      khachKhongToiLayPhut: i('khachKhongToiLayPhut', d.khachKhongToiLayPhut),
      phanDoiPhut: i('phanDoiPhut', d.phanDoiPhut),
      giuThemPhut: i('giuThemPhut', d.giuThemPhut),
      khieuNaiPhut: i('khieuNaiPhut', d.khieuNaiPhut),
      quanTraLoiPhut: i('quanTraLoiPhut', d.quanTraLoiPhut),
      tuHoanTatPhut: i('tuHoanTatPhut', d.tuHoanTatPhut),
      nhacTuHoanTatSauPhut: i('nhacTuHoanTatSauPhut', d.nhacTuHoanTatSauPhut),
      nhacTuHoanTatConLaiPhut: i(
        'nhacTuHoanTatConLaiPhut',
        d.nhacTuHoanTatConLaiPhut,
      ),
      maNhanMonSoChu: i('maNhanMonSoChu', d.maNhanMonSoChu),
      quaHanPhut: i('quaHanPhut', d.quaHanPhut),
      tienMatDuoi: i('tienMatDuoi', d.tienMatDuoi),
      bomHangMatTienMatSoLan: i(
        'bomHangMatTienMatSoLan',
        d.bomHangMatTienMatSoLan,
      ),
      bomHangKhoaSoLan: i('bomHangKhoaSoLan', d.bomHangKhoaSoLan),
      bomHangKhoaNgay: i('bomHangKhoaNgay', d.bomHangKhoaNgay),
      khieuNaiSaiSoLan: i('khieuNaiSaiSoLan', d.khieuNaiSaiSoLan),
      khieuNaiSaiKhoaNgay: i('khieuNaiSaiKhoaNgay', d.khieuNaiSaiKhoaNgay),
      danhGiaToiDaNgay: i('danhGiaToiDaNgay', d.danhGiaToiDaNgay),
      danhGiaNhanXetToiThieu: i(
        'danhGiaNhanXetToiThieu',
        d.danhGiaNhanXetToiThieu,
      ),
      danhGiaAnhToiDa: i('danhGiaAnhToiDa', d.danhGiaAnhToiDa),
      choThanhToanPhut: i('choThanhToanPhut', d.choThanhToanPhut),
      gpsLechMet: i('gpsLechMet', d.gpsLechMet),
      banKinhMet: l('banKinhMet', d.banKinhMet),
      baoCaoTuoiTaiKhoanNgay: i(
        'baoCaoTuoiTaiKhoanNgay',
        d.baoCaoTuoiTaiKhoanNgay,
      ),
      baoCaoToiDaNgay: i('baoCaoToiDaNgay', d.baoCaoToiDaNgay),
      khieuNaiKhanPhut: i('khieuNaiKhanPhut', d.khieuNaiKhanPhut),
      khangNghiHanGuiNgay: i('khangNghiHanGuiNgay', d.khangNghiHanGuiNgay),
      khangNghiBangChungToiDa: i(
        'khangNghiBangChungToiDa',
        d.khangNghiBangChungToiDa,
      ),
      tenQuanToiThieu: i('tenQuanToiThieu', d.tenQuanToiThieu),
      tenQuanToiDa: i('tenQuanToiDa', d.tenQuanToiDa),
      tenMonToiThieu: i('tenMonToiThieu', d.tenMonToiThieu),
      tenMonToiDa: i('tenMonToiDa', d.tenMonToiDa),
    );
  }

  /// Số khuyến mãi tối đa theo loại quán.
  int khuyenMaiToiDa(String loaiQuan) => loaiQuan == 'ho_kinh_doanh'
      ? khuyenMaiToiDaHoKinhDoanh
      : khuyenMaiToiDaBanLe;
}

// ---------------------------------------------------------------------------
// Nhãn tiếng Việt cho mọi mã (hợp đồng quan-an-hop-dong.md, "Mã dùng chung").
// ---------------------------------------------------------------------------

const loaiQuanLabels = {
  'ho_kinh_doanh': 'Hộ kinh doanh',
  'ban_le': 'Bán lẻ / vỉa hè',
};

/// Nhãn huy hiệu xác thực theo loại quán (mục 3.2).
const huyHieuLoaiQuanLabels = {
  'ho_kinh_doanh': 'Đã xác thực kinh doanh',
  'ban_le': 'Đã xác thực chủ quán',
};

const loaiMonLabels = {
  'com': 'Cơm',
  'bun_pho_mi': 'Bún / Phở / Mì',
  'banh_mi': 'Bánh mì',
  'an_vat': 'Ăn vặt',
  'lau_nuong': 'Lẩu / Nướng',
  'chay': 'Chay',
  'do_uong': 'Đồ uống',
  'tra_sua': 'Trà sữa',
  'ca_phe': 'Cà phê',
  'trang_mien': 'Tráng miệng',
  'khac': 'Khác',
};

const tienIchLabels = {
  'trong_nha': 'Chỗ ngồi trong nhà',
  'ngoai_troi': 'Ngồi ngoài trời',
  'may_lanh': 'Máy lạnh',
  'wifi': 'Wifi',
  'o_cam': 'Ổ cắm sạc',
  'do_xe': 'Chỗ để xe',
  'hoc_nhom': 'Phù hợp học nhóm',
};

/// Tiện ích dùng làm bộ lọc ở sảnh (mục 3.4 Bước 1).
const tienIchLoc = [
  'ngoai_troi',
  'may_lanh',
  'wifi',
  'o_cam',
  'do_xe',
  'hoc_nhom',
];

const trangThaiQuanLabels = {
  'draft': 'Nháp',
  'pending_review': 'Chờ duyệt',
  'rejected': 'Bị từ chối',
  'active': 'Đang hoạt động',
  'hidden': 'Tạm ẩn',
  'suspended': 'Bị đình chỉ',
  'closed': 'Ngừng kinh doanh',
};

const trangThaiMoCuaLabels = {
  'mo': 'Đang mở cửa',
  'sap_dong': 'Sắp đóng cửa',
  'dong': 'Đã đóng cửa',
  'tam_nghi': 'Tạm nghỉ',
};

const loaiKhuyenMaiLabels = {
  'giam_phan_tram': 'Giảm %',
  'giam_tien': 'Giảm tiền',
  'combo': 'Combo',
  'gio_vang': 'Giờ vàng',
  'sinh_vien': 'Ưu đãi sinh viên',
};

const trangThaiKhuyenMaiLabels = {
  'chay': 'Đang chạy',
  'dung': 'Đã dừng',
  'het_han': 'Hết hạn',
};

/// Trạng thái đơn món (mục 3.5i).
const trangThaiDonLabels = {
  'pending_payment': 'Chờ thanh toán',
  'expired': 'Hết hạn thanh toán',
  'placed': 'Chờ quán xác nhận',
  'cancelled_student': 'Sinh viên hủy',
  'rejected': 'Quán từ chối',
  'expired_accept': 'Quán không xác nhận kịp',
  'accepted': 'Đang chuẩn bị',
  'cancelled_restaurant': 'Quán hủy',
  'ready': 'Sẵn sàng để lấy',
  'delivering': 'Đang giao',
  'delivered': 'Chờ xác nhận nhận món',
  'completed': 'Hoàn tất',
  'not_received': 'Khách không nhận',
  'disputed': 'Đang khiếu nại',
  'refunded': 'Đã hoàn toàn bộ',
  'partially_refunded': 'Đã hoàn một phần',
};

/// Trạng thái đặt bàn (mục 3.5j).
const trangThaiBanLabels = {
  'pending': 'Chờ quán xác nhận',
  'confirmed': 'Đã xác nhận',
  'rejected': 'Bị từ chối',
  'expired': 'Hết hạn',
  'cancelled_student': 'Sinh viên hủy',
  'cancelled_restaurant': 'Quán hủy',
  'arrived': 'Khách đã đến',
  'no_show': 'Khách không đến',
};

const cachNhanLabels = {'den_lay': 'Đến lấy', 'giao': 'Giao tận nơi'};
const gioDatLabels = {'asap': 'Càng sớm càng tốt', 'hen': 'Hẹn giờ'};
const cachTraLabels = {
  'app': 'Trên app (PayPal / MoMo)',
  'tien_mat': 'Tiền mặt khi nhận',
};

const trangThaiTienLabels = {
  'cho_tra': 'Chờ trả',
  'dang_giu': 'App đang giữ',
  'da_chuyen': 'Đã chuyển cho quán',
  'da_hoan': 'Đã hoàn cho sinh viên',
  'hoan_mot_phan': 'Đã hoàn một phần',
  'het_han': 'Hết hạn',
  'that_bai': 'Thất bại',
};

/// Nhãn xác minh đánh giá (mục 3.4 Bước 6), từ mạnh tới yếu.
const nhanDanhGiaLabels = {
  'dat_mon': '🛵 Đã đặt món',
  'dat_ban': '🍽 Đã đến theo đặt bàn',
  'check_in': '📍 Check-in tại quán',
};

/// Lý do khiếu nại đơn (mục 3.5d).
const lyDoKhieuNaiDonLabels = {
  'khong_nhan_duoc': 'Không nhận được món',
  'thieu_mon': 'Thiếu món',
  'sai_mon': 'Sai món',
  'mon_hu': 'Món hư / mất vệ sinh',
  'khac': 'Khác',
};

/// Lý do khiếu nại cần ảnh (mọi lý do trừ "Không nhận được món").
bool lyDoKhieuNaiCanAnh(String lyDo) => lyDo != 'khong_nhan_duoc';

const loaiKhieuNaiDonLabels = {
  'khieu_nai': 'Khiếu nại đơn',
  'chua_nhan_mon': 'Chưa nhận được món',
  'phan_doi_khong_nhan': 'Phản đối "khách không nhận"',
  'xac_minh': 'Xác minh giao nhận',
};

const quyetDinhKhieuNaiLabels = {
  'hoan_toan': 'Hoàn toàn phần',
  'hoan_mot_phan': 'Hoàn một phần',
  'chuyen_cho_quan': 'Chuyển tiền cho quán',
  'da_giao': 'Đơn đã giao / nhận',
  'khong_giao': 'Đơn không giao được',
};

/// Lý do báo cáo (mục 3.5h + lý do chung).
const lyDoBaoCaoLabels = {
  'quan_khong_ton_tai': 'Quán không tồn tại / đã đóng',
  'sai_gio': 'Sai giờ mở cửa',
  'sai_gia': 'Sai giá',
  'khuyen_mai_sai': 'Khuyến mãi không đúng thực tế',
  'khai_sai_loai': 'Khai sai loại hình',
  'mat_ve_sinh': 'Mất vệ sinh an toàn thực phẩm',
  'chuyen_khoan_ngoai_app': 'Yêu cầu chuyển khoản ngoài app',
  'lua_dao': 'Lừa đảo',
  'xuc_pham': 'Xúc phạm / lộ thông tin cá nhân',
  'spam': 'Spam',
  'khac': 'Khác',
};

/// Lý do báo cáo ưu tiên cao.
const lyDoBaoCaoUuTienCao = {'mat_ve_sinh', 'chuyen_khoan_ngoai_app'};

/// Tiêu chí đánh giá (mục 3.4 Bước 6).
const tieuChiDanhGiaLabels = {
  'monAn': '🍜 Món ăn',
  'giaCa': '💰 Giá cả',
  'veSinh': '🧹 Vệ sinh',
  'phucVu': '🙋 Phục vụ',
};

const theNhanhDanhGiaLabels = {
  'mon_ngon': 'Món ngon',
  'phuc_vu_nhanh': 'Phục vụ nhanh',
  'gia_hop_ly': 'Giá hợp lý',
  'phan_an_nhieu': 'Phần ăn nhiều',
  'sach_se': 'Sạch sẽ',
  'hop_hoc_nhom': 'Hợp học nhóm',
  'cho_lau': 'Chờ lâu',
  'gia_cao': 'Giá cao',
  'on_ao': 'Ồn ào',
  'it_cho_ngoi': 'Ít chỗ ngồi',
};

/// Lý do từ chối quán có sẵn (mục 3.12).
const lyDoTuChoiQuanLabels = [
  'Ảnh mặt tiền không rõ / sai địa điểm',
  'Mã số thuế không tồn tại / ngừng hoạt động',
  'Tên chủ hộ không khớp',
  'Địa chỉ không khớp',
  'Khai sai loại hình',
  'Thông tin sai lệch',
  'Khác',
];

/// Lý do kết thúc đơn (hiển thị ở dòng thời gian).
const lyDoHuyDonLabels = {
  'restaurant_late': 'Quán chậm quá hạn',
  'student_cancelled': 'Sinh viên hủy đơn',
  'restaurant_rejected': 'Quán từ chối',
  'restaurant_cancelled': 'Quán hủy đơn',
  'payment_expired': 'Hết hạn thanh toán',
  'accept_expired': 'Quán không xác nhận kịp',
};

/// Mốc giá nhanh theo giá trung vị sinh từ cấu hình: (nhãn, từ, đến) — `đến` loại trừ,
/// null = không giới hạn. Ví dụ mặc định: Dưới 20k · 20–35k · 35–50k · Trên 50k.
List<(String, int?, int?)> mocGiaNhanh(QuanAnConfig cfg) {
  String k(int v) => '${(v / 1000).round()}k';
  final m = cfg.mocGia;
  if (m.isEmpty) return const [];
  return [
    ('Dưới ${k(m.first)}', null, m.first),
    for (var i = 0; i + 1 < m.length; i++)
      ('${(m[i] / 1000).round()}–${k(m[i + 1])}', m[i], m[i + 1]),
    ('Trên ${k(m.last)}', m.last, null),
  ];
}
