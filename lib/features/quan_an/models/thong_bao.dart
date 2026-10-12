import 'package:cloud_firestore/cloud_firestore.dart';

/// Thông báo riêng của Quán ăn — collection `qa_thong_bao` (mục 3.11).
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

  /// `{loai: 'quan'|'don'|'dat_ban'|'chat'|'khang_nghi'|'danh_gia', id}`
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

/// Nhóm thông báo: (mã, tên, khóa?). Nhóm khóa không tắt được: tiền, đơn hàng, đặt bàn, khiếu nại, kháng nghị (mục 3.11).
const nhomThongBao = <(String, String, bool)>[
  ('giao_dich', 'Tiền và thanh toán', true),
  ('don_hang', 'Đơn món', true),
  ('dat_ban', 'Đặt bàn', true),
  ('khieu_nai', 'Khiếu nại', true),
  ('khang_nghi', 'Kháng nghị và vi phạm', true),
  ('tin_nhan', 'Tin nhắn', false),
  ('quan_da_luu', 'Quán đã lưu có khuyến mãi / mở lại', false),
  ('danh_gia', 'Đánh giá mới', false),
  ('nhac_danh_gia', 'Nhắc đánh giá', false),
];
