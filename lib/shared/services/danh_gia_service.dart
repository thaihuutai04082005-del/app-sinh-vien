import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/danh_gia.dart';

/// Đọc đánh giá (công khai). Viết đánh giá đi qua callable của từng module
/// vì server phải kiểm tra người viết đã mua hàng / đi chuyến thật.
abstract interface class DanhGiaService {
  /// Đánh giá về một shop (`targetType` = shop) hoặc tài xế (xe_don_tro).
  Future<List<DanhGia>> theoDoiTuong(String targetType, String targetId);

  /// Đánh giá của các đơn có chứa sản phẩm này.
  Future<List<DanhGia>> theoSanPham(String productId);
}

class FirebaseDanhGiaService implements DanhGiaService {
  FirebaseDanhGiaService([this._db]);

  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      (_db ?? FirebaseFirestore.instance).collection(Collections.reviews);

  @override
  Future<List<DanhGia>> theoDoiTuong(String targetType, String targetId) =>
      _lay(
        _reviews
            .where('targetType', isEqualTo: targetType)
            .where('targetId', isEqualTo: targetId),
      );

  @override
  Future<List<DanhGia>> theoSanPham(String productId) =>
      _lay(_reviews.where('productIds', arrayContains: productId));

  Future<List<DanhGia>> _lay(Query<Map<String, dynamic>> q) async {
    final snap = await q.orderBy('createdAt', descending: true).limit(50).get();
    return [
      for (final d in snap.docs) DanhGia.fromMap({...d.data(), 'id': d.id}),
    ];
  }
}
