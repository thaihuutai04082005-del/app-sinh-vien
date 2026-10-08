import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/khuyen_mai.dart';
import 'quan_an_api.dart';

/// Khuyến mãi của quán: đọc `qa_khuyen_mai`; ghi qua API (mục 3.3 Bước 4).
abstract interface class KhuyenMaiService {
  /// Cho khách: khuyến mãi đang chạy và còn hiệu lực của quán.
  Stream<List<KhuyenMai>> dangChay(String quanId);

  /// Cho chủ quán: mọi khuyến mãi của quán (kể cả đã dừng / hết hạn).
  Stream<List<KhuyenMai>> cuaChu(String quanId);

  /// Trả về id khuyến mãi vừa lưu.
  Future<String?> luu(KhuyenMai km);
  Future<void> dung(String khuyenMaiId);
}

class FirebaseKhuyenMaiService implements KhuyenMaiService {
  FirebaseKhuyenMaiService({
    required this.api,
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _db = firestore;

  final QuanAnApi api;
  final String uid;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  List<KhuyenMai> _doc(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs) KhuyenMai.fromMap(d.id, d.data()),
  ];

  @override
  Stream<List<KhuyenMai>> dangChay(String quanId) => _f
      .collection('qa_khuyen_mai')
      .where('quanId', isEqualTo: quanId)
      .where('trangThai', isEqualTo: 'chay')
      .snapshots()
      .map((s) {
        final bayGio = DateTime.now();
        return _doc(s).where((k) => k.conHieuLuc(bayGio)).toList();
      });

  @override
  Stream<List<KhuyenMai>> cuaChu(String quanId) => _f
      .collection('qa_khuyen_mai')
      .where('quanId', isEqualTo: quanId)
      .where('chuQuanId', isEqualTo: uid)
      .snapshots()
      .map(_doc);

  @override
  Future<String?> luu(KhuyenMai km) async =>
      (await api.goi('luuKhuyenMai', km.toApiMap()))['khuyenMaiId'] as String?;

  @override
  Future<void> dung(String khuyenMaiId) =>
      api.goi('dungKhuyenMai', {'khuyenMaiId': khuyenMaiId});
}
