import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/services/xac_thuc_service.dart';
import 'xe_service.dart';

/// Mọi thứ module Xe dọn trọ cần, gom lại để truyền cho các màn hình
/// (test thay bằng bản giả).
class XeDichVu {
  const XeDichVu({
    required this.uid,
    required this.xe,
    required this.storage,
    required this.xacThuc,
    this.pickImages,
    this.pickVideo,
  });

  final String uid;
  final XeService xe;
  final ImageStorageService storage;

  /// OTP, danh tính, quyền admin (dùng chung toàn app).
  final XacThucService xacThuc;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  factory XeDichVu.firebase() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return XeDichVu(
      uid: uid,
      xe: FirebaseXeService(uid: uid),
      storage: FirebaseImageStorageService(),
      xacThuc: FirebaseXacThucService(),
    );
  }
}
