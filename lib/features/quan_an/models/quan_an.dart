import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import 'gio_mo_cua.dart';
import 'quan_an_config.dart';

DateTime? _t(Object? v) => v is Timestamp ? v.toDate() : null;

List<String> _ds(Object? v) => List<String>.from(v as List? ?? const []);

/// Hình thức phục vụ do quán tự khai (mục 3.3 Bước 2, phần 3).
class PhucVu {
  const PhucVu({this.anTaiQuan = true, this.mangDi = false});

  final bool anTaiQuan;
  final bool mangDi;

  static PhucVu fromMap(Object? m) => m is Map
      ? PhucVu(
          anTaiQuan: m['anTaiQuan'] as bool? ?? false,
          mangDi: m['mangDi'] as bool? ?? false,
        )
      : const PhucVu();

  Map<String, dynamic> toMap() => {'anTaiQuan': anTaiQuan, 'mangDi': mangDi};

  /// Phải chọn ít nhất 1 hình thức.
  bool get hopLe => anTaiQuan || mangDi;
}

/// Cài đặt đặt món của hộ kinh doanh (mục 3.3 Bước 5) — sửa được bất cứ lúc nào, không cần duyệt.
class CaiDatDatMon {
  const CaiDatDatMon({
    this.bat = false,
    this.denLay = true,
    this.giaoTanNoi = false,
    this.banKinhKm = 2,
    this.phiGiaoKieu = 'co_dinh',
    this.phiGiao = 0,
    this.phiMoiKm = 0,
    this.donToiThieu = 0,
    this.chuanBiPhut = 15,
    this.tienMat = false,
  });

  final bool bat;
  final bool denLay;
  final bool giaoTanNoi;

  /// Bán kính giao tối đa (km).
  final num banKinhKm;

  /// 'co_dinh' | 'theo_km'
  final String phiGiaoKieu;
  final num phiGiao;
  final num phiMoiKm;

  /// Tính trên tiền món, chưa gồm phí giao.
  final num donToiThieu;
  final int chuanBiPhut;
  final bool tienMat;

  bool get theoKm => phiGiaoKieu == 'theo_km';

  /// Có ít nhất một cách nhận món.
  bool get coCachNhan => denLay || giaoTanNoi;

  /// Mô tả phí giao ngắn: "Phí giao 10.000đ", "Phí giao 5.000đ/km", "Miễn phí giao".
  String get phiGiaoMoTa {
    if (theoKm) {
      return phiMoiKm <= 0
          ? 'Miễn phí giao'
          : 'Phí giao ${formatPrice(phiMoiKm)}/km';
    }
    return phiGiao <= 0 ? 'Miễn phí giao' : 'Phí giao ${formatPrice(phiGiao)}';
  }

  static CaiDatDatMon fromMap(Object? m) {
    if (m is! Map) return const CaiDatDatMon();
    return CaiDatDatMon(
      bat: m['bat'] as bool? ?? false,
      denLay: m['denLay'] as bool? ?? false,
      giaoTanNoi: m['giaoTanNoi'] as bool? ?? false,
      banKinhKm: m['banKinhKm'] as num? ?? 2,
      phiGiaoKieu: m['phiGiaoKieu'] as String? ?? 'co_dinh',
      phiGiao: m['phiGiao'] as num? ?? 0,
      phiMoiKm: m['phiMoiKm'] as num? ?? 0,
      donToiThieu: m['donToiThieu'] as num? ?? 0,
      chuanBiPhut: (m['chuanBiPhut'] as num?)?.toInt() ?? 15,
      tienMat: m['tienMat'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'bat': bat,
    'denLay': denLay,
    'giaoTanNoi': giaoTanNoi,
    'banKinhKm': banKinhKm,
    'phiGiaoKieu': phiGiaoKieu,
    'phiGiao': phiGiao,
    'phiMoiKm': phiMoiKm,
    'donToiThieu': donToiThieu,
    'chuanBiPhut': chuanBiPhut,
    'tienMat': tienMat,
  };

  CaiDatDatMon copyWith({
    bool? bat,
    bool? denLay,
    bool? giaoTanNoi,
    num? banKinhKm,
    String? phiGiaoKieu,
    num? phiGiao,
    num? phiMoiKm,
    num? donToiThieu,
    int? chuanBiPhut,
    bool? tienMat,
  }) => CaiDatDatMon(
    bat: bat ?? this.bat,
    denLay: denLay ?? this.denLay,
    giaoTanNoi: giaoTanNoi ?? this.giaoTanNoi,
    banKinhKm: banKinhKm ?? this.banKinhKm,
    phiGiaoKieu: phiGiaoKieu ?? this.phiGiaoKieu,
    phiGiao: phiGiao ?? this.phiGiao,
    phiMoiKm: phiMoiKm ?? this.phiMoiKm,
    donToiThieu: donToiThieu ?? this.donToiThieu,
    chuanBiPhut: chuanBiPhut ?? this.chuanBiPhut,
    tienMat: tienMat ?? this.tienMat,
  );
}

/// Số liệu hệ thống tự tính (mục 3.17) — app chỉ đọc.
class SoLieuQuan {
  const SoLieuQuan({
    this.soMon = 0,
    this.giaP25,
    this.giaTrungVi,
    this.giaP75,
    this.diemTong,
    this.soDanhGia = 0,
    this.diemChuaXm,
    this.soDanhGiaChuaXm = 0,
    this.diemTieuChi = const {},
    this.soNguoi30Ngay = 0,
    this.hayAn = false,
    this.tyLeNhanDon,
    this.tyLeGiuBan,
    this.coKhuyenMai = false,
    this.moiMo = false,
  });

  final int soMon;
  final num? giaP25;
  final num? giaTrungVi;
  final num? giaP75;

  /// Điểm tổng thể chỉ tính từ đánh giá ĐÃ XÁC MINH; null = "Chưa có đánh giá xác minh".
  final double? diemTong;
  final int soDanhGia;

  /// Điểm các đánh giá chưa xác minh (chỉ hiện phụ, màu nhạt).
  final double? diemChuaXm;
  final int soDanhGiaChuaXm;

  /// monAn · giaCa · veSinh · phucVu.
  final Map<String, double> diemTieuChi;
  final int soNguoi30Ngay;
  final bool hayAn;
  final int? tyLeNhanDon;
  final int? tyLeGiuBan;
  final bool coKhuyenMai;
  final bool moiMo;

  bool get coDiemXacMinh => diemTong != null && soDanhGia > 0;

  static SoLieuQuan fromMap(Object? m) {
    if (m is! Map) return const SoLieuQuan();
    final tc = <String, double>{};
    if (m['diemTieuChi'] is Map) {
      (m['diemTieuChi'] as Map).forEach((k, v) {
        if (v is num) tc['$k'] = v.toDouble();
      });
    }
    return SoLieuQuan(
      soMon: (m['soMon'] as num?)?.toInt() ?? 0,
      giaP25: m['giaP25'] as num?,
      giaTrungVi: m['giaTrungVi'] as num?,
      giaP75: m['giaP75'] as num?,
      diemTong: (m['diemTong'] as num?)?.toDouble(),
      soDanhGia: (m['soDanhGia'] as num?)?.toInt() ?? 0,
      diemChuaXm: (m['diemChuaXm'] as num?)?.toDouble(),
      soDanhGiaChuaXm: (m['soDanhGiaChuaXm'] as num?)?.toInt() ?? 0,
      diemTieuChi: tc,
      soNguoi30Ngay: (m['soNguoi30Ngay'] as num?)?.toInt() ?? 0,
      hayAn: m['hayAn'] as bool? ?? false,
      tyLeNhanDon: (m['tyLeNhanDon'] as num?)?.toInt(),
      tyLeGiuBan: (m['tyLeGiuBan'] as num?)?.toInt(),
      coKhuyenMai: m['coKhuyenMai'] as bool? ?? false,
      moiMo: m['moiMo'] as bool? ?? false,
    );
  }
}

/// Cờ nghi khai sai loại quán (mục 3.5f).
class KhaiSaiLoai {
  const KhaiSaiLoai({this.lyDo = const [], this.hanChuyen});

  final List<String> lyDo;

  /// Có giá trị = admin đã yêu cầu chuyển loại; quá hạn mà chưa chuyển thì ẩn quán.
  final DateTime? hanChuyen;

  static KhaiSaiLoai? fromMap(Object? m) => m is Map
      ? KhaiSaiLoai(lyDo: _ds(m['lyDo']), hanChuyen: _t(m['hanChuyen']))
      : null;
}

/// Quán ăn — collection `qa_quan` (hợp đồng dữ liệu).
class QuanAn {
  const QuanAn({
    required this.id,
    required this.chuQuanId,
    required this.ten,
    this.loaiQuan = 'ban_le',
    this.loaiMon = const [],
    this.moTa = '',
    this.sdt = '',
    this.diaChi = '',
    this.phuong = '',
    this.viTri,
    this.luuDong = false,
    this.ghiChuViTri = '',
    this.searchText = '',
    this.gioMoCua = const {},
    this.tamNghiDen,
    this.tamNghiLoai,
    this.tamNgungNhanDon = false,
    this.tamNgungDen,
    this.phucVu = const PhucVu(),
    this.tienIch = const [],
    this.nhanDatBan = false,
    this.datMon = const CaiDatDatMon(),
    this.anhMatTien = const [],
    this.anhBia = '',
    this.anhKhac = const [],
    this.viTriAnh,
    this.camKet = false,
    this.daDoiChieuMst = false,
    this.trangThai = 'draft',
    this.lyDoTuChoi,
    this.banChinhSua,
    this.khaiSaiLoai,
    this.anBoi,
    this.khoaBan = false,
    this.hoatDongLuc,
    this.hanXacNhanHoatDong,
    this.duyetLuc,
    this.taoLuc,
    this.capNhatLuc,
    this.soLieu = const SoLieuQuan(),
  });

  final String id;
  final String chuQuanId;
  final String ten;

  /// 'ho_kinh_doanh' | 'ban_le'
  final String loaiQuan;
  final List<String> loaiMon;
  final String moTa;

  /// Khách chưa đăng nhập không thấy; có thể rỗng (lấy qua `laySdtQuan`).
  final String sdt;
  final String diaChi;
  final String phuong;
  final GeoPoint? viTri;

  /// Bán lưu động (xe đẩy không đứng cố định).
  final bool luuDong;
  final String ghiChuViTri;
  final String searchText;
  final LichMoCua gioMoCua;
  final DateTime? tamNghiDen;

  /// 'hom_nay' | 'dai_ngay' | null
  final String? tamNghiLoai;
  final bool tamNgungNhanDon;
  final DateTime? tamNgungDen;
  final PhucVu phucVu;
  final List<String> tienIch;
  final bool nhanDatBan;
  final CaiDatDatMon datMon;
  final List<String> anhMatTien;
  final String anhBia;
  final List<String> anhKhac;
  final GeoPoint? viTriAnh;
  final bool camKet;
  final bool daDoiChieuMst;

  /// draft | pending_review | rejected | active | hidden | suspended | closed
  final String trangThai;
  final String? lyDoTuChoi;

  /// Bản chỉnh sửa chờ duyệt: các trường đổi + `guiLuc` + `loai` ('sua' | 'nang_cap').
  final Map<String, dynamic>? banChinhSua;
  final KhaiSaiLoai? khaiSaiLoai;
  final String? anBoi;
  final bool khoaBan;
  final DateTime? hoatDongLuc;
  final DateTime? hanXacNhanHoatDong;
  final DateTime? duyetLuc;
  final DateTime? taoLuc;
  final DateTime? capNhatLuc;
  final SoLieuQuan soLieu;

  // ---- Loại quán, huy hiệu ----
  bool get laHoKinhDoanh => loaiQuan == 'ho_kinh_doanh';
  String get loaiQuanLabel => loaiQuanLabels[loaiQuan] ?? loaiQuan;

  /// "Đã xác thực kinh doanh" (hộ kinh doanh) / "Đã xác thực chủ quán" (bán lẻ).
  String get daXacThucLabel =>
      huyHieuLoaiQuanLabels[loaiQuan] ?? 'Đã xác thực chủ quán';

  /// Các nhãn nhỏ trên thẻ quán (mục 3.4 Bước 1), theo thứ tự hiển thị.
  List<String> get nhanHuyHieu => [
    if (soLieu.coKhuyenMai) '🏷 Khuyến mãi',
    if (nhanDatMon) '🛵 Đặt món',
    if (soLieu.hayAn) '🔥 Sinh viên hay ăn',
    if (soLieu.moiMo) '🆕 Mới mở',
  ];

  // ---- Trạng thái ----
  bool get dangHien => trangThai == 'active';
  String get trangThaiLabel => trangThaiQuanLabels[trangThai] ?? trangThai;
  bool get coBanChinhSua => banChinhSua != null && banChinhSua!.isNotEmpty;

  /// Chủ quán sửa trực tiếp bản nháp được khi ở trạng thái nháp / bị từ chối.
  bool get suaNhapDuoc => trangThai == 'draft' || trangThai == 'rejected';

  // ---- Đặt món / đặt bàn ----
  /// Quán nhận đặt món qua app (chỉ hộ kinh doanh đã bật và có ít nhất một cách nhận).
  bool get nhanDatMon => laHoKinhDoanh && datMon.bat && datMon.coCachNhan;
  bool get nhanDatBanQuaApp => laHoKinhDoanh && nhanDatBan;

  /// Chủ quán đang tạm ngưng nhận đơn (tay hoặc hệ thống tự tạm ngưng tới hết ngày).
  bool dangTamNgung(DateTime now) =>
      tamNgungNhanDon || (tamNgungDen != null && now.isBefore(tamNgungDen!));

  /// Có đặt món được ngay lúc này: nhận đặt món, đang mở (không tạm nghỉ), chưa tạm ngưng, chưa bị khóa bán.
  bool datMonDuocLuc(DateTime now, {QuanAnConfig? cfg}) =>
      dangHien &&
      !khoaBan &&
      nhanDatMon &&
      !dangTamNgung(now) &&
      tinhMoCua(
        gioMoCua,
        now,
        tamNghiDen: tamNghiDen,
        sapDongPhut: cfg?.sapDongPhut,
      ).trangThai.dangMo;

  // ---- Mở cửa ----
  TinhTrangMoCua moCua(DateTime now, {QuanAnConfig? cfg}) => tinhMoCua(
    gioMoCua,
    now,
    tamNghiDen: tamNghiDen,
    sapDongPhut: cfg?.sapDongPhut,
  );

  // ---- Giá ----
  /// Khoảng giá trên thẻ: "25–40k" (P25–P75); chưa có menu thì "—".
  String get giaHienThi {
    final a = soLieu.giaP25;
    final b = soLieu.giaP75;
    if (a == null || b == null) return '—';
    if (a >= 1000000 || b >= 1000000) {
      return a == b ? formatGiaGon(a) : '${formatGiaGon(a)}–${formatGiaGon(b)}';
    }
    final lo = (a / 1000).round();
    final hi = (b / 1000).round();
    return lo == hi ? '${lo}k' : '$lo–${hi}k';
  }

  /// "Món chính: Cơm · Bún / Phở / Mì".
  String get loaiMonLabel =>
      loaiMon.map((m) => loaiMonLabels[m] ?? m).join(' · ');

  factory QuanAn.fromMap(String id, Map<String, dynamic> m) => QuanAn(
    id: id,
    chuQuanId: m['chuQuanId'] as String? ?? '',
    ten: m['ten'] as String? ?? '',
    loaiQuan: m['loaiQuan'] as String? ?? 'ban_le',
    loaiMon: _ds(m['loaiMon']),
    moTa: m['moTa'] as String? ?? '',
    sdt: m['sdt'] as String? ?? '',
    diaChi: m['diaChi'] as String? ?? '',
    phuong: m['phuong'] as String? ?? '',
    viTri: m['viTri'] as GeoPoint?,
    luuDong: m['luuDong'] as bool? ?? false,
    ghiChuViTri: m['ghiChuViTri'] as String? ?? '',
    searchText: m['searchText'] as String? ?? '',
    gioMoCua: lichTuMap(m['gioMoCua']),
    tamNghiDen: _t(m['tamNghiDen']),
    tamNghiLoai: m['tamNghiLoai'] as String?,
    tamNgungNhanDon: m['tamNgungNhanDon'] as bool? ?? false,
    tamNgungDen: _t(m['tamNgungDen']),
    phucVu: PhucVu.fromMap(m['phucVu']),
    tienIch: _ds(m['tienIch']),
    nhanDatBan: m['nhanDatBan'] as bool? ?? false,
    datMon: CaiDatDatMon.fromMap(m['datMon']),
    anhMatTien: _ds(m['anhMatTien']),
    anhBia: m['anhBia'] as String? ?? '',
    anhKhac: _ds(m['anhKhac']),
    viTriAnh: m['viTriAnh'] as GeoPoint?,
    camKet: m['camKet'] as bool? ?? false,
    daDoiChieuMst: m['daDoiChieuMst'] as bool? ?? false,
    trangThai: m['trangThai'] as String? ?? 'draft',
    lyDoTuChoi: m['lyDoTuChoi'] as String?,
    banChinhSua: (m['banChinhSua'] as Map?)?.cast<String, dynamic>(),
    khaiSaiLoai: KhaiSaiLoai.fromMap(m['khaiSaiLoai']),
    anBoi: m['anBoi'] as String?,
    khoaBan: m['khoaBan'] as bool? ?? false,
    hoatDongLuc: _t(m['hoatDongLuc']),
    hanXacNhanHoatDong: _t(m['hanXacNhanHoatDong']),
    duyetLuc: _t(m['duyetLuc']),
    taoLuc: _t(m['taoLuc']),
    capNhatLuc: _t(m['capNhatLuc']),
    soLieu: SoLieuQuan.fromMap(m['soLieu']),
  );

  /// Dữ liệu bản nháp chủ quán tự ghi (trạng thái do hệ thống đổi khi gửi duyệt).
  /// Không gồm `searchText`, `soLieu`, `trangThai` và các trường hệ thống.
  Map<String, dynamic> toDraftMap() => {
    'chuQuanId': chuQuanId,
    'ten': ten,
    'loaiQuan': loaiQuan,
    'loaiMon': loaiMon,
    'moTa': moTa,
    'sdt': sdt,
    'diaChi': diaChi,
    'phuong': phuong,
    'viTri': viTri,
    'luuDong': luuDong,
    'ghiChuViTri': ghiChuViTri,
    'gioMoCua': lichToMap(gioMoCua),
    'phucVu': phucVu.toMap(),
    'tienIch': tienIch,
    'nhanDatBan': nhanDatBan,
    'datMon': datMon.toMap(),
    'anhMatTien': anhMatTien,
    'anhBia': anhMatTien.isNotEmpty ? anhMatTien.first : anhBia,
    'anhKhac': anhKhac,
    'viTriAnh': viTriAnh,
    'camKet': camKet,
  };
}

/// Chỉ số uy tín công khai của chủ quán (`qa_chi_so_chu`, mục 3.3 Bước 6).
class ChiSoChuQuan {
  const ChiSoChuQuan({
    this.hoTen,
    this.daXacThucDanhTinh = false,
    this.tyLePhanHoi,
    this.tyLeNhanDon,
    this.tyLeGiuBan,
    this.soCanhCao = 0,
  });

  final String? hoTen;
  final bool daXacThucDanhTinh;
  final int? tyLePhanHoi;
  final int? tyLeNhanDon;
  final int? tyLeGiuBan;
  final int soCanhCao;

  factory ChiSoChuQuan.fromMap(Map<String, dynamic>? m) => ChiSoChuQuan(
    hoTen: m?['hoTen'] as String?,
    daXacThucDanhTinh: m?['daXacThucDanhTinh'] as bool? ?? false,
    tyLePhanHoi: (m?['tyLePhanHoi'] as num?)?.toInt(),
    tyLeNhanDon: (m?['tyLeNhanDon'] as num?)?.toInt(),
    tyLeGiuBan: (m?['tyLeGiuBan'] as num?)?.toInt(),
    soCanhCao: (m?['soCanhCao'] as num?)?.toInt() ?? 0,
  );
}

/// Giấy tờ riêng của quán (`qa_quan/{id}/rieng/giay_to`) — chỉ chủ quán và admin đọc.
class GiayToQuan {
  const GiayToQuan({
    this.maSoThue = '',
    this.anhGiayChungNhan = const [],
    this.anhAttp = const [],
  });

  final String maSoThue;
  final List<String> anhGiayChungNhan;
  final List<String> anhAttp;

  factory GiayToQuan.fromMap(Map<String, dynamic>? m) => GiayToQuan(
    maSoThue: m?['maSoThue'] as String? ?? '',
    anhGiayChungNhan: _ds(m?['anhGiayChungNhan']),
    anhAttp: _ds(m?['anhAttp']),
  );

  Map<String, dynamic> toMap() => {
    'maSoThue': maSoThue,
    'anhGiayChungNhan': anhGiayChungNhan,
    'anhAttp': anhAttp,
  };
}
