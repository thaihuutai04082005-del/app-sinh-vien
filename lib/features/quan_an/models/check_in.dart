import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';

/// Mã tài liệu check-in: `{svId}_{quanId}_{yyyyMMdd}` (ngày theo giờ Việt Nam; 1 lần / quán / ngày).
String maCheckIn(String svId, String quanId, DateTime now) {
  final v = gioVietNam(now);
  String h(int n) => n.toString().padLeft(2, '0');
  return '${svId}_${quanId}_${v.year}${h(v.month)}${h(v.day)}';
}

/// Check-in tại quán — collection `qa_check_in` (mục 3.4 Bước 3).
class CheckIn {
  const CheckIn({
    required this.id,
    required this.svId,
    required this.quanId,
    this.viTri,
    this.khoangCachM,
    this.anh = '',
    this.camNghi = '',
    this.congKhai = false,
    this.tinhHayAn = false,
    this.luc,
  });

  final String id;
  final String svId;
  final String quanId;
  final GeoPoint? viTri;
  final num? khoangCachM;
  final String anh;
  final String camNghi;
  final bool congKhai;

  /// Có được tính vào "Sinh viên hay ăn" không (hệ thống đặt).
  final bool tinhHayAn;
  final DateTime? luc;

  factory CheckIn.fromMap(String id, Map<String, dynamic> m) => CheckIn(
    id: id,
    svId: m['svId'] as String? ?? '',
    quanId: m['quanId'] as String? ?? '',
    viTri: m['viTri'] as GeoPoint?,
    khoangCachM: m['khoangCachM'] as num?,
    anh: m['anh'] as String? ?? '',
    camNghi: m['camNghi'] as String? ?? '',
    congKhai: m['congKhai'] as bool? ?? false,
    tinhHayAn: m['tinhHayAn'] as bool? ?? false,
    luc: (m['luc'] as Timestamp?)?.toDate(),
  );
}
