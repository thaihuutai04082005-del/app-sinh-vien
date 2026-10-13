import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/services/callable_api.dart';
import '../models/product.dart';

/// Đọc sản phẩm trực tiếp; đăng / sửa / xóa gửi qua callable `shopApi`.
abstract interface class ProductService {
  Future<List<Product>> getDanhSachSanPham();
  Future<List<Product>> getSanPhamCuaShop(String shopId);
  Future<Product> getSanPham(String id);

  /// Trả về id sản phẩm mới.
  Future<String> dangSanPham(SanPhamNhap sp);
  Future<void> suaSanPham(String id, SanPhamNhap sp);
  Future<void> xoaSanPham(String id);
}

class FirebaseProductService implements ProductService {
  FirebaseProductService({CallableApi? api, this._db})
    : _api = api ?? FirebaseCallableApi('shopApi');

  final CallableApi _api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      (_db ?? FirebaseFirestore.instance).collection(Collections.products);

  @override
  Future<List<Product>> getDanhSachSanPham() async {
    final snapshot = await _products
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<Product>> getSanPhamCuaShop(String shopId) async {
    final snapshot = await _products
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<Product> getSanPham(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) throw StateError('Sản phẩm không còn tồn tại.');
    return _fromDoc(doc);
  }

  @override
  Future<String> dangSanPham(SanPhamNhap sp) async =>
      (await _api.goi('dangSanPham', sp.toMap()))['id'] as String;

  @override
  Future<void> suaSanPham(String id, SanPhamNhap sp) =>
      _api.goi('suaSanPham', {...sp.toMap(), 'productId': id});

  @override
  Future<void> xoaSanPham(String id) =>
      _api.goi('xoaSanPham', {'productId': id});

  static Product _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Product.fromMap({...?doc.data(), 'id': doc.id});
}
