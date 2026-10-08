import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Đánh giá nhà trọ — collection `tro_danh_gia` (mục 2.9). Gắn với NHÀ TRỌ.
class DanhGia {
  const DanhGia({
    required this.id,
    required this.nhaTroId,
    required this.nguoiViet,
    required this.diemTB,
    this.tenNguoiViet = '',
    this.tenPhong = '',
    this.nhan,
    this.tinhDiem = false,
    this.diem = const {},
    this.the = const [],
    this.nhanXet = '',
    this.anh = const [],
    this.chuTraLoi,
    this.daCapNhat = false,
    this.hienThi = 'hien',
    this.capNhatLuc,
  });

  final String id;
  final String nhaTroId;
  final String nguoiViet;
  final double diemTB;
  final String tenNguoiViet;
  final String tenPhong;

  /// 'da_thue' | 'khieu_nai_chap_nhan' | null (Chưa xác minh)
  final String? nhan;
  final bool tinhDiem;
  final Map<String, int> diem;
  final List<String> the;
  final String nhanXet;
  final List<String> anh;
  final String? chuTraLoi;
  final bool daCapNhat;
  final String hienThi;
  final DateTime? capNhatLuc;

  String get nhanLabel => switch (nhan) {
    'da_thue' => '✔ Đã thuê',
    'khieu_nai_chap_nhan' => '⚠ Có khiếu nại được chấp nhận',
    _ => 'Chưa xác minh',
  };

  factory DanhGia.fromMap(String id, Map<String, dynamic> m) => DanhGia(
    id: id,
    nhaTroId: m['nhaTroId'] as String? ?? '',
    nguoiViet: m['nguoiViet'] as String? ?? '',
    diemTB: (m['diemTB'] as num?)?.toDouble() ?? 0,
    tenNguoiViet: m['tenNguoiViet'] as String? ?? '',
    tenPhong: m['tenPhong'] as String? ?? '',
    nhan: m['nhan'] as String?,
    tinhDiem: m['tinhDiem'] as bool? ?? false,
    diem: {
      for (final e in ((m['diem'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as num).toInt(),
    },
    the: List<String>.from(m['the'] as List? ?? const []),
    nhanXet: m['nhanXet'] as String? ?? '',
    anh: List<String>.from(m['anh'] as List? ?? const []),
    chuTraLoi: (m['chuTraLoi'] as Map?)?['noiDung'] as String?,
    daCapNhat: m['daCapNhat'] as bool? ?? false,
    hienThi: m['hienThi'] as String? ?? 'hien',
    capNhatLuc: _t(m['capNhatLuc']),
  );
}

/// Đánh giá có nhãn lên trước, "Chưa xác minh" hiện riêng, màu nhạt, xếp sau (mục 2.4 Bước 5).
List<DanhGia> sapXepDanhGia(List<DanhGia> ds) {
  final hien = ds.where((d) => d.hienThi != 'an').toList();
  hien.sort((a, b) {
    if (a.tinhDiem != b.tinhDiem) return a.tinhDiem ? -1 : 1;
    return (b.capNhatLuc ?? DateTime(0)).compareTo(a.capNhatLuc ?? DateTime(0));
  });
  return hien;
}
