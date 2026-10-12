import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/coc_truc_tiep.dart';
import 'tro_api.dart';

/// Cọc trực tiếp ngoài app (mục 2.5d).
abstract interface class CocTrucTiepService {
  Stream<List<CocTrucTiep>> cuaChuTro(String uid);
  Stream<CocTrucTiep?> theoId(String id);

  /// Các khoản cọc trực tiếp mà chủ trọ ghi số điện thoại của mình là người cọc.
  Stream<List<CocTrucTiep>> cuaNguoiCoc(String sdt);
  Future<void> xacNhan({
    required String phongId,
    required DateTime ngayNhanDuKien,
    String? sdtNguoiCoc,
  });
  Future<void> capNhat(String id, String ketQua, {DateTime? ngayNhanDuKien});
  Future<void> toiDaThue(String id);
}

class FirebaseCocTrucTiepService implements CocTrucTiepService {
  FirebaseCocTrucTiepService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _c =>
      (_db ?? FirebaseFirestore.instance).collection('tro_coc_truc_tiep');

  @override
  Stream<List<CocTrucTiep>> cuaChuTro(String uid) => _c
      .where('chuTroId', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CocTrucTiep.fromMap(d.id, d.data())],
      );

  @override
  Stream<List<CocTrucTiep>> cuaNguoiCoc(String sdt) => _c
      .where('sdtNguoiCoc', isEqualTo: sdt)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CocTrucTiep.fromMap(d.id, d.data())],
      );

  @override
  Stream<CocTrucTiep?> theoId(String id) => _c
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? CocTrucTiep.fromMap(s.id, s.data()!) : null);

  @override
  Future<void> xacNhan({
    required String phongId,
    required DateTime ngayNhanDuKien,
    String? sdtNguoiCoc,
  }) => api.goi('xacNhanCocTrucTiep', {
    'phongId': phongId,
    'ngayNhanDuKien': ngayNhanDuKien.millisecondsSinceEpoch,
    if (sdtNguoiCoc != null && sdtNguoiCoc.trim().isNotEmpty)
      'sdtNguoiCoc': sdtNguoiCoc.trim(),
  });

  @override
  Future<void> capNhat(String id, String ketQua, {DateTime? ngayNhanDuKien}) =>
      api.goi('capNhatCocTrucTiep', {
        'id': id,
        'ketQua': ketQua,
        if (ngayNhanDuKien != null)
          'ngayNhanDuKien': ngayNhanDuKien.millisecondsSinceEpoch,
      });

  @override
  Future<void> toiDaThue(String id) => api.goi('toiDaThuePhong', {'id': id});
}
