import '../services/callable_api.dart';

/// Một đánh giá — collection `reviews` (mục 7.3), dùng chung Shop và Xe dọn trọ.
/// Chỉ server ghi, và chỉ khi người viết đã mua hàng / đi chuyến thật.
class DanhGia {
  const DanhGia({
    required this.id,
    required this.userName,
    required this.rating,
    this.ratingDetail = const {},
    this.comment = '',
    this.images = const [],
    this.createdAt,
  });

  final String id;
  final String userName;

  /// Điểm tổng 1–5 (trung bình các tiêu chí).
  final num rating;

  /// Khóa tiêu chí (xem [TieuChi]) → số sao.
  final Map<String, int> ratingDetail;
  final String comment;
  final List<String> images;
  final DateTime? createdAt;

  factory DanhGia.fromMap(Map<String, dynamic> m) => DanhGia(
    id: m['id'] as String? ?? '',
    userName: m['userName'] as String? ?? '',
    rating: m['rating'] as num? ?? 0,
    ratingDetail: {
      for (final e in (m['ratingDetail'] as Map? ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    },
    comment: m['comment'] as String? ?? '',
    images: m['images'] is List
        ? (m['images'] as List).whereType<String>().toList()
        : const [],
    createdAt: docThoiGian(m['createdAt']),
  );
}

/// Một tiêu chí chấm sao: khóa gửi lên server + tên hiện cho người dùng.
typedef TieuChi = ({String khoa, String ten});

/// Khớp TIEU_CHI_SHOP / TIEU_CHI_XE ở functions-xe-shop/src/danh_gia.js.
const tieuChiShop = <TieuChi>[
  (khoa: 'quality', ten: 'Chất lượng sản phẩm'),
  (khoa: 'accuracy', ten: 'Đúng mô tả'),
  (khoa: 'service', ten: 'Thái độ shop'),
];

const tieuChiXe = <TieuChi>[
  (khoa: 'attitude', ten: 'Thái độ'),
  (khoa: 'punctuality', ten: 'Đúng giờ'),
  (khoa: 'priceAccuracy', ten: 'Giá đúng như báo'),
];

/// Điểm cộng dồn (`ratingSum`, `ratingCount`) do server ghi trên shop / sản phẩm / tài xế.
class DiemDanhGia {
  const DiemDanhGia({this.tong = 0, this.soLuot = 0});

  final num tong;
  final int soLuot;

  static const chuaCo = DiemDanhGia();

  factory DiemDanhGia.fromMap(Map<String, dynamic>? m) => DiemDanhGia(
    tong: m?['ratingSum'] as num? ?? 0,
    soLuot: (m?['ratingCount'] as num?)?.toInt() ?? 0,
  );

  double get trungBinh => soLuot == 0 ? 0 : tong / soLuot;
}

/// Người dùng nhập khi viết đánh giá.
class DanhGiaNhap {
  const DanhGiaNhap({
    required this.ratingDetail,
    this.comment = '',
    this.images = const [],
  });

  final Map<String, int> ratingDetail;
  final String comment;
  final List<String> images;

  Map<String, dynamic> toMap() => {
    'ratingDetail': ratingDetail,
    'comment': comment,
    'images': images,
  };
}
