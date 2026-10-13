import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/services/callable_api.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';

/// Đọc hồ sơ tài xế, đơn đặt xe; mọi thay đổi gửi qua callable `xeApi`.
abstract interface class XeService {
  Future<List<TaiXe>> danhSachTaiXe();
  Future<TaiXe?> hoSoTaiXe(String uid);
  Future<void> luuHoSoTaiXe({
    required String vehicleType,
    required String area,
    required String priceReference,
    String description,
  });
  Future<void> doiTrangThaiTaiXe(String status);

  /// Đơn mình đặt (sinh viên).
  Future<List<BookingXe>> donCuaToi();

  /// Đơn khách gửi cho mình (tài xế).
  Future<List<BookingXe>> donDuocGiao();
  Future<BookingXe> getBooking(String id);

  /// Gửi yêu cầu, trả về id đơn.
  Future<String> guiYeuCau(YeuCauXe yeuCau);

  /// hanhDong: baoGia (cần [price]) | chapNhan | batDau | hoanThanh | huy (cần [reason]).
  Future<void> thaoTac(
    String bookingId,
    String hanhDong, {
    int? price,
    String? reason,
  });
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
        .where('status', isEqualTo: 'available')
        .limit(100)
        .get();
    return [
      for (final d in snap.docs)
        if (d.data()['driverVerified'] == true) TaiXe.fromMap(d.data()),
    ];
  }

  @override
  Future<TaiXe?> hoSoTaiXe(String uid) async {
    final d = await _taiXe.doc(uid).get();
    return d.exists ? TaiXe.fromMap(d.data()!) : null;
  }

  @override
  Future<void> luuHoSoTaiXe({
    required String vehicleType,
    required String area,
    required String priceReference,
    String description = '',
  }) => _api.goi('luuHoSoTaiXe', {
    'vehicleType': vehicleType,
    'area': area,
    'priceReference': priceReference,
    'description': description,
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

  static BookingXe _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BookingXe.fromMap({...?doc.data(), 'id': doc.id});
}
