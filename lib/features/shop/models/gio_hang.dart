import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product.dart';

/// Một dòng trong giỏ. Giá chỉ để hiển thị; khi đặt, server tính lại theo giá hiện tại.
class DongGio {
  const DongGio({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.image,
    required this.price,
    required this.size,
    required this.quantity,
    required this.stock,
  });

  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final String image;
  final num price;
  final String size;
  final int quantity;

  /// Tồn kho lúc thêm vào giỏ, để giới hạn nút "+".
  final int stock;

  String get khoa => '$productId|$size';

  factory DongGio.tu(
    Product p, {
    required String size,
    required int quantity,
  }) => DongGio(
    productId: p.id,
    shopId: p.shopId,
    shopName: p.shopName,
    name: p.name,
    image: p.images.isEmpty ? '' : p.images.first,
    price: p.price,
    size: size,
    quantity: quantity,
    stock: p.stock,
  );

  DongGio voiSoLuong(int q) => DongGio(
    productId: productId,
    shopId: shopId,
    shopName: shopName,
    name: name,
    image: image,
    price: price,
    size: size,
    quantity: q,
    stock: stock,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'shopId': shopId,
    'shopName': shopName,
    'name': name,
    'image': image,
    'price': price,
    'size': size,
    'quantity': quantity,
    'stock': stock,
  };

  /// Phần gửi lên server khi đặt hàng.
  Map<String, dynamic> toItem() => {
    'productId': productId,
    'size': size,
    'quantity': quantity,
  };

  factory DongGio.fromJson(Map<String, dynamic> m) => DongGio(
    productId: m['productId'] as String? ?? '',
    shopId: m['shopId'] as String? ?? '',
    shopName: m['shopName'] as String? ?? '',
    name: m['name'] as String? ?? '',
    image: m['image'] as String? ?? '',
    price: m['price'] as num? ?? 0,
    size: m['size'] as String? ?? '',
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    stock: (m['stock'] as num?)?.toInt() ?? 1,
  );
}

/// Nơi lưu giỏ giữa các lần mở app (test dùng bản trong bộ nhớ).
abstract interface class LuuGioHang {
  Future<String?> doc(String khoa);
  Future<void> ghi(String khoa, String giaTri);
}

class SharedPrefsLuuGioHang implements LuuGioHang {
  @override
  Future<String?> doc(String khoa) async =>
      (await SharedPreferences.getInstance()).getString(khoa);

  @override
  Future<void> ghi(String khoa, String giaTri) async =>
      (await SharedPreferences.getInstance()).setString(khoa, giaTri);
}

class BoNhoLuuGioHang implements LuuGioHang {
  final data = <String, String>{};

  @override
  Future<String?> doc(String khoa) async => data[khoa];

  @override
  Future<void> ghi(String khoa, String giaTri) async => data[khoa] = giaTri;
}

/// Giỏ hàng của một tài khoản, lưu trên máy (mỗi uid một giỏ).
class GioHang extends ChangeNotifier {
  GioHang({required String uid, required this._luu})
    : _khoa = 'shop_gio_hang_v1_$uid' {
    _san = _tai();
  }

  static const soLuongToiDa = 10;

  final String _khoa;
  final LuuGioHang _luu;
  late final Future<void> _san;
  List<DongGio> _dong = [];

  /// Xong khi đã đọc giỏ đã lưu.
  Future<void> get san => _san;
  List<DongGio> get dong => List.unmodifiable(_dong);
  int get soMon => _dong.fold(0, (s, d) => s + d.quantity);
  num get tamTinh => _dong.fold<num>(0, (s, d) => s + d.price * d.quantity);

  Future<void> _tai() async {
    try {
      final raw = await _luu.doc(_khoa);
      if (raw == null) return;
      _dong = [
        for (final m in jsonDecode(raw) as List)
          DongGio.fromJson(Map<String, dynamic>.from(m as Map)),
      ];
      notifyListeners();
    } catch (_) {
      // Giỏ lưu hỏng thì bỏ, không chặn người dùng.
    }
  }

  void _doi(List<DongGio> moi) {
    _dong = moi;
    notifyListeners();
    _luu.ghi(_khoa, jsonEncode([for (final d in _dong) d.toJson()]));
  }

  void them(DongGio d) {
    final i = _dong.indexWhere((x) => x.khoa == d.khoa);
    if (i < 0) {
      _doi([..._dong, d]);
    } else {
      datSoLuong(d.khoa, _dong[i].quantity + d.quantity);
    }
  }

  /// Số lượng bị kẹp trong 1..min(tồn kho, 10).
  void datSoLuong(String khoa, int q) {
    _doi([
      for (final d in _dong)
        if (d.khoa == khoa)
          d.voiSoLuong(q.clamp(1, d.stock.clamp(1, soLuongToiDa)))
        else
          d,
    ]);
  }

  void xoa(String khoa) => _doi([
    for (final d in _dong)
      if (d.khoa != khoa) d,
  ]);

  void xoaNhieu(Iterable<String> khoa) {
    final bo = khoa.toSet();
    _doi([
      for (final d in _dong)
        if (!bo.contains(d.khoa)) d,
    ]);
  }
}
