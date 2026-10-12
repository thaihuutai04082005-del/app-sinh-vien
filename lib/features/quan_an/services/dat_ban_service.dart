import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dat_ban.dart';
import 'quan_an_api.dart';

/// Đặt bàn (không thu tiền): gửi, theo dõi realtime, thao tác theo bảng 3.5j.
abstract interface class DatBanService {
  /// Gửi yêu cầu đặt bàn; trả về id lượt đặt bàn.
  Future<String> guiDatBan({
    required String quanId,
    required DateTime gio,
    required int soNguoi,
    String ghiChu = '',
  });

  Stream<DatBan?> datBan(String id);
  Stream<List<DatBan>> cuaSinhVien(String uid);
  Stream<List<DatBan>> cuaChuQuan(String uid);

  /// Số bàn đang chờ quán xác nhận (`pending`) của chủ quán.
  Stream<int> banChoXacNhan(String uid);

  /// `loai` ∈ QUAN_XAC_NHAN, QUAN_TU_CHOI, QUAN_HUY, QUAN_KHACH_DEN, QUAN_KHONG_DEN,
  /// SV_HUY, SV_CHECK_IN. `version` = phiên bản đang thấy.
  Future<void> thaoTac(String banId, int version, String loai);

  /// Mở lại: nhờ hệ thống xử lý các hạn đã tới.
  Future<void> xuLyHan(String banId);
}

class FirebaseDatBanService implements DatBanService {
  FirebaseDatBanService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<String> guiDatBan({
    required String quanId,
    required DateTime gio,
    required int soNguoi,
    String ghiChu = '',
  }) async {
    final r = await api.goi('datBan', {
      'quanId': quanId,
      'gio': gio.millisecondsSinceEpoch,
      'soNguoi': soNguoi,
      'ghiChu': ghiChu,
    });
    return (r['banId'] ?? r['id']) as String;
  }

  @override
  Stream<DatBan?> datBan(String id) => _f
      .collection('qa_dat_ban')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? DatBan.fromMap(s.id, s.data()!) : null);

  Stream<List<DatBan>> _theo(String truong, String uid) => _f
      .collection('qa_dat_ban')
      .where(truong, isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) DatBan.fromMap(d.id, d.data())]
              ..sort((a, b) => b.gio.compareTo(a.gio)),
      );

  @override
  Stream<List<DatBan>> cuaSinhVien(String uid) => _theo('svId', uid);

  @override
  Stream<List<DatBan>> cuaChuQuan(String uid) => _theo('chuQuanId', uid);

  @override
  Stream<int> banChoXacNhan(String uid) => _f
      .collection('qa_dat_ban')
      .where('chuQuanId', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.length);

  @override
  Future<void> thaoTac(String banId, int version, String loai) =>
      api.goi('thaoTacBan', {'banId': banId, 'version': version, 'loai': loai});

  @override
  Future<void> xuLyHan(String banId) => api.goi('xuLyHanBan', {'banId': banId});
}
