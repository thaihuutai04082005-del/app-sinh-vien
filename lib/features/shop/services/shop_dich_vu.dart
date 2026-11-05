import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/services/callable_api.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/services/danh_gia_service.dart';
import '../../../shared/services/theo_doi_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/services/xac_thuc_service.dart';
import '../models/gio_hang.dart';
import 'don_hang_service.dart';
import 'product_service.dart';
import 'uu_dai_service.dart';

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
    required this.danhGia,
    required this.uuDai,
    required this.theoDoi,
    required this.chat,
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

  /// Đọc đánh giá shop / sản phẩm (viết đánh giá qua [donHang]).
  final DanhGiaService danhGia;

  /// Trả giá, voucher.
  final UuDaiService uuDai;

  /// Theo dõi shop, sản phẩm yêu thích.
  final TheoDoiService theoDoi;

  /// Chat người mua ↔ shop.
  final ChatService chat;
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
      danhGia: FirebaseDanhGiaService(),
      uuDai: FirebaseUuDaiService(uid: uid),
      theoDoi: FirebaseTheoDoiService(uid: uid),
      chat: FirebaseChatService(
        uid: uid,
        module: 'shop',
        api: FirebaseCallableApi('shopApi'),
      ),
    );
  }
}
