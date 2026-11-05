import '../../../core/utils/formatters.dart';
import '../../../shared/services/callable_api.dart';

/// Một lần trả giá (Make an offer) — collection `offers`. Chỉ server ghi.
class TraGia {
  const TraGia({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.buyerId,
    required this.price,
    required this.offerPrice,
    required this.status,
    this.productName = '',
    this.productImage = '',
    this.shopName = '',
    this.buyerName = '',
    this.size = '',
    this.message = '',
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String shopId;
  final String buyerId;

  /// Giá niêm yết lúc trả giá.
  final num price;
  final num offerPrice;

  /// pending | accepted | rejected | cancelled | used
  final String status;
  final String productName;
  final String productImage;
  final String shopName;
  final String buyerName;
  final String size;
  final String message;

  /// Hạn mua theo giá đã trả (chỉ có sau khi shop chấp nhận).
  final DateTime? expiresAt;
  final DateTime? createdAt;

  static const statusLabels = {
    'pending': 'Chờ shop trả lời',
    'accepted': 'Shop đồng ý',
    'rejected': 'Shop từ chối',
    'cancelled': 'Đã rút lại',
    'used': 'Đã mua',
  };

  bool get conMuaDuoc =>
      status == 'accepted' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory TraGia.fromMap(Map<String, dynamic> m) => TraGia(
    id: m['id'] as String? ?? '',
    productId: m['productId'] as String? ?? '',
    shopId: m['shopId'] as String? ?? '',
    buyerId: m['buyerId'] as String? ?? '',
    price: m['price'] as num? ?? 0,
    offerPrice: m['offerPrice'] as num? ?? 0,
    status: m['status'] as String? ?? 'pending',
    productName: m['productName'] as String? ?? '',
    productImage: m['productImage'] as String? ?? '',
    shopName: m['shopName'] as String? ?? '',
    buyerName: m['buyerName'] as String? ?? '',
    size: m['size'] as String? ?? '',
    message: m['message'] as String? ?? '',
    expiresAt: docThoiGian(m['expiresAt']),
    createdAt: docThoiGian(m['createdAt']),
  );
}

/// Voucher của shop — collection `vouchers/{code}` (mục 7.3). Chỉ server ghi.
class Voucher {
  const Voucher({
    required this.code,
    required this.shopId,
    required this.discountType,
    required this.discountValue,
    required this.expiredAt,
    this.shopName = '',
    this.maxDiscount,
    this.minOrderValue = 0,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.active = true,
  });

  final String code;
  final String shopId;
  final String shopName;

  /// percent | fixed
  final String discountType;
  final num discountValue;

  /// Trần số tiền giảm của voucher theo %.
  final num? maxDiscount;
  final num minOrderValue;
  final DateTime expiredAt;
  final int usageLimit;
  final int usedCount;
  final bool active;

  bool get conDung =>
      active && expiredAt.isAfter(DateTime.now()) && usedCount < usageLimit;

  /// "Giảm 10% (tối đa 20k) · đơn từ 100k"
  String moTa(String Function(num) gia) => [
    discountType == 'percent'
        ? 'Giảm $discountValue%${maxDiscount == null ? '' : ' (tối đa ${gia(maxDiscount!)})'}'
        : 'Giảm ${gia(discountValue)}',
    if (minOrderValue > 0) 'đơn từ ${gia(minOrderValue)}',
  ].join(' · ');

  /// Số tiền giảm cho đơn có tạm tính [tamTinh] (cách tính giống tinhGiam ở server),
  /// hoặc câu báo lỗi nếu chưa dùng được.
  (num giam, String? loi) tinhGiam(num tamTinh) {
    if (!active) return (0, 'Mã voucher đã ngừng.');
    final hetHan = !expiredAt.isAfter(DateTime.now());
    if (hetHan) return (0, 'Mã voucher đã hết hạn.');
    if (usedCount >= usageLimit) return (0, 'Mã voucher đã hết lượt dùng.');
    if (tamTinh < minOrderValue) {
      return (0, 'Mã này áp dụng cho đơn từ ${formatPrice(minOrderValue)}.');
    }
    var giam = discountType == 'percent'
        ? (tamTinh * discountValue / 100).floor()
        : discountValue;
    if (maxDiscount != null && giam > maxDiscount!) giam = maxDiscount!;
    return (giam > tamTinh ? tamTinh : giam, null);
  }

  factory Voucher.fromMap(Map<String, dynamic> m) => Voucher(
    code: m['code'] as String? ?? m['id'] as String? ?? '',
    shopId: m['shopId'] as String? ?? '',
    shopName: m['shopName'] as String? ?? '',
    discountType: m['discountType'] as String? ?? 'fixed',
    discountValue: m['discountValue'] as num? ?? 0,
    maxDiscount: m['maxDiscount'] as num?,
    minOrderValue: m['minOrderValue'] as num? ?? 0,
    expiredAt:
        docThoiGian(m['expiredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    usageLimit: (m['usageLimit'] as num?)?.toInt() ?? 0,
    usedCount: (m['usedCount'] as num?)?.toInt() ?? 0,
    active: m['active'] as bool? ?? true,
  );
}

/// Shop nhập khi tạo voucher.
class VoucherNhap {
  const VoucherNhap({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.usageLimit,
    required this.expiredAt,
    this.maxDiscount,
    this.minOrderValue = 0,
  });

  final String code;
  final String discountType;
  final int discountValue;
  final int? maxDiscount;
  final int minOrderValue;
  final int usageLimit;
  final DateTime expiredAt;

  Map<String, dynamic> toMap() => {
    'code': code,
    'discountType': discountType,
    'discountValue': discountValue,
    'maxDiscount': maxDiscount,
    'minOrderValue': minOrderValue,
    'usageLimit': usageLimit,
    'expiredAt': expiredAt.millisecondsSinceEpoch,
  };
}
