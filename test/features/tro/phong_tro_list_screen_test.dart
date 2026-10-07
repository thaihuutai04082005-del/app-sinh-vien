import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/screens/phong_tro_list_screen.dart';
import 'package:app_sinh_vien/features/tro/services/phong_tro_service.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_states.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoStorage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$fileName';
}

class _FakeService implements PhongTroService {
  _FakeService(this._results);

  final List<Object> _results; // List<PhongTro> hoặc Exception, dùng lần lượt
  int calls = 0;

  @override
  Future<List<PhongTro>> getDanhSachPhongTro() async {
    final r = _results[calls < _results.length ? calls : _results.length - 1];
    calls++;
    if (r is Exception) throw r;
    return r as List<PhongTro>;
  }

  @override
  Future<PhongTro> dangPhongTro(PhongTro phong) async => phong;
}

const _studio = PhongTro(
  id: '1',
  ownerId: 'u1',
  title: 'Studio gần Đại học Đồng Tháp',
  address: 'Phường 6, TP. Cao Lãnh, Đồng Tháp',
  price: 2600000,
  area: 24,
  roomType: RoomType.studio,
  ownerVerified: true,
  amenities: ['may_lanh', 'wifi'],
);
const _ghep = PhongTro(
  id: '2',
  ownerId: 'u2',
  title: 'Phòng ở ghép khu Tân Quy Đông',
  address: 'Tân Quy Đông, TP. Sa Đéc, Đồng Tháp',
  price: 900000,
  area: 20,
  roomType: RoomType.oGhep,
);

Widget _app(PhongTroService s) => MaterialApp(
  home: PhongTroListScreen(service: s, storage: _NoStorage()),
);

void main() {
  setUpAll(() => TroTheme.webFontEnabled = false);

  testWidgets('hiển thị danh sách lấy từ service', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService([
          <PhongTro>[_studio, _ghep],
        ]),
      ),
    );
    expect(find.byType(TroSkeletonList), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('2 chỗ ở phù hợp'), findsOneWidget);
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);
    expect(find.textContaining('2.600.000đ'), findsOneWidget);
  });

  testWidgets('tìm theo khu vực', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService([
          <PhongTro>[_studio, _ghep],
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cao Lãnh');
    await tester.pump();
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);
    expect(find.text('Phòng ở ghép khu Tân Quy Đông'), findsNothing);
  });

  testWidgets('lọc theo loại phòng và theo xác thực', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService([
          <PhongTro>[_studio, _ghep],
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ở ghép'));
    await tester.pump();
    expect(find.text('Phòng ở ghép khu Tân Quy Đông'), findsOneWidget);
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.tap(find.widgetWithText(FilterChip, 'Đã xác thực'));
    await tester.pump();
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);
    expect(find.text('Phòng ở ghép khu Tân Quy Đông'), findsNothing);
  });

  testWidgets('trạng thái rỗng khi chưa có phòng nào', (tester) async {
    await tester.pumpWidget(_app(_FakeService([<PhongTro>[]])));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phòng nào'), findsOneWidget);
  });

  testWidgets('báo lỗi và tải lại được', (tester) async {
    final service = _FakeService([
      Exception('mạng'),
      <PhongTro>[_studio],
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa tải được danh sách phòng. Vui lòng thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('bấm vào phòng mở màn chi tiết đủ thông tin', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService([
          <PhongTro>[_studio],
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studio gần Đại học Đồng Tháp'));
    await tester.pumpAndSettle();
    expect(find.text('Máy lạnh'), findsOneWidget);
    expect(find.text('Wifi'), findsOneWidget);
    expect(find.text('Liên hệ chủ trọ'), findsOneWidget);
  });

  test('PhongTro.fromMap đọc đúng tên field theo bảng 7.3', () {
    final p = PhongTro.fromMap('x', {
      'ownerId': 'o',
      'ownerVerified': true,
      'title': 'T',
      'images': ['a'],
      'price': 1500000,
      'electricPrice': 3500,
      'waterPrice': 100000,
      'area': 18,
      'maxPeople': 2,
      'amenities': ['wifi'],
      'lifestylePrefs': ['an_chay'],
      'depositEnabled': true,
      'address': 'Đ',
      'status': 'available',
      'roomType': 'o_ghep',
    });
    expect(p.ownerVerified, isTrue);
    expect(p.maxPeople, 2);
    expect(p.lifestylePrefs, ['an_chay']);
    expect(p.depositEnabled, isTrue);
    expect(p.roomType, RoomType.oGhep);
  });
}
