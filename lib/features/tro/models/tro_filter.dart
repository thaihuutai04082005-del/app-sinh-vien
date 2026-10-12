import 'dart:math' as math;

import 'nha_tro.dart';
import 'phong_tro.dart';

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

/// Khoảng cách đường thẳng (mét) giữa 2 điểm — mục 2.7.
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

enum SapXep {
  ganNhat('Gần nhất'),
  giaThap('Giá thấp nhất'),
  moiNhat('Mới nhất'),
  danhGia('Đánh giá cao nhất');

  const SapXep(this.label);
  final String label;
}

/// Tiện ích lọc được: của PHÒNG hay của NHÀ TRỌ (mục 2.4 "Cách lọc hoạt động").
const tienIchLocPhong = {'may_lanh', 'wc_rieng'};
const tienIchLocNha = {'wifi', 'cho_de_xe', 'camera', 'may_giat'};

/// Bộ lọc sảnh (mục 2.4 Bước 1). App nhớ bộ lọc lần trước qua [toJson].
class TroFilter {
  const TroFilter({
    this.tuKhoa = '',
    this.loaiHinh,
    this.coGac,
    this.banKinhMet,
    this.giaTu,
    this.giaDen,
    this.tienIch = const {},
    this.tuDo24 = false,
    this.veMuonToi,
    this.thuCung = false,
    this.oQuaDem = false,
    this.baoTruocToiDa,
    this.chiConPhong = true,
    this.sapXep = SapXep.ganNhat,
  });

  final String tuKhoa;

  /// null | 'phong' | 'nguyen_can'
  final String? loaiHinh;

  /// Chỉ áp khi [loaiHinh] = 'phong'.
  final bool? coGac;
  final int? banKinhMet;
  final int? giaTu;
  final int? giaDen;
  final Set<String> tienIch;

  /// "Tự do 24/24": chỉ trọ không có giờ đóng cửa.
  final bool tuDo24;

  /// "Về muộn được tới ít nhất HH:mm": trọ tự do + trọ đóng cửa từ giờ đó trở đi.
  final String? veMuonToi;
  final bool thuCung;
  final bool oQuaDem;

  /// "Báo trước tối đa N tuần": trọ báo trước ≤ N tuần.
  final int? baoTruocToiDa;
  final bool chiConPhong;
  final SapXep sapXep;

  static const macDinh = TroFilter();

  bool get dangLoc =>
      loaiHinh != null ||
      coGac != null ||
      banKinhMet != null ||
      giaTu != null ||
      giaDen != null ||
      tienIch.isNotEmpty ||
      tuDo24 ||
      veMuonToi != null ||
      thuCung ||
      oQuaDem ||
      baoTruocToiDa != null ||
      !chiConPhong;

  TroFilter copyWith({
    String? tuKhoa,
    Object? loaiHinh = _giuNguyen,
    Object? coGac = _giuNguyen,
    Object? banKinhMet = _giuNguyen,
    Object? giaTu = _giuNguyen,
    Object? giaDen = _giuNguyen,
    Set<String>? tienIch,
    bool? tuDo24,
    Object? veMuonToi = _giuNguyen,
    bool? thuCung,
    bool? oQuaDem,
    Object? baoTruocToiDa = _giuNguyen,
    bool? chiConPhong,
    SapXep? sapXep,
  }) => TroFilter(
    tuKhoa: tuKhoa ?? this.tuKhoa,
    loaiHinh: loaiHinh == _giuNguyen ? this.loaiHinh : loaiHinh as String?,
    coGac: coGac == _giuNguyen ? this.coGac : coGac as bool?,
    banKinhMet: banKinhMet == _giuNguyen ? this.banKinhMet : banKinhMet as int?,
    giaTu: giaTu == _giuNguyen ? this.giaTu : giaTu as int?,
    giaDen: giaDen == _giuNguyen ? this.giaDen : giaDen as int?,
    tienIch: tienIch ?? this.tienIch,
    tuDo24: tuDo24 ?? this.tuDo24,
    veMuonToi: veMuonToi == _giuNguyen ? this.veMuonToi : veMuonToi as String?,
    thuCung: thuCung ?? this.thuCung,
    oQuaDem: oQuaDem ?? this.oQuaDem,
    baoTruocToiDa: baoTruocToiDa == _giuNguyen
        ? this.baoTruocToiDa
        : baoTruocToiDa as int?,
    chiConPhong: chiConPhong ?? this.chiConPhong,
    sapXep: sapXep ?? this.sapXep,
  );

  /// Xóa bộ lọc nhưng giữ từ khóa và cách sắp xếp.
  TroFilter xoaLoc() => TroFilter(tuKhoa: tuKhoa, sapXep: sapXep);

  Map<String, dynamic> toJson() => {
    'loaiHinh': loaiHinh,
    'coGac': coGac,
    'banKinhMet': banKinhMet,
    'giaTu': giaTu,
    'giaDen': giaDen,
    'tienIch': tienIch.toList(),
    'tuDo24': tuDo24,
    'veMuonToi': veMuonToi,
    'thuCung': thuCung,
    'oQuaDem': oQuaDem,
    'baoTruocToiDa': baoTruocToiDa,
    'chiConPhong': chiConPhong,
    'sapXep': sapXep.name,
  };

  static TroFilter fromJson(Map<String, dynamic> m) => TroFilter(
    loaiHinh: m['loaiHinh'] as String?,
    coGac: m['coGac'] as bool?,
    banKinhMet: (m['banKinhMet'] as num?)?.toInt(),
    giaTu: (m['giaTu'] as num?)?.toInt(),
    giaDen: (m['giaDen'] as num?)?.toInt(),
    tienIch: {...List<String>.from(m['tienIch'] as List? ?? const [])},
    tuDo24: m['tuDo24'] as bool? ?? false,
    veMuonToi: m['veMuonToi'] as String?,
    thuCung: m['thuCung'] as bool? ?? false,
    oQuaDem: m['oQuaDem'] as bool? ?? false,
    baoTruocToiDa: (m['baoTruocToiDa'] as num?)?.toInt(),
    chiConPhong: m['chiConPhong'] as bool? ?? true,
    sapXep: SapXep.values.firstWhere(
      (s) => s.name == m['sapXep'],
      orElse: () => SapXep.ganNhat,
    ),
  );
}

const _giuNguyen = Object();

int _phutTu(String hhmm) {
  final p = hhmm.split(':');
  final phut = int.parse(p[0]) * 60 + int.parse(p[1]);
  return phut < 4 * 60 ? phut + 24 * 60 : phut;
}

/// Một nhà trọ trong kết quả: các phòng phù hợp nằm trên cùng ở trang chi tiết.
class KetQuaNhaTro {
  const KetQuaNhaTro({
    required this.nhaTro,
    required this.phongPhuHop,
    this.khoangCach,
  });

  final NhaTro nhaTro;
  final List<PhongTro> phongPhuHop;
  final double? khoangCach;

  bool get hetPhong => phongPhuHop.isEmpty;

  num? get giaThapNhat => phongPhuHop.isEmpty
      ? nhaTro.soLieu.giaMin
      : phongPhuHop.map((p) => p.giaThue).reduce(math.min);
}

class KetQuaLoc {
  const KetQuaLoc(this.danhSach);

  final List<KetQuaNhaTro> danhSach;

  int get soNhaTro => danhSach.length;
  int get soPhong => danhSach.fold(0, (s, k) => s + k.phongPhuHop.length);
}

/// Lọc theo cấp NHÀ TRỌ: từ khóa, loại hình, nội quy, tiện ích chung, bán kính.
bool nhaTroThoa(NhaTro n, TroFilter f, {DiemGoc? goc}) {
  if (f.tuKhoa.trim().isNotEmpty) {
    final can = boDau(f.tuKhoa);
    final chu = boDau('${n.ten} ${n.diaChi} ${n.phuong}');
    if (can.isNotEmpty && !chu.contains(can)) return false;
  }
  if (f.loaiHinh != null && n.loaiHinh != f.loaiHinh) return false;
  final nq = n.noiQuy;
  if (f.tuDo24 && !(nq?.tuDo ?? false)) return false;
  if (f.veMuonToi != null && nq != null && !nq.tuDo) {
    final dong = nq.phutDongCua;
    if (dong == null || dong < _phutTu(f.veMuonToi!)) return false;
  }
  if (f.thuCung && !(nq?.thuCung ?? false)) return false;
  if (f.oQuaDem && !(nq?.oQuaDem ?? false)) return false;
  if (f.baoTruocToiDa != null &&
      (nq == null || nq.baoTruocTuan > f.baoTruocToiDa!)) {
    return false;
  }
  for (final ti in f.tienIch.intersection(tienIchLocNha)) {
    if (!n.tienIchChung.contains(ti)) return false;
  }
  if (goc != null && f.banKinhMet != null) {
    final v = n.viTri;
    if (v == null) return false;
    if (khoangCachMet(goc.lat, goc.lng, v.latitude, v.longitude) >
        f.banKinhMet!) {
      return false;
    }
  }
  return true;
}

/// Lọc theo cấp PHÒNG: giá, gác, tiện ích trong phòng; chỉ phòng "Còn trống".
bool phongThoa(PhongTro p, TroFilter f) {
  if (!p.conTrong || p.daXoa) return false;
  if (f.giaTu != null && p.giaThue < f.giaTu!) return false;
  if (f.giaDen != null && p.giaThue > f.giaDen!) return false;
  if (f.loaiHinh == 'phong' && f.coGac != null && p.coGac != f.coGac) {
    return false;
  }
  for (final ti in f.tienIch.intersection(tienIchLocPhong)) {
    if (!p.tienIch.contains(ti)) return false;
  }
  return true;
}

/// Danh sách hiện NHÀ TRỌ; nhà trọ được hiện khi có ít nhất 1 phòng "Còn trống" thỏa điều kiện.
/// Tắt "Chỉ hiện nơi còn phòng" thì nhà trọ hết phòng (thỏa điều kiện cấp nhà) hiện ở cuối.
KetQuaLoc locNhaTro({
  required List<NhaTro> nhaTro,
  required List<PhongTro> phong,
  required TroFilter filter,
  DiemGoc? goc,
}) {
  final theoNha = <String, List<PhongTro>>{};
  for (final p in phong) {
    if (phongThoa(p, filter)) theoNha.putIfAbsent(p.nhaTroId, () => []).add(p);
  }
  final conPhong = <KetQuaNhaTro>[];
  final hetPhong = <KetQuaNhaTro>[];
  for (final n in nhaTro) {
    if (!n.dangHien || !nhaTroThoa(n, filter, goc: goc)) continue;
    final v = n.viTri;
    final kc = goc != null && v != null
        ? khoangCachMet(goc.lat, goc.lng, v.latitude, v.longitude)
        : null;
    final ds = theoNha[n.id] ?? const <PhongTro>[];
    if (ds.isNotEmpty) {
      conPhong.add(
        KetQuaNhaTro(
          nhaTro: n,
          phongPhuHop: [...ds]..sort((a, b) => a.giaThue.compareTo(b.giaThue)),
          khoangCach: kc,
        ),
      );
    } else if (!filter.chiConPhong && !n.conPhong) {
      hetPhong.add(
        KetQuaNhaTro(nhaTro: n, phongPhuHop: const [], khoangCach: kc),
      );
    }
  }
  int so(KetQuaNhaTro a, KetQuaNhaTro b) {
    switch (filter.sapXep) {
      case SapXep.ganNhat:
        if (a.khoangCach != null && b.khoangCach != null) {
          return a.khoangCach!.compareTo(b.khoangCach!);
        }
        return _moiNhat(a, b);
      case SapXep.giaThap:
        return (a.giaThapNhat ?? double.infinity).compareTo(
          b.giaThapNhat ?? double.infinity,
        );
      case SapXep.moiNhat:
        return _moiNhat(a, b);
      case SapXep.danhGia:
        return (b.nhaTro.soLieu.diem ?? -1).compareTo(
          a.nhaTro.soLieu.diem ?? -1,
        );
    }
  }

  conPhong.sort(so);
  hetPhong.sort(so);
  return KetQuaLoc([...conPhong, ...hetPhong]);
}

int _moiNhat(KetQuaNhaTro a, KetQuaNhaTro b) =>
    (b.nhaTro.taoLuc ?? DateTime(0)).compareTo(a.nhaTro.taoLuc ?? DateTime(0));
