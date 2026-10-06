import 'package:cloud_firestore/cloud_firestore.dart';

/// Điểm vui chơi — collection `vui_choi` (mục 7.3). Tên field khớp bảng trong tài liệu.
class VuiChoiModel {
  const VuiChoiModel({
    required this.id,
    required this.name,
    required this.images,
    required this.category,
    required this.location,
    required this.address,
    required this.openHour,
    required this.closeHour,
    required this.ticketPrice,
    this.ownerId = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final List<String> images;

  /// "cafe" | "rap_phim" | "cong_vien"...
  final String category;
  final GeoPoint location;
  final String address;
  final String openHour;
  final String closeHour;
  final double ticketPrice;

  /// uid người đăng (do DailyQuota gán khi đăng tin).
  final String ownerId;
  final DateTime? createdAt;

  factory VuiChoiModel.fromMap(String id, Map<String, dynamic> map) =>
      VuiChoiModel(
        id: id,
        name: map['name'] as String? ?? '',
        images: List<String>.from(map['images'] as List? ?? const []),
        category: map['category'] as String? ?? '',
        location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
        address: map['address'] as String? ?? '',
        openHour: map['openHour'] as String? ?? '',
        closeHour: map['closeHour'] as String? ?? '',
        ticketPrice: (map['ticketPrice'] as num? ?? 0).toDouble(),
        ownerId: map['ownerId'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'images': images,
    'category': category,
    'location': location,
    'address': address,
    'openHour': openHour,
    'closeHour': closeHour,
    'ticketPrice': ticketPrice,
  };
}

/// Tên hiển thị của mã loại hình lưu trong Firestore.
const vuiChoiCategoryLabels = {
  'cafe': 'Cà phê',
  'rap_phim': 'Rạp phim',
  'cong_vien': 'Công viên',
};
