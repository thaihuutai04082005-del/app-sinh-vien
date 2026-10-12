import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gio_hang.dart';

/// Kết quả thêm món vào giỏ.
enum KetQuaThemGio {
  /// Đã thêm.
  daThem,

  /// Giỏ đang có món của quán khác: hỏi "Xóa giỏ hiện tại?" rồi gọi
  /// [GioHangService.xacNhanDoiQuan] (đồng ý) hoặc [GioHangService.huyDoiQuan].
  needConfirm,
}

/// Giữ [GioHang] trong bộ nhớ và SharedPreferences (mở lại app vẫn còn giỏ), mục 3.4 Bước 5a.
/// Lỗi bộ nhớ (trình duyệt chặn...) thì bỏ qua, giỏ vẫn chạy trong bộ nhớ.
class GioHangService extends ChangeNotifier {
  GioHangService({this.luuBoNho = true});

  static const _khoa = 'quan_an_gio_hang';

  /// Tắt trong test để không đụng SharedPreferences.
  final bool luuBoNho;

  GioHang _gio = GioHang.rong;
  ({String quanId, String tenQuan, DongGioHang dong})? _cho;

  GioHang get gio => _gio;

  /// Món đang chờ khách xác nhận đổi quán (khi [them] trả [KetQuaThemGio.needConfirm]).
  ({String quanId, String tenQuan, DongGioHang dong})? get choXacNhan => _cho;

  /// Nạp giỏ đã lưu (gọi một lần khi mở module).
  Future<void> tai() async {
    if (!luuBoNho) return;
    try {
      final s = (await SharedPreferences.getInstance()).getString(_khoa);
      if (s == null) return;
      _gio = GioHang.fromJson(jsonDecode(s));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _luu() async {
    if (!luuBoNho) return;
    try {
      final p = await SharedPreferences.getInstance();
      if (_gio.laRong) {
        await p.remove(_khoa);
      } else {
        await p.setString(_khoa, jsonEncode(_gio.toJson()));
      }
    } catch (_) {}
  }

  void _doi(GioHang g) {
    _gio = g;
    notifyListeners();
    _luu();
  }

  /// Thêm [dong] của quán [quanId]. Món của quán khác: giữ nguyên giỏ, ghi nhớ món chờ
  /// và trả [KetQuaThemGio.needConfirm].
  KetQuaThemGio them({
    required String quanId,
    required String tenQuan,
    required DongGioHang dong,
  }) {
    if (_gio.khacQuan(quanId)) {
      _cho = (quanId: quanId, tenQuan: tenQuan, dong: dong);
      notifyListeners();
      return KetQuaThemGio.needConfirm;
    }
    _doi(_gio.them(dong, quanId: quanId, tenQuan: tenQuan));
    return KetQuaThemGio.daThem;
  }

  /// Khách đồng ý xóa giỏ cũ: giỏ mới chỉ có món đang chờ.
  void xacNhanDoiQuan() {
    final c = _cho;
    if (c == null) return;
    _cho = null;
    _doi(GioHang.moi(c.quanId, c.tenQuan, c.dong));
  }

  /// Khách giữ giỏ cũ: bỏ món đang chờ.
  void huyDoiQuan() {
    if (_cho == null) return;
    _cho = null;
    notifyListeners();
  }

  void boBot(String khoa, [int n = 1]) => _doi(_gio.boBot(khoa, n));
  void xoaDong(String khoa) => _doi(_gio.xoa(khoa));

  /// Thêm một phần nữa của dòng có khóa [khoa].
  void themMotPhan(String khoa) {
    for (final d in _gio.dong) {
      if (d.khoa == khoa) {
        _doi(
          _gio.them(
            d.copyWith(soLuong: 1),
            quanId: _gio.quanId,
            tenQuan: _gio.tenQuan,
          ),
        );
        return;
      }
    }
  }

  /// Xóa cả giỏ (sau khi đặt món thành công, hoặc khách bấm xóa giỏ).
  void xoaHet() {
    _cho = null;
    _doi(GioHang.rong);
  }
}
