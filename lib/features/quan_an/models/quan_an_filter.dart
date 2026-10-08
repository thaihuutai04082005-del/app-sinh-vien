import 'dart:math' as math;

import 'gio_mo_cua.dart';
import 'quan_an.dart';
import 'quan_an_config.dart';

/// Bỏ dấu tiếng Việt, chữ thường, ký tự đặc biệt thành khoảng trắng.
/// "Nguyễn Huệ (P.1)*" → "nguyen hue p 1". Ký tự đặc biệt không làm lỗi tìm kiếm.
String boDau(String s) {
  const co =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const khong =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final thuong = s.toLowerCase();
  final b = StringBuffer();
  for (final r in thuong.runes) {
    final c = String.fromCharCode(r);
    final i = co.indexOf(c);
    b.write(i >= 0 ? khong[i] : c);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Khoảng cách đường thẳng (mét) giữa 2 điểm (mục 3.7) — công thức haversine.
double khoangCachMet(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Điểm gốc để tính khoảng cách: vị trí hiện tại hoặc điểm chọn trên bản đồ.
class DiemGoc {
  const DiemGoc({required this.lat, required this.lng, this.ten = ''});

  final double lat;
  final double lng;
  final String ten;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'ten': ten};

  static DiemGoc? fromJson(Object? m) =>
      m is Map && m['lat'] is num && m['lng'] is num
      ? DiemGoc(
          lat: (m['lat'] as num).toDouble(),
          lng: (m['lng'] as num).toDouble(),
          ten: m['ten'] as String? ?? '',
        )
      : null;
}

enum SapXepQuan {
  ganNhat('Gần nhất'),
  danhGia('Đánh giá cao nhất'),
  giaThap('Giá thấp nhất'),
  hayAn('Sinh viên hay ăn'),
  moiMo('Mới mở');

  const SapXepQuan(this.label);
  final String label;
}

const _giuNguyen = Object();

/// Bộ lọc sảnh Quán ăn (mục 3.4 Bước 1). App nhớ bộ lọc lần trước qua [toJson].
class QuanAnFilter {
  const QuanAnFilter({
    this.tuKhoa = '',
    this.loaiMon = const {},
    this.giaTu,
    this.giaDen,
    this.banKinhMet,
    this.dangMo = true,
    this.anTaiQuan = false,
    this.mangDi = false,
    this.giaoHang = false,
    this.diemTu,
    this.tienIch = const {},
    this.nhanDatBan = false,
    this.loaiQuan,
    this.coKhuyenMai = false,
    this.sapXep = SapXepQuan.ganNhat,
  });

  final String tuKhoa;

  /// Quán khớp khi có ít nhất một loại món trong tập này.
  final Set<String> loaiMon;

  /// Mức giá theo GIÁ TRUNG VỊ: `giaTu` ≤ trung vị < `giaDen` (null = không giới hạn).
  final int? giaTu;
  final int? giaDen;
  final int? banKinhMet;

  /// "Đang mở cửa" — bật sẵn.
  final bool dangMo;
  final bool anTaiQuan;
  final bool mangDi;

  /// "Giao hàng (đặt qua app)": chỉ hộ kinh doanh đã bật đặt món, giao tới điểm gốc được hoặc có đến lấy.
  final bool giaoHang;

  /// 4 hoặc 3,5: điểm tổng thể ĐÃ XÁC MINH tối thiểu.
  final double? diemTu;
  final Set<String> tienIch;
  final bool nhanDatBan;

  /// null | 'ho_kinh_doanh' | 'ban_le'
  final String? loaiQuan;
  final bool coKhuyenMai;
  final SapXepQuan sapXep;

  static const macDinh = QuanAnFilter();

  /// Chip "Dưới 35k": giá trung vị dưới [QuanAnConfig.chipGiaReDen].
  bool chipDuoiGiaRe(QuanAnConfig cfg) =>
      giaTu == null && giaDen == cfg.chipGiaReDen;

  bool get dangLoc =>
      loaiMon.isNotEmpty ||
      giaTu != null ||
      giaDen != null ||
      banKinhMet != null ||
      !dangMo ||
      anTaiQuan ||
      mangDi ||
      giaoHang ||
      diemTu != null ||
      tienIch.isNotEmpty ||
      nhanDatBan ||
      loaiQuan != null ||
      coKhuyenMai;

  QuanAnFilter copyWith({
    String? tuKhoa,
    Set<String>? loaiMon,
    Object? giaTu = _giuNguyen,
    Object? giaDen = _giuNguyen,
    Object? banKinhMet = _giuNguyen,
    bool? dangMo,
    bool? anTaiQuan,
    bool? mangDi,
    bool? giaoHang,
    Object? diemTu = _giuNguyen,
    Set<String>? tienIch,
    bool? nhanDatBan,
    Object? loaiQuan = _giuNguyen,
    bool? coKhuyenMai,
    SapXepQuan? sapXep,
  }) => QuanAnFilter(
    tuKhoa: tuKhoa ?? this.tuKhoa,
    loaiMon: loaiMon ?? this.loaiMon,
    giaTu: giaTu == _giuNguyen ? this.giaTu : giaTu as int?,
    giaDen: giaDen == _giuNguyen ? this.giaDen : giaDen as int?,
    banKinhMet: banKinhMet == _giuNguyen ? this.banKinhMet : banKinhMet as int?,
    dangMo: dangMo ?? this.dangMo,
    anTaiQuan: anTaiQuan ?? this.anTaiQuan,
    mangDi: mangDi ?? this.mangDi,
    giaoHang: giaoHang ?? this.giaoHang,
    diemTu: diemTu == _giuNguyen ? this.diemTu : diemTu as double?,
    tienIch: tienIch ?? this.tienIch,
    nhanDatBan: nhanDatBan ?? this.nhanDatBan,
    loaiQuan: loaiQuan == _giuNguyen ? this.loaiQuan : loaiQuan as String?,
    coKhuyenMai: coKhuyenMai ?? this.coKhuyenMai,
    sapXep: sapXep ?? this.sapXep,
  );

  /// Xóa bộ lọc (đưa "Đang mở cửa" về bật sẵn) nhưng giữ từ khóa và cách sắp xếp.
  QuanAnFilter xoaLoc() => QuanAnFilter(tuKhoa: tuKhoa, sapXep: sapXep);

  Map<String, dynamic> toJson() => {
    'loaiMon': loaiMon.toList(),
    'giaTu': giaTu,
    'giaDen': giaDen,
    'banKinhMet': banKinhMet,
    'dangMo': dangMo,
    'anTaiQuan': anTaiQuan,
    'mangDi': mangDi,
    'giaoHang': giaoHang,
    'diemTu': diemTu,
    'tienIch': tienIch.toList(),
    'nhanDatBan': nhanDatBan,
    'loaiQuan': loaiQuan,
    'coKhuyenMai': coKhuyenMai,
    'sapXep': sapXep.name,
  };

  static QuanAnFilter fromJson(Map<String, dynamic> m) => QuanAnFilter(
    loaiMon: {...List<String>.from(m['loaiMon'] as List? ?? const [])},
    giaTu: (m['giaTu'] as num?)?.toInt(),
    giaDen: (m['giaDen'] as num?)?.toInt(),
    banKinhMet: (m['banKinhMet'] as num?)?.toInt(),
    dangMo: m['dangMo'] as bool? ?? true,
    anTaiQuan: m['anTaiQuan'] as bool? ?? false,
    mangDi: m['mangDi'] as bool? ?? false,
    giaoHang: m['giaoHang'] as bool? ?? false,
    diemTu: (m['diemTu'] as num?)?.toDouble(),
    tienIch: {...List<String>.from(m['tienIch'] as List? ?? const [])},
    nhanDatBan: m['nhanDatBan'] as bool? ?? false,
    loaiQuan: m['loaiQuan'] as String?,
    coKhuyenMai: m['coKhuyenMai'] as bool? ?? false,
    sapXep: SapXepQuan.values.firstWhere(
      (s) => s.name == m['sapXep'],
      orElse: () => SapXepQuan.ganNhat,
    ),
  );
}

/// Một quán trong kết quả: kèm khoảng cách và trạng thái mở cửa đã tính.
class KetQuaQuan {
  const KetQuaQuan({
    required this.quan,
    required this.moCua,
    this.khoangCach,
    this.giaoDuoc = false,
  });

  final QuanAn quan;
  final TinhTrangMoCua moCua;

  /// Mét, đường thẳng từ điểm gốc; null nếu chưa có điểm gốc hoặc quán chưa có vị trí.
  final double? khoangCach;

  /// Giao tận nơi tới điểm gốc được (hộ kinh doanh, trong bán kính giao). Chỉ tính khi có điểm gốc.
  final bool giaoDuoc;

  bool get dangMo => moCua.trangThai.dangMo;
}

/// Khoảng cách (mét) từ [goc] tới quán, null nếu thiếu dữ liệu.
double? khoangCachToiQuan(QuanAn q, DiemGoc? goc) {
  final v = q.viTri;
  if (goc == null || v == null) return null;
  return khoangCachMet(goc.lat, goc.lng, v.latitude, v.longitude);
}

/// Quán có giao tận nơi tới [goc] được không: hộ kinh doanh, đã bật đặt món, bật giao tận nơi,
/// điểm gốc nằm trong bán kính giao. Quán bán lẻ không bao giờ.
bool giaoTanNoiToi(QuanAn q, DiemGoc? goc) {
  if (!q.laHoKinhDoanh || !q.datMon.bat || !q.datMon.giaoTanNoi) return false;
  final kc = khoangCachToiQuan(q, goc);
  return kc != null && kc <= q.datMon.banKinhKm * 1000;
}

/// Quán có hiện ở sảnh không (điều kiện chung, không phụ thuộc bộ lọc của người dùng):
/// đang hoạt động và có đủ số món tối thiểu.
bool quanHienOSanh(QuanAn q, QuanAnConfig cfg) =>
    q.dangHien && q.soLieu.soMon >= cfg.monToiThieuHienThi;

/// Quán thỏa bộ lọc [f]? Chưa gồm điều kiện hiện ở sảnh ([quanHienOSanh]).
bool quanThoa(QuanAn q, QuanAnFilter f, {DiemGoc? goc, required DateTime now}) {
  final can = boDau(f.tuKhoa);
  if (can.isNotEmpty) {
    final chu = boDau(
      q.searchText.isNotEmpty
          ? q.searchText
          : '${q.ten} ${q.diaChi} ${q.phuong}',
    );
    for (final tu in can.split(' ')) {
      if (!chu.contains(tu)) return false;
    }
  }
  if (f.loaiMon.isNotEmpty && !q.loaiMon.any(f.loaiMon.contains)) return false;
  if (f.giaTu != null || f.giaDen != null) {
    final tv = q.soLieu.giaTrungVi;
    if (tv == null) return false;
    if (f.giaTu != null && tv < f.giaTu!) return false;
    if (f.giaDen != null && tv >= f.giaDen!) return false;
  }
  if (goc != null && f.banKinhMet != null) {
    final kc = khoangCachToiQuan(q, goc);
    if (kc == null || kc > f.banKinhMet!) return false;
  }
  if (f.dangMo &&
      !tinhMoCua(q.gioMoCua, now, tamNghiDen: q.tamNghiDen).trangThai.dangMo) {
    return false;
  }
  if (f.anTaiQuan && !q.phucVu.anTaiQuan) return false;
  if (f.mangDi && !q.phucVu.mangDi) return false;
  if (f.giaoHang) {
    final denLay = q.laHoKinhDoanh && q.datMon.bat && q.datMon.denLay;
    if (!denLay && !giaoTanNoiToi(q, goc)) return false;
  }
  if (f.diemTu != null) {
    // Chỉ tính điểm đã xác minh; quán chưa có đánh giá xác minh thì loại.
    if (!q.soLieu.coDiemXacMinh || q.soLieu.diemTong! < f.diemTu!) {
      return false;
    }
  }
  for (final ti in f.tienIch) {
    if (!q.tienIch.contains(ti)) return false;
  }
  if (f.nhanDatBan && !q.nhanDatBanQuaApp) return false;
  if (f.loaiQuan != null && q.loaiQuan != f.loaiQuan) return false;
  if (f.coKhuyenMai && !q.soLieu.coKhuyenMai) return false;
  return true;
}

/// Lọc và sắp xếp danh sách quán cho sảnh (mục 3.4 Bước 1, 3.2).
///
/// - Chỉ hiện quán `active` có ít nhất [QuanAnConfig.monToiThieuHienThi] món.
/// - Quán đang mở luôn xếp trước quán đã đóng; cùng điểm xếp thì hộ kinh doanh trước
///   (KHÔNG áp dụng khi chọn "Gần nhất": chỉ xếp theo khoảng cách).
List<KetQuaQuan> locQuan({
  required List<QuanAn> quan,
  required QuanAnFilter filter,
  DiemGoc? goc,
  DateTime? now,
  QuanAnConfig cfg = const QuanAnConfig(),
}) {
  final luc = now ?? DateTime.now();
  final kq = <KetQuaQuan>[];
  for (final q in quan) {
    if (!quanHienOSanh(q, cfg)) continue;
    if (!quanThoa(q, filter, goc: goc, now: luc)) continue;
    kq.add(
      KetQuaQuan(
        quan: q,
        moCua: tinhMoCua(
          q.gioMoCua,
          luc,
          tamNghiDen: q.tamNghiDen,
          sapDongPhut: cfg.sapDongPhut,
        ),
        khoangCach: khoangCachToiQuan(q, goc),
        giaoDuoc: giaoTanNoiToi(q, goc),
      ),
    );
  }
  kq.sort((a, b) => _soSanh(a, b, filter.sapXep));
  return kq;
}

int _soSanh(KetQuaQuan a, KetQuaQuan b, SapXepQuan sx) {
  // Quán đang mở luôn trước quán đã đóng / tạm nghỉ.
  if (a.dangMo != b.dangMo) return a.dangMo ? -1 : 1;
  int c;
  switch (sx) {
    case SapXepQuan.ganNhat:
      c = _tang(a.khoangCach, b.khoangCach);
      return c != 0 ? c : _moiMo(a, b);
    case SapXepQuan.danhGia:
      c = _giam(
        a.quan.soLieu.coDiemXacMinh ? a.quan.soLieu.diemTong : null,
        b.quan.soLieu.coDiemXacMinh ? b.quan.soLieu.diemTong : null,
      );
    case SapXepQuan.giaThap:
      c = _tang(a.quan.soLieu.giaTrungVi, b.quan.soLieu.giaTrungVi);
    case SapXepQuan.hayAn:
      if (a.quan.soLieu.hayAn != b.quan.soLieu.hayAn) {
        return a.quan.soLieu.hayAn ? -1 : 1;
      }
      c = b.quan.soLieu.soNguoi30Ngay.compareTo(a.quan.soLieu.soNguoi30Ngay);
    case SapXepQuan.moiMo:
      c = _moiMo(a, b);
  }
  if (c != 0) return c;
  // Cùng điểm xếp: hộ kinh doanh trước, rồi gần hơn, rồi mới mở.
  if (a.quan.laHoKinhDoanh != b.quan.laHoKinhDoanh) {
    return a.quan.laHoKinhDoanh ? -1 : 1;
  }
  c = _tang(a.khoangCach, b.khoangCach);
  return c != 0 ? c : _moiMo(a, b);
}

/// Tăng dần, giá trị null xếp cuối.
int _tang(num? a, num? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Giảm dần, giá trị null xếp cuối.
int _giam(num? a, num? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _moiMo(KetQuaQuan a, KetQuaQuan b) {
  final x = a.quan.duyetLuc ?? a.quan.taoLuc;
  final y = b.quan.duyetLuc ?? b.quan.taoLuc;
  if (x == null && y == null) return a.quan.ten.compareTo(b.quan.ten);
  if (x == null) return 1;
  if (y == null) return -1;
  final c = y.compareTo(x);
  return c != 0 ? c : a.quan.ten.compareTo(b.quan.ten);
}
