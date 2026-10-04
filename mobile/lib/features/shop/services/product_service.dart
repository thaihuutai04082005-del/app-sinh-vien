import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/daily_quota.dart';
import '../models/product.dart';

abstract interface class ProductService {
  Future<List<Product>> getDanhSachSanPham();
  Future<Product> getSanPham(String id);

  /// Lưu sản phẩm mới; gán id, shopId = uid người đăng, status = "active".
  Future<Product> dangSanPham(Product product);
}

class FirestoreProductService implements ProductService {
  FirestoreProductService({this._firestore, DailyQuota? quota})
    : _quota = quota ?? DailyQuota(_firestore);

  final FirebaseFirestore? _firestore;
  final DailyQuota _quota;

  CollectionReference<Map<String, dynamic>> get _products =>
      (_firestore ?? FirebaseFirestore.instance).collection('products');

  @override
  Future<List<Product>> getDanhSachSanPham() async {
    final snapshot = await _products
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<Product> getSanPham(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) throw StateError('Không tìm thấy sản phẩm.');
    return _fromDoc(doc);
  }

  @override
  Future<Product> dangSanPham(Product product) async {
    final post = await _quota.createPost(
      'products',
      (uid) => product.toMap()
        ..remove('id')
        ..['shopId'] = uid
        ..['status'] = 'active',
    );
    return Product.fromMap({...post.data, 'id': post.id});
  }

  static Product _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Product.fromMap({...?doc.data(), 'id': doc.id});
}
