import 'package:app_sinh_vien/features/tro/models/nha_tro.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/screens/admin/hang_cho_admin_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/quan_ly_coc_truc_tiep_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/quan_ly_dat_coc_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/quan_ly_nha_tro_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/quan_ly_tong_quan_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/tao_nha_tro_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/them_phong_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/vi_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/cua_toi_tro_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/dat_coc_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/nha_tro_detail_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/phong_tro_detail_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/tro_shell.dart';
import 'package:app_sinh_vien/features/tro/screens/tuong_tac/chat_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/tuong_tac/thong_bao_screen.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Mở thử từng màn hình với dữ liệu giả ở cả kichCo điện thoại và kichCo máy tính;
/// bất kỳ lỗi hiển thị nào (tràn, "unbounded height"...) làm test đỏ.
void main() {
  setUpAll(() => TroTheme.webFontEnabled = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const nha = NhaTro(
    id: 'n1',
    chuTroId: 'chu',
    ten: 'Nhà trọ Xanh',
    trangThai: 'active',
    diaChi: '12 Lê Lợi',
    tongSoPhong: 5,
  );
  const phong = PhongTro(
    id: 'p1',
    nhaTroId: 'n1',
    chuTroId: 'chu',
    ten: 'Phòng 101',
    dienTich: 20,
    giaThue: 2500000,
    tienCoc: 1000000,
    trangThai: 'available',
  );

  TroGia du(String uid) => TroGia(uid: uid)
    ..nhaTro = [nha]
    ..phong = [phong];

  final man = <String, Widget Function(TroGia)>{
    'Shell (sảnh)': (g) => TroShell(dv: g.dv),
    'Chi tiết nhà trọ': (g) => NhaTroDetailScreen(dv: g.dv, nhaTroId: 'n1'),
    'Chi tiết phòng': (g) => PhongTroDetailScreen(dv: g.dv, phongId: 'p1'),
    'Đặt cọc': (g) => DatCocScreen(dv: g.dv, phong: phong),
    'Của tôi': (g) => CuaToiTroScreen(dv: g.dv),
    'Chat': (g) => ChatListScreen(dv: g.dv),
    'Thông báo': (g) => ThongBaoScreen(dv: g.dv),
    'Cài đặt thông báo': (g) => CaiDatThongBaoScreen(dv: g.dv),
    'Quản lý tổng quan': (g) => QuanLyTongQuanScreen(dv: g.dv),
    'Quản lý nhà trọ': (g) => QuanLyNhaTroScreen(dv: g.dv, nhaTroId: 'n1'),
    'Quản lý đặt cọc': (g) => QuanLyDatCocScreen(dv: g.dv),
    'Cọc trực tiếp': (g) => QuanLyCocTrucTiepScreen(dv: g.dv),
    'Ví': (g) => ViScreen(dv: g.dv),
    'Tạo nhà trọ': (g) => TaoNhaTroScreen(dv: g.dv),
    'Thêm phòng': (g) => ThemPhongScreen(dv: g.dv, nhaTro: nha),
    'Hàng chờ admin': (g) => HangChoAdminScreen(dv: g.dv),
    'Cấu hình admin': (g) => CauHinhAdminScreen(dv: g.dv),
  };

  for (final kichCo in const [Size(390, 800), Size(1300, 900)]) {
    for (final e in man.entries) {
      testWidgets('${e.key} · ${kichCo.width.toInt()}px mở không lỗi', (
        tester,
      ) async {
        tester.view.physicalSize = kichCo;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final g = du('chu');
        await tester.pumpWidget(
          MaterialApp(theme: TroTheme.data(webFont: false), home: e.value(g)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
