import 'package:cloud_firestore/cloud_firestore.dart';

import 'nha_tro.dart';

/// Tiền điện / nước: cách tính + giá.
class ChiPhi {
  const ChiPhi({required this.cach, required this.gia});

  final String cach;
  final num gia;

  static ChiPhi? fromMap(Object? m) => m is Map
      ? ChiPhi(cach: m['cach'] as String? ?? '', gia: m['gia'] as num? ?? 0)
      : null;

  Map<String, dynamic> toMap() => {'cach': cach, 'gia': gia};
}

class PhiKhac {
  const PhiKhac({required this.ten, required this.gia});

  final String ten;
  final num gia;

  Map<String, dynamic> toMap() => {'ten': ten, 'gia': gia};
}

/// Thông tin nhà trọ được chép sang phòng để lọc nhanh ở sảnh (mục 2.17).
class NhaTroRutGon {
  const NhaTroRutGon({
    required this.id,
    this.trangThai = 'draft',
    this.ten = '',
    this.loaiHinh = 'phong',
    this.tienIchChung = const [],
    this.noiQuy,
    this.viTri,
    this.diaChi = '',
    this.phuong = '',
    this.searchText = '',
    this.anhBia = '',
    this.daXacThucNha = false,
  });

  final String id;
  final String trangThai;
  final String ten;
  final String loaiHinh;
  final List<String> tienIchChung;
  final NoiQuy? noiQuy;
  final GeoPoint? viTri;
  final String diaChi;
  final String phuong;
  final String searchText;
  final String anhBia;
  final bool daXacThucNha;

  static NhaTroRutGon? fromMap(Object? m) {
    if (m is! Map) return null;
    return NhaTroRutGon(
      id: m['id'] as String? ?? '',
      trangThai: m['trangThai'] as String? ?? 'draft',
      ten: m['ten'] as String? ?? '',
      loaiHinh: m['loaiHinh'] as String? ?? 'phong',
      tienIchChung: List<String>.from(m['tienIchChung'] as List? ?? const []),
      noiQuy: NoiQuy.fromMap(m['noiQuy']),
      viTri: m['viTri'] as GeoPoint?,
      diaChi: m['diaChi'] as String? ?? '',
      phuong: m['phuong'] as String? ?? '',
      searchText: m['searchText'] as String? ?? '',
      anhBia: m['anhBia'] as String? ?? '',
      daXacThucNha: m['daXacThucNha'] as bool? ?? false,
    );
  }
}

/// Phòng — collection `phong_tro` (mục 2.17). 1 tin = 1 phòng; cọc cho đúng 1 phòng.
class PhongTro {
  const PhongTro({
    required this.id,
    required this.nhaTroId,
    required this.chuTroId,
    required this.ten,
    this.khu = '',
    this.tang,
    this.coGac,
    this.dienTich = 0,
    this.dienTichGac,
    this.soNguoiToiDa = 1,
    this.soPhongNgu,
    this.soWc,
    this.coBep,
    this.tienIch = const [],
    this.giaThue = 0,
    this.tienCoc = 0,
    this.tienDien,
    this.tienNuoc,
    this.phiKhac = const [],
    this.hopDongToiThieu,
    this.ngayVaoO,
    this.moTa = '',
    this.anh = const [],
    this.video = const [],
    this.anhBia = '',
    this.videoQuayLuc,
    this.trangThai = 'draft',
    this.lyDoTuChoi,
    this.banChinhSua,
    this.khoaThanhToanDen,
    this.dangGiuLoai,
    this.daXoa = false,
    this.nhaTro,
    this.taoLuc,
  });

  final String id;
  final String nhaTroId;
  final String chuTroId;
  final String ten;
  final String khu;
  final int? tang;
  final bool? coGac;
  final num dienTich;
  final num? dienTichGac;
  final int soNguoiToiDa;
  final int? soPhongNgu;
  final int? soWc;
  final bool? coBep;
  final List<String> tienIch;
  final num giaThue;
  final num tienCoc;
  final ChiPhi? tienDien;
  final ChiPhi? tienNuoc;
  final List<PhiKhac> phiKhac;
  final int? hopDongToiThieu;
  final DateTime? ngayVaoO;
  final String moTa;
  final List<String> anh;
  final List<String> video;
  final String anhBia;
  final DateTime? videoQuayLuc;

  /// draft | pending_review | rejected | available | reserved | rented | hidden
  final String trangThai;
  final String? lyDoTuChoi;
  final Map<String, dynamic>? banChinhSua;

  /// Khóa thanh toán: có người đang ở trang thanh toán cọc tới lúc này.
  final DateTime? khoaThanhToanDen;

  /// 'app' | 'truc_tiep' khi phòng đang được giữ.
  final String? dangGiuLoai;
  final bool daXoa;
  final NhaTroRutGon? nhaTro;
  final DateTime? taoLuc;

  bool dangKhoaThanhToan([DateTime? now]) =>
      khoaThanhToanDen != null &&
      khoaThanhToanDen!.isAfter(now ?? DateTime.now());

  bool get conTrong => trangThai == 'available';

  String get moTaDienTich {
    final gac = (coGac ?? false) && dienTichGac != null
        ? ' + gác ${_so(dienTichGac!)} m²'
        : '';
    return '${_so(dienTich)} m²$gac · Tối đa $soNguoiToiDa người';
  }

  static String _so(num x) =>
      x == x.roundToDouble() ? x.toStringAsFixed(0) : x.toString();

  factory PhongTro.fromMap(String id, Map<String, dynamic> m) => PhongTro(
    id: id,
    nhaTroId: m['nhaTroId'] as String? ?? '',
    chuTroId: m['chuTroId'] as String? ?? '',
    ten: m['ten'] as String? ?? '',
    khu: m['khu'] as String? ?? '',
    tang: (m['tang'] as num?)?.toInt(),
    coGac: m['coGac'] as bool?,
    dienTich: m['dienTich'] as num? ?? 0,
    dienTichGac: m['dienTichGac'] as num?,
    soNguoiToiDa: (m['soNguoiToiDa'] as num?)?.toInt() ?? 1,
    soPhongNgu: (m['soPhongNgu'] as num?)?.toInt(),
    soWc: (m['soWc'] as num?)?.toInt(),
    coBep: m['coBep'] as bool?,
    tienIch: List<String>.from(m['tienIch'] as List? ?? const []),
    giaThue: m['giaThue'] as num? ?? 0,
    tienCoc: m['tienCoc'] as num? ?? 0,
    tienDien: ChiPhi.fromMap(m['tienDien']),
    tienNuoc: ChiPhi.fromMap(m['tienNuoc']),
    phiKhac: [
      for (final x in m['phiKhac'] as List? ?? const [])
        if (x is Map)
          PhiKhac(ten: x['ten'] as String? ?? '', gia: x['gia'] as num? ?? 0),
    ],
    hopDongToiThieu: (m['hopDongToiThieu'] as num?)?.toInt(),
    ngayVaoO: (m['ngayVaoO'] as Timestamp?)?.toDate(),
    moTa: m['moTa'] as String? ?? '',
    anh: List<String>.from(m['anh'] as List? ?? const []),
    video: List<String>.from(m['video'] as List? ?? const []),
    anhBia: m['anhBia'] as String? ?? '',
    videoQuayLuc: (m['videoQuayLuc'] as Timestamp?)?.toDate(),
    trangThai: m['trangThai'] as String? ?? 'draft',
    lyDoTuChoi: m['lyDoTuChoi'] as String?,
    banChinhSua: (m['banChinhSua'] as Map?)?.cast<String, dynamic>(),
    khoaThanhToanDen: ((m['khoaThanhToan'] as Map?)?['den'] as Timestamp?)
        ?.toDate(),
    dangGiuLoai: (m['dangGiu'] as Map?)?['loai'] as String?,
    daXoa: m['daXoa'] as bool? ?? false,
    nhaTro: NhaTroRutGon.fromMap(m['nhaTro']),
    taoLuc: (m['taoLuc'] as Timestamp?)?.toDate(),
  );

  /// Bản nháp chủ trọ tự lưu. Nhân bản phòng dùng [nhanBan].
  Map<String, dynamic> toDraftMap() => {
    'nhaTroId': nhaTroId,
    'chuTroId': chuTroId,
    'ten': ten,
    'khu': khu,
    'tang': tang,
    'coGac': coGac,
    'dienTich': dienTich,
    'dienTichGac': dienTichGac,
    'soNguoiToiDa': soNguoiToiDa,
    'soPhongNgu': soPhongNgu,
    'soWc': soWc,
    'coBep': coBep,
    'tienIch': tienIch,
    'giaThue': giaThue,
    'tienCoc': tienCoc,
    'tienDien': tienDien?.toMap(),
    'tienNuoc': tienNuoc?.toMap(),
    'phiKhac': [for (final p in phiKhac) p.toMap()],
    'hopDongToiThieu': hopDongToiThieu,
    'ngayVaoO': ngayVaoO == null ? null : Timestamp.fromDate(ngayVaoO!),
    'moTa': moTa,
    'anh': anh,
    'video': video,
    'anhBia': anhBia,
  };

  /// "Nhân bản phòng": copy hết thông tin TRỪ tên phòng, ảnh và video (mục 2.3 Bước 3).
  Map<String, dynamic> nhanBan() => {
    ...toDraftMap(),
    'ten': '',
    'anh': <String>[],
    'video': <String>[],
    'anhBia': '',
  };
}
