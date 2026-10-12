import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/services/xac_thuc_service.dart';
import 'admin_quan_an_service.dart';
import 'bao_cao_service.dart';
import 'chat_service.dart';
import 'check_in_service.dart';
import 'danh_gia_service.dart';
import 'dat_ban_service.dart';
import 'don_mon_service.dart';
import 'gio_hang_service.dart';
import 'khuyen_mai_service.dart';
import 'menu_service.dart';
import 'quan_an_api.dart';
import 'quan_an_service.dart';
import 'thong_bao_service.dart';

/// Mọi dịch vụ module Quán ăn cần, gom lại để truyền cho các màn hình
/// (test thay bằng bản giả, không màn hình nào gọi Firebase trực tiếp).
class QuanAnDichVu {
  const QuanAnDichVu({
    required this.uid,
    required this.quan,
    required this.menu,
    required this.khuyenMai,
    required this.gioHang,
    required this.donMon,
    required this.datBan,
    required this.checkIn,
    required this.chat,
    required this.danhGia,
    required this.baoCao,
    required this.thongBao,
    required this.admin,
    required this.xacThuc,
    required this.storage,
    this.pickImages,
    this.pickVideo,
  });

  final String uid;
  final QuanAnService quan;
  final MenuService menu;
  final KhuyenMaiService khuyenMai;
  final GioHangService gioHang;
  final DonMonService donMon;
  final DatBanService datBan;
  final CheckInService checkIn;
  final ChatService chat;
  final DanhGiaService danhGia;
  final BaoCaoService baoCao;
  final ThongBaoService thongBao;
  final AdminQuanAnService admin;
  final XacThucService xacThuc;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  factory QuanAnDichVu.firebase() {
    final api = FirebaseQuanAnApi();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return QuanAnDichVu(
      uid: uid,
      quan: FirebaseQuanAnService(api: api, uid: uid),
      menu: FirebaseMenuService(api: api, uid: uid),
      khuyenMai: FirebaseKhuyenMaiService(api: api, uid: uid),
      gioHang: GioHangService(),
      donMon: FirebaseDonMonService(api: api),
      datBan: FirebaseDatBanService(api: api),
      checkIn: FirebaseCheckInService(api: api),
      chat: FirebaseChatService(api: api),
      danhGia: FirebaseDanhGiaService(api: api),
      baoCao: FirebaseBaoCaoService(api: api),
      thongBao: FirebaseThongBaoService(),
      admin: FirebaseAdminQuanAnService(api: api),
      xacThuc: FirebaseXacThucService(),
      storage: FirebaseImageStorageService(),
    );
  }
}
