import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _moc(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Phiên thanh toán của một đơn món trên cổng GIẢ LẬP (kết quả `xemPhienThanhToan`).
/// Hệ thống chỉ ghi nhận "đã thanh toán" khi cổng báo về có chữ ký hợp lệ (mục 3.6).
class PhienThanhToan {
  const PhienThanhToan({
    required this.donId,
    required this.soTien,
    required this.trangThaiDon,
    this.tenQuan = '',
    this.trangThaiTien = 'cho_tra',
    this.hanThanhToan,
  });

  final String donId;
  final num soTien;
  final String tenQuan;

  /// Trạng thái đơn (`qa_don.status`): pending_payment | expired | placed | refunded ...
  final String trangThaiDon;

  /// Trạng thái tiền (`qa_khoan_tien`): cho_tra | dang_giu | da_hoan | het_han | that_bai ...
  final String trangThaiTien;
  final DateTime? hanThanhToan;

  bool get choThanhToan => trangThaiDon == 'pending_payment';
  bool get hetHan => trangThaiDon == 'expired';
  bool get daHoan => trangThaiDon == 'refunded';

  factory PhienThanhToan.fromMap(Map<String, dynamic> m) => PhienThanhToan(
    donId: m['donId'] as String? ?? '',
    soTien: (m['soTien'] ?? m['soTienVnd'] ?? m['tong']) as num? ?? 0,
    tenQuan: m['tenQuan'] as String? ?? '',
    trangThaiDon: (m['trangThaiDon'] ?? m['status']) as String? ?? '',
    trangThaiTien: m['trangThaiTien'] as String? ?? 'cho_tra',
    hanThanhToan: _moc(m['hanThanhToan']),
  );
}

/// Khoản tiền của đơn — collection `qa_khoan_tien/{donId}` (mục 3.6).
/// Trạng thái tiền tách khỏi trạng thái đơn.
class KhoanTien {
  const KhoanTien({
    required this.trangThai,
    required this.soTien,
    this.donId = '',
    this.lichSu = const [],
  });

  /// cho_tra | dang_giu | da_chuyen | da_hoan | hoan_mot_phan | het_han | that_bai
  final String trangThai;
  final num soTien;
  final String donId;
  final List<(String, DateTime)> lichSu;

  static const labels = {
    'cho_tra': 'Chờ trả',
    'dang_giu': 'App đang giữ',
    'da_chuyen': 'Đã chuyển cho chủ quán',
    'da_hoan': 'Đã hoàn cho sinh viên',
    'hoan_mot_phan': 'Đã hoàn một phần',
    'het_han': 'Hết hạn',
    'that_bai': 'Thất bại',
  };

  factory KhoanTien.fromMap(Map<String, dynamic> m) => KhoanTien(
    trangThai: m['trangThai'] as String? ?? 'cho_tra',
    soTien: (m['soTienVnd'] ?? m['soTien']) as num? ?? 0,
    donId: m['donId'] as String? ?? '',
    lichSu: [
      for (final x in m['lichSu'] as List? ?? const [])
        if (x is Map && _moc(x['luc']) != null)
          (x['trangThai'] as String? ?? '', _moc(x['luc'])!),
    ],
  );
}

/// Ví chủ quán trong module (chỉ để hiển thị): đang giữ, đã nhận — `qa_vi/{chuQuanId}`.
class ViChuQuan {
  const ViChuQuan({this.dangGiu = 0, this.daNhan = 0});

  final num dangGiu;
  final num daNhan;

  factory ViChuQuan.fromMap(Map<String, dynamic>? m) => ViChuQuan(
    dangGiu: m?['dangGiu'] as num? ?? 0,
    daNhan: m?['daNhan'] as num? ?? 0,
  );
}
