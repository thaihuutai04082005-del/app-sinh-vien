import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/thong_bao.dart';

/// Thông báo và cài đặt thông báo riêng của Tìm trọ (mục 2.11).
abstract interface class ThongBaoService {
  Stream<List<ThongBao>> cuaToi(String uid);
  Future<void> daDoc(String id);
  Stream<Map<String, bool>> caiDat(String uid);
  Future<void> doiCaiDat(String uid, String nhom, bool bat);
}

class FirebaseThongBaoService implements ThongBaoService {
  FirebaseThongBaoService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Stream<List<ThongBao>> cuaToi(String uid) => _f
      .collection('tro_thong_bao')
      .where('nguoiNhan', isEqualTo: uid)
      .orderBy('taoLuc', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => [for (final d in s.docs) ThongBao.fromMap(d.id, d.data())]);

  @override
  Future<void> daDoc(String id) => _f
      .collection('tro_thong_bao')
      .doc(id)
      .update({'docLuc': FieldValue.serverTimestamp()});

  @override
  Stream<Map<String, bool>> caiDat(String uid) =>
      _f.collection('tro_ho_so').doc(uid).snapshots().map((s) {
        final m = (s.data()?['caiDatThongBao'] as Map?) ?? const {};
        return {for (final e in m.entries) e.key as String: e.value as bool};
      });

  @override
  Future<void> doiCaiDat(String uid, String nhom, bool bat) =>
      _f.collection('tro_ho_so').doc(uid).set({
        'caiDatThongBao': {nhom: bat},
      }, SetOptions(merge: true));
}
