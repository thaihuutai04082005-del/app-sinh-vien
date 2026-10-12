import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// 4 tiêu chí chấm sao 1–5, bắt buộc đủ cả 4 (mục 3.9): (mã, nhãn).
const tieuChiDanhGia = <(String, String)>[
  ('monAn', 'Món ăn'),
  ('giaCa', 'Giá cả'),
  ('veSinh', 'Vệ sinh'),
  ('phucVu', 'Phục vụ'),
];

final tieuChiDanhGiaLabels = {for (final (k, v) in tieuChiDanhGia) k: v};

/// Thẻ nhanh (mục 3.9): (mã, nhãn, tích cực?). Mã trùng với backend `qa_danh_gia.the[]`.
const theNhanhDanhGia = <(String, String, bool)>[
  ('mon_ngon', 'Món ngon', true),
  ('phuc_vu_nhanh', 'Phục vụ nhanh', true),
  ('gia_hop_ly', 'Giá hợp lý', true),
  ('phan_an_nhieu', 'Phần ăn nhiều', true),
  ('sach_se', 'Sạch sẽ', true),
  ('hop_hoc_nhom', 'Hợp học nhóm', true),
  ('cho_lau', 'Chờ lâu', false),
  ('gia_cao', 'Giá cao', false),
  ('on_ao', 'Ồn ào', false),
  ('it_cho_ngoi', 'Ít chỗ ngồi', false),
];

final theNhanhDanhGiaLabels = {for (final (k, v, _) in theNhanhDanhGia) k: v};

/// Đủ cả 4 tiêu chí, mỗi tiêu chí 1–5 sao.
bool duBonTieuChi(Map<String, int> diem) => tieuChiDanhGia.every((e) {
  final d = diem[e.$1];
  return d != null && d >= 1 && d <= 5;
});

/// Điểm tổng thể của một đánh giá = trung bình 4 tiêu chí (mục 3.9). Thiếu tiêu chí thì trả 0.
/// Người viết không nhập điểm tổng riêng; hệ thống cũng tính lại khi lưu.
double tinhDiemTong(Map<String, int> diem) {
  if (!duBonTieuChi(diem)) return 0;
  final tong = tieuChiDanhGia.fold<int>(0, (s, e) => s + diem[e.$1]!);
  return tong / tieuChiDanhGia.length;
}

/// Đánh giá quán — collection `qa_danh_gia`, id `{svId}_{quanId}` (mỗi người 1 đánh giá / quán; mục 3.9).
class DanhGia {
  const DanhGia({
    required this.id,
    required this.quanId,
    required this.nguoiViet,
    required this.diemTong,
    this.tenNguoiViet = '',
    this.nhan,
    this.tinhDiem = false,
    this.diem = const {},
    this.the = const [],
    this.nhanXet = '',
    this.anh = const [],
    this.chuTraLoi,
    this.chuTraLoiLuc,
    this.daCapNhat = false,
    this.hienThi = 'hien',
    this.capNhatLuc,
  });

  final String id;
  final String quanId;

  /// uid sinh viên (`svId`).
  final String nguoiViet;
  final double diemTong;
  final String tenNguoiViet;

  /// 'dat_mon' | 'dat_ban' | 'check_in' | null (Chưa xác minh)
  final String? nhan;
  final bool tinhDiem;

  /// `{monAn, giaCa, veSinh, phucVu}` mỗi tiêu chí 1–5.
  final Map<String, int> diem;
  final List<String> the;
  final String nhanXet;
  final List<String> anh;
  final String? chuTraLoi;
  final DateTime? chuTraLoiLuc;
  final bool daCapNhat;

  /// `trangThaiHienThi`: 'hien' | 'an_tam' | 'an'
  final String hienThi;
  final DateTime? capNhatLuc;

  /// Nhãn xác minh: 🛵 Đã đặt món · 🍽 Đã đến theo đặt bàn · 📍 Check-in tại quán.
  String get nhanLabel => switch (nhan) {
    'dat_mon' => '🛵 Đã đặt món',
    'dat_ban' => '🍽 Đã đến theo đặt bàn',
    'check_in' => '📍 Check-in tại quán',
    _ => 'Chưa xác minh',
  };

  factory DanhGia.fromMap(String id, Map<String, dynamic> m) {
    final diem = {
      for (final e in ((m['diem'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as num).toInt(),
    };
    final tra = m['chuTraLoi'];
    return DanhGia(
      id: id,
      quanId: m['quanId'] as String? ?? '',
      nguoiViet: m['svId'] as String? ?? '',
      diemTong: (m['diemTong'] as num?)?.toDouble() ?? tinhDiemTong(diem),
      tenNguoiViet: m['tenNguoiViet'] as String? ?? '',
      nhan: m['nhan'] as String?,
      tinhDiem: m['tinhDiem'] as bool? ?? false,
      diem: diem,
      the: List<String>.from(m['the'] as List? ?? const []),
      nhanXet: m['nhanXet'] as String? ?? '',
      anh: List<String>.from(m['anh'] as List? ?? const []),
      chuTraLoi: tra is Map ? tra['noiDung'] as String? : tra as String?,
      chuTraLoiLuc: tra is Map ? _t(tra['luc']) : null,
      daCapNhat: m['daCapNhat'] as bool? ?? false,
      hienThi: m['trangThaiHienThi'] as String? ?? 'hien',
      capNhatLuc: _t(m['capNhatLuc']) ?? _t(m['taoLuc']),
    );
  }
}

/// Đánh giá có nhãn (tính điểm) lên trước, "Chưa xác minh" hiện riêng, màu nhạt, xếp sau (mục 3.4 Bước 6).
List<DanhGia> sapXepDanhGia(List<DanhGia> ds) {
  final hien = ds.where((d) => d.hienThi != 'an').toList();
  hien.sort((a, b) {
    if (a.tinhDiem != b.tinhDiem) return a.tinhDiem ? -1 : 1;
    return (b.capNhatLuc ?? DateTime(0)).compareTo(a.capNhatLuc ?? DateTime(0));
  });
  return hien;
}
