import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Nơi lưu ảnh. Giao diện chỉ phụ thuộc vào interface này nên có thể đổi
/// Cloudflare R2 sang Firebase Storage mà không phải sửa màn hình nào.
abstract interface class ImageStorageService {
  /// Upload ảnh vào [folder] (VD: `products`, `booking_xe`) và trả về URL công khai.
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  });
}

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Upload qua Cloudflare Worker (`cloudflare/image-api`), ảnh được lưu trên R2.
class CloudflareImageStorageService implements ImageStorageService {
  CloudflareImageStorageService({Uri? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? defaultApiBaseUrl,
      _client = client ?? http.Client();

  /// Ảnh tối đa 5 MB, video tối đa 25 MB (server kiểm tra lại theo loại file).
  static const maxBytes = 25 * 1024 * 1024;

  final Uri _baseUrl;
  final http.Client _client;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    if (bytes.length > maxBytes) {
      throw const ImageUploadException('File vượt quá 25 MB.');
    }

    final request =
        http.MultipartRequest('POST', _baseUrl.resolve('/api/upload'))
          ..fields['folder'] = folder
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } catch (_) {
      throw const ImageUploadException('Không kết nối được máy chủ.');
    }

    final body = decodeJsonObject(response.bodyBytes);
    if (response.statusCode != 200 || body['url'] is! String) {
      throw ImageUploadException(
        body['error'] as String? ?? 'Upload thất bại (${response.statusCode}).',
      );
    }
    return body['url'] as String;
  }
}
