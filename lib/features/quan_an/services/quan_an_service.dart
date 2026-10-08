import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mon_an.dart';
import '../models/nhom_mon.dart';
import '../models/quan_an.dart';
import 'quan_an_api.dart';

/// Quán ăn: đọc cho sảnh / chi tiết, bản nháp và thao tác của chủ quán (mục 3.3, 3.4).
abstract interface class QuanAnService {
  // ---- Sinh viên ----
  /// Quán `active` (sảnh còn lọc tiếp: đủ số món, theo bộ lọc).
  Stream<List<QuanAn>> quanDangHien();
  Stream<QuanAn?> quan(String id);

  /// Món còn trong menu (đã loại món đã xóa), mọi trạng thái còn hàng / hết hàng.
  Stream<List<MonAn>> monCuaQuan(String quanId);
  Stream<List<NhomMon>> nhomMon(String quanId);
  Stream<ChiSoChuQuan> chiSoChu(String chuQuanId);

  /// Số điện thoại quán — khách chưa đăng nhập không thấy; hệ thống trả khi đã đăng nhập.
  Future<String?> laySdtQuan(String quanId);
  Stream<bool> daLuu(String uid, String quanId);
  Stream<List<String>> quanDaLuu(String uid);
  Future<void> luu(String uid, String quanId, {required bool luu});

  // ---- Chủ quán ----
  Stream<List<QuanAn>> quanCuaToi(String uid);

  /// Ghi bản nháp (trạng thái `draft`). Trả về id quán.
  Future<String> luuNhapQuan(String? id, Map<String, dynamic> duLieu);
  Future<void> luuGiayTo(String quanId, GiayToQuan giayTo);

  /// Giấy tờ của quán (chủ quán / admin) qua hành động `layGiayToQuan`.
  Future<GiayToQuan> layGiayTo(String quanId);

  /// Gọi hành động của chủ quán: `guiDuyetQuan`, `suaQuan`, `nangCapLoaiQuan`, `caiDatDatMon`,
  /// `tamNghi`, `tamNgungNhanDon`, `anHienQuan`, `ngungKinhDoanh`, `xacNhanConHoatDong`,
  /// `chuyenLoaiQuan`... Trả về kết quả của server (ví dụ `tamNghi` có thể trả
  /// `{canXacNhan: true, donAnhHuong, banAnhHuong}`).
  Future<Map<String, dynamic>> thaoTac(
    String hanhDong,
    Map<String, dynamic> tham,
  );
}

class FirebaseQuanAnService implements QuanAnService {
  FirebaseQuanAnService({
    required this.api,
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _db = firestore;

  final QuanAnApi api;

  /// Người đang dùng (để truy vấn dữ liệu của chủ quán khớp rules).
  final String uid;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _quan =>
      _f.collection('qa_quan');

  @override
  Stream<List<QuanAn>> quanDangHien() => _quan
      .where('trangThai', isEqualTo: 'active')
      .limit(500)
      .snapshots()
      .map((s) => [for (final d in s.docs) QuanAn.fromMap(d.id, d.data())]);

  @override
  Stream<QuanAn?> quan(String id) => _quan
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? QuanAn.fromMap(s.id, s.data()!) : null);

  @override
  Stream<List<MonAn>> monCuaQuan(String quanId) => _f
      .collection('qa_mon')
      .where('quanId', isEqualTo: quanId)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) MonAn.fromMap(d.id, d.data())]
          ..removeWhere((m) => m.daXoa)
          ..sort((a, b) => a.thuTu.compareTo(b.thuTu)),
      );

  @override
  Stream<List<NhomMon>> nhomMon(String quanId) => _f
      .collection('qa_nhom_mon')
      .where('quanId', isEqualTo: quanId)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) NhomMon.fromMap(d.id, d.data())]
              ..sort((a, b) => a.thuTu.compareTo(b.thuTu)),
      );

  @override
  Stream<ChiSoChuQuan> chiSoChu(String chuQuanId) => _f
      .collection('qa_chi_so_chu')
      .doc(chuQuanId)
      .snapshots()
      .map((s) => ChiSoChuQuan.fromMap(s.data()));

  @override
  Future<String?> laySdtQuan(String quanId) async =>
      (await api.goi('laySdtQuan', {'quanId': quanId}))['sdt'] as String?;

  DocumentReference<Map<String, dynamic>> _luu(String uid, String quanId) =>
      _f.collection('qa_luu').doc('${uid}_$quanId');

  @override
  Stream<bool> daLuu(String uid, String quanId) =>
      _luu(uid, quanId).snapshots().map((s) => s.exists);

  @override
  Stream<List<String>> quanDaLuu(String uid) => _f
      .collection('qa_luu')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) d.data()['quanId'] as String]);

  @override
  Future<void> luu(String uid, String quanId, {required bool luu}) => luu
      ? _luu(uid, quanId).set({
          'uid': uid,
          'quanId': quanId,
          'nhanThongBao': true,
          'luc': FieldValue.serverTimestamp(),
        })
      : _luu(uid, quanId).delete();

  @override
  Stream<List<QuanAn>> quanCuaToi(String uid) => _quan
      // Điều kiện chủ quán để truy vấn khớp rules (bản nháp chỉ chủ đọc được).
      .where('chuQuanId', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) QuanAn.fromMap(d.id, d.data())]);

  @override
  Future<String> luuNhapQuan(String? id, Map<String, dynamic> duLieu) async {
    final ref = id == null ? _quan.doc() : _quan.doc(id);
    await ref.set({
      ...duLieu,
      'chuQuanId': uid,
      'trangThai': 'draft',
      'capNhatLuc': FieldValue.serverTimestamp(),
      if (id == null) 'taoLuc': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  @override
  Future<void> luuGiayTo(String quanId, GiayToQuan giayTo) =>
      _quan.doc(quanId).collection('rieng').doc('giay_to').set(giayTo.toMap());

  @override
  Future<GiayToQuan> layGiayTo(String quanId) async {
    final r = await api.goi('layGiayToQuan', {'quanId': quanId});
    final g = r['giayTo'];
    return GiayToQuan.fromMap(g is Map ? Map<String, dynamic>.from(g) : r);
  }

  @override
  Future<Map<String, dynamic>> thaoTac(
    String hanhDong,
    Map<String, dynamic> tham,
  ) => api.goi(hanhDong, tham);
}
