import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/xac_thuc.dart';

/// Lỗi nghiệp vụ trả về từ server, hiện thẳng cho người dùng.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tài khoản dùng chung: OTP số điện thoại, xác nhận người thật, quyền admin (Phần 4).
abstract interface class XacThucService {
  Stream<XacThuc> cuaToi(String uid);
  Stream<QuyenAdmin> quyenAdmin(String uid);
  Future<String> guiOtp(String sdt);
  Future<void> xacNhanOtp(String ma);
  Future<void> guiDanhTinh({required String hoTen, required String soCccd});
  Stream<List<(String uid, String hoTen, String cccd4)>> danhTinhChoDuyet();
  Future<void> duyetDanhTinh(String uid, {required bool dongY, String? lyDo});
}

class FirebaseXacThucService implements XacThucService {
  FirebaseXacThucService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _db = firestore,
       _fn = functions;

  final FirebaseFirestore? _db;
  final FirebaseFunctions? _fn;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _goi(
    String hanhDong, [
    Map<String, dynamic> tham = const {},
  ]) async {
    try {
      final r = await (_fn ?? FirebaseFunctions.instance)
          .httpsCallable('taiKhoanApi')
          .call({'hanhDong': hanhDong, ...tham});
      return Map<String, dynamic>.from(r.data as Map? ?? const {});
    } on FirebaseFunctionsException catch (e) {
      throw ApiException(e.message ?? 'Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  @override
  Stream<XacThuc> cuaToi(String uid) => _firestore
      .collection('xac_thuc')
      .doc(uid)
      .snapshots()
      .map((s) => XacThuc.fromMap(s.data()));

  @override
  Stream<QuyenAdmin> quyenAdmin(String uid) => _firestore
      .collection('admins')
      .doc(uid)
      .snapshots()
      .map((s) => QuyenAdmin.fromMap(s.data()));

  @override
  Future<String> guiOtp(String sdt) async =>
      (await _goi('guiOtp', {'sdt': sdt}))['goiY'] as String? ?? '';

  @override
  Future<void> xacNhanOtp(String ma) => _goi('xacNhanOtp', {'ma': ma});

  @override
  Future<void> guiDanhTinh({required String hoTen, required String soCccd}) =>
      _goi('guiXacThucDanhTinh', {
        'hoTen': hoTen,
        'soCccd': soCccd,
        'dongYXuLyDuLieu': true,
        'camKet': true,
      });

  @override
  Stream<List<(String, String, String)>> danhTinhChoDuyet() => _firestore
      .collection('xac_thuc')
      .where('danhTinh', isEqualTo: 'cho_duyet')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            (
              d.id,
              d.data()['hoTenKhai'] as String? ?? '',
              d.data()['cccd4'] as String? ?? '',
            ),
        ],
      );

  @override
  Future<void> duyetDanhTinh(String uid, {required bool dongY, String? lyDo}) =>
      _goi('adminDuyetDanhTinh', {'uid': uid, 'dongY': dongY, 'lyDo': lyDo});
}
