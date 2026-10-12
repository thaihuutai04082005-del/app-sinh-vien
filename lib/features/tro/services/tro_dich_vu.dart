import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/services/xac_thuc_service.dart';
import 'admin_service.dart';
import 'bao_cao_service.dart';
import 'chat_service.dart';
import 'coc_truc_tiep_service.dart';
import 'danh_gia_service.dart';
import 'dat_coc_service.dart';
import 'nha_tro_service.dart';
import 'thong_bao_service.dart';
import 'tro_api.dart';

/// Mọi dịch vụ module Tìm trọ cần, gom lại để truyền cho các màn hình
/// (test thay bằng bản giả, không màn hình nào gọi Firebase trực tiếp).
class TroDichVu {
  const TroDichVu({
    required this.uid,
    required this.nhaTro,
    required this.datCoc,
    required this.cocTrucTiep,
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
  final NhaTroService nhaTro;
  final DatCocService datCoc;
  final CocTrucTiepService cocTrucTiep;
  final ChatService chat;
  final DanhGiaService danhGia;
  final BaoCaoService baoCao;
  final ThongBaoService thongBao;
  final AdminTroService admin;
  final XacThucService xacThuc;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  factory TroDichVu.firebase() {
    final api = FirebaseTroApi();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return TroDichVu(
      uid: uid,
      nhaTro: FirebaseNhaTroService(api: api, uid: uid),
      datCoc: FirebaseDatCocService(api: api),
      cocTrucTiep: FirebaseCocTrucTiepService(api: api),
      chat: FirebaseChatService(api: api),
      danhGia: FirebaseDanhGiaService(api: api),
      baoCao: FirebaseBaoCaoService(api: api),
      thongBao: FirebaseThongBaoService(),
      admin: FirebaseAdminTroService(api: api),
      xacThuc: FirebaseXacThucService(),
      storage: FirebaseImageStorageService(),
    );
  }
}
