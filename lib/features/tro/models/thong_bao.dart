import 'package:cloud_firestore/cloud_firestore.dart';

/// Thông báo riêng của Tìm trọ — collection `tro_thong_bao` (mục 2.11).
class ThongBao {
  const ThongBao({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.nhom,
    this.moTrang,
    this.taoLuc,
    this.docLuc,
  });

  final String id;
  final String tieuDe;
  final String noiDung;
  final String nhom;
  final Map<String, dynamic>? moTrang;
  final DateTime? taoLuc;
  final DateTime? docLuc;

  bool get daDoc => docLuc != null;

  factory ThongBao.fromMap(String id, Map<String, dynamic> m) => ThongBao(
    id: id,
    tieuDe: m['tieuDe'] as String? ?? '',
    noiDung: m['noiDung'] as String? ?? '',
    nhom: m['nhom'] as String? ?? '',
    moTrang: (m['moTrang'] as Map?)?.cast<String, dynamic>(),
    taoLuc: (m['taoLuc'] as Timestamp?)?.toDate(),
    docLuc: (m['docLuc'] as Timestamp?)?.toDate(),
  );
}

/// Nhóm thông báo; nhóm `khoa` không tắt được (tiền cọc, nhận phòng, yêu cầu thay đổi, khiếu nại, kháng nghị).
const nhomThongBao = <(String, String, bool)>[
  ('giao_dich', 'Tiền cọc và nhận phòng', true),
  ('khieu_nai', 'Khiếu nại', true),
  ('khang_nghi', 'Kháng nghị và vi phạm', true),
  ('tin_nhan', 'Tin nhắn', false),
  ('nha_tro_da_luu', 'Nhà trọ đã lưu có phòng trống / giảm giá', false),
  ('danh_gia', 'Nhắc đánh giá, đánh giá mới', false),
  ('quan_ly_tin', 'Duyệt tin, tin sắp hết hạn', false),
  ('bao_cao', 'Kết quả báo cáo', false),
];
