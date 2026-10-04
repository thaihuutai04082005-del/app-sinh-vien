import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unihub_student_app/core/services/image_storage_service.dart';
import 'package:unihub_student_app/shared/widgets/video_upload_field.dart';

class _RecordingStorage implements ImageStorageService {
  int calls = 0;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    calls++;
    return 'https://cdn.test/videos/$folder/v.mp4';
  }
}

Future<void> _pump(
  WidgetTester tester,
  ImageStorageService storage,
  XFile video,
  void Function(List<String>, bool) onChanged,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: VideoUploadField(
        storage: storage,
        folder: 'products',
        pickVideo: () async => video,
        onChanged: onChanged,
      ),
    ),
  ),
);

void main() {
  testWidgets('upload video và trả về URL', (tester) async {
    final storage = _RecordingStorage();
    var urls = <String>[];
    await _pump(
      tester,
      storage,
      XFile.fromData(Uint8List(1024), name: 'phong.mp4'),
      (u, _) => urls = u,
    );

    await tester.tap(find.textContaining('Thêm video'));
    await tester.pumpAndSettle();

    expect(urls, ['https://cdn.test/videos/products/v.mp4']);
    expect(find.textContaining('Đã tải lên'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa video'));
    await tester.pump();
    expect(urls, isEmpty);
  });

  testWidgets('từ chối video quá 15 MB mà không gửi lên máy chủ', (
    tester,
  ) async {
    final storage = _RecordingStorage();
    await _pump(
      tester,
      storage,
      XFile.fromData(Uint8List(VideoUploadField.maxBytes + 1), name: 'dai.mp4'),
      (_, _) {},
    );

    await tester.tap(find.textContaining('Thêm video'));
    await tester.pumpAndSettle();

    expect(storage.calls, 0);
    expect(find.textContaining('vượt quá 15 MB'), findsOneWidget);
  });
}
