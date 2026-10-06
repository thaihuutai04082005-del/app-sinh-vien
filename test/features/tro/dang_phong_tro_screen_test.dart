import 'dart:convert';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/daily_quota.dart';
import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/screens/dang_phong_tro_screen.dart';
import 'package:app_sinh_vien/features/tro/screens/phong_tro_list_screen.dart';
import 'package:app_sinh_vien/features/tro/services/phong_tro_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _InstantStorage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$folder/$fileName';
}

class _Service implements PhongTroService {
  _Service({this.error});

  final Object? error;
  final posted = <PhongTro>[];

  @override
  Future<List<PhongTro>> getDanhSachPhongTro() async => const [];

  @override
  Future<PhongTro> dangPhongTro(PhongTro phong) async {
    if (error != null) throw error!;
    posted.add(phong);
    return phong;
  }
}

Future<List<XFile>> _pickOne(int _) async => [
  XFile.fromData(_png, name: 'phong.png'),
];

Future<void> _pump(WidgetTester tester, PhongTroService service) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: DangPhongTroScreen(
        service: service,
        storage: _InstantStorage(),
        pickImages: _pickOne,
      ),
    ),
  );
}

Future<void> _enter(WidgetTester tester, String label, String text) =>
    tester.enterText(find.widgetWithText(TextFormField, label), text);

Future<void> _fill(WidgetTester tester, {bool upload = false}) async {
  if (upload) {
    await tester.tap(find.text('Tải ảnh từ máy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm ảnh'));
    await tester.pumpAndSettle();
  } else {
    await tester.enterText(
      find.widgetWithText(TextField, 'Link ảnh'),
      'https://example.com/phong.jpg',
    );
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
  }
  await _enter(tester, 'Tiêu đề tin', 'Studio gần trường');
  await _enter(tester, 'Địa chỉ', 'Cao Lãnh');
  await _enter(tester, 'Giá thuê / tháng', '2600000');
  await _enter(tester, 'Diện tích', '24.5');
  await _enter(tester, 'Vĩ độ', '10.46');
  await _enter(tester, 'Kinh độ', '105.63');
}

Finder get _submit => find.widgetWithText(FilledButton, 'Đăng tin');

void main() {
  testWidgets('để trống thì báo lỗi, không gọi service', (tester) async {
    final service = _Service();
    await _pump(tester, service);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Nhập tiêu đề tin'), findsOneWidget);
    expect(find.text('Nhập địa chỉ'), findsOneWidget);
    expect(find.text('Nhập giá thuê hợp lệ'), findsOneWidget);
    expect(find.text('Cần ít nhất 1 ảnh phòng.'), findsOneWidget);
    expect(service.posted, isEmpty);
  });

  testWidgets('đăng bằng link ảnh', (tester) async {
    final service = _Service();
    await _pump(tester, service);
    await _fill(tester);
    await tester.tap(find.text('Wifi'));
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    final p = service.posted.single;
    expect(p.images, ['https://example.com/phong.jpg']);
    expect(p.price, 2600000);
    expect(p.area, 24.5);
    expect(p.amenities, ['wifi']);
    expect(p.roomType, RoomType.oRieng);
    expect(p.toMap()['status'], 'available');
    expect(p.toMap()['ownerVerified'], false);
  });

  testWidgets('đăng bằng ảnh tải từ máy', (tester) async {
    final service = _Service();
    await _pump(tester, service);
    await _fill(tester, upload: true);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      service.posted.single.images.single,
      startsWith('https://cdn.test/phong_tro/'),
    );
  });

  testWidgets('vượt hạn mức thì báo đúng thông điệp', (tester) async {
    final service = _Service(
      error: const QuotaException('Hết lượt đăng hôm nay'),
    );
    await _pump(tester, service);
    await _fill(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Hết lượt đăng hôm nay'), findsOneWidget);
  });

  testWidgets('danh sách có nút Đăng tin mở form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhongTroListScreen(
          service: _Service(),
          storage: _InstantStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đăng tin cho thuê'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng tin cho thuê'), findsOneWidget);
  });
}
