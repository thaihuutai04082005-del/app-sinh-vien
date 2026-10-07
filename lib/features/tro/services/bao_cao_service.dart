import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/khang_nghi.dart';
import 'tro_api.dart';

/// Báo cáo vi phạm (mục 2.10), vi phạm và kháng nghị (mục 2.5e, 2.15) của Tìm trọ.
abstract interface class BaoCaoService {
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu,
    List<String> tieuChiSai,
    DateTime? thoiDiemXayRa,
    String? datCocId,
  });
  Stream<List<ViPham>> viPhamCuaToi(String uid);
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid);
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

  final TroApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu = '',
    List<String> tieuChiSai = const [],
    DateTime? thoiDiemXayRa,
    String? datCocId,
  }) => api.goi('guiBaoCao', {
    'doiTuong': {'loai': loai, 'id': id, 'chatId': ?chatId},
    'lyDo': lyDo,
    'ghiChu': ghiChu,
    'tieuChiSai': tieuChiSai,
    if (thoiDiemXayRa != null)
      'thoiDiemXayRa': thoiDiemXayRa.millisecondsSinceEpoch,
    'datCocId': ?datCocId,
  });

  @override
  Stream<List<ViPham>> viPhamCuaToi(String uid) => _f
      .collection('tro_vi_pham')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) ViPham.fromMap(d.id, d.data())]
              ..sort((a, b) => b.luc.compareTo(a.luc)),
      );

  @override
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid) => _f
      .collection('tro_khang_nghi')
      .where('nguoiGui', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) KhangNghi.fromMap(d.id, d.data())]);

  @override
  Stream<Map<String, DateTime?>> khoaCuaToi(String khoa) =>
      _f.collection('tro_khoa').doc(khoa).snapshots().map((s) {
        final m = s.data() ?? const {};
        DateTime? t(String k) => (m[k] as Timestamp?)?.toDate();
        return {
          'khoaCocDen': t('khoaCocDen'),
          'khoaBaoCaoDen': t('khoaBaoCaoDen'),
          'khoaDangTinDen': t('khoaDangTinDen'),
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
