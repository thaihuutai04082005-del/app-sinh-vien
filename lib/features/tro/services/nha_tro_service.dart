import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nha_tro.dart';
import '../models/phong_tro.dart';
import 'tro_api.dart';

/// Chỉ số uy tín công khai của chủ trọ (mục 2.3 Bước 4).
class ChiSoChu {
  const ChiSoChu({
    this.hoTen,
    this.daXacThucDanhTinh = false,
    this.tyLePhanHoi,
    this.tyLeCamKet,
    this.soViPham90 = 0,
  });

  final String? hoTen;
  final bool daXacThucDanhTinh;
  final int? tyLePhanHoi;
  final int? tyLeCamKet;
  final int soViPham90;

  factory ChiSoChu.fromMap(Map<String, dynamic>? m) => ChiSoChu(
    hoTen: m?['hoTen'] as String?,
    daXacThucDanhTinh: m?['daXacThucDanhTinh'] as bool? ?? false,
    tyLePhanHoi: (m?['tyLePhanHoi'] as num?)?.toInt(),
    tyLeCamKet: (m?['tyLeCamKet'] as num?)?.toInt(),
    soViPham90: (m?['soViPham90'] as num?)?.toInt() ?? 0,
  );
}

/// Nhà trọ và phòng: đọc cho sảnh / chi tiết, bản nháp của chủ trọ, các thao tác quản lý.
abstract interface class NhaTroService {
  // ---- Sinh viên ----
  Stream<List<NhaTro>> nhaTroDangHien();
  Stream<List<PhongTro>> phongConTrong();
  Stream<NhaTro?> nhaTro(String id);
  Stream<List<PhongTro>> phongHienThi(String nhaTroId);
  Stream<PhongTro?> phong(String id);
  Stream<ChiSoChu> chiSoChu(String chuTroId);
  Future<String?> laySdtChuTro(String nhaTroId);
  Stream<bool> daLuu(String uid, String nhaTroId);
  Stream<List<String>> nhaTroDaLuu(String uid);
  Future<void> luu(String uid, String nhaTroId, {required bool luu});

  // ---- Chủ trọ ----
  Stream<List<NhaTro>> nhaTroCuaToi(String uid);
  Stream<List<PhongTro>> phongCuaNha(String nhaTroId);
  Future<String> luuNhapNhaTro(String? id, Map<String, dynamic> duLieu);
  Future<void> luuGiayTo(String nhaTroId, List<String> giayTo);
  Future<List<String>> docGiayTo(String nhaTroId);
  Future<String> luuNhapPhong(String? id, Map<String, dynamic> duLieu);
  Future<void> xoaNhap(String col, String id);
  Future<void> thaoTac(String hanhDong, Map<String, dynamic> thamSo);
}

class FirebaseNhaTroService implements NhaTroService {
  FirebaseNhaTroService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _nha =>
      _f.collection('nha_tro');
  CollectionReference<Map<String, dynamic>> get _phong =>
      _f.collection('phong_tro');

  @override
  Stream<List<NhaTro>> nhaTroDangHien() => _nha
      .where('trangThai', isEqualTo: 'active')
      .limit(500)
      .snapshots()
      .map((s) => [for (final d in s.docs) NhaTro.fromMap(d.id, d.data())]);

  @override
  Stream<List<PhongTro>> phongConTrong() => _phong
      .where('trangThai', isEqualTo: 'available')
      .where('nhaTro.trangThai', isEqualTo: 'active')
      .limit(1000)
      .snapshots()
      .map((s) => [for (final d in s.docs) PhongTro.fromMap(d.id, d.data())]);

  @override
  Stream<NhaTro?> nhaTro(String id) => _nha
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? NhaTro.fromMap(s.id, s.data()!) : null);

  @override
  Stream<List<PhongTro>> phongHienThi(String nhaTroId) => _phong
      .where('nhaTroId', isEqualTo: nhaTroId)
      .where('trangThai', whereIn: ['available', 'reserved', 'rented'])
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) PhongTro.fromMap(d.id, d.data())]
              ..removeWhere((p) => p.daXoa),
      );

  @override
  Stream<PhongTro?> phong(String id) => _phong
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? PhongTro.fromMap(s.id, s.data()!) : null);

  @override
  Stream<ChiSoChu> chiSoChu(String chuTroId) => _f
      .collection('tro_chi_so_chu')
      .doc(chuTroId)
      .snapshots()
      .map((s) => ChiSoChu.fromMap(s.data()));

  @override
  Future<String?> laySdtChuTro(String nhaTroId) async =>
      (await api.goi('laySdtChuTro', {'nhaTroId': nhaTroId}))['sdt'] as String?;

  DocumentReference<Map<String, dynamic>> _luu(String uid, String nhaTroId) =>
      _f.collection('tro_luu').doc('${uid}_$nhaTroId');

  @override
  Stream<bool> daLuu(String uid, String nhaTroId) =>
      _luu(uid, nhaTroId).snapshots().map((s) => s.exists);

  @override
  Stream<List<String>> nhaTroDaLuu(String uid) => _f
      .collection('tro_luu')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) d.data()['nhaTroId'] as String]);

  @override
  Future<void> luu(String uid, String nhaTroId, {required bool luu}) => luu
      ? _luu(uid, nhaTroId).set({
          'uid': uid,
          'nhaTroId': nhaTroId,
          'nhanThongBao': true,
          'luc': FieldValue.serverTimestamp(),
        })
      : _luu(uid, nhaTroId).delete();

  @override
  Stream<List<NhaTro>> nhaTroCuaToi(String uid) => _nha
      .where('chuTroId', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) NhaTro.fromMap(d.id, d.data())]);

  @override
  Stream<List<PhongTro>> phongCuaNha(String nhaTroId) => _phong
      .where('nhaTroId', isEqualTo: nhaTroId)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) PhongTro.fromMap(d.id, d.data())]
              ..removeWhere((p) => p.daXoa),
      );

  @override
  Future<String> luuNhapNhaTro(String? id, Map<String, dynamic> duLieu) async {
    final ref = id == null ? _nha.doc() : _nha.doc(id);
    await ref.set({
      ...duLieu,
      'trangThai': 'draft',
      'capNhatLuc': FieldValue.serverTimestamp(),
      if (id == null) 'taoLuc': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  @override
  Future<void> luuGiayTo(String nhaTroId, List<String> giayTo) => _nha
      .doc(nhaTroId)
      .collection('rieng')
      .doc('giay_to')
      .set({'giayTo': giayTo});

  @override
  Future<List<String>> docGiayTo(String nhaTroId) async {
    final s = await _nha.doc(nhaTroId).collection('rieng').doc('giay_to').get();
    return List<String>.from(s.data()?['giayTo'] as List? ?? const []);
  }

  @override
  Future<String> luuNhapPhong(String? id, Map<String, dynamic> duLieu) async {
    final ref = id == null ? _phong.doc() : _phong.doc(id);
    await ref.set({
      ...duLieu,
      'trangThai': 'draft',
      'daXoa': false,
      'capNhatLuc': FieldValue.serverTimestamp(),
      if (id == null) 'taoLuc': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  @override
  Future<void> xoaNhap(String col, String id) =>
      _f.collection(col).doc(id).delete();

  @override
  Future<void> thaoTac(String hanhDong, Map<String, dynamic> thamSo) =>
      api.goi(hanhDong, thamSo);
}
