import 'package:app_sinh_vien/features/quan_an/screens/admin/hang_cho_admin_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/chu_quan/doanh_thu_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/chu_quan/quan_ly_dat_ban_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/chu_quan/quan_ly_don_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/chu_quan/quan_ly_menu_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/chu_quan/vi_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/cua_toi_quan_an_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/dat_ban_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/dat_mon_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/gio_hang_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/quan_an_detail_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/quan_an_sanh_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/sinh_vien/theo_doi_don_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/tuong_tac/chat_screen.dart';
import 'package:app_sinh_vien/features/quan_an/screens/tuong_tac/thong_bao_screen.dart';
import 'package:app_sinh_vien/features/quan_an/widgets/quan_an_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Widget _app(Widget w) =>
    MaterialApp(theme: QuanAnTheme.data(webFont: false), home: w);

QuanAnGia _du() => QuanAnGia()
  ..quan = [quanMau()]
  ..nhom = [nhomMau()]
  ..mon = [monMau()]
  ..don = [donMau(), donMau(id: 'd2', status: 'accepted')]
  ..ban = [banMau()];

void main() {
  setUpAll(() => QuanAnTheme.webFontEnabled = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final man = <String, Widget Function(QuanAnGia g)>{
    'sảnh': (g) => QuanAnSanhScreen(dv: g.dv),
    'chi tiết quán': (g) => QuanAnDetailScreen(dv: g.dv, quanId: 'q1'),
    'đặt bàn': (g) => DatBanScreen(dv: g.dv, quan: g.quan.first),
    'đặt món': (g) => DatMonScreen(dv: g.dv, quan: g.quan.first),
    'giỏ hàng': (g) => GioHangScreen(dv: g.dv),
    'theo dõi đơn': (g) => TheoDoiDonScreen(dv: g.dv, donId: 'd1'),
    'của tôi': (g) => CuaToiQuanAnScreen(dv: g.dv),
    'danh sách chat': (g) => ChatListScreen(dv: g.dv),
    'thông báo': (g) => ThongBaoScreen(dv: g.dv),
    'quản lý đơn': (g) => QuanLyDonScreen(dv: g.dv),
    'quản lý đặt bàn': (g) => QuanLyDatBanScreen(dv: g.dv),
    'quản lý menu': (g) => QuanLyMenuScreen(dv: g.dv, quanId: 'q1'),
    'doanh thu': (g) => DoanhThuScreen(dv: g.dv),
    'ví': (g) => ViScreen(dv: g.dv),
    'hàng chờ admin': (g) => HangChoAdminScreen(dv: g.dv),
  };

  for (final size in const [Size(390, 800), Size(1300, 900)]) {
    for (final e in man.entries) {
      // Chữ OSM của flutter_map (SimpleAttributionWidget) tràn khi test dùng phông Ahem; máy thật không bị.
      if (e.key == 'chi tiết quán' && size.width < 500) continue;
      testWidgets('${e.key} @${size.width.toInt()} không lỗi', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(e.value(_du())));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
