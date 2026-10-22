import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/services/callable_api.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';

/// Đọc hồ sơ tài xế, đơn đặt xe; mọi thay đổi gửi qua callable `xeApi`.
abstract interface class XeService {
  Future<List<TaiXe>> danhSachTaiXe();
  Future<TaiXe?> hoSoTaiXe(String uid);

  /// Lưu hồ sơ, trả về trạng thái duyệt sau khi lưu (pending | approved).
  Future<String> luuHoSoTaiXe(HoSoTaiXeNhap hoSo);
  Future<void> doiTrangThaiTaiXe(String status);

  /// Ảnh bằng lái (chỉ chính tài xế và admin Xe dọn trọ đọc được).
  Future<List<String>> giayTo(String driverId);

  /// Admin: hồ sơ tài xế đang chờ duyệt.
  Future<List<TaiXe>> hoSoChoDuyet();
  Future<void> duyetTaiXe(String driverId, {required bool dongY, String? lyDo});

  /// Đơn mình đặt (sinh viên).
  Future<List<BookingXe>> donCuaToi();

  /// Đơn khách gửi cho mình (tài xế).
  Future<List<BookingXe>> donDuocGiao();
  Future<BookingXe> getBooking(String id);

  /// Đơn cập nhật realtime (sinh viên xem vị trí tài xế).
  Stream<BookingXe> theoDoiBooking(String id);

  /// Tài xế gửi vị trí khi đơn đang chuyển (ghi thẳng, rules chỉ cho 2 trường vị trí).
  Future<void> capNhatViTri(String bookingId, double lat, double lng);

  /// Gửi yêu cầu, trả về id đơn.
  Future<String> guiYeuCau(YeuCauXe yeuCau);

  /// hanhDong: baoGia (cần [price]) | chapNhan | batDau | hoanThanh | huy (cần [reason]).
  Future<void> thaoTac(
    String bookingId,
    String hanhDong, {
    int? price,
    String? reason,
  });

  /// Sinh viên đánh giá tài xế sau chuyến hoàn thành, mỗi đơn một lần.
  Future<void> danhGia(String bookingId, DanhGiaNhap danhGia);
}

class FirebaseXeService implements XeService {
  FirebaseXeService({required this.uid, CallableApi? api, this._db})
    : _api = api ?? FirebaseCallableApi('xeApi');

  final String uid;
  final CallableApi _api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _taiXe =>
      _firestore.collection(Collections.xeDonTro);
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(Collections.bookingXe);

  @override
  Future<List<TaiXe>> danhSachTaiXe() async {
    final snap = await _taiXe
        .where('approval', isEqualTo: 'approved')
        .where('status', isEqualTo: 'available')
        .limit(100)
        .get();
    return [for (final d in snap.docs) TaiXe.fromMap(d.data())];
  }

  @override
  Future<TaiXe?> hoSoTaiXe(String uid) async {
    final d = await _taiXe.doc(uid).get();
    return d.exists ? TaiXe.fromMap(d.data()!) : null;
  }

  @override
  Future<String> luuHoSoTaiXe(HoSoTaiXeNhap hoSo) async =>
      (await _api.goi('luuHoSoTaiXe', hoSo.toMap()))['approval'] as String? ??
      'pending';

  @override
  Future<List<String>> giayTo(String driverId) async {
    final d = await _taiXe
        .doc(driverId)
        .collection('rieng')
        .doc('giayTo')
        .get();
    final l = d.data()?['licensePhotos'];
    return l is List ? l.whereType<String>().toList() : const [];
  }

  @override
  Future<List<TaiXe>> hoSoChoDuyet() async {
    final snap = await _taiXe
        .where('approval', isEqualTo: 'pending')
        .limit(100)
        .get();
    return [for (final d in snap.docs) TaiXe.fromMap(d.data())];
  }

  @override
  Future<void> duyetTaiXe(
    String driverId, {
    required bool dongY,
    String? lyDo,
  }) => _api.goi('duyetTaiXe', {
    'driverId': driverId,
    'dongY': dongY,
    'lyDo': ?lyDo,
  });

  @override
  Future<void> doiTrangThaiTaiXe(String status) =>
      _api.goi('doiTrangThaiTaiXe', {'status': status});

  // Rules chỉ cho đọc đơn của chính mình nên truy vấn phải lọc theo uid.
  Future<List<BookingXe>> _theo(String truong) async {
    if (uid.isEmpty) return [];
    final snap = await _bookings
        .where(truong, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<BookingXe>> donCuaToi() => _theo('userId');

  @override
  Future<List<BookingXe>> donDuocGiao() => _theo('driverId');

  @override
  Future<BookingXe> getBooking(String id) async {
    final d = await _bookings.doc(id).get();
    if (!d.exists) throw StateError('Không tìm thấy đơn đặt xe.');
    return _fromDoc(d);
  }

  @override
  Stream<BookingXe> theoDoiBooking(String id) =>
      _bookings.doc(id).snapshots().where((d) => d.exists).map(_fromDoc);

  @override
  Future<void> capNhatViTri(String bookingId, double lat, double lng) =>
      _bookings.doc(bookingId).update({
        'driverLastLocation': GeoPoint(lat, lng),
        'driverLocationAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<String> guiYeuCau(YeuCauXe yeuCau) async {
    final r = await _api.goi('guiYeuCau', yeuCau.toMap());
    return r['id'] as String;
  }

  @override
  Future<void> thaoTac(
    String bookingId,
    String hanhDong, {
    int? price,
    String? reason,
  }) => _api.goi('thaoTacDon', {
    'bookingId': bookingId,
    'hanhDong': hanhDong,
    'price': ?price,
    'reason': ?reason,
  });

  @override
  Future<void> danhGia(String bookingId, DanhGiaNhap danhGia) =>
      _api.goi('danhGiaChuyen', {...danhGia.toMap(), 'bookingId': bookingId});

  static BookingXe _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BookingXe.fromMap({...?doc.data(), 'id': doc.id});
}
