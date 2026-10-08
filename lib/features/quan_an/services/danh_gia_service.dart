import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/danh_gia.dart';
import 'quan_an_api.dart';

/// Đánh giá riêng của Quán ăn (mục 3.9). Mỗi người 1 đánh giá / quán: id tài liệu `{svId}_{quanId}`.
abstract interface class DanhGiaService {
  /// Đánh giá đang hiển thị của một quán (nhãn xác minh lên trước).
  Stream<List<DanhGia>> cuaQuan(String quanId);

  /// Đánh giá của chính tôi về quán (null nếu chưa viết) — để sửa lại.
  Stream<DanhGia?> cuaToi(String quanId);

  /// Gửi / cập nhật đánh giá. [diem] đủ 4 tiêu chí `{monAn, giaCa, veSinh, phucVu}`;
  /// điểm tổng do hệ thống tính.
  Future<void> gui(
    String quanId, {
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  });

  /// Chủ quán trả lời công khai 1 lần.
  Future<void> traLoi(String danhGiaId, String noiDung);
}

class FirebaseDanhGiaService implements DanhGiaService {
  /// [uid] tùy chọn (test); mặc định lấy người đang đăng nhập.
  FirebaseDanhGiaService({
    required this.api,
    FirebaseFirestore? firestore,
    this.uid,
  }) : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;
  final String? uid;

  CollectionReference<Map<String, dynamic>> get _c =>
      (_db ?? FirebaseFirestore.instance).collection('qa_danh_gia');

  @override
  Stream<List<DanhGia>> cuaQuan(String quanId) => _c
      .where('quanId', isEqualTo: quanId)
      .where('trangThaiHienThi', isEqualTo: 'hien')
      .snapshots()
      .map(
        (s) => sapXepDanhGia([
          for (final d in s.docs) DanhGia.fromMap(d.id, d.data()),
        ]),
      );

  @override
  Stream<DanhGia?> cuaToi(String quanId) {
    final ma = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (ma == null || ma.isEmpty) return Stream.value(null);
    return _c
        .doc('${ma}_$quanId')
        .snapshots()
        .map((s) => s.exists ? DanhGia.fromMap(s.id, s.data()!) : null);
  }

  @override
  Future<void> gui(
    String quanId, {
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  }) => api.goi('guiDanhGia', {
    'quanId': quanId,
    'diem': diem,
    'the': the,
    'nhanXet': nhanXet,
    'anh': anh,
  });

  @override
  Future<void> traLoi(String danhGiaId, String noiDung) =>
      api.goi('traLoiDanhGia', {'danhGiaId': danhGiaId, 'noiDung': noiDung});
}
