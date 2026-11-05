import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/services/callable_api.dart';

/// Đơn đặt xe dọn trọ — collection `booking_xe` (mục 7.3). Chỉ server ghi.
class BookingXe {
  const BookingXe({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.itemPhotos,
    required this.quotedPrice,
    required this.scheduledAt,
    required this.status,
    this.videos = const [],
    this.userName = '',
    this.driverName = '',
    this.vehicleType = '',
    this.contactPhone = '',
    this.driverPhone,
    this.note = '',
    this.cancelledBy,
    this.cancelReason,
    this.lichSu = const [],
    this.reviewed = false,
    this.driverLastLocation,
    this.driverLocationAt,
  });

  final String id;
  final String userId;
  final String driverId;
  final String fromAddress;
  final String toAddress;

  /// URL ảnh đồ đạc để tài xế báo giá chính xác.
  final List<String> itemPhotos;

  /// Giá báo trọn gói; null khi tài xế chưa báo giá.
  final num? quotedPrice;
  final DateTime scheduledAt;

  /// pending | quoted | confirmed | in_progress | done | cancelled
  final String status;

  /// URL video quay đồ đạc (tối đa 1).
  final List<String> videos;
  final String userName;
  final String driverName;
  final String vehicleType;

  /// Số của sinh viên, tài xế thấy để liên hệ.
  final String contactPhone;

  /// Số tài xế (đã OTP), chỉ có sau khi sinh viên chấp nhận báo giá.
  final String? driverPhone;
  final String note;

  /// user | driver
  final String? cancelledBy;
  final String? cancelReason;
  final List<MocTrangThai> lichSu;

  /// Sinh viên đã đánh giá chuyến này.
  final bool reviewed;

  /// Vị trí tài xế gửi lên khi đang chuyển (mục 3.3: theo dõi realtime).
  final ({double lat, double lng})? driverLastLocation;
  final DateTime? driverLocationAt;

  static const statusLabels = {
    'pending': 'Chờ báo giá',
    'quoted': 'Đã báo giá',
    'confirmed': 'Đã chốt',
    'in_progress': 'Đang chuyển',
    'done': 'Hoàn thành',
    'cancelled': 'Đã hủy',
  };

  static const nguoiLamLabels = {'user': 'Sinh viên', 'driver': 'Tài xế'};

  bool get dangMo => !['done', 'cancelled'].contains(status);

  factory BookingXe.fromMap(Map<String, dynamic> map) => BookingXe(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    driverId: map['driverId'] as String? ?? '',
    fromAddress: map['fromAddress'] as String? ?? '',
    toAddress: map['toAddress'] as String? ?? '',
    itemPhotos: _strings(map['itemPhotos']),
    quotedPrice: map['quotedPrice'] as num?,
    scheduledAt:
        docThoiGian(map['scheduledAt'])?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    status: map['status'] as String? ?? 'pending',
    videos: _strings(map['videos']),
    userName: map['userName'] as String? ?? '',
    driverName: map['driverName'] as String? ?? '',
    vehicleType: map['vehicleType'] as String? ?? '',
    contactPhone: map['contactPhone'] as String? ?? '',
    driverPhone: map['driverPhone'] as String?,
    note: map['note'] as String? ?? '',
    cancelledBy: map['cancelledBy'] as String?,
    cancelReason: map['cancelReason'] as String?,
    lichSu: MocTrangThai.docDanhSach(map['lichSu']),
    reviewed: map['reviewed'] as bool? ?? false,
    driverLastLocation: switch (map['driverLastLocation']) {
      GeoPoint(:final latitude, :final longitude) => (
        lat: latitude,
        lng: longitude,
      ),
      _ => null,
    },
    driverLocationAt: docThoiGian(map['driverLocationAt']),
  );
}

/// Thông tin sinh viên nhập khi gửi yêu cầu đặt xe.
class YeuCauXe {
  const YeuCauXe({
    required this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.scheduledAt,
    required this.contactPhone,
    required this.itemPhotos,
    this.videos = const [],
    this.note = '',
  });

  final String driverId;
  final String fromAddress;
  final String toAddress;
  final DateTime scheduledAt;
  final String contactPhone;
  final List<String> itemPhotos;
  final List<String> videos;
  final String note;

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'fromAddress': fromAddress,
    'toAddress': toAddress,
    'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    'contactPhone': contactPhone,
    'itemPhotos': itemPhotos,
    'videos': videos,
    'note': note,
  };
}

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];
