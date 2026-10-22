import 'dart:convert';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/shop/models/don_hang.dart';
import 'package:app_sinh_vien/features/shop/models/gio_hang.dart';
import 'package:app_sinh_vien/features/shop/models/product.dart';
import 'package:app_sinh_vien/features/shop/services/don_hang_service.dart';
import 'package:app_sinh_vien/features/shop/services/product_service.dart';
import 'package:app_sinh_vien/features/shop/services/shop_dich_vu.dart';
import 'package:app_sinh_vien/shared/models/danh_gia.dart';
import 'package:image_picker/image_picker.dart';

import '../../fakes/danh_gia_gia.dart';
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
  final diemShop = <String, DiemDanhGia>{};
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
  Future<DiemDanhGia> diemShop(String shopId) async =>
      kho.diemShop[shopId] ?? DiemDanhGia.chuaCo;

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
            totalPrice: e.value.fold<num>(
              0,
              (s, d) => s + d.price * d.quantity,
            ),
            status: 'pending_confirmation',
            confirmDeadline: DateTime.now().add(const Duration(days: 2)),
          ),
        ),
    ];
  }

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
