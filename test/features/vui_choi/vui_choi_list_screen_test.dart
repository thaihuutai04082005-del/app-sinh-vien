import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/vui_choi/models/vui_choi_model.dart';
import 'package:app_sinh_vien/features/vui_choi/screens/vui_choi_list_screen.dart';
import 'package:app_sinh_vien/features/vui_choi/services/vui_choi_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$folder/$fileName';
}

class _FakeService implements VuiChoiService {
  _FakeService(this._streams);

  /// Mỗi lần gọi lấy một stream theo thứ tự; hết thì dùng stream cuối.
  final List<Stream<List<VuiChoiModel>>> _streams;
  final List<String?> categories = [];

  @override
  Future<VuiChoiModel> dangVuiChoi(VuiChoiModel item) async => item;

  @override
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category}) {
    final index = categories.length < _streams.length
        ? categories.length
        : _streams.length - 1;
    categories.add(category);
    return _streams[index];
  }
}

const _cafe = VuiChoiModel(
  id: '1',
  name: 'Cà phê Sân Vườn',
  images: [],
  category: 'cafe',
  location: GeoPoint(10.46, 105.63),
  address: '12 Nguyễn Huệ, TP. Cao Lãnh',
  openHour: '07:00',
  closeHour: '22:00',
  ticketPrice: 0,
);
const _rap = VuiChoiModel(
  id: '2',
  name: 'Rạp Galaxy',
  images: [],
  category: 'rap_phim',
  location: GeoPoint(10.45, 105.64),
  address: '1 Lê Lợi, TP. Cao Lãnh',
  openHour: '09:00',
  closeHour: '23:00',
  ticketPrice: 90000,
);

Widget _app(VuiChoiService s) => MaterialApp(
  home: VuiChoiListScreen(service: s, storage: _FakeStorage()),
);

void main() {
  testWidgets('hiển thị danh sách lấy từ service, giá vé định dạng đúng', (
    tester,
  ) async {
    final service = _FakeService([
      Stream.value([_cafe, _rap]),
    ]);
    await tester.pumpWidget(_app(service));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Cà phê Sân Vườn'), findsOneWidget);
    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.text('90.000đ'), findsOneWidget);
    expect(service.categories, ['all']);
  });

  testWidgets('chọn loại hình thì gọi lại service với đúng category', (
    tester,
  ) async {
    final service = _FakeService([
      Stream.value([_cafe, _rap]),
      Stream.value([_rap]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rạp phim'));
    await tester.pumpAndSettle();
    expect(service.categories, ['all', 'rap_phim']);
    expect(find.text('Rạp Galaxy'), findsOneWidget);
    expect(find.text('Cà phê Sân Vườn'), findsNothing);
  });

  testWidgets('trạng thái rỗng', (tester) async {
    await tester.pumpWidget(
      _app(_FakeService([Stream.value(<VuiChoiModel>[])])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có địa điểm nào.'), findsOneWidget);
  });

  testWidgets('báo lỗi dễ hiểu (không lộ exception) và thử lại được', (
    tester,
  ) async {
    final service = _FakeService([
      Stream<List<VuiChoiModel>>.error(Exception('permission-denied')),
      Stream.value([_cafe]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Chưa tải được danh sách điểm vui chơi'),
      findsOneWidget,
    );
    expect(find.textContaining('permission-denied'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Cà phê Sân Vườn'), findsOneWidget);
    expect(service.categories.length, 2);
  });

  testWidgets('bấm vào địa điểm mở màn chi tiết', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeService([
          Stream.value([_rap]),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rạp Galaxy'));
    await tester.pumpAndSettle();
    expect(find.text('Rạp phim'), findsOneWidget); // nhãn loại hình
    expect(find.text('Giờ mở cửa: 09:00 - 23:00'), findsOneWidget);
    expect(find.text('Giá vé: 90.000đ'), findsOneWidget);
  });

  testWidgets('nút dấu cộng mở form đăng địa điểm', (tester) async {
    await tester.pumpWidget(
      _app(_FakeService([Stream.value(<VuiChoiModel>[])])),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Đăng địa điểm'),
      findsOneWidget,
    ); // nút nổi nhìn thấy ngay
    await tester.tap(find.byTooltip('Đăng địa điểm mới'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng địa điểm vui chơi'), findsOneWidget);
  });

  test('VuiChoiModel.fromMap đọc đúng tên field theo bảng 7.3', () {
    final m = VuiChoiModel.fromMap('x', {
      'name': 'N',
      'images': ['a'],
      'category': 'cong_vien',
      'location': const GeoPoint(1, 2),
      'address': 'Đ',
      'openHour': '06:00',
      'closeHour': '21:00',
      'ticketPrice': 15000,
      'ownerId': 'u1',
    });
    expect(m.ownerId, 'u1');
    expect(m.category, 'cong_vien');
    expect(m.ticketPrice, 15000.0);
    expect(m.location.longitude, 2);
    expect(m.toMap().keys.toSet(), {
      'name',
      'images',
      'category',
      'location',
      'address',
      'openHour',
      'closeHour',
      'ticketPrice',
    });
  });

  test('VuiChoiModel.fromMap chịu được dữ liệu thiếu', () {
    final m = VuiChoiModel.fromMap('x', {});
    expect(m.name, '');
    expect(m.images, isEmpty);
    expect(m.ticketPrice, 0);
  });
}
