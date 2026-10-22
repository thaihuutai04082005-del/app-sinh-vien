import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

/// Theo dõi / yêu thích — collection `follows` (mục 7.3, dùng chung).
/// `targetType`: shop (theo dõi shop) | product (sản phẩm yêu thích).
/// App tự ghi / xóa của mình (rules kiểm tra id `{uid}_{targetType}_{targetId}`).
abstract interface class TheoDoiService {
  Future<bool> dangTheoDoi(String targetType, String targetId);
  Future<void> theoDoi(String targetType, String targetId);
  Future<void> boTheoDoi(String targetType, String targetId);

  /// Id các đối tượng mình đang theo dõi / yêu thích.
  Future<List<String>> cuaToi(String targetType);

  /// Số người theo dõi một shop.
  Future<int> soNguoiTheoDoi(String targetId);
}

class FirebaseTheoDoiService implements TheoDoiService {
  FirebaseTheoDoiService({required this.uid, this._db});

  final String uid;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _follows =>
      (_db ?? FirebaseFirestore.instance).collection(Collections.follows);

  DocumentReference<Map<String, dynamic>> _doc(String type, String id) =>
      _follows.doc('${uid}_${type}_$id');

  @override
  Future<bool> dangTheoDoi(String targetType, String targetId) async =>
      uid.isNotEmpty && (await _doc(targetType, targetId).get()).exists;

  @override
  Future<void> theoDoi(String targetType, String targetId) =>
      _doc(targetType, targetId).set({
        'followerId': uid,
        'targetId': targetId,
        'targetType': targetType,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> boTheoDoi(String targetType, String targetId) =>
      _doc(targetType, targetId).delete();

  @override
  Future<List<String>> cuaToi(String targetType) async {
    if (uid.isEmpty) return [];
    final snap = await _follows
        .where('followerId', isEqualTo: uid)
        .where('targetType', isEqualTo: targetType)
        .limit(200)
        .get();
    return [for (final d in snap.docs) d.data()['targetId'] as String];
  }

  @override
  Future<int> soNguoiTheoDoi(String targetId) async {
    final snap = await _follows
        .where('targetType', isEqualTo: 'shop')
        .where('targetId', isEqualTo: targetId)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
