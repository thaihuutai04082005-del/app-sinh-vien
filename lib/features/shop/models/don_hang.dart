import '../../../shared/services/callable_api.dart';

/// Một món trong đơn — tên, ảnh, giá chụp lại lúc đặt (sản phẩm có bị sửa/xóa vẫn giữ).
class MonTrongDon {
  const MonTrongDon({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.size,
    required this.quantity,
    this.listPrice,
  });

  final String productId;
  final String name;
  final String image;
  final num price;
  final String size;
  final int quantity;

  /// Giá niêm yết khi món này mua theo giá đã trả ([price] là giá trả).
  final num? listPrice;

  factory MonTrongDon.fromMap(Map<String, dynamic> m) => MonTrongDon(
    productId: m['productId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    image: m['image'] as String? ?? '',
    price: m['price'] as num? ?? 0,
    size: m['size'] as String? ?? '',
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    listPrice: m['listPrice'] as num?,
  );
}

/// Đơn hàng — collection `orders` (mục 7.3). Mỗi đơn thuộc một shop. Chỉ server ghi.
class DonHang {
  const DonHang({
    required this.id,
    required this.buyerId,
    required this.shopId,
    required this.items,
    required this.totalPrice,
    required this.status,
    this.buyerName = '',
    this.shopName = '',
    this.receiverName = '',
    this.phone = '',
    this.deliveryMethod = 'giao_tan_tro',
    this.address = '',
    this.note = '',
    this.paymentMethod = 'cod',
    this.cancelledBy,
    this.cancelReason,
    this.confirmDeadline,
    this.createdAt,
    this.lichSu = const [],
    this.reviewed = false,
    this.paid = false,
    this.fundsReleased = false,
    this.refunded = false,
    this.returnDeadline,
    this.returnResponseDeadline,
    this.returnReason,
    this.returnImages = const [],
    this.returnRejectReason,
    this.disputeReason,
    this.disputeResult,
    this.subtotal,
    this.voucherCode,
    this.discountAmount = 0,
  });

  final String id;
  final String buyerId;
  final String shopId;
  final List<MonTrongDon> items;

  /// Số tiền phải trả = [subtotal] − [discountAmount].
  final num totalPrice;

  /// Tạm tính trước giảm giá (đơn cũ không có thì bằng [totalPrice]).
  final num? subtotal;
  final String? voucherCode;
  final num discountAmount;

  /// pending_confirmation | to_ship | shipping | delivered | buyer_confirmed | cancelled
  /// | return_requested | return_rejected | return_disputed | return_refund
  final String status;
  final String buyerName;
  final String shopName;
  final String receiverName;
  final String phone;

  /// giao_tan_tro | hen_lay
  final String deliveryMethod;
  final String address;
  final String note;

  /// cod | online (thanh toán giả lập, app giữ tiền đến khi khách xác nhận nhận hàng).
  final String paymentMethod;

  /// Đơn online: đã trả tiền / tiền đã chuyển cho shop / đã hoàn lại cho khách.
  final bool paid;
  final bool fundsReleased;
  final bool refunded;

  /// Hạn khách yêu cầu trả hàng (tính từ lúc shop báo đã giao), quá hạn đơn tự hoàn tất.
  final DateTime? returnDeadline;

  /// Hạn shop trả lời yêu cầu trả hàng, quá hạn coi như đồng ý.
  final DateTime? returnResponseDeadline;
  final String? returnReason;
  final List<String> returnImages;
  final String? returnRejectReason;
  final String? disputeReason;

  /// Kết luận của admin Shop khi phân xử khiếu nại.
  final String? disputeResult;

  /// buyer | shop | system
  final String? cancelledBy;
  final String? cancelReason;

  /// Hạn shop phải xác nhận, quá hạn hệ thống tự hủy.
  final DateTime? confirmDeadline;
  final DateTime? createdAt;
  final List<MocTrangThai> lichSu;

  /// Người mua đã đánh giá đơn này.
  final bool reviewed;

  int get soLuong => items.fold(0, (s, i) => s + i.quantity);

  static const statusLabels = {
    'pending_confirmation': 'Chờ xác nhận',
    'to_ship': 'Chờ lấy hàng',
    'shipping': 'Đang giao',
    'delivered': 'Đã giao',
    'buyer_confirmed': 'Hoàn tất',
    'cancelled': 'Đã hủy',
    'return_requested': 'Yêu cầu trả hàng',
    'return_rejected': 'Shop từ chối trả',
    'return_disputed': 'Đang khiếu nại',
    'return_refund': 'Đã trả hàng / hoàn tiền',
  };

  /// Tab trong danh sách đơn: tên tab → các trạng thái thuộc tab đó.
  static const tabs = {
    'Chờ xác nhận': ['pending_confirmation'],
    'Chờ lấy hàng': ['to_ship'],
    'Đang giao': ['shipping'],
    'Đã giao': ['delivered'],
    'Hoàn tất': ['buyer_confirmed'],
    'Trả hàng / Hoàn tiền': [
      'return_requested',
      'return_rejected',
      'return_disputed',
      'return_refund',
    ],
    'Đã hủy': ['cancelled'],
  };

  static const paymentLabels = {
    'cod': 'Thanh toán khi nhận hàng (COD)',
    'online': 'Thanh toán online (giả lập)',
  };

  /// Câu ngắn về tiền của đơn online; null với COD.
  String? get trangThaiTien {
    if (paymentMethod != 'online') return null;
    if (refunded) return 'Đã hoàn tiền cho người mua.';
    if (fundsReleased) return 'Tiền đã chuyển cho shop.';
    return 'Đã thanh toán, app đang giữ tiền đến khi người mua xác nhận nhận hàng.';
  }

  static const nguoiLamLabels = {
    'buyer': 'Người mua',
    'shop': 'Shop',
    'system': 'Hệ thống',
    'admin': 'Admin Shop',
  };

  static const deliveryLabels = {
    'giao_tan_tro': 'Giao tận trọ',
    'hen_lay': 'Hẹn lấy trực tiếp',
  };

  factory DonHang.fromMap(Map<String, dynamic> m) => DonHang(
    id: m['id'] as String? ?? '',
    buyerId: m['buyerId'] as String? ?? '',
    shopId: m['shopId'] as String? ?? '',
    items: [
      for (final i in m['items'] as List? ?? const [])
        if (i is Map) MonTrongDon.fromMap(Map<String, dynamic>.from(i)),
    ],
    totalPrice: m['totalPrice'] as num? ?? 0,
    status: m['status'] as String? ?? 'pending_confirmation',
    buyerName: m['buyerName'] as String? ?? '',
    shopName: m['shopName'] as String? ?? '',
    receiverName: m['receiverName'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    deliveryMethod: m['deliveryMethod'] as String? ?? 'giao_tan_tro',
    address: m['address'] as String? ?? '',
    note: m['note'] as String? ?? '',
    paymentMethod: m['paymentMethod'] as String? ?? 'cod',
    cancelledBy: m['cancelledBy'] as String?,
    cancelReason: m['cancelReason'] as String?,
    confirmDeadline: docThoiGian(m['confirmDeadline']),
    createdAt: docThoiGian(m['createdAt']),
    lichSu: MocTrangThai.docDanhSach(m['lichSu']),
    reviewed: m['reviewed'] as bool? ?? false,
    paid: m['paid'] as bool? ?? false,
    fundsReleased: m['fundsReleased'] as bool? ?? false,
    refunded: m['refunded'] as bool? ?? false,
    returnDeadline: docThoiGian(m['returnDeadline']),
    returnResponseDeadline: docThoiGian(m['returnResponseDeadline']),
    returnReason: m['returnReason'] as String?,
    returnImages: m['returnImages'] is List
        ? (m['returnImages'] as List).whereType<String>().toList()
        : const [],
    returnRejectReason: m['returnRejectReason'] as String?,
    disputeReason: m['disputeReason'] as String?,
    disputeResult: m['disputeResult'] as String?,
    subtotal: m['subtotal'] as num?,
    voucherCode: m['voucherCode'] as String?,
    discountAmount: m['discountAmount'] as num? ?? 0,
  );
}

/// Thông tin nhận hàng người mua nhập lúc đặt.
class ThongTinNhan {
  const ThongTinNhan({
    required this.receiverName,
    required this.phone,
    required this.deliveryMethod,
    this.address = '',
    this.note = '',
    this.paymentMethod = 'cod',
    this.voucherCode,
  });

  final String receiverName;
  final String phone;
  final String deliveryMethod;
  final String address;
  final String note;

  /// cod | online
  final String paymentMethod;

  /// Mã voucher của một shop, chỉ giảm cho đơn của shop đó.
  final String? voucherCode;

  Map<String, dynamic> toMap() => {
    'receiverName': receiverName,
    'phone': phone,
    'deliveryMethod': deliveryMethod,
    'address': address,
    'note': note,
    'paymentMethod': paymentMethod,
    'voucherCode': ?voucherCode,
  };
}
