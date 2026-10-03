/// Sản phẩm của shop quần áo — khớp collection `products` (mục 7.3).
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

  /// URL video (tối đa 1). Field bổ sung, chưa có trong mục 7.3.
  final List<String> videos;

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
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'shopId': shopId,
    'name': name,
    'images': images,
    'price': price,
    'sizes': sizes,
    'stock': stock,
    'category': category,
    'status': status,
    'videos': videos,
  };
}

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];
