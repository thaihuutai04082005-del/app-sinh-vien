import 'package:cloud_firestore/cloud_firestore.dart';

/// Lần vi phạm của người dùng trong Quán ăn — collection `qa_vi_pham` (mục 3.5, 3.15).
class ViPham {
  const ViPham({
    required this.id,
    required this.loai,
    required this.luc,
    this.daGo = false,
  });

  final String id;
  final String loai;
  final DateTime luc;
  final bool daGo;

  static const loaiLabels = {
    'bo_hen_dat_ban': 'Bỏ hẹn đặt bàn',
    'bom_hang': 'Bom hàng (không nhận món)',
    'bao_cao_sai': 'Báo cáo sai bị bác bỏ',
    'khieu_nai_sai': 'Khiếu nại bị tính sai',
    'quan_cham_xac_nhan': 'Quán chậm xác nhận đơn / đặt bàn',
  };

  factory ViPham.fromMap(String id, Map<String, dynamic> m) => ViPham(
    id: id,
    loai: m['loai'] as String? ?? '',
    luc: (m['luc'] as Timestamp).toDate(),
    daGo: m['daGo'] as bool? ?? false,
  );
}

/// Kháng nghị — collection `qa_khang_nghi` (mục 3.15).
class KhangNghi {
  const KhangNghi({
    required this.id,
    required this.loaiQuyetDinh,
    required this.lyDo,
    required this.trangThai,
    this.ketQua,
    this.guiLuc,
  });

  final String id;
  final String loaiQuyetDinh;
  final String lyDo;

  /// 'cho_xu_ly' | 'da_xu_ly'
  final String trangThai;

  /// 'go_khoa' | 'giu_nguyen' | 'xoa_vi_pham'
  final String? ketQua;
  final DateTime? guiLuc;

  static const ketQuaLabels = {
    'go_khoa': 'Đã gỡ khóa',
    'giu_nguyen': 'Giữ nguyên quyết định',
    'xoa_vi_pham': 'Đã xóa lần vi phạm',
  };

  factory KhangNghi.fromMap(String id, Map<String, dynamic> m) => KhangNghi(
    id: id,
    loaiQuyetDinh: (m['quyetDinh'] as Map?)?['loai'] as String? ?? '',
    lyDo: m['lyDo'] as String? ?? '',
    trangThai: m['trangThai'] as String? ?? 'cho_xu_ly',
    ketQua: m['ketQua'] as String?,
    guiLuc: (m['guiLuc'] as Timestamp?)?.toDate(),
  );
}
