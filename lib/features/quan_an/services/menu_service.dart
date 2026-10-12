import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mon_an.dart';
import '../models/nhom_mon.dart';
import 'quan_an_api.dart';

/// Menu của quán: đọc nhóm món + món theo quán; ghi qua API (mục 3.3 Bước 3).
abstract interface class MenuService {
  /// Cho khách: nhóm và món của quán (món đã xóa bị loại).
  Stream<List<NhomMon>> nhomMon(String quanId);
  Stream<List<MonAn>> mon(String quanId);

  /// Cho chủ quán (truy vấn kèm điều kiện chủ quán để khớp rules).
  Stream<List<NhomMon>> nhomMonCuaChu(String quanId);
  Stream<List<MonAn>> monCuaChu(String quanId);

  /// Trả về id nhóm vừa lưu.
  Future<String?> luuNhomMon(NhomMon nhom);
  Future<void> xoaNhomMon(String nhomId);

  /// Trả về id món vừa lưu.
  Future<String?> luuMon(MonAn mon);
  Future<void> xoaMon(String monId);
  Future<void> batTatMon(String monId, {required bool conHang});
}

class FirebaseMenuService implements MenuService {
  FirebaseMenuService({
    required this.api,
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _db = firestore;

  final QuanAnApi api;
  final String uid;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  Stream<List<NhomMon>> _nhom(Query<Map<String, dynamic>> q) =>
      q.snapshots().map(
        (s) =>
            [for (final d in s.docs) NhomMon.fromMap(d.id, d.data())]
              ..sort((a, b) => a.thuTu.compareTo(b.thuTu)),
      );

  Stream<List<MonAn>> _mon(Query<Map<String, dynamic>> q) => q.snapshots().map(
    (s) => [for (final d in s.docs) MonAn.fromMap(d.id, d.data())]
      ..removeWhere((m) => m.daXoa)
      ..sort((a, b) => a.thuTu.compareTo(b.thuTu)),
  );

  @override
  Stream<List<NhomMon>> nhomMon(String quanId) =>
      _nhom(_f.collection('qa_nhom_mon').where('quanId', isEqualTo: quanId));

  @override
  Stream<List<MonAn>> mon(String quanId) =>
      _mon(_f.collection('qa_mon').where('quanId', isEqualTo: quanId));

  @override
  Stream<List<NhomMon>> nhomMonCuaChu(String quanId) => _nhom(
    _f
        .collection('qa_nhom_mon')
        .where('quanId', isEqualTo: quanId)
        .where('chuQuanId', isEqualTo: uid),
  );

  @override
  Stream<List<MonAn>> monCuaChu(String quanId) => _mon(
    _f
        .collection('qa_mon')
        .where('quanId', isEqualTo: quanId)
        .where('chuQuanId', isEqualTo: uid),
  );

  @override
  Future<String?> luuNhomMon(NhomMon nhom) async =>
      (await api.goi('luuNhomMon', nhom.toApiMap()))['nhomId'] as String?;

  @override
  Future<void> xoaNhomMon(String nhomId) =>
      api.goi('xoaNhomMon', {'nhomId': nhomId});

  @override
  Future<String?> luuMon(MonAn mon) async =>
      (await api.goi('luuMon', mon.toApiMap()))['monId'] as String?;

  @override
  Future<void> xoaMon(String monId) => api.goi('xoaMon', {'monId': monId});

  @override
  Future<void> batTatMon(String monId, {required bool conHang}) =>
      api.goi('batTatMon', {'monId': monId, 'conHang': conHang});
}
