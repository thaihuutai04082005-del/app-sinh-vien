/// Trạng thái xác thực của tài khoản (đặc tả Phần 4) — collection `xac_thuc/{uid}`, chỉ server ghi.
class XacThuc {
  const XacThuc({
    this.sdt,
    this.sdtDaXacThuc = false,
    this.danhTinh = 'chua',
    this.hoTenXacThuc,
    this.cccd4,
    this.lyDoTuChoi,
    this.khoaTaiKhoan = false,
  });

  final String? sdt;
  final bool sdtDaXacThuc;

  /// 'chua' | 'cho_duyet' | 'da_xac_thuc' | 'tu_choi'
  final String danhTinh;
  final String? hoTenXacThuc;
  final String? cccd4;
  final String? lyDoTuChoi;
  final bool khoaTaiKhoan;

  bool get daOtp => sdtDaXacThuc && sdt != null;
  bool get daXacThucDanhTinh => danhTinh == 'da_xac_thuc';

  static const danhTinhLabels = {
    'chua': 'Chưa xác nhận người thật',
    'cho_duyet': 'Đang chờ admin duyệt',
    'da_xac_thuc': 'Đã xác thực danh tính',
    'tu_choi': 'Bị từ chối',
  };

  factory XacThuc.fromMap(Map<String, dynamic>? m) => XacThuc(
    sdt: m?['sdt'] as String?,
    sdtDaXacThuc: m?['sdtDaXacThuc'] as bool? ?? false,
    danhTinh: m?['danhTinh'] as String? ?? 'chua',
    hoTenXacThuc: m?['hoTenXacThuc'] as String?,
    cccd4: m?['cccd4'] as String?,
    lyDoTuChoi: m?['lyDoTuChoi'] as String?,
    khoaTaiKhoan: m?['khoaTaiKhoan'] as bool? ?? false,
  );
}

/// Quyền admin — collection `admins/{uid}`, tạo trong Firebase Console.
class QuyenAdmin {
  const QuyenAdmin({
    this.tro = false,
    this.quanAn = false,
    this.danhTinh = false,
  });

  final bool tro;

  /// Admin của module Quán ăn (`admins/{uid}.quanAn`).
  final bool quanAn;
  final bool danhTinh;

  factory QuyenAdmin.fromMap(Map<String, dynamic>? m) => QuyenAdmin(
    tro: m?['tro'] as bool? ?? false,
    quanAn: m?['quanAn'] as bool? ?? false,
    danhTinh: m?['danhTinh'] as bool? ?? false,
  );
}
