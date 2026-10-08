import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dat_coc.dart';
import '../models/thanh_toan.dart';
import '../models/tro_config.dart';
import 'tro_api.dart';

/// Thông tin hiện ở màn hình đặt cọc: số lần hủy miễn phí còn lại, khóa cọc.
class ThongTinDatCoc {
  const ThongTinDatCoc({required this.conHuyMienPhi, this.khoaCocDen});

  final int conHuyMienPhi;
  final DateTime? khoaCocDen;
}

/// Khoản cọc trên app: tạo, thao tác theo bảng 2.5h, theo dõi realtime.
abstract interface class DatCocService {
  Future<TroConfig> cauHinh();
  Future<ThongTinDatCoc> thongTin();
  Future<String> taoCoc({required String phongId, required DateTime t});
  Stream<DatCoc?> datCoc(String id);
  Stream<List<DatCoc>> cuaSinhVien(String uid);
  Stream<List<DatCoc>> cuaChuTro(String uid);
  Stream<KhoanTien?> khoanTien(String datCocId);
  Stream<ViChuTro> vi(String uid);

  /// Mở lại khoản cọc: nhờ hệ thống xử lý các hạn đã tới (thấy đúng trạng thái sau hạn).
  Future<void> xuLyHan(String datCocId);

  /// `su` = { loai: 'SV_HUY' | ..., ...tham số }. `version` = phiên bản đang thấy.
  Future<void> thaoTac(String datCocId, int version, Map<String, dynamic> su);

  /// Cổng thanh toán giả lập: 'thanh_cong' | 'that_bai'.
  Future<void> thanhToan(String datCocId, String ketQua);
}

class FirebaseDatCocService implements DatCocService {
  FirebaseDatCocService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;
  TroConfig? _cfg;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<TroConfig> cauHinh() async {
    if (_cfg != null) return _cfg!;
    try {
      _cfg = TroConfig.fromMap(await api.goi('cauHinh'));
    } catch (_) {
      _cfg = const TroConfig();
    }
    return _cfg!;
  }

  @override
  Future<ThongTinDatCoc> thongTin() async {
    final r = await api.goi('thongTinDatCoc');
    final khoa = r['khoaCocDen'] as num?;
    return ThongTinDatCoc(
      conHuyMienPhi: (r['conHuyMienPhi'] as num?)?.toInt() ?? 0,
      khoaCocDen: khoa == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(khoa.toInt()),
    );
  }

  @override
  Future<String> taoCoc({required String phongId, required DateTime t}) async {
    final r = await api.goi('taoCoc', {
      'phongId': phongId,
      't': t.millisecondsSinceEpoch,
      'dongYChinhSach': true,
      'dongYDieuKhoan': true,
    });
    return r['datCocId'] as String;
  }

  @override
  Stream<DatCoc?> datCoc(String id) => _f
      .collection('tro_dat_coc')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? DatCoc.fromMap(s.id, s.data()!) : null);

  Stream<List<DatCoc>> _theo(String truong, String uid) => _f
      .collection('tro_dat_coc')
      .where(truong, isEqualTo: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) DatCoc.fromMap(d.id, d.data())]
          ..sort(
            (a, b) =>
                (b.taoLuc ?? DateTime(0)).compareTo(a.taoLuc ?? DateTime(0)),
          ),
      );

  @override
  Stream<List<DatCoc>> cuaSinhVien(String uid) => _theo('sinhVienId', uid);

  @override
  Stream<List<DatCoc>> cuaChuTro(String uid) => _theo('chuTroId', uid);

  @override
  Stream<KhoanTien?> khoanTien(String datCocId) => _f
      .collection('tro_khoan_tien')
      .doc(datCocId)
      .snapshots()
      .map((s) => s.exists ? KhoanTien.fromMap(s.data()!) : null);

  @override
  Stream<ViChuTro> vi(String uid) => _f
      .collection('tro_vi')
      .doc(uid)
      .snapshots()
      .map((s) => ViChuTro.fromMap(s.data()));

  @override
  Future<void> xuLyHan(String datCocId) =>
      api.goi('xuLyHanCoc', {'datCocId': datCocId});

  @override
  Future<void> thaoTac(String datCocId, int version, Map<String, dynamic> su) =>
      api.goi('thaoTacCoc', {
        'datCocId': datCocId,
        'version': version,
        'su': su,
      });

  @override
  Future<void> thanhToan(String datCocId, String ketQua) =>
      api.goi('thanhToanGiaLap', {'datCocId': datCocId, 'ketQua': ketQua});
}
