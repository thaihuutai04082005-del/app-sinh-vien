import 'package:cloud_firestore/cloud_firestore.dart';

/// Nội quy của nhà trọ (4 tiêu chí, mục 2.3) — áp cho mọi phòng, dùng cho bộ lọc.
class NoiQuy {
  const NoiQuy({
    required this.gioGiac,
    this.gioDongCua,
    required this.thuCung,
    required this.oQuaDem,
    required this.baoTruocTuan,
  });

  /// 'tu_do' (Tự do 24/24) | 'gioi_han' (có giờ đóng cửa)
  final String gioGiac;

  /// "HH:mm" khi [gioGiac] = 'gioi_han'.
  final String? gioDongCua;
  final bool thuCung;
  final bool oQuaDem;

  /// 1 | 2 | 3 tuần báo trước khi trả phòng.
  final int baoTruocTuan;

  bool get tuDo => gioGiac == 'tu_do';

  /// Phút trong ngày của giờ đóng cửa (00:00 – 03:59 coi là sau nửa đêm, muộn hơn 23:59).
  int? get phutDongCua {
    final g = gioDongCua;
    if (tuDo || g == null) return null;
    final p = g.split(':');
    final phut = int.parse(p[0]) * 60 + int.parse(p[1]);
    return phut < 4 * 60 ? phut + 24 * 60 : phut;
  }

  String get gioGiacLabel =>
      tuDo ? 'Tự do 24/24' : 'Đóng cửa ${gioDongCua ?? ''}';

  static NoiQuy? fromMap(Object? m) {
    if (m is! Map) return null;
    return NoiQuy(
      gioGiac: m['gioGiac'] as String? ?? 'tu_do',
      gioDongCua: m['gioDongCua'] as String?,
      thuCung: m['thuCung'] as bool? ?? false,
      oQuaDem: m['oQuaDem'] as bool? ?? false,
      baoTruocTuan: (m['baoTruocTuan'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'gioGiac': gioGiac,
    'gioDongCua': tuDo ? null : gioDongCua,
    'thuCung': thuCung,
    'oQuaDem': oQuaDem,
    'baoTruocTuan': baoTruocTuan,
  };
}

/// Số liệu app tự tính từ các phòng và đánh giá (mục 2.2).
class SoLieuNhaTro {
  const SoLieuNhaTro({
    this.soPhong = 0,
    this.soPhongTrong = 0,
    this.giaMin,
    this.giaMax,
    this.diem,
    this.soDanhGia = 0,
  });

  final int soPhong;
  final int soPhongTrong;
  final num? giaMin;
  final num? giaMax;
  final double? diem;
  final int soDanhGia;

  static SoLieuNhaTro fromMap(Object? m) {
    if (m is! Map) return const SoLieuNhaTro();
    return SoLieuNhaTro(
      soPhong: (m['soPhong'] as num?)?.toInt() ?? 0,
      soPhongTrong: (m['soPhongTrong'] as num?)?.toInt() ?? 0,
      giaMin: m['giaMin'] as num?,
      giaMax: m['giaMax'] as num?,
      diem: (m['diem'] as num?)?.toDouble(),
      soDanhGia: (m['soDanhGia'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Nhà trọ — collection `nha_tro` (mục 2.17). Ở danh sách và bản đồ hiện nhà trọ.
class NhaTro {
  const NhaTro({
    required this.id,
    required this.chuTroId,
    required this.ten,
    this.loaiHinh = 'phong',
    this.tongSoPhong,
    this.soTang,
    this.tienIchChung = const [],
    this.noiQuy,
    this.moTa = '',
    this.diaChi = '',
    this.phuong = '',
    this.viTri,
    this.anh = const [],
    this.video = const [],
    this.anhBia = '',
    this.camKet = false,
    this.trangThai = 'draft',
    this.lyDoTuChoi,
    this.daXacThucNha = false,
    this.banChinhSua,
    this.hetHanLuc,
    this.soLieu = const SoLieuNhaTro(),
    this.anBoi,
    this.coGanCo = false,
    this.taoLuc,
  });

  final String id;
  final String chuTroId;
  final String ten;

  /// 'phong' | 'nguyen_can'
  final String loaiHinh;
  final int? tongSoPhong;
  final int? soTang;
  final List<String> tienIchChung;
  final NoiQuy? noiQuy;
  final String moTa;
  final String diaChi;
  final String phuong;
  final GeoPoint? viTri;
  final List<String> anh;
  final List<String> video;
  final String anhBia;
  final bool camKet;

  /// draft | pending_review | rejected | active | hidden | expired
  final String trangThai;
  final String? lyDoTuChoi;
  final bool daXacThucNha;

  /// Bản chỉnh sửa ảnh / video / địa chỉ đang chờ duyệt (null nếu không có).
  final Map<String, dynamic>? banChinhSua;
  final DateTime? hetHanLuc;
  final SoLieuNhaTro soLieu;
  final String? anBoi;
  final bool coGanCo;
  final DateTime? taoLuc;

  bool get laNguyenCan => loaiHinh == 'nguyen_can';
  bool get dangHien => trangThai == 'active';
  bool get conPhong => soLieu.soPhongTrong > 0;

  factory NhaTro.fromMap(String id, Map<String, dynamic> m) => NhaTro(
    id: id,
    chuTroId: m['chuTroId'] as String? ?? '',
    ten: m['ten'] as String? ?? '',
    loaiHinh: m['loaiHinh'] as String? ?? 'phong',
    tongSoPhong: (m['tongSoPhong'] as num?)?.toInt(),
    soTang: (m['soTang'] as num?)?.toInt(),
    tienIchChung: List<String>.from(m['tienIchChung'] as List? ?? const []),
    noiQuy: NoiQuy.fromMap(m['noiQuy']),
    moTa: m['moTa'] as String? ?? '',
    diaChi: m['diaChi'] as String? ?? '',
    phuong: m['phuong'] as String? ?? '',
    viTri: m['viTri'] as GeoPoint?,
    anh: List<String>.from(m['anh'] as List? ?? const []),
    video: List<String>.from(m['video'] as List? ?? const []),
    anhBia: m['anhBia'] as String? ?? '',
    camKet: m['camKet'] as bool? ?? false,
    trangThai: m['trangThai'] as String? ?? 'draft',
    lyDoTuChoi: m['lyDoTuChoi'] as String?,
    daXacThucNha: m['daXacThucNha'] as bool? ?? false,
    banChinhSua: (m['banChinhSua'] as Map?)?.cast<String, dynamic>(),
    hetHanLuc: (m['hetHanLuc'] as Timestamp?)?.toDate(),
    soLieu: SoLieuNhaTro.fromMap(m['soLieu']),
    anBoi: m['anBoi'] as String?,
    coGanCo: m['coGanCo'] as bool? ?? false,
    taoLuc: (m['taoLuc'] as Timestamp?)?.toDate(),
  );

  /// Dữ liệu bản nháp chủ trọ tự lưu (trạng thái do hệ thống đổi khi gửi duyệt).
  Map<String, dynamic> toDraftMap() => {
    'chuTroId': chuTroId,
    'ten': ten,
    'loaiHinh': loaiHinh,
    'tongSoPhong': tongSoPhong,
    'soTang': soTang,
    'tienIchChung': tienIchChung,
    'noiQuy': noiQuy?.toMap(),
    'moTa': moTa,
    'diaChi': diaChi,
    'phuong': phuong,
    'viTri': viTri,
    'anh': anh,
    'video': video,
    'anhBia': anhBia,
    'camKet': camKet,
  };
}
