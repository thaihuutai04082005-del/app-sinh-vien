import 'package:cloud_firestore/cloud_firestore.dart';

/// Khoản tiền của khoản cọc — collection `tro_khoan_tien` (mục 2.6).
/// Trạng thái tiền tách khỏi trạng thái giao dịch.
class KhoanTien {
  const KhoanTien({
    required this.trangThai,
    required this.soTien,
    this.lichSu = const [],
  });

  /// cho_tra | dang_giu | da_chuyen | da_hoan | het_han | that_bai
  final String trangThai;
  final num soTien;
  final List<(String, DateTime)> lichSu;

  static const labels = {
    'cho_tra': 'Chờ trả',
    'dang_giu': 'App đang giữ',
    'da_chuyen': 'Đã chuyển cho chủ trọ',
    'da_hoan': 'Đã hoàn cho sinh viên',
    'het_han': 'Hết hạn',
    'that_bai': 'Thất bại',
  };

  factory KhoanTien.fromMap(Map<String, dynamic> m) => KhoanTien(
    trangThai: m['trangThai'] as String? ?? 'cho_tra',
    soTien: m['soTienVnd'] as num? ?? 0,
    lichSu: [
      for (final x in m['lichSu'] as List? ?? const [])
        if (x is Map)
          (x['trangThai'] as String? ?? '', (x['luc'] as Timestamp).toDate()),
    ],
  );
}

/// Ví chủ trọ trong module (chỉ để hiển thị): đang giữ, đã nhận.
class ViChuTro {
  const ViChuTro({this.dangGiu = 0, this.daNhan = 0});

  final num dangGiu;
  final num daNhan;

  factory ViChuTro.fromMap(Map<String, dynamic>? m) => ViChuTro(
    dangGiu: m?['dangGiu'] as num? ?? 0,
    daNhan: m?['daNhan'] as num? ?? 0,
  );
}
