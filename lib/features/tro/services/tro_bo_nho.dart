import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tro_filter.dart';

/// App nhớ bộ lọc và điểm gốc lần trước, riêng trong module Tìm trọ (mục 2.4, 2.7).
/// Lỗi bộ nhớ (trình duyệt chặn...) thì bỏ qua, app vẫn chạy với mặc định.
class TroBoNho {
  static const _khoaLoc = 'tro_bo_loc';
  static const _khoaGoc = 'tro_diem_goc';

  static Future<TroFilter> docLoc() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoaLoc);
      if (s == null) return TroFilter.macDinh;
      return TroFilter.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return TroFilter.macDinh;
    }
  }

  static Future<void> luuLoc(TroFilter f) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _khoaLoc,
        jsonEncode(f.toJson()),
      );
    } catch (_) {}
  }

  static Future<DiemGoc?> docGoc() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoaGoc);
      return s == null ? null : DiemGoc.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  static Future<void> luuGoc(DiemGoc? g) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (g == null) {
        await p.remove(_khoaGoc);
      } else {
        await p.setString(_khoaGoc, jsonEncode(g.toJson()));
      }
    } catch (_) {}
  }
}
