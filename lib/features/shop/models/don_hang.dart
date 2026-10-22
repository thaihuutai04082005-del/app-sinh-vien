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
  });

  final String productId;
  final String name;
  final String image;
  final num price;
  final String size;
  final int quantity;

  factory MonTrongDon.fromMap(Map<String, dynamic> m) => MonTrongDon(
    productId: m['productId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    image: m['image'] as String? ?? '',
    price: m['price'] as num? ?? 0,
    size: m['size'] as String? ?? '',
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
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
  });

  final String id;
  final String buyerId;
  final String shopId;
  final List<MonTrongDon> items;
  final num totalPrice;

  /// pending_confirmation | to_ship | shipping | delivered | buyer_confirmed | cancelled
  final String status;
  final String buyerName;
  final String shopName;
  final String receiverName;
  final String phone;

  /// giao_tan_tro | hen_lay
  final String deliveryMethod;
  final String address;
  final String note;
  final String paymentMethod;

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
  };

  static const nguoiLamLabels = {
    'buyer': 'Người mua',
    'shop': 'Shop',
    'system': 'Hệ thống',
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
  });

  final String receiverName;
  final String phone;
  final String deliveryMethod;
  final String address;
  final String note;

  Map<String, dynamic> toMap() => {
    'receiverName': receiverName,
    'phone': phone,
    'deliveryMethod': deliveryMethod,
    'address': address,
    'note': note,
  };
}
