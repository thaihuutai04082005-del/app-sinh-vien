import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/danh_gia.dart';
import 'tro_api.dart';

/// Đánh giá riêng của Tìm trọ (mục 2.9).
abstract interface class DanhGiaService {
  Stream<List<DanhGia>> cuaNhaTro(String nhaTroId);
  Stream<DanhGia?> theoNguon(String loai, String id);
  Future<void> gui({
    required String loaiNguon,
    required String idNguon,
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  });
  Future<void> traLoi(String danhGiaId, String noiDung);
}

class FirebaseDanhGiaService implements DanhGiaService {
  FirebaseDanhGiaService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _c =>
      (_db ?? FirebaseFirestore.instance).collection('tro_danh_gia');

  @override
  Stream<List<DanhGia>> cuaNhaTro(String nhaTroId) => _c
      .where('nhaTroId', isEqualTo: nhaTroId)
      .where('hienThi', isEqualTo: 'hien')
      .snapshots()
      .map(
        (s) => sapXepDanhGia([
          for (final d in s.docs) DanhGia.fromMap(d.id, d.data()),
        ]),
      );

  @override
  Stream<DanhGia?> theoNguon(String loai, String id) => _c
      .doc('${loai}_$id')
      .snapshots()
      .map((s) => s.exists ? DanhGia.fromMap(s.id, s.data()!) : null);

  @override
  Future<void> gui({
    required String loaiNguon,
    required String idNguon,
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  }) => api.goi('guiDanhGia', {
    'nguon': {'loai': loaiNguon, 'id': idNguon},
    'diem': diem,
    'the': the,
    'nhanXet': nhanXet,
    'anh': anh,
  });

  @override
  Future<void> traLoi(String danhGiaId, String noiDung) =>
      api.goi('traLoiDanhGia', {'danhGiaId': danhGiaId, 'noiDung': noiDung});
}
