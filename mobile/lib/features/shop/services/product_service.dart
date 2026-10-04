import '../../../core/services/api_client.dart';
import '../models/product.dart';

abstract interface class ProductService {
  Future<List<Product>> getDanhSachSanPham();
  Future<Product> getSanPham(String id);

  /// Lưu sản phẩm mới; server gán id, shopId, status.
  Future<Product> dangSanPham(Product product);
}

class CloudflareProductService implements ProductService {
  CloudflareProductService({ApiClient? api}) : _api = api ?? ApiClient();

  static const _collection = 'products';
  final ApiClient _api;

  @override
  Future<List<Product>> getDanhSachSanPham() async =>
      (await _api.list(_collection)).map(Product.fromMap).toList();

  @override
  Future<Product> getSanPham(String id) async =>
      Product.fromMap(await _api.get(_collection, id));

  @override
  Future<Product> dangSanPham(Product product) async =>
      Product.fromMap(await _api.create(_collection, product.toMap()));
}
