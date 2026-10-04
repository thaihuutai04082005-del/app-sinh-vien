import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unihub_student_app/core/services/api_client.dart';

http.Response _json(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  test('list, create gọi đúng đường dẫn collection', () async {
    final calls = <String>[];
    final api = ApiClient(
      baseUrl: Uri.parse('https://unihub.example/'),
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'POST') {
          return _json({'id': 'x', ...jsonDecode(request.body) as Map}, 201);
        }
        return _json({
          'items': [
            {'id': 'a'},
          ],
        }, 200);
      }),
    );

    expect(await api.list('products'), [
      {'id': 'a'},
    ]);
    expect((await api.create('products', {'name': 'Áo'}))['name'], 'Áo');
    expect(calls, ['GET /api/products', 'POST /api/products']);
  });

  test('ném ApiException với thông báo của máy chủ', () async {
    final api = ApiClient(
      baseUrl: Uri.parse('https://unihub.example/'),
      client: MockClient(
        (_) async => _json({'error': 'Trường "name" không hợp lệ.'}, 400),
      ),
    );

    expect(
      api.create('products', {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Trường "name" không hợp lệ.',
        ),
      ),
    );
  });
}
