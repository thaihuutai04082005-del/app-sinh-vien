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
