import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/services/xac_thuc_service.dart';
import '../models/gio_hang.dart';
import 'don_hang_service.dart';
import 'product_service.dart';

/// Mọi thứ module Shop đồ rẻ cần, gom lại để truyền cho các màn hình
/// (test thay bằng bản giả).
class ShopDichVu {
  const ShopDichVu({
    required this.uid,
    required this.products,
    required this.donHang,
    required this.gioHang,
    required this.storage,
    required this.xacThuc,
    this.pickImages,
    this.pickVideo,
  });

  final String uid;
  final ProductService products;
  final DonHangService donHang;
  final GioHang gioHang;
  final ImageStorageService storage;

  /// OTP số điện thoại (bắt buộc trước khi đăng bán).
  final XacThucService xacThuc;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  factory ShopDichVu.firebase() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return ShopDichVu(
      uid: uid,
      products: FirebaseProductService(),
      donHang: FirebaseDonHangService(uid: uid),
      gioHang: GioHang(uid: uid, luu: SharedPrefsLuuGioHang()),
      storage: FirebaseImageStorageService(),
      xacThuc: FirebaseXacThucService(),
    );
  }
}
