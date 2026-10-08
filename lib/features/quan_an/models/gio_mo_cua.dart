import '../../../core/utils/formatters.dart';
import 'quan_an_config.dart';

/// Một ca mở cửa: số phút kể từ 0:00 giờ Việt Nam. Ca qua nửa đêm có `den < tu`
/// (18:00–02:00 = tu 1080, den 120) và thuộc NGÀY BẮT ĐẦU ca (mục 3.2).
class CaMoCua {
  const CaMoCua({required this.tu, required this.den});

  final int tu;
  final int den;

  bool get quaNuaDem => den < tu;

  static CaMoCua? fromMap(Object? m) {
    if (m is! Map || m['tu'] is! num || m['den'] is! num) return null;
    return CaMoCua(
      tu: (m['tu'] as num).toInt(),
      den: (m['den'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {'tu': tu, 'den': den};

  @override
  bool operator ==(Object other) =>
      other is CaMoCua && other.tu == tu && other.den == den;

  @override
  int get hashCode => Object.hash(tu, den);

  @override
  String toString() => '${phutHienThi(tu)}–${phutHienThi(den)}';
}

/// Lịch tuần: khóa 1 = Thứ hai … 7 = Chủ nhật; danh sách rỗng hoặc thiếu khóa = nghỉ.
typedef LichMoCua = Map<int, List<CaMoCua>>;

/// Đọc lịch từ Firestore (`{"1": [{tu, den}], ...}`); bỏ qua phần tử sai dạng.
LichMoCua lichTuMap(Object? m) {
  final kq = <int, List<CaMoCua>>{};
  if (m is! Map) return kq;
  m.forEach((k, v) {
    final ngay = int.tryParse('$k');
    if (ngay == null || ngay < 1 || ngay > 7 || v is! List) return;
    kq[ngay] = [for (final x in v) ?CaMoCua.fromMap(x)];
  });
  return kq;
}

/// Ghi lịch ra Map để lưu (đủ 7 ngày, ngày nghỉ = mảng rỗng).
Map<String, dynamic> lichToMap(LichMoCua lich) => {
  for (var d = 1; d <= 7; d++)
    '$d': [for (final ca in lich[d] ?? const <CaMoCua>[]) ca.toMap()],
};

/// "6:00", "21:30" — phút kể từ 0:00. Giờ không thêm số 0 đứng đầu.
String phutHienThi(int phut) {
  final p = phut % (24 * 60);
  return '${p ~/ 60}:${(p % 60).toString().padLeft(2, '0')}';
}

const _tenThu = {
  1: 'Thứ hai',
  2: 'Thứ ba',
  3: 'Thứ tư',
  4: 'Thứ năm',
  5: 'Thứ sáu',
  6: 'Thứ bảy',
  7: 'Chủ nhật',
};

String tenThu(int ngay) => _tenThu[ngay] ?? '';

/// "6:00–10:00 · 16:00–21:00" hoặc "Nghỉ".
String tomTatNgay(List<CaMoCua>? ca) =>
    ca == null || ca.isEmpty ? 'Nghỉ' : ca.map((c) => c.toString()).join(' · ');

/// Một khoảng mở cửa cụ thể trên trục thời gian thật.
class KhoangMoCua {
  const KhoangMoCua({required this.tu, required this.den});

  /// Giờ mở và giờ đóng (thời điểm thật, UTC).
  final DateTime tu;
  final DateTime den;

  bool chua(DateTime t) => !t.isBefore(tu) && t.isBefore(den);
}

enum TrangThaiMoCua {
  mo('Đang mở cửa'),
  sapDong('Sắp đóng cửa'),
  dong('Đã đóng cửa'),
  tamNghi('Tạm nghỉ');

  const TrangThaiMoCua(this.label);
  final String label;

  /// Mã trong hợp đồng (`mo`, `sap_dong`, `dong`, `tam_nghi`).
  String get ma => switch (this) {
    TrangThaiMoCua.mo => 'mo',
    TrangThaiMoCua.sapDong => 'sap_dong',
    TrangThaiMoCua.dong => 'dong',
    TrangThaiMoCua.tamNghi => 'tam_nghi',
  };

  bool get dangMo => this == mo || this == sapDong;
}

/// Kết quả đầy đủ: trạng thái, câu hiển thị, giờ đóng / giờ mở kế tiếp.
class TinhTrangMoCua {
  const TinhTrangMoCua({
    required this.trangThai,
    required this.thongDiep,
    this.dongLuc,
    this.moLuc,
  });

  final TrangThaiMoCua trangThai;

  /// "Đang mở · Đóng lúc 21:00", "Sắp đóng · 20:40", "Mở lúc 6:00 sáng mai", "Tạm nghỉ đến …".
  final String thongDiep;

  /// Giờ đóng của ca đang mở (khi mở / sắp đóng).
  final DateTime? dongLuc;

  /// Giờ mở của ca kế tiếp (khi đóng / tạm nghỉ, nếu có lịch).
  final DateTime? moLuc;
}

/// Các khoảng mở cửa quanh [now] (từ hôm qua tới [soNgaySau] ngày sau), đã gộp ca nối liền nhau.
List<KhoangMoCua> _cacKhoang(LichMoCua lich, DateTime now, int soNgaySau) {
  // Đồng hồ Việt Nam được biểu diễn bằng DateTime UTC để cộng trừ không dính múi giờ máy.
  final vn = gioVietNam(now);
  final nuaDem = DateTime.utc(vn.year, vn.month, vn.day);
  const bu = Duration(hours: 7);
  final ds = <(DateTime, DateTime)>[];
  for (var d = -1; d <= soNgaySau; d++) {
    final goc = nuaDem.add(Duration(days: d));
    final thu = goc.weekday; // 1 = Thứ hai … 7 = Chủ nhật, khớp khóa lịch
    for (final ca in lich[thu] ?? const <CaMoCua>[]) {
      if (ca.den == ca.tu) continue;
      final tu = goc.add(Duration(minutes: ca.tu));
      final den = goc.add(
        Duration(minutes: ca.den, days: ca.quaNuaDem ? 1 : 0),
      );
      ds.add((tu.subtract(bu), den.subtract(bu)));
    }
  }
  ds.sort((a, b) => a.$1.compareTo(b.$1));
  final gop = <KhoangMoCua>[];
  for (final (tu, den) in ds) {
    if (gop.isNotEmpty && !tu.isAfter(gop.last.den)) {
      final cu = gop.removeLast();
      gop.add(KhoangMoCua(tu: cu.tu, den: den.isAfter(cu.den) ? den : cu.den));
    } else {
      gop.add(KhoangMoCua(tu: tu, den: den));
    }
  }
  return gop;
}

/// Ca đang mở tại [now] (kể cả ca qua nửa đêm bắt đầu từ hôm qua); null nếu đang đóng.
KhoangMoCua? caDangMo(LichMoCua lich, DateTime now) {
  for (final k in _cacKhoang(lich, now, 1)) {
    if (k.chua(now)) return k;
  }
  return null;
}

/// Có mở cửa tại thời điểm [t] theo lịch tuần không (không tính tạm nghỉ).
bool coMoTai(LichMoCua lich, DateTime t) => caDangMo(lich, t) != null;

/// Giờ đóng cửa của ca đang mở; null nếu đang đóng.
DateTime? gioDongCuaCaDangMo(LichMoCua lich, DateTime now) =>
    caDangMo(lich, now)?.den;

/// Ca mở kế tiếp bắt đầu SAU [now] (trong 8 ngày tới); null nếu lịch trống.
KhoangMoCua? caKeTiep(LichMoCua lich, DateTime now) {
  for (final k in _cacKhoang(lich, now, 8)) {
    if (k.tu.isAfter(now)) return k;
  }
  return null;
}

/// Giờ quán sẽ mở lại sau "Tạm nghỉ hôm nay": ca đầu tiên theo lịch tuần tính từ NGÀY MAI
/// (mục 3.2). Null nếu lịch trống.
DateTime? moLaiSauTamNghiHomNay(LichMoCua lich, DateTime now) {
  final vn = gioVietNam(now);
  final maiVn = DateTime.utc(
    vn.year,
    vn.month,
    vn.day,
  ).add(const Duration(days: 1));
  final mai = maiVn.subtract(const Duration(hours: 7));
  for (final k in _cacKhoang(lich, now, 9)) {
    if (!k.tu.isBefore(mai)) return k.tu;
  }
  return null;
}

String _buoi(int gio) {
  if (gio < 11) return 'sáng';
  if (gio < 13) return 'trưa';
  if (gio < 18) return 'chiều';
  return 'tối';
}

String _gioPhut(DateTime t) {
  final v = gioVietNam(t);
  return phutHienThi(v.hour * 60 + v.minute);
}

DateTime _ngayVn(DateTime t) {
  final v = gioVietNam(t);
  return DateTime.utc(v.year, v.month, v.day);
}

String _moTaMoLuc(DateTime moLuc, DateTime now) {
  final chenh = _ngayVn(moLuc).difference(_ngayVn(now)).inDays;
  final v = gioVietNam(moLuc);
  final gio = _gioPhut(moLuc);
  if (chenh <= 0) return 'Mở lúc $gio hôm nay';
  if (chenh == 1) return 'Mở lúc $gio ${_buoi(v.hour)} mai';
  return 'Mở lúc $gio ${tenThu(v.weekday)}';
}

String _moTaTamNghi(DateTime den) {
  final v = gioVietNam(den);
  final dauNgay = v.hour == 0 && v.minute == 0;
  return 'Tạm nghỉ đến ${dauNgay ? formatNgay(den) : formatNgayGio(den)}';
}

/// Tính trạng thái mở cửa thuần Dart (mọi giờ theo UTC+7).
///
/// Thứ tự: tạm nghỉ ([tamNghiDen] còn ở tương lai) → đang trong ca (mở / sắp đóng khi còn
/// ≤ [sapDongPhut] phút) → đóng. [sapDongPhut] mặc định lấy từ [QuanAnConfig].
TinhTrangMoCua tinhMoCua(
  LichMoCua lich,
  DateTime now, {
  DateTime? tamNghiDen,
  int? sapDongPhut,
}) {
  if (tamNghiDen != null && now.isBefore(tamNghiDen)) {
    return TinhTrangMoCua(
      trangThai: TrangThaiMoCua.tamNghi,
      thongDiep: _moTaTamNghi(tamNghiDen),
      moLuc: tamNghiDen,
    );
  }
  final nguong = sapDongPhut ?? const QuanAnConfig().sapDongPhut;
  final ca = caDangMo(lich, now);
  if (ca != null) {
    final conLai = ca.den.difference(now);
    final gio = _gioPhut(ca.den);
    if (conLai <= Duration(minutes: nguong)) {
      return TinhTrangMoCua(
        trangThai: TrangThaiMoCua.sapDong,
        thongDiep: 'Sắp đóng · $gio',
        dongLuc: ca.den,
      );
    }
    return TinhTrangMoCua(
      trangThai: TrangThaiMoCua.mo,
      thongDiep: 'Đang mở · Đóng lúc $gio',
      dongLuc: ca.den,
    );
  }
  final tiep = caKeTiep(lich, now);
  return TinhTrangMoCua(
    trangThai: TrangThaiMoCua.dong,
    thongDiep: tiep == null ? 'Chưa có giờ mở cửa' : _moTaMoLuc(tiep.tu, now),
    moLuc: tiep?.tu,
  );
}

/// Chỉ lấy trạng thái (xem [tinhMoCua] nếu cần cả câu hiển thị).
TrangThaiMoCua trangThaiMoCua(
  LichMoCua lich,
  DateTime now, {
  DateTime? tamNghiDen,
  int? sapDongPhut,
}) => tinhMoCua(
  lich,
  now,
  tamNghiDen: tamNghiDen,
  sapDongPhut: sapDongPhut,
).trangThai;

/// Câu hiển thị trạng thái mở cửa.
String thongDiepMoCua(
  LichMoCua lich,
  DateTime now, {
  DateTime? tamNghiDen,
  int? sapDongPhut,
}) => tinhMoCua(
  lich,
  now,
  tamNghiDen: tamNghiDen,
  sapDongPhut: sapDongPhut,
).thongDiep;
