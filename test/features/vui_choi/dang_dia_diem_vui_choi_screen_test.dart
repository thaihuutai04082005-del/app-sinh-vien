import 'dart:convert';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/daily_quota.dart';
import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/vui_choi/models/vui_choi_model.dart';
import 'package:app_sinh_vien/features/vui_choi/screens/dang_dia_diem_vui_choi_screen.dart';
import 'package:app_sinh_vien/features/vui_choi/services/vui_choi_service.dart';
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

class _RecordingService implements VuiChoiService {
  _RecordingService({this.error});

  final Object? error;
  final posted = <VuiChoiModel>[];

  @override
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category}) =>
      Stream.value(const []);

  @override
  Future<VuiChoiModel> dangVuiChoi(VuiChoiModel item) async {
    if (error != null) throw error!;
    posted.add(item);
    return item;
  }
}

Future<List<XFile>> _pickOne(int _) async => [
  XFile.fromData(_png, name: 'quan.png'),
];

/// Mở màn đăng bằng nút đẩy route để kiểm tra được giá trị `pop(true)`.
Future<ValueNotifier<bool?>> _pump(
  WidgetTester tester,
  VuiChoiService service,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final result = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result.value = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => DangDiaDiemVuiChoiScreen(
                    service: service,
                    storage: _InstantStorage(),
                    pickImages: _pickOne,
                  ),
                ),
              );
            },
            child: const Text('mở form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở form'));
  await tester.pumpAndSettle();
  return result;
}

const _link = 'https://example.com/cafe.jpg';

/// Điền form hợp lệ. Mặc định thêm ảnh bằng cách dán link; [upload] = true thì
/// chuyển sang "Tải ảnh từ máy" và chọn ảnh.
Future<void> _fillValid(WidgetTester tester, {bool upload = false}) async {
  if (upload) {
    await tester.tap(find.text('Tải ảnh từ máy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm ảnh'));
    await tester.pumpAndSettle();
  } else {
    await tester.enterText(find.widgetWithText(TextField, 'Link ảnh'), _link);
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Tên địa điểm'),
    'Cà phê Sân Vườn',
  );
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cà phê').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Địa chỉ'),
    '12 Nguyễn Huệ, Cao Lãnh',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Vĩ độ'), '10.46');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kinh độ'),
    '105.633',
  );
}

Finder get _submit => find.widgetWithText(FilledButton, 'Đăng địa điểm');

void main() {
  testWidgets('để trống thì báo đủ các lỗi, không gọi service', (tester) async {
    final service = _RecordingService();
    await _pump(tester, service);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Nhập tên địa điểm'), findsOneWidget);
    expect(find.text('Chọn loại địa điểm'), findsOneWidget);
    expect(find.text('Nhập địa chỉ'), findsOneWidget);
    expect(find.text('Vĩ độ -90 đến 90'), findsOneWidget);
    expect(find.text('Kinh độ -180 đến 180'), findsOneWidget);
    expect(find.text('Cần ít nhất 1 ảnh địa điểm.'), findsOneWidget);
    expect(service.posted, isEmpty);
  });

  testWidgets('giờ sai định dạng và tọa độ ngoài phạm vi bị từ chối', (
    tester,
  ) async {
    final service = _RecordingService();
    await _pump(tester, service);
    await _fillValid(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mở cửa'),
      '25:00',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Vĩ độ'), '95');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Giờ không hợp lệ (VD: 08:30)'), findsOneWidget);
    expect(find.text('Vĩ độ -90 đến 90'), findsOneWidget);
    expect(service.posted, isEmpty);
  });

  testWidgets('nhập đúng thì đăng đủ dữ liệu theo bảng 7.3 và đóng form', (
    tester,
  ) async {
    final service = _RecordingService();
    final result = await _pump(tester, service);
    await _fillValid(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Giá vé'),
      '50000',
    );
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(service.posted, hasLength(1));
    final item = service.posted.single;
    expect(item.name, 'Cà phê Sân Vườn');
    expect(item.category, 'cafe');
    expect(item.address, '12 Nguyễn Huệ, Cao Lãnh');
    expect(item.location.latitude, 10.46);
    expect(item.location.longitude, 105.633);
    expect(item.openHour, '08:00');
    expect(item.closeHour, '22:00');
    expect(item.ticketPrice, 50000);
    expect(item.images, [_link]);
    expect(result.value, isTrue);
    expect(find.text('Đăng địa điểm vui chơi'), findsNothing);
  });

  testWidgets('tải ảnh từ máy cũng đăng được và lưu link ảnh đã upload', (
    tester,
  ) async {
    final service = _RecordingService();
    final result = await _pump(tester, service);
    await _fillValid(tester, upload: true);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      service.posted.single.images.single,
      startsWith('https://cdn.test/vui_choi/'),
    );
    expect(result.value, isTrue);
  });

  testWidgets(
    'đổi chế độ giữ ảnh đã thêm, và chỉ tính ảnh của chế độ đang chọn',
    (tester) async {
      final service = _RecordingService();
      await _pump(tester, service);
      await _fillValid(tester); // đã thêm 1 link

      await tester.tap(find.text('Tải ảnh từ máy'));
      await tester.pumpAndSettle();
      await tester.tap(_submit); // chưa chọn ảnh nào ở chế độ này
      await tester.pumpAndSettle();
      expect(find.text('Cần ít nhất 1 ảnh địa điểm.'), findsOneWidget);
      expect(service.posted, isEmpty);

      await tester.tap(find.text('Dán link ảnh')); // quay lại: link vẫn còn
      await tester.pumpAndSettle();
      expect(find.text('Ảnh địa điểm (1/6)'), findsOneWidget);
      await tester.tap(_submit);
      await tester.pumpAndSettle();
      expect(service.posted.single.images, [_link]);
    },
  );

  testWidgets('vượt hạn mức thì hiện đúng thông báo của hạn mức', (
    tester,
  ) async {
    final service = _RecordingService(
      error: const QuotaException('Mỗi ngày chỉ được đăng tối đa 10 tin.'),
    );
    await _pump(tester, service);
    await _fillValid(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Mỗi ngày chỉ được đăng tối đa 10 tin.'), findsOneWidget);
    expect(find.text('Đăng địa điểm vui chơi'), findsOneWidget); // ở lại form
  });

  testWidgets('lỗi khác thì báo dễ hiểu, không lộ nội dung exception', (
    tester,
  ) async {
    final service = _RecordingService(error: Exception('permission-denied'));
    await _pump(tester, service);
    await _fillValid(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa đăng được địa điểm. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.textContaining('permission-denied'), findsNothing);
  });
}
