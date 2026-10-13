/// Hồ sơ tài xế — collection `xe_don_tro/{uid}` (mục 7.3). Chỉ server ghi,
/// và chỉ tạo được sau khi tài xế đã xác thực danh tính.
class TaiXe {
  const TaiXe({
    required this.driverId,
    required this.name,
    required this.vehicleType,
    required this.area,
    required this.priceReference,
    this.description = '',
    this.status = 'available',
    this.driverVerified = false,
  });

  final String driverId;
  final String name;

  /// xe_tai_nho | xe_ba_gac | xe_may
  final String vehicleType;
  final String area;
  final String priceReference;
  final String description;

  /// available | busy
  final String status;
  final bool driverVerified;

  static const loaiXeLabels = {
    'xe_tai_nho': 'Xe tải nhỏ',
    'xe_ba_gac': 'Xe ba gác',
    'xe_may': 'Xe máy chở hàng',
  };

  String get loaiXe => loaiXeLabels[vehicleType] ?? vehicleType;
  bool get sanSang => status == 'available';

  factory TaiXe.fromMap(Map<String, dynamic> map) => TaiXe(
    driverId: map['driverId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    vehicleType: map['vehicleType'] as String? ?? '',
    area: map['area'] as String? ?? '',
    priceReference: map['priceReference'] as String? ?? '',
    description: map['description'] as String? ?? '',
    status: map['status'] as String? ?? 'available',
    driverVerified: map['driverVerified'] as bool? ?? false,
  );
}
