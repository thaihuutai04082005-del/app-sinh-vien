import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/services/callable_api.dart';
import '../models/uu_dai.dart';

/// Trả giá và voucher: đọc trực tiếp (rules: trả giá chỉ 2 bên, voucher công khai),
/// mọi thay đổi qua `shopApi`.
abstract interface class UuDaiService {
  /// Người mua trả giá một sản phẩm, trả về id lần trả giá.
  Future<String> traGia(
    String productId,
    int offerPrice, {
    String size = '',
    String message = '',
  });

  /// hanhDong: chapNhan | tuChoi (shop) | huy (người mua rút lại).
  Future<void> phanHoiTraGia(String offerId, String hanhDong);

  /// Các lần mình trả giá (người mua) hoặc khách trả giá hàng của mình (shop).
  Future<List<TraGia>> danhSachTraGia({required bool laNguoiBan});

  Future<List<Voucher>> voucherCuaShop(String shopId);

  /// Tìm voucher theo mã (không phân biệt hoa thường); null nếu không có.
  Future<Voucher?> timVoucher(String code);
  Future<void> taoVoucher(VoucherNhap v);
  Future<void> ngungVoucher(String code);
}

class FirebaseUuDaiService implements UuDaiService {
  FirebaseUuDaiService({required this.uid, CallableApi? api, this._db})
    : _api = api ?? FirebaseCallableApi('shopApi');

  final String uid;
  final CallableApi _api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _fs => _db ?? FirebaseFirestore.instance;

  @override
  Future<String> traGia(
    String productId,
    int offerPrice, {
    String size = '',
    String message = '',
  }) async =>
      (await _api.goi('traGia', {
            'productId': productId,
            'offerPrice': offerPrice,
            'size': size,
            'message': message,
          }))['id']
          as String;

  @override
  Future<void> phanHoiTraGia(String offerId, String hanhDong) =>
      _api.goi('phanHoiTraGia', {'offerId': offerId, 'hanhDong': hanhDong});

  @override
  Future<List<TraGia>> danhSachTraGia({required bool laNguoiBan}) async {
    if (uid.isEmpty) return [];
    // Chỉ lọc một trường nên không cần chỉ mục ghép; sắp xếp ở app.
    final snap = await _fs
        .collection('offers')
        .where(laNguoiBan ? 'shopId' : 'buyerId', isEqualTo: uid)
        .limit(100)
        .get();
    return [
      for (final d in snap.docs) TraGia.fromMap({...d.data(), 'id': d.id}),
    ]..sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
  }

  @override
  Future<List<Voucher>> voucherCuaShop(String shopId) async {
    final snap = await _fs
        .collection(Collections.vouchers)
        .where('shopId', isEqualTo: shopId)
        .limit(50)
        .get();
    return [
      for (final d in snap.docs) Voucher.fromMap({...d.data(), 'id': d.id}),
    ]..sort((a, b) => b.expiredAt.compareTo(a.expiredAt));
  }

  @override
  Future<Voucher?> timVoucher(String code) async {
    final ma = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{4,15}$').hasMatch(ma)) return null;
    final d = await _fs.collection(Collections.vouchers).doc(ma).get();
    return d.exists ? Voucher.fromMap({...d.data()!, 'id': d.id}) : null;
  }

  @override
  Future<void> taoVoucher(VoucherNhap v) => _api.goi('taoVoucher', v.toMap());

  @override
  Future<void> ngungVoucher(String code) =>
      _api.goi('ngungVoucher', {'code': code});
}
