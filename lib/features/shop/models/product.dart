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
