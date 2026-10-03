import 'dart:convert';

import 'package:http/http.dart' as http;

/// Truyền `--dart-define=API_URL=https://...` khi API nằm ở domain khác.
/// Mặc định gọi cùng domain với web app (Worker phục vụ cả app lẫn API).
Uri get defaultApiBaseUrl {
  const configured = String.fromEnvironment('API_URL');
  return configured.isEmpty ? Uri.base : Uri.parse(configured);
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gọi REST API của Cloudflare Worker (`cloudflare/src/index.js`).
/// Mỗi collection tương ứng 1 collection Firestore trong mục 7.3.
class ApiClient {
  ApiClient({Uri? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? defaultApiBaseUrl,
      _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  Future<List<Map<String, dynamic>>> list(String collection) async {
    final body = await _send(() => _client.get(_uri('/api/$collection')));
    return (body['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> get(String collection, String id) =>
      _send(() => _client.get(_uri('/api/$collection/$id')));

  Future<Map<String, dynamic>> create(
    String collection,
    Map<String, dynamic> data,
  ) => _send(
    () => _client.post(
      _uri('/api/$collection'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ),
  );

  Uri _uri(String path) => baseUrl.resolve(path);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request();
    } catch (_) {
      throw const ApiException('Không kết nối được máy chủ.');
    }
    final body = decodeJsonObject(response.bodyBytes);
    if (response.statusCode >= 300) {
      throw ApiException(
        body['error'] as String? ?? 'Lỗi máy chủ (${response.statusCode}).',
      );
    }
    return body;
  }
}

Map<String, dynamic> decodeJsonObject(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}
