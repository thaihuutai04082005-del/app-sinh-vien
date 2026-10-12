import 'package:cloud_firestore/cloud_firestore.dart';

/// Lần vi phạm / khóa / kháng nghị trong Tìm trọ (mục 2.5e, 2.15).
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
    'huy_coc': 'Chủ trọ hủy cọc',
    'khong_tra_loi_doi': 'Không trả lời yêu cầu thay đổi trong 24 giờ',
    'khieu_nai_chap_nhan': 'Khiếu nại của sinh viên được chấp nhận',
    'noi_quy_sai': 'Nội quy sai tại thời điểm giao dịch',
    'bao_cao_hop_le': 'Báo cáo vi phạm được xác nhận',
  };

  factory ViPham.fromMap(String id, Map<String, dynamic> m) => ViPham(
    id: id,
    loai: m['loai'] as String? ?? '',
    luc: (m['luc'] as Timestamp).toDate(),
    daGo: m['daGo'] as bool? ?? false,
  );
}

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
