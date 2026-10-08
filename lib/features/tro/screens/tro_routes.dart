import 'package:flutter/material.dart';

import '../services/tro_dich_vu.dart';
import '../widgets/tro_theme.dart';
import 'admin/hang_cho_admin_screen.dart';
import 'chu_tro/quan_ly_tong_quan_screen.dart';
import 'sinh_vien/dat_coc_detail_screen.dart';
import 'sinh_vien/nha_tro_detail_screen.dart';
import 'sinh_vien/phong_tro_detail_screen.dart';
import 'sinh_vien/xac_nhan_da_thue_screen.dart';
import 'tro_shell.dart';
import 'tuong_tac/chat_screen.dart';

/// Route của module Tìm trọ: bọc màn hình trong giao diện riêng (mục 2.19) để mọi
/// màn hình mở từ module đều xanh biển – trắng, không đổi theme của phần còn lại.
Route<T> troRoute<T>(WidgetBuilder builder) => MaterialPageRoute<T>(
  builder: (context) => Theme(
    data: TroTheme.data(),
    child: Builder(builder: builder),
  ),
);

/// Điều hướng giữa các màn hình của module.
class TroDieuHuong {
  const TroDieuHuong._();

  static Future<T?> mo<T>(BuildContext context, WidgetBuilder builder) =>
      Navigator.of(context).push<T>(troRoute(builder));

  static Future<void> nhaTro(
    BuildContext context,
    TroDichVu dv,
    String id, {
    Set<String> phongPhuHop = const {},
  }) => mo(
    context,
    (_) => NhaTroDetailScreen(dv: dv, nhaTroId: id, phongPhuHop: phongPhuHop),
  );

  static Future<void> phong(BuildContext context, TroDichVu dv, String id) =>
      mo(context, (_) => PhongTroDetailScreen(dv: dv, phongId: id));

  static Future<void> datCoc(BuildContext context, TroDichVu dv, String id) =>
      mo(context, (_) => DatCocDetailScreen(dv: dv, datCocId: id));

  static Future<void> chat(
    BuildContext context,
    TroDichVu dv,
    String nguoiKia, {
    String? phongId,
  }) => mo(
    context,
    (_) => CuocTroChuyenScreen(dv: dv, nguoiKia: nguoiKia, phongId: phongId),
  );

  static Future<void> quanLy(BuildContext context, TroDichVu dv) =>
      mo(context, (_) => QuanLyTongQuanScreen(dv: dv));

  static Future<void> admin(BuildContext context, TroDichVu dv) =>
      mo(context, (_) => HangChoAdminScreen(dv: dv));

  /// Mở đúng trang mà thông báo trỏ tới.
  static Future<void> theoThongBao(
    BuildContext context,
    TroDichVu dv,
    Map<String, dynamic>? moTrang,
  ) async {
    final id = moTrang?['id'] as String?;
    switch (moTrang?['loai']) {
      case 'dat_coc' when id != null:
        return datCoc(context, dv, id);
      case 'nha_tro' when id != null:
        return nhaTro(context, dv, id);
      case 'chat' when id != null:
        final nguoiKia = id
            .split('_')
            .firstWhere((x) => x != dv.uid, orElse: () => '');
        return chat(context, dv, nguoiKia);
      case 'coc_truc_tiep' when id != null:
        return mo(context, (_) => XacNhanDaThueScreen(dv: dv, id: id));
      case 'quan_ly_nha_tro' || 'quan_ly_coc_truc_tiep':
        return quanLy(context, dv);
      case 'admin_hang_cho':
        return admin(context, dv);
    }
  }
}

/// Mở module Tìm trọ từ trang chủ của app.
Route<void> troModuleRoute() =>
    troRoute((_) => TroShell(dv: TroDichVu.firebase()));
