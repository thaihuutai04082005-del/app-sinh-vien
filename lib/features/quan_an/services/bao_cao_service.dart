import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/khang_nghi.dart';
import 'quan_an_api.dart';

/// Lý do báo cáo của Quán ăn (mục 3.5h + lý do chung): mã → nhãn.
const lyDoBaoCao = {
  'quan_khong_ton_tai': 'Quán không tồn tại / đã đóng',
  'sai_gio': 'Sai giờ mở cửa',
  'sai_gia': 'Sai giá',
  'khuyen_mai_sai': 'Khuyến mãi không đúng thực tế',
  'khai_sai_loai': 'Khai sai loại hình',
  'mat_ve_sinh': 'Mất vệ sinh an toàn thực phẩm',
  'chuyen_khoan_ngoai_app': 'Yêu cầu chuyển khoản ngoài app',
  'lua_dao': 'Lừa đảo',
  'xuc_pham': 'Xúc phạm / lộ thông tin cá nhân',
  'spam': 'Spam',
  'khac': 'Khác',
};

/// Lý do ưu tiên cao (mục 3.5h): admin kiểm tra sớm.
const lyDoUuTienCao = {'mat_ve_sinh', 'chuyen_khoan_ngoai_app', 'lua_dao'};

/// Báo cáo vi phạm (mục 3.10), vi phạm và kháng nghị (mục 3.15) của Quán ăn.
abstract interface class BaoCaoService {
  /// [loai]: 'quan' | 'mon' | 'nguoi_dung' | 'danh_gia' | 'tin_nhan'.
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu,
  });
  Stream<List<ViPham>> viPhamCuaToi(String uid);
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid);

  /// Các khóa chức năng còn hiệu lực của tôi (`qa_khoa/{khoa}`, khóa = số điện thoại hoặc uid):
  /// `khoaDatMonDen`, `khoaDatBanDen`, `khoaTienMatDen`, `khoaBaoCaoDen`, `khoaDatMonAppDen`.
  Stream<Map<String, DateTime?>> khoaCuaToi(String khoa);
  Future<void> khangNghi({
    required String loai,
    required String id,
    String? col,
    required String lyDo,
    List<String> bangChung,
  });
}

class FirebaseBaoCaoService implements BaoCaoService {
  FirebaseBaoCaoService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu = '',
  }) => api.goi('guiBaoCao', {
    'doiTuong': {'loai': loai, 'id': id, 'chatId': ?chatId},
    'lyDo': lyDo,
    'ghiChu': ghiChu,
  });

  @override
  Stream<List<ViPham>> viPhamCuaToi(String uid) => _f
      .collection('qa_vi_pham')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) ViPham.fromMap(d.id, d.data())]
              ..sort((a, b) => b.luc.compareTo(a.luc)),
      );

  @override
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid) => _f
      .collection('qa_khang_nghi')
      .where('nguoiGui', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) KhangNghi.fromMap(d.id, d.data())]);

  @override
  Stream<Map<String, DateTime?>> khoaCuaToi(String khoa) =>
      _f.collection('qa_khoa').doc(khoa).snapshots().map((s) {
        final m = s.data() ?? const {};
        DateTime? t(String k) => (m[k] as Timestamp?)?.toDate();
        return {
          'khoaDatMonDen': t('khoaDatMonDen'),
          'khoaDatBanDen': t('khoaDatBanDen'),
          'khoaTienMatDen': t('khoaTienMatDen'),
          'khoaBaoCaoDen': t('khoaBaoCaoDen'),
          'khoaDatMonAppDen': t('khoaDatMonAppDen'),
        };
      });

  @override
  Future<void> khangNghi({
    required String loai,
    required String id,
    String? col,
    required String lyDo,
    List<String> bangChung = const [],
  }) => api.goi('guiKhangNghi', {
    'quyetDinh': {'loai': loai, 'id': id, 'col': ?col},
    'lyDo': lyDo,
    'bangChung': bangChung,
  });
}
