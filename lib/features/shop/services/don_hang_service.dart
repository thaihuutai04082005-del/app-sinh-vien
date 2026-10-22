import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/services/callable_api.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';

/// Đơn hàng: đọc trực tiếp (rules chỉ cho người mua / shop), mọi thay đổi qua `shopApi`.
abstract interface class DonHangService {
  /// Đặt hàng, server tách đơn theo shop. Trả về id các đơn.
  Future<List<String>> datHang(List<DongGio> dong, ThongTinNhan nhan);
  Future<List<DonHang>> donMua();
  Future<List<DonHang>> donBan();
  Future<DonHang> getDon(String id);

  /// hanhDong: xacNhan | giaoHang | daGiao | daNhan | huy (cần [reason])
  /// | yeuCauTraHang (cần [reason], kèm [images]) | dongYTraHang
  /// | tuChoiTraHang (cần [reason]) | khieuNai (cần [reason]).
  Future<void> thaoTac(
    String orderId,
    String hanhDong, {
    String? reason,
    List<String>? images,
  });

  /// Admin Shop: đơn đang khiếu nại trả hàng.
  Future<List<DonHang>> donKhieuNai();

  /// Admin Shop phân xử: đồng ý thì hoàn tiền cho người mua, không thì đơn hoàn tất.
  Future<void> xuLyKhieuNai(
    String orderId, {
    required bool dongY,
    required String lyDo,
  });

  /// Người mua đánh giá đơn đã nhận (3 tiêu chí), mỗi đơn một lần.
  Future<void> danhGia(String orderId, DanhGiaNhap danhGia);
}

class FirebaseDonHangService implements DonHangService {
  FirebaseDonHangService({required this.uid, CallableApi? api, this._db})
    : _api = api ?? FirebaseCallableApi('shopApi');

  final String uid;
  final CallableApi _api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      (_db ?? FirebaseFirestore.instance).collection(Collections.orders);

  @override
  Future<List<String>> datHang(List<DongGio> dong, ThongTinNhan nhan) async {
    final r = await _api.goi('datHang', {
      ...nhan.toMap(),
      'items': [for (final d in dong) d.toItem()],
    });
    return (r['ids'] as List? ?? const []).cast<String>();
  }

  Future<List<DonHang>> _theo(String truong) async {
    if (uid.isEmpty) return [];
    // Đơn quá hạn shop xác nhận được hủy lúc mở danh sách (không có job hẹn giờ).
    // Lỗi ở bước này không chặn việc xem đơn.
    try {
      await _api.goi('xuLyDonQuaHan');
    } catch (_) {}
    final snap = await _orders
        .where(truong, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<DonHang>> donMua() => _theo('buyerId');

  @override
  Future<List<DonHang>> donBan() => _theo('shopId');

  @override
  Future<DonHang> getDon(String id) async {
    final d = await _orders.doc(id).get();
    if (!d.exists) throw StateError('Không tìm thấy đơn hàng.');
    return _fromDoc(d);
  }

  @override
  Future<void> thaoTac(
    String orderId,
    String hanhDong, {
    String? reason,
    List<String>? images,
  }) => _api.goi('thaoTacDon', {
    'orderId': orderId,
    'hanhDong': hanhDong,
    'reason': ?reason,
    'images': ?images,
  });

  @override
  Future<List<DonHang>> donKhieuNai() async {
    // Chỉ lọc một trường nên không cần chỉ mục ghép; sắp xếp ở app.
    final snap = await _orders
        .where('status', isEqualTo: 'return_disputed')
        .limit(100)
        .get();
    return snap.docs.map(_fromDoc).toList()..sort(
      (a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
    );
  }

  @override
  Future<void> xuLyKhieuNai(
    String orderId, {
    required bool dongY,
    required String lyDo,
  }) => _api.goi('xuLyKhieuNai', {
    'orderId': orderId,
    'dongY': dongY,
    'lyDo': lyDo,
  });

  @override
  Future<void> danhGia(String orderId, DanhGiaNhap danhGia) =>
      _api.goi('danhGiaDon', {...danhGia.toMap(), 'orderId': orderId});

  static DonHang _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      DonHang.fromMap({...?doc.data(), 'id': doc.id});
}
