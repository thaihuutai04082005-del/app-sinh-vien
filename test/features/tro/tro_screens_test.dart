import 'package:app_sinh_vien/features/tro/models/dat_coc.dart';
import 'package:app_sinh_vien/features/tro/models/nha_tro.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/screens/chu_tro/tao_nha_tro_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/dat_coc_detail_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/phong_tro_detail_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/sinh_vien/tro_sanh_screen.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Widget _app(Widget w) =>
    MaterialApp(theme: TroTheme.data(webFont: false), home: w);

PhongTro _phong({
  String trangThai = 'available',
  String chu = 'chu',
  DateTime? khoa,
}) => PhongTro(
  id: 'p1',
  nhaTroId: 'n1',
  chuTroId: chu,
  ten: 'Phòng 101',
  dienTich: 20,
  giaThue: 2500000,
  tienCoc: 1000000,
  trangThai: trangThai,
  khoaThanhToanDen: khoa,
);

DatCoc _coc({
  required String status,
  required DateTime t,
  DateTime? hanHuy,
  bool quyenHuy = false,
}) => DatCoc(
  id: 'c1',
  status: status,
  version: 3,
  phongId: 'p1',
  nhaTroId: 'n1',
  chuTroId: 'chu',
  sinhVienId: 'sv',
  soTien: 1000000,
  t: t,
  tenPhong: 'Phòng 101',
  tenNhaTro: 'Nhà trọ Xanh',
  coQuyenHuyMienPhi: quyenHuy,
  hanHuyMienPhi: hanHuy,
  hanThanhToan: status == 'pending_payment'
      ? DateTime.now().add(const Duration(minutes: 10))
      : null,
);

void main() {
  setUpAll(() => TroTheme.webFontEnabled = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Sảnh Tìm trọ', () {
    testWidgets('hiện nhà trọ còn phòng trống', (tester) async {
      final g = TroGia()
        ..nhaTro = [
          const NhaTro(
            id: 'n1',
            chuTroId: 'chu',
            ten: 'Nhà trọ Xanh',
            trangThai: 'active',
            diaChi: '12 Lê Lợi',
          ),
        ]
        ..phong = [_phong()];
      await tester.pumpWidget(_app(TroSanhScreen(dv: g.dv)));
      await tester.pumpAndSettle();
      expect(find.text('Nhà trọ Xanh'), findsOneWidget);
    });

    testWidgets('không có kết quả thì hiện trạng thái rỗng + Xóa bộ lọc', (
      tester,
    ) async {
      final g = TroGia();
      await tester.pumpWidget(_app(TroSanhScreen(dv: g.dv)));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy nhà trọ phù hợp'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);
    });

    testWidgets('lỗi tải thì có nút Thử lại', (tester) async {
      final g = TroGia()..loiSanh = Exception('mất mạng');
      await tester.pumpWidget(_app(TroSanhScreen(dv: g.dv)));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('Thanh hành động phòng', () {
    Future<void> dung(WidgetTester tester, TroGia g, PhongTro p) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: PhongActionBar(dv: g.dv, phong: p),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('phòng trống: có nút Đặt cọc, Nhắn tin, Gọi', (tester) async {
      await dung(tester, TroGia(), _phong());
      expect(find.text('Đặt cọc giữ phòng'), findsOneWidget);
      expect(find.text('Nhắn tin'), findsOneWidget);
      expect(find.text('Gọi'), findsOneWidget);
    });

    testWidgets('đang có người thanh toán: nút cọc bị khóa và có lời nhắn', (
      tester,
    ) async {
      await dung(
        tester,
        TroGia(),
        _phong(khoa: DateTime.now().add(const Duration(minutes: 10))),
      );
      final nut = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Đặt cọc giữ phòng'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(nut.onPressed, isNull);
      expect(
        find.text('Đang có người thanh toán, thử lại sau ít phút'),
        findsOneWidget,
      );
    });

    testWidgets('phòng đã có người cọc: không đặt cọc được, không gọi', (
      tester,
    ) async {
      await dung(tester, TroGia(), _phong(trangThai: 'reserved'));
      expect(find.text('Đã có người cọc'), findsOneWidget);
      expect(find.text('Đặt cọc giữ phòng'), findsNothing);
      expect(find.text('Gọi'), findsNothing);
    });

    testWidgets('phòng của chính mình: không tự cọc / tự nhắn', (tester) async {
      await dung(tester, TroGia(uid: 'chu'), _phong());
      expect(find.text('Đây là phòng của bạn'), findsOneWidget);
      expect(find.text('Đặt cọc giữ phòng'), findsNothing);
      expect(find.text('Nhắn tin'), findsNothing);
    });
  });

  group('Chi tiết khoản cọc (sinh viên)', () {
    Future<TroGia> mo(WidgetTester tester, DatCoc d) async {
      final g = TroGia()..datCoc = [d];
      await tester.pumpWidget(
        _app(DatCocDetailScreen(dv: g.dv, datCocId: d.id)),
      );
      await tester.pumpAndSettle();
      return g;
    }

    testWidgets(
      'chờ thanh toán: có nút Tiếp tục thanh toán; mở màn hình là xử lý hạn',
      (tester) async {
        final g = await mo(
          tester,
          _coc(
            status: 'pending_payment',
            t: DateTime.now().add(const Duration(days: 3)),
          ),
        );
        expect(find.text('Tiếp tục thanh toán'), findsOneWidget);
        expect(g.goi, contains('xuLyHan'));
      },
    );

    testWidgets(
      'đang giữ trong 30 phút đầu: Hủy hoàn 100%, chưa có Không thuê nữa',
      (tester) async {
        await mo(
          tester,
          _coc(
            status: 'held',
            t: DateTime.now().add(const Duration(days: 3)),
            quyenHuy: true,
            hanHuy: DateTime.now().add(const Duration(minutes: 20)),
          ),
        );
        expect(find.textContaining('Hủy (hoàn 100%'), findsOneWidget);
        expect(find.text('Không thuê nữa'), findsNothing);
        expect(find.text('✅ Đã nhận phòng'), findsNothing);
      },
    );

    testWidgets(
      'đang giữ, hết 30 phút: Không thuê nữa (mất cọc) cần xác nhận rồi mới gửi',
      (tester) async {
        final g = await mo(
          tester,
          _coc(status: 'held', t: DateTime.now().add(const Duration(days: 3))),
        );
        await tester.ensureVisible(find.text('Không thuê nữa'));
        await tester.tap(find.text('Không thuê nữa'));
        await tester.pumpAndSettle();
        expect(find.textContaining('MẤT CỌC'), findsOneWidget);
        await tester.tap(find.text('Tôi không thuê nữa'));
        await tester.pumpAndSettle();
        expect(g.goi, contains('thaoTac:SV_KHONG_THUE'));
        expect(g.thamSo.last['version'], 3);
      },
    );

    testWidgets('đã tới thời điểm nhận phòng: Đã nhận phòng + Khiếu nại', (
      tester,
    ) async {
      await mo(
        tester,
        _coc(
          status: 'held',
          t: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(find.text('✅ Đã nhận phòng'), findsOneWidget);
      expect(
        find.text('⚠️ Chủ trọ không thực hiện đúng cam kết'),
        findsOneWidget,
      );
      expect(find.text('Không thuê nữa'), findsNothing);
    });
  });

  group('Form tạo nhà trọ', () {
    testWidgets(
      'bấm Tiếp khi thiếu thông tin: hiện khung lỗi ngay, không lưu nháp',
      (tester) async {
        tester.view.physicalSize = const Size(390, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final g = TroGia(uid: 'chu');
        await tester.pumpWidget(_app(TaoNhaTroScreen(dv: g.dv)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa qua được bước này, cần sửa:'), findsOneWidget);
        expect(find.textContaining('Tên nhà trọ 5–80 ký tự'), findsOneWidget);
        expect(find.textContaining('Mô tả ít nhất 30 ký tự'), findsOneWidget);
        expect(g.goi, isNot(contains('luuNhapNhaTro')));
        expect(find.textContaining('Bước 1/5'), findsOneWidget);
      },
    );
  });
}
