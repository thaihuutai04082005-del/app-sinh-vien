import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/shared/widgets/image_upload_field.dart';

// PNG 1x1 hợp lệ để Image.memory giải mã được.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakeStorage implements ImageStorageService {
  final pending = <Completer<String>>[];

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) {
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }
}

Future<List<XFile>> _pickTwo(int maxCount) async => [
  XFile.fromData(_png, name: 'a.png'),
  XFile.fromData(_png, name: 'b.png'),
];

void main() {
  testWidgets('upload ngay khi chọn, báo lỗi và cho thử lại', (tester) async {
    final storage = _FakeStorage();
    late List<String> urls;
    late bool uploading;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageUploadField(
            storage: storage,
            folder: 'products',
            pickImages: _pickTwo,
            onChanged: (u, busy) {
              urls = u;
              uploading = busy;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Thêm ảnh'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Ảnh (2/6)'), findsOneWidget);
    expect(storage.pending, hasLength(2));
    expect(uploading, isTrue);

    storage.pending[0].complete('https://cdn/a.png');
    storage.pending[1].completeError(const ImageUploadException('Lỗi mạng'));
    await tester.pump();

    expect(urls, ['https://cdn/a.png']);
    expect(uploading, isFalse);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    storage.pending[2].complete('https://cdn/b.png');
    await tester.pump();

    expect(urls, ['https://cdn/a.png', 'https://cdn/b.png']);

    await tester.tap(find.byTooltip('Xóa ảnh').first);
    await tester.pump();
    expect(urls, ['https://cdn/b.png']);
    expect(find.text('Ảnh (1/6)'), findsOneWidget);
  });
}
