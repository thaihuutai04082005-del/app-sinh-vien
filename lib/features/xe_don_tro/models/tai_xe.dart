import '../../../shared/models/danh_gia.dart';

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
    this.licensePlate = '',
    this.vehiclePhotos = const [],
    this.approval = 'pending',
    this.rejectReason,
    this.diem = DiemDanhGia.chuaCo,
    this.priceTrip,
    this.pricePerKm,
    this.priceHourly,
  });

  final String driverId;
  final String name;

  /// xe_tai_nho | xe_ba_gac | xe_may
  final String vehicleType;
  final String area;

  /// Ghi chú thêm cho bảng giá (hồ sơ cũ chỉ có trường này).
  final String priceReference;

  /// Bảng giá tham khảo: theo chuyến, theo km, theo giờ (chỉ khuân vác); có thể thiếu.
  final num? priceTrip;
  final num? pricePerKm;
  final num? priceHourly;
  final String description;

  /// available | busy
  final String status;
  final bool driverVerified;
  final String licensePlate;
  final List<String> vehiclePhotos;

  /// pending | approved | rejected — admin Xe dọn trọ duyệt hồ sơ xe.
  final String approval;
  final String? rejectReason;

  /// Điểm cộng dồn từ đánh giá sau chuyến.
  final DiemDanhGia diem;

  static const loaiXeLabels = {
    'xe_tai_nho': 'Xe tải nhỏ',
    'xe_ba_gac': 'Xe ba gác',
    'xe_may': 'Xe máy chở hàng',
  };

  String get loaiXe => loaiXeLabels[vehicleType] ?? vehicleType;
  bool get daDuyet => approval == 'approved';
  bool get sanSang => daDuyet && status == 'available';

  static const approvalLabels = {
    'pending': 'Đang chờ duyệt',
    'approved': 'Đã duyệt',
    'rejected': 'Bị từ chối',
  };

  factory TaiXe.fromMap(Map<String, dynamic> map) => TaiXe(
    driverId: map['driverId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    vehicleType: map['vehicleType'] as String? ?? '',
    area: map['area'] as String? ?? '',
    priceReference: map['priceReference'] as String? ?? '',
    description: map['description'] as String? ?? '',
    status: map['status'] as String? ?? 'available',
    driverVerified: map['driverVerified'] as bool? ?? false,
    licensePlate: map['licensePlate'] as String? ?? '',
    vehiclePhotos: map['vehiclePhotos'] is List
        ? (map['vehiclePhotos'] as List).whereType<String>().toList()
        : const [],
    approval: map['approval'] as String? ?? 'pending',
    rejectReason: map['rejectReason'] as String?,
    diem: DiemDanhGia.fromMap(map),
    priceTrip: map['priceTrip'] as num?,
    pricePerKm: map['pricePerKm'] as num?,
    priceHourly: map['priceHourly'] as num?,
  );
}

/// Thông tin tài xế nhập khi đăng ký / sửa hồ sơ.
class HoSoTaiXeNhap {
  const HoSoTaiXeNhap({
    required this.vehicleType,
    required this.licensePlate,
    required this.vehiclePhotos,
    required this.licensePhotos,
    required this.area,
    this.priceReference = '',
    this.priceTrip,
    this.pricePerKm,
    this.priceHourly,
    this.description = '',
  });

  final String vehicleType;
  final String licensePlate;
  final List<String> vehiclePhotos;

  /// Ảnh bằng lái — lưu riêng, chỉ tài xế và admin xem.
  final List<String> licensePhotos;
  final String area;
  final String priceReference;
  final int? priceTrip;
  final int? pricePerKm;
  final int? priceHourly;
  final String description;

  Map<String, dynamic> toMap() => {
    'vehicleType': vehicleType,
    'licensePlate': licensePlate,
    'vehiclePhotos': vehiclePhotos,
    'licensePhotos': licensePhotos,
    'area': area,
    'priceReference': priceReference,
    'priceTrip': priceTrip,
    'pricePerKm': pricePerKm,
    'priceHourly': priceHourly,
    'description': description,
  };
}
