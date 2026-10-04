import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

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
  FirebaseImageStorageService({this._storage});

  static const maxImageBytes = 5 * 1024 * 1024;
  static const maxVideoBytes = 25 * 1024 * 1024;

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
        isVideo ? 'Video vượt quá 25 MB.' : 'Ảnh vượt quá 5 MB.',
      );
    }

    final ref = (_storage ?? FirebaseStorage.instance).ref(
      '$folder/${_randomId()}.$ext',
    );
    try {
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ImageUploadException('Upload thất bại (${e.code}).');
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(
      20,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
  }
}
