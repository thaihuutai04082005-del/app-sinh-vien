import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Cọc trực tiếp ngoài app — collection `tro_coc_truc_tiep` (mục 2.5d).
/// App không giữ, không hoàn tiền của khoản này; chỉ ghi nhận để phòng không bị cọc 2 lần.
class CocTrucTiep {
  const CocTrucTiep({
    required this.id,
    required this.phongId,
    required this.nhaTroId,
    required this.chuTroId,
    required this.tenPhong,
    required this.ngayNhanDuKien,
    required this.ketQua,
    this.sdtNguoiCoc,
    this.xacNhanLuc,
    this.daChoThueLuc,
    this.hanXacNhanDaThue,
    this.nguoiCocXacNhanLuc,
  });

  final String id;
  final String phongId;
  final String nhaTroId;
  final String chuTroId;
  final String tenPhong;
  final DateTime ngayNhanDuKien;

  /// 'dang_cho' | 'da_cho_thue' | 'khong_thue'
  final String ketQua;
  final String? sdtNguoiCoc;
  final DateTime? xacNhanLuc;
  final DateTime? daChoThueLuc;
  final DateTime? hanXacNhanDaThue;
  final DateTime? nguoiCocXacNhanLuc;

  static const ketQuaLabels = {
    'dang_cho': 'Chờ nhận phòng',
    'da_cho_thue': 'Đã cho thuê',
    'khong_thue': 'Người cọc không thuê nữa',
  };

  bool get dangCho => ketQua == 'dang_cho';

  bool coXacNhanDaThue(DateTime now) =>
      ketQua == 'da_cho_thue' &&
      nguoiCocXacNhanLuc == null &&
      hanXacNhanDaThue != null &&
      now.isBefore(hanXacNhanDaThue!);

  factory CocTrucTiep.fromMap(String id, Map<String, dynamic> m) => CocTrucTiep(
    id: id,
    phongId: m['phongId'] as String? ?? '',
    nhaTroId: m['nhaTroId'] as String? ?? '',
    chuTroId: m['chuTroId'] as String? ?? '',
    tenPhong: m['tenPhong'] as String? ?? '',
    ngayNhanDuKien: _t(m['ngayNhanDuKien']) ?? DateTime.now(),
    ketQua: m['ketQua'] as String? ?? 'dang_cho',
    sdtNguoiCoc: m['sdtNguoiCoc'] as String?,
    xacNhanLuc: _t(m['xacNhanLuc']),
    daChoThueLuc: _t(m['daChoThueLuc']),
    hanXacNhanDaThue: _t(m['hanXacNhanDaThue']),
    nguoiCocXacNhanLuc: _t(m['nguoiCocXacNhanLuc']),
  );
}
