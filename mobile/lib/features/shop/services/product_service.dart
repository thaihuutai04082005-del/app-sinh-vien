import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

abstract interface class ProductService {
  Future<List<Product>> getDanhSachSanPham();
  Future<Product> getSanPham(String id);

  /// Lưu sản phẩm mới; Firestore gán id, status = "active".
  Future<Product> dangSanPham(Product product);
}

class FirestoreProductService implements ProductService {
  FirestoreProductService({this._firestore});

  final FirebaseFirestore? _firestore;

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
    final data = product.toMap()
      ..remove('id')
      ..['status'] = 'active';
    final ref = await _products.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return Product.fromMap({...data, 'id': ref.id});
  }

  static Product _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Product.fromMap({...?doc.data(), 'id': doc.id});
}
