import 'package:flutter/material.dart';

import '../models/dat_ban.dart';
import '../models/don_mon.dart';
import '../services/quan_an_dich_vu.dart';
import '../widgets/quan_an_states.dart';
import '../widgets/quan_an_theme.dart';
import 'admin/hang_cho_admin_screen.dart';
import 'chu_quan/chi_tiet_don_chu_quan_screen.dart';
import 'chu_quan/quan_ly_dat_ban_screen.dart';
import 'chu_quan/quan_ly_tong_quan_screen.dart';
import 'quan_an_shell.dart';
import 'sinh_vien/chi_tiet_dat_ban_screen.dart';
import 'sinh_vien/danh_gia_quan_screen.dart';
import 'sinh_vien/quan_an_detail_screen.dart';
import 'sinh_vien/theo_doi_don_screen.dart';
import 'tuong_tac/chat_screen.dart';

/// Route của module Quán ăn: bọc màn hình trong giao diện riêng (mục 3.19) để mọi
/// màn hình mở từ module đều xanh biển – trắng, không đổi theme của phần còn lại.
Route<T> quanAnRoute<T>(WidgetBuilder builder) => MaterialPageRoute<T>(
  builder: (context) =>
      Theme(data: QuanAnTheme.data(), child: Builder(builder: builder)),
);

/// Điều hướng giữa các màn hình của module.
class QuanAnDieuHuong {
  const QuanAnDieuHuong._();

  static Future<T?> mo<T>(BuildContext context, WidgetBuilder builder) =>
      Navigator.of(context).push<T>(quanAnRoute(builder));

  static Future<void> quan(
    BuildContext context,
    QuanAnDichVu dv,
    String quanId,
  ) => mo(context, (_) => QuanAnDetailScreen(dv: dv, quanId: quanId));

  /// Mở đơn: sinh viên thấy màn theo dõi đơn, chủ quán thấy màn xử lý đơn.
  static Future<void> don(
    BuildContext context,
    QuanAnDichVu dv,
    String donId,
  ) => mo(
    context,
    (_) => QuanAnStream<DonMon?>(
      stream: () => dv.donMon.donMon(donId),
      builder: (context, d) {
        if (d == null) {
          return const Scaffold(
            body: QuanAnEmptyState(title: 'Không tìm thấy đơn'),
          );
        }
        return d.chuQuanId == dv.uid
            ? ChiTietDonChuQuanScreen(dv: dv, donId: donId)
            : TheoDoiDonScreen(dv: dv, donId: donId);
      },
    ),
  );

  /// Mở lượt đặt bàn: sinh viên xem chi tiết, chủ quán vào danh sách quản lý đặt bàn.
  static Future<void> datBan(
    BuildContext context,
    QuanAnDichVu dv,
    String banId,
  ) => mo(
    context,
    (_) => QuanAnStream<DatBan?>(
      stream: () => dv.datBan.datBan(banId),
      builder: (context, b) {
        if (b == null) {
          return const Scaffold(
            body: QuanAnEmptyState(title: 'Không tìm thấy lượt đặt bàn'),
          );
        }
        return b.chuQuanId == dv.uid
            ? QuanLyDatBanScreen(dv: dv)
            : ChiTietDatBanScreen(dv: dv, banId: banId);
      },
    ),
  );

  static Future<void> chat(
    BuildContext context,
    QuanAnDichVu dv,
    String nguoiKia, {
    String? quanId,
    String? donId,
  }) => mo(
    context,
    (_) => CuocChatScreen(
      dv: dv,
      nguoiKia: nguoiKia,
      quanId: quanId,
      donId: donId,
    ),
  );

  static Future<void> quanLy(BuildContext context, QuanAnDichVu dv) =>
      mo(context, (_) => QuanLyTongQuanScreen(dv: dv));

  static Future<void> admin(BuildContext context, QuanAnDichVu dv) =>
      mo(context, (_) => HangChoAdminScreen(dv: dv));

  /// Mở đúng trang mà thông báo trỏ tới.
  static Future<void> theoThongBao(
    BuildContext context,
    QuanAnDichVu dv,
    Map<String, dynamic>? moTrang,
  ) async {
    final id = moTrang?['id'] as String?;
    switch (moTrang?['loai']) {
      case 'don' when id != null:
        return don(context, dv, id);
      case 'dat_ban' when id != null:
        return datBan(context, dv, id);
      case 'quan' when id != null:
        return quan(context, dv, id);
      case 'chat' when id != null:
        final nguoiKia = id
            .split('_')
            .firstWhere((x) => x != dv.uid, orElse: () => '');
        return chat(context, dv, nguoiKia);
      case 'danh_gia' when id != null:
        return mo(
          context,
          (_) => DanhGiaQuanScreen(dv: dv, quanId: id, tenQuan: ''),
        );
      case 'quan_ly_quan':
        return quanLy(context, dv);
      case 'admin_hang_cho':
        return admin(context, dv);
    }
  }
}

/// Mở module Quán ăn từ trang chủ của app.
Route<void> quanAnModuleRoute() =>
    quanAnRoute((_) => QuanAnShell(dv: QuanAnDichVu.firebase()));
