import '../../../shared/models/danh_gia.dart';

/// Sản phẩm của shop quần áo — collection `products` (mục 7.3). Chỉ server ghi.
class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.images,
    required this.price,
    required this.sizes,
    required this.stock,
    required this.category,
    required this.status,
    this.videos = const [],
    this.description = '',
    this.shopName = '',
    this.diem = DiemDanhGia.chuaCo,
  });

  final String id;
  final String shopId;
  final String name;

  /// URL ảnh sản phẩm (đã upload), ảnh đầu tiên là ảnh bìa.
  final List<String> images;
  final num price;
  final List<String> sizes;
  final int stock;
  final String category;

  /// "active" | "out_of_stock"
  final String status;

  /// URL video (tối đa 1).
  final List<String> videos;
  final String description;
  final String shopName;

  /// Điểm cộng dồn từ đánh giá các đơn có sản phẩm này.
  final DiemDanhGia diem;

  bool get conHang => status != 'out_of_stock' && stock > 0;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String? ?? '',
    shopId: map['shopId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    images: _strings(map['images']),
    price: map['price'] as num? ?? 0,
    sizes: _strings(map['sizes']),
    stock: (map['stock'] as num?)?.toInt() ?? 0,
    category: map['category'] as String? ?? '',
    status: map['status'] as String? ?? 'active',
    videos: _strings(map['videos']),
    description: map['description'] as String? ?? '',
    shopName: map['shopName'] as String? ?? '',
    diem: DiemDanhGia.fromMap(map),
  );
}

/// Thông tin người bán nhập khi đăng / sửa sản phẩm.
class SanPhamNhap {
  const SanPhamNhap({
    required this.name,
    required this.images,
    required this.price,
    required this.sizes,
    required this.stock,
    required this.category,
    this.description = '',
    this.videos = const [],
  });

  final String name;
  final String description;
  final List<String> images;
  final List<String> videos;
  final int price;
  final List<String> sizes;
  final int stock;
  final String category;

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'images': images,
    'videos': videos,
    'price': price,
    'sizes': sizes,
    'stock': stock,
    'category': category,
  };
}

const productCategoryLabels = {
  'ao': 'Áo',
  'quan': 'Quần',
  'phu_kien': 'Phụ kiện',
};

const productSizes = ['S', 'M', 'L', 'XL', 'XXL', 'Freesize'];

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

/// Thống kê công khai của shop — `shop_stats/{shopId}` (server cộng dồn).
class ThongKeShop {
  const ThongKeShop({
    this.diem = DiemDanhGia.chuaCo,
    this.orderCount = 0,
    this.cancelCount = 0,
    this.confirmCount = 0,
    this.confirmMsSum = 0,
  });

  final DiemDanhGia diem;
  final int orderCount;

  /// Đơn shop tự hủy hoặc hệ thống hủy vì shop không xác nhận.
  final int cancelCount;
  final int confirmCount;
  final num confirmMsSum;

  static const trong = ThongKeShop();

  factory ThongKeShop.fromMap(Map<String, dynamic>? m) => ThongKeShop(
    diem: DiemDanhGia.fromMap(m),
    orderCount: (m?['orderCount'] as num?)?.toInt() ?? 0,
    cancelCount: (m?['cancelCount'] as num?)?.toInt() ?? 0,
    confirmCount: (m?['confirmCount'] as num?)?.toInt() ?? 0,
    confirmMsSum: m?['confirmMsSum'] as num? ?? 0,
  );

  /// Tỷ lệ đơn bị shop / hệ thống hủy (0–1); null khi chưa có đơn.
  double? get tyLeHuy => orderCount == 0 ? null : cancelCount / orderCount;

  /// Thời gian trung bình từ lúc đặt đến lúc shop xác nhận; null khi chưa xác nhận đơn nào.
  Duration? get xacNhanTrungBinh => confirmCount == 0
      ? null
      : Duration(milliseconds: (confirmMsSum / confirmCount).round());
}
