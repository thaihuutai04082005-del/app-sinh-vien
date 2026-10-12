import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// App nhớ bộ lọc, điểm gốc và địa chỉ đã lưu lần trước, riêng trong module Quán ăn (mục 3.4, 3.7).
/// Lỗi bộ nhớ (trình duyệt chặn...) thì bỏ qua, app vẫn chạy với mặc định.
/// Bộ lọc nhận / trả `Map<String, dynamic>` JSON để module không phụ thuộc kiểu lọc của màn hình.
class QuanAnBoNho {
  QuanAnBoNho._();

  static const _khoaLoc = 'quan_an_bo_loc';
  static const _khoaGoc = 'quan_an_diem_goc';
  static const _khoaDiaChi = 'quan_an_dia_chi';

  /// Bộ lọc đã lưu; null khi chưa có (dùng mặc định).
  static Future<Map<String, dynamic>?> docLoc() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoaLoc);
      if (s == null) return null;
      final m = jsonDecode(s);
      return m is Map ? Map<String, dynamic>.from(m) : null;
    } catch (_) {
      return null;
    }
  }

  /// Lưu bộ lọc; truyền null để xóa.
  static Future<void> luuLoc(Map<String, dynamic>? loc) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (loc == null) {
        await p.remove(_khoaLoc);
      } else {
        await p.setString(_khoaLoc, jsonEncode(loc));
      }
    } catch (_) {}
  }

  static Future<({double lat, double lng, String ten})?> docGoc() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoaGoc);
      if (s == null) return null;
      final m = jsonDecode(s) as Map<String, dynamic>;
      return (
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        ten: m['ten'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> luuGoc(({double lat, double lng, String ten})? g) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (g == null) {
        await p.remove(_khoaGoc);
      } else {
        await p.setString(
          _khoaGoc,
          jsonEncode({'lat': g.lat, 'lng': g.lng, 'ten': g.ten}),
        );
      }
    } catch (_) {}
  }

  /// Địa chỉ giao hàng đã lưu cục bộ: `[{ten, dong, lat, lng}]`.
  static Future<List<Map<String, dynamic>>> docDiaChi() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoaDiaChi);
      if (s == null) return const [];
      return [
        for (final x in jsonDecode(s) as List)
          if (x is Map) Map<String, dynamic>.from(x),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> luuDiaChi(List<Map<String, dynamic>> ds) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _khoaDiaChi,
        jsonEncode(ds),
      );
    } catch (_) {}
  }
}
