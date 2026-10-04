import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'daily_quota.dart';

/// Nơi lưu ảnh. Giao diện chỉ phụ thuộc vào interface này nên có thể đổi
/// nơi lưu mà không phải sửa màn hình nào.
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

/// Upload lên Firebase Storage, chỉ lưu URL trả về vào Firestore (mục 7.4.5).
/// Giới hạn dung lượng và loại file được kiểm tra lại trong `storage.rules`.
class FirebaseImageStorageService implements ImageStorageService {
  FirebaseImageStorageService({this._storage, DailyQuota? quota})
    : _quota = quota ?? DailyQuota();

  static const maxImageBytes = 5 * 1024 * 1024;
  static const maxVideoBytes = 15 * 1024 * 1024;

  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
  };

  final FirebaseStorage? _storage;
  final DailyQuota _quota;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = _contentTypes[ext];
    if (contentType == null) {
      throw const ImageUploadException(
        'Chỉ chấp nhận ảnh JPG, PNG, WEBP, GIF hoặc video MP4, MOV, WEBM.',
      );
    }
    final isVideo = contentType.startsWith('video/');
    if (bytes.length > (isVideo ? maxVideoBytes : maxImageBytes)) {
      throw ImageUploadException(
        isVideo ? 'Video vượt quá 15 MB.' : 'Ảnh vượt quá 5 MB.',
      );
    }

    final String path;
    try {
      path = await _quota.reserveUploadPath(folder, ext);
    } on QuotaException catch (e) {
      throw ImageUploadException(e.message);
    } on FirebaseException catch (e) {
      throw ImageUploadException('Upload thất bại (${e.code}).');
    }
    final ref = (_storage ?? FirebaseStorage.instance).ref(path);
    try {
      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000, immutable',
      );
      try {
        await ref.putData(bytes, metadata);
      } on FirebaseException catch (e) {
        // Lượt upload đầu tiên ngay sau khi vừa đăng nhập ẩn danh đôi khi bị
        // từ chối; thử lại 1 lần với cùng tên file đã giữ chỗ.
        if (e.code != 'unauthorized') rethrow;
        await Future<void>.delayed(const Duration(seconds: 2));
        await ref.putData(bytes, metadata);
      }
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ImageUploadException('Upload thất bại (${e.code}).');
    }
  }

}
