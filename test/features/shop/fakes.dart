import 'dart:convert';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/shop/models/don_hang.dart';
import 'package:app_sinh_vien/features/shop/models/gio_hang.dart';
import 'package:app_sinh_vien/features/shop/models/product.dart';
import 'package:app_sinh_vien/features/shop/models/uu_dai.dart';
import 'package:app_sinh_vien/features/shop/services/don_hang_service.dart';
import 'package:app_sinh_vien/features/shop/services/product_service.dart';
import 'package:app_sinh_vien/features/shop/services/shop_dich_vu.dart';
import 'package:app_sinh_vien/features/shop/services/uu_dai_service.dart';
import 'package:app_sinh_vien/shared/models/danh_gia.dart';
import 'package:image_picker/image_picker.dart';

import '../../fakes/danh_gia_gia.dart';
import '../../fakes/theo_doi_gia.dart';
import '../../fakes/xac_thuc_gia.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class InstantStorage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/images/$folder/$fileName';
}

Future<List<XFile>> pickOne(int _) async => [
  XFile.fromData(png, name: 'ao.png'),
];

/// Sản phẩm + đơn trong bộ nhớ, dùng chung giữa nhiều "người dùng" trong 1 test.
class KhoGia {
  final products = <Product>[];
  final orders = <DonHang>[];
  final danhGia = DanhGiaGia();
  final thongKe = <String, ThongKeShop>{};
  final theoDoi = <(String, String, String)>{};
  final traGia = <TraGia>[];
  final vouchers = <String, Voucher>{};
  var _id = 0;

  String id(String tienTo) => '$tienTo${++_id}';
}

class FakeProductService implements ProductService {
  FakeProductService(this.kho, this.uid);

  final KhoGia kho;
  final String uid;

  @override
  Future<List<Product>> getDanhSachSanPham() async => List.of(kho.products);

  @override
  Future<List<Product>> getSanPhamCuaShop(String shopId) async => [
    for (final p in kho.products)
      if (p.shopId == shopId) p,
  ];

  @override
  Future<Product> getSanPham(String id) async =>
      kho.products.firstWhere((p) => p.id == id);

  @override
  Future<ThongKeShop> thongKeShop(String shopId) async =>
      kho.thongKe[shopId] ?? ThongKeShop.trong;

  Product _tao(String id, SanPhamNhap sp) => Product.fromMap({
    ...sp.toMap(),
    'id': id,
    'shopId': uid,
    'shopName': 'Shop $uid',
    'status': sp.stock > 0 ? 'active' : 'out_of_stock',
  });

  @override
  Future<String> dangSanPham(SanPhamNhap sp) async {
    final p = _tao(kho.id('p'), sp);
    kho.products.insert(0, p);
    return p.id;
  }

  @override
  Future<void> suaSanPham(String id, SanPhamNhap sp) async {
    final i = kho.products.indexWhere((p) => p.id == id);
    kho.products[i] = _tao(id, sp);
  }

  @override
  Future<void> xoaSanPham(String id) async =>
      kho.products.removeWhere((p) => p.id == id);
}

class FakeDonHangService implements DonHangService {
  FakeDonHangService(this.kho, this.uid);

  final KhoGia kho;
  final String uid;
  final thaoTacDaLam = <(String, String, String?)>[];

  @override
  Future<List<String>> datHang(List<DongGio> dong, ThongTinNhan nhan) async {
    final theoShop = <String, List<DongGio>>{};
    for (final d in dong) {
      (theoShop[d.shopId] ??= []).add(d);
    }
    final v = nhan.voucherCode == null ? null : kho.vouchers[nhan.voucherCode];
    if (nhan.voucherCode != null && v == null) {
      throw const ApiException('Mã voucher không tồn tại.');
    }
    return [
      for (final e in theoShop.entries)
        _them(
          DonHang(
            id: kho.id('o'),
            buyerId: uid,
            shopId: e.key,
            buyerName: 'Người mua',
            shopName: e.value.first.shopName,
            receiverName: nhan.receiverName,
            phone: nhan.phone,
            address: nhan.address,
            deliveryMethod: nhan.deliveryMethod,
            paymentMethod: nhan.paymentMethod,
            voucherCode: v?.shopId == e.key ? v!.code : null,
            discountAmount: v?.shopId == e.key
                ? v!.tinhGiam(_tong(e.value)).$1
                : 0,
            paid: nhan.paymentMethod == 'online',
            items: [
              for (final d in e.value)
                MonTrongDon(
                  productId: d.productId,
                  name: d.name,
                  image: d.image,
                  price: d.price,
                  size: d.size,
                  quantity: d.quantity,
                ),
            ],
            subtotal: _tong(e.value),
            totalPrice:
                _tong(e.value) -
                (v?.shopId == e.key ? v!.tinhGiam(_tong(e.value)).$1 : 0),
            status: 'pending_confirmation',
            confirmDeadline: DateTime.now().add(const Duration(days: 2)),
          ),
        ),
    ];
  }

  static num _tong(List<DongGio> ds) =>
      ds.fold<num>(0, (s, d) => s + d.price * d.quantity);

  String _them(DonHang d) {
    kho.orders.insert(0, d);
    return d.id;
  }

  @override
  Future<List<DonHang>> donMua() async => [
    for (final d in kho.orders)
      if (d.buyerId == uid) d,
  ];

  @override
  Future<List<DonHang>> donBan() async => [
    for (final d in kho.orders)
      if (d.shopId == uid) d,
  ];

  @override
  Future<DonHang> getDon(String id) async =>
      kho.orders.firstWhere((d) => d.id == id);

  @override
  Future<void> thaoTac(
    String orderId,
    String hanhDong, {
    String? reason,
    List<String>? images,
  }) async {
    thaoTacDaLam.add((orderId, hanhDong, reason));
    final sang = {
      'xacNhan': 'to_ship',
      'giaoHang': 'shipping',
      'daGiao': 'delivered',
      'daNhan': 'buyer_confirmed',
      'huy': 'cancelled',
      'yeuCauTraHang': 'return_requested',
      'dongYTraHang': 'return_refund',
      'tuChoiTraHang': 'return_rejected',
      'khieuNai': 'return_disputed',
    }[hanhDong];
    if (sang == null) throw const ApiException('Hành động không hợp lệ.');
    _doi(orderId, (d) {
      final online = d.paymentMethod == 'online';
      return {
        'status': sang,
        if (hanhDong == 'huy') ...{
          'cancelReason': reason,
          'cancelledBy': uid == d.shopId ? 'shop' : 'buyer',
        },
        if (hanhDong == 'yeuCauTraHang') ...{
          'returnReason': reason,
          'returnImages': images ?? const <String>[],
        },
        if (hanhDong == 'tuChoiTraHang') 'returnRejectReason': reason,
        if (hanhDong == 'khieuNai') 'disputeReason': reason,
        if (online && sang == 'buyer_confirmed') 'fundsReleased': true,
        if (online && (sang == 'cancelled' || sang == 'return_refund'))
          'refunded': true,
      };
    });
  }

  @override
  Future<List<DonHang>> donKhieuNai() async => [
    for (final d in kho.orders)
      if (d.status == 'return_disputed') d,
  ];

  @override
  Future<void> xuLyKhieuNai(
    String orderId, {
    required bool dongY,
    required String lyDo,
  }) async => _doi(
    orderId,
    (d) => {
      'status': dongY ? 'return_refund' : 'buyer_confirmed',
      'disputeResult': lyDo,
    },
  );

  /// Ghi đè vài trường của đơn, giữ nguyên phần còn lại.
  void _doi(String orderId, Map<String, dynamic> Function(DonHang) doi) {
    final i = kho.orders.indexWhere((d) => d.id == orderId);
    final d = kho.orders[i];
    kho.orders[i] = DonHang.fromMap({
      'id': d.id,
      'buyerId': d.buyerId,
      'shopId': d.shopId,
      'buyerName': d.buyerName,
      'shopName': d.shopName,
      'items': [
        for (final m in d.items)
          {
            'productId': m.productId,
            'name': m.name,
            'image': m.image,
            'price': m.price,
            'size': m.size,
            'quantity': m.quantity,
          },
      ],
      'totalPrice': d.totalPrice,
      'status': d.status,
      'receiverName': d.receiverName,
      'phone': d.phone,
      'deliveryMethod': d.deliveryMethod,
      'address': d.address,
      'paymentMethod': d.paymentMethod,
      'paid': d.paid,
      'fundsReleased': d.fundsReleased,
      'refunded': d.refunded,
      'reviewed': d.reviewed,
      'cancelReason': d.cancelReason,
      'cancelledBy': d.cancelledBy,
      'returnReason': d.returnReason,
      'returnImages': d.returnImages,
      'returnRejectReason': d.returnRejectReason,
      'disputeReason': d.disputeReason,
      'disputeResult': d.disputeResult,
      ...doi(d),
    });
  }

  @override
  Future<void> danhGia(String orderId, DanhGiaNhap danhGia) async {
    final d = await getDon(orderId);
    if (d.status != 'buyer_confirmed' || d.reviewed) {
      throw const ApiException('Không đánh giá được đơn này.');
    }
    kho.danhGia.them(
      'shop',
      d.shopId,
      danhGia,
      productIds: [for (final m in d.items) m.productId],
    );
    _doi(orderId, (_) => {'reviewed': true});
  }
}

class FakeUuDaiService implements UuDaiService {
  FakeUuDaiService(this.kho, this.uid);

  final KhoGia kho;
  final String uid;

  @override
  Future<String> traGia(
    String productId,
    int offerPrice, {
    String size = '',
    String message = '',
  }) async {
    final p = kho.products.firstWhere((p) => p.id == productId);
    final t = TraGia(
      id: kho.id('t'),
      productId: p.id,
      productName: p.name,
      shopId: p.shopId,
      shopName: p.shopName,
      buyerId: uid,
      buyerName: 'Người mua',
      price: p.price,
      offerPrice: offerPrice,
      size: size,
      message: message,
      status: 'pending',
    );
    kho.traGia.insert(0, t);
    return t.id;
  }

  @override
  Future<void> phanHoiTraGia(String offerId, String hanhDong) async {
    final i = kho.traGia.indexWhere((t) => t.id == offerId);
    final t = kho.traGia[i];
    kho.traGia[i] = TraGia(
      id: t.id,
      productId: t.productId,
      productName: t.productName,
      shopId: t.shopId,
      shopName: t.shopName,
      buyerId: t.buyerId,
      buyerName: t.buyerName,
      price: t.price,
      offerPrice: t.offerPrice,
      size: t.size,
      message: t.message,
      status: {
        'chapNhan': 'accepted',
        'tuChoi': 'rejected',
        'huy': 'cancelled',
      }[hanhDong]!,
      expiresAt: hanhDong == 'chapNhan'
          ? DateTime.now().add(const Duration(days: 1))
          : null,
    );
  }

  @override
  Future<List<TraGia>> danhSachTraGia({required bool laNguoiBan}) async => [
    for (final t in kho.traGia)
      if ((laNguoiBan ? t.shopId : t.buyerId) == uid) t,
  ];

  @override
  Future<List<Voucher>> voucherCuaShop(String shopId) async => [
    for (final v in kho.vouchers.values)
      if (v.shopId == shopId) v,
  ];

  @override
  Future<Voucher?> timVoucher(String code) async =>
      kho.vouchers[code.trim().toUpperCase()];

  @override
  Future<void> taoVoucher(VoucherNhap v) async {
    if (kho.vouchers.containsKey(v.code)) {
      throw ApiException('Mã ${v.code} đã có người dùng, chọn mã khác.');
    }
    kho.vouchers[v.code] = Voucher(
      code: v.code,
      shopId: uid,
      shopName: 'Shop $uid',
      discountType: v.discountType,
      discountValue: v.discountValue,
      maxDiscount: v.maxDiscount,
      minOrderValue: v.minOrderValue,
      usageLimit: v.usageLimit,
      expiredAt: v.expiredAt,
    );
  }

  @override
  Future<void> ngungVoucher(String code) async {
    final v = kho.vouchers[code]!;
    kho.vouchers[code] = Voucher(
      code: v.code,
      shopId: v.shopId,
      shopName: v.shopName,
      discountType: v.discountType,
      discountValue: v.discountValue,
      maxDiscount: v.maxDiscount,
      minOrderValue: v.minOrderValue,
      usageLimit: v.usageLimit,
      expiredAt: v.expiredAt,
      active: false,
    );
  }
}

ShopDichVu shopDv(
  KhoGia kho,
  String uid, {
  LuuGioHang? luu,
  XacThucGia? xacThuc,
}) => ShopDichVu(
  uid: uid,
  products: FakeProductService(kho, uid),
  donHang: FakeDonHangService(kho, uid),
  gioHang: GioHang(uid: uid, luu: luu ?? BoNhoLuuGioHang()),
  storage: InstantStorage(),
  xacThuc: xacThuc ?? XacThucGia.day(),
  danhGia: kho.danhGia,
  uuDai: FakeUuDaiService(kho, uid),
  theoDoi: TheoDoiGia(kho.theoDoi, uid),
  pickImages: pickOne,
);

Product sanPhamMau({
  required String id,
  String shopId = 'ban',
  String name = 'Áo thun basic',
  num price = 85000,
  String category = 'ao',
  List<String> sizes = const ['M', 'L'],
  int stock = 3,
}) => Product(
  id: id,
  shopId: shopId,
  shopName: 'Shop $shopId',
  name: name,
  images: const ['https://cdn.test/a.jpg'],
  price: price,
  sizes: sizes,
  stock: stock,
  category: category,
  status: stock > 0 ? 'active' : 'out_of_stock',
);
