import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unihub_student_app/core/services/image_storage_service.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('gửi multipart tới /api/upload và trả về URL ảnh', () async {
    late http.Request sent;
    final service = CloudflareImageStorageService(
      baseUrl: Uri.parse('https://unihub.example/app/'),
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({'url': 'https://unihub.example/images/products/a.jpg'}),
          200,
        );
      }),
    );

    final url = await service.upload(
      bytes: bytes,
      fileName: 'a.jpg',
      folder: 'products',
    );

    expect(url, 'https://unihub.example/images/products/a.jpg');
    expect(sent.url.toString(), 'https://unihub.example/api/upload');
    expect(sent.headers['content-type'], startsWith('multipart/form-data'));
    expect(sent.body, contains('name="folder"'));
    expect(sent.body, contains('products'));
  });

  test('báo lỗi của máy chủ bằng tiếng Việt', () async {
    final service = CloudflareImageStorageService(
      baseUrl: Uri.parse('https://unihub.example/'),
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({'error': 'Chỉ chấp nhận ảnh JPG, PNG, WEBP, GIF.'}),
          ),
          415,
        ),
      ),
    );

    expect(
      service.upload(bytes: bytes, fileName: 'a.txt', folder: 'products'),
      throwsA(
        isA<ImageUploadException>().having(
          (e) => e.message,
          'message',
          'Chỉ chấp nhận ảnh JPG, PNG, WEBP, GIF.',
        ),
      ),
    );
  });

  test('chặn file lớn hơn 25 MB trước khi gửi', () async {
    var called = false;
    final service = CloudflareImageStorageService(
      baseUrl: Uri.parse('https://unihub.example/'),
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.upload(
        bytes: Uint8List(CloudflareImageStorageService.maxBytes + 1),
        fileName: 'big.jpg',
        folder: 'products',
      ),
      throwsA(isA<ImageUploadException>()),
    );
    expect(called, isFalse);
  });
}
