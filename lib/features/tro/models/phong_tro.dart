import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại phòng để lọc ở mục 3.1 (ở ghép / ở riêng). Lưu trong Firestore dạng chữ.
enum RoomType {
  oRieng('o_rieng', 'Phòng riêng'),
  oGhep('o_ghep', 'Ở ghép'),
  studio('studio', 'Studio');

  const RoomType(this.value, this.label);

  final String value;
  final String label;

  static RoomType fromValue(String? value) => RoomType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => RoomType.oRieng,
  );
}

/// Phòng trọ — collection `phong_tro` (mục 7.3). Tên field khớp bảng trong tài liệu.
class PhongTro {
  const PhongTro({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.price,
    required this.address,
    this.ownerVerified = false,
    this.images = const [],
    this.electricPrice = 0,
    this.waterPrice = 0,
    this.area = 0,
    this.maxPeople = 1,
    this.amenities = const [],
    this.lifestylePrefs = const [],
    this.depositEnabled = false,
    this.location,
    this.status = 'available',
    this.roomType = RoomType.oRieng,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final bool ownerVerified;
  final String title;
  final List<String> images;
  final num price;
  final num electricPrice;
  final num waterPrice;
  final double area;
  final int maxPeople;
  final List<String> amenities;
  final List<String> lifestylePrefs;
  final bool depositEnabled;
  final GeoPoint? location;
  final String address;

  /// "available" | "rented" | "hidden"
  final String status;

  /// Không có trong bảng 7.3 nhưng cần cho bộ lọc ở mục 3.1.
  final RoomType roomType;
  final DateTime? createdAt;

  factory PhongTro.fromMap(String id, Map<String, dynamic> map) => PhongTro(
    id: id,
    ownerId: map['ownerId'] as String? ?? '',
    ownerVerified: map['ownerVerified'] as bool? ?? false,
    title: map['title'] as String? ?? '',
    images: List<String>.from(map['images'] as List? ?? const []),
    price: map['price'] as num? ?? 0,
    electricPrice: map['electricPrice'] as num? ?? 0,
    waterPrice: map['waterPrice'] as num? ?? 0,
    area: (map['area'] as num? ?? 0).toDouble(),
    maxPeople: (map['maxPeople'] as num? ?? 1).toInt(),
    amenities: List<String>.from(map['amenities'] as List? ?? const []),
    lifestylePrefs: List<String>.from(
      map['lifestylePrefs'] as List? ?? const [],
    ),
    depositEnabled: map['depositEnabled'] as bool? ?? false,
    location: map['location'] as GeoPoint?,
    address: map['address'] as String? ?? '',
    status: map['status'] as String? ?? 'available',
    roomType: RoomType.fromValue(map['roomType'] as String?),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  /// Dữ liệu ghi lên Firestore khi đăng tin. `ownerId` và `createdAt` do
  /// `DailyQuota.createPost` gán; tin mới luôn chưa xác thực và còn trống.
  Map<String, dynamic> toMap() => {
    'ownerVerified': false,
    'title': title,
    'images': images,
    'price': price,
    'electricPrice': electricPrice,
    'waterPrice': waterPrice,
    'area': area,
    'maxPeople': maxPeople,
    'amenities': amenities,
    'lifestylePrefs': lifestylePrefs,
    'depositEnabled': depositEnabled,
    'location': location,
    'address': address,
    'status': 'available',
    'roomType': roomType.value,
  };
}

/// Tên hiển thị của mã tiện ích / phong cách sống lưu trong Firestore.
const amenityLabels = {
  'may_lanh': 'Máy lạnh',
  'gac_lung': 'Gác lửng',
  'wifi': 'Wifi',
  'cho_de_xe': 'Chỗ để xe',
  'an_ninh': 'An ninh',
  'gio_giac_tu_do': 'Giờ giấc tự do',
};

const lifestyleLabels = {
  'an_chay': 'Ăn chay',
  'co_nuoi_thu_cung': 'Có nuôi thú cưng',
  'khong_hut_thuoc': 'Không hút thuốc',
};
