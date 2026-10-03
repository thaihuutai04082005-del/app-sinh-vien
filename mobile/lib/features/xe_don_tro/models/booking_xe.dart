/// Đơn đặt xe dọn trọ — khớp collection `booking_xe` (mục 7.3).
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

  /// "pending" | "confirmed" | "in_progress" | "done"
  final String status;

  /// URL video quay đồ đạc (tối đa 1). Field bổ sung, chưa có trong mục 7.3.
  final List<String> videos;

  factory BookingXe.fromMap(Map<String, dynamic> map) => BookingXe(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    driverId: map['driverId'] as String? ?? '',
    fromAddress: map['fromAddress'] as String? ?? '',
    toAddress: map['toAddress'] as String? ?? '',
    itemPhotos: map['itemPhotos'] is List
        ? (map['itemPhotos'] as List).whereType<String>().toList()
        : const [],
    quotedPrice: map['quotedPrice'] as num?,
    scheduledAt:
        DateTime.tryParse(map['scheduledAt'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    status: map['status'] as String? ?? 'pending',
    videos: map['videos'] is List
        ? (map['videos'] as List).whereType<String>().toList()
        : const [],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'driverId': driverId,
    'fromAddress': fromAddress,
    'toAddress': toAddress,
    'itemPhotos': itemPhotos,
    'quotedPrice': quotedPrice,
    'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    'status': status,
    'videos': videos,
  };
}
