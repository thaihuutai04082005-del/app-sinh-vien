import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import 'gio_mo_cua.dart';
import 'quan_an_config.dart';

DateTime? _t(Object? v) => v is Timestamp ? v.toDate() : null;

/// Một món trong combo.
class MonCombo {
  const MonCombo({required this.monId, this.soLuong = 1});

  final String monId;
  final int soLuong;

  static MonCombo fromMap(Object? m) => MonCombo(
    monId: m is Map ? m['monId'] as String? ?? '' : '',
    soLuong: m is Map ? (m['soLuong'] as num?)?.toInt() ?? 1 : 1,
  );

  Map<String, dynamic> toMap() => {'monId': monId, 'soLuong': soLuong};
}

class ComboKm {
  const ComboKm({this.mon = const [], this.gia = 0});

  final List<MonCombo> mon;
  final num gia;

  static ComboKm? fromMap(Object? m) => m is Map
      ? ComboKm(
          mon: [
            for (final x in m['mon'] as List? ?? const []) MonCombo.fromMap(x),
          ],
          gia: m['gia'] as num? ?? 0,
        )
      : null;

  Map<String, dynamic> toMap() => {
    'mon': [for (final x in mon) x.toMap()],
    'gia': gia,
  };
}

/// Giờ vàng: khung giờ (phút từ 0:00 giờ Việt Nam) + các ngày áp dụng (1 = Thứ hai … 7 = Chủ nhật).
class GioVangKm {
  const GioVangKm({
    this.tu = 0,
    this.den = 0,
    this.ngay = const [],
    this.phanTram = 0,
    this.giamToiDa,
  });

  final int tu;
  final int den;
  final List<int> ngay;
  final num phanTram;
  final num? giamToiDa;

  static GioVangKm? fromMap(Object? m) => m is Map
      ? GioVangKm(
          tu: (m['tu'] as num?)?.toInt() ?? 0,
          den: (m['den'] as num?)?.toInt() ?? 0,
          ngay: [
            for (final x in m['ngay'] as List? ?? const []) ?int.tryParse('$x'),
          ],
          phanTram: m['phanTram'] as num? ?? 0,
          giamToiDa: m['giamToiDa'] as num?,
        )
      : null;

  Map<String, dynamic> toMap() => {
    'tu': tu,
    'den': den,
    'ngay': ngay,
    'phanTram': phanTram,
    'giamToiDa': giamToiDa,
  };

  /// "T2–T6" (ngày liên tiếp) hoặc "T2, T4, CN".
  String get ngayMoTa {
    final ds = ({...ngay}.toList()..sort());
    if (ds.isEmpty) return 'mọi ngày';
    String n(int d) => d == 7 ? 'CN' : 'T${d + 1}';
    var lienTiep = ds.length > 2;
    for (var i = 1; i < ds.length; i++) {
      if (ds[i] != ds[i - 1] + 1) lienTiep = false;
    }
    return lienTiep ? '${n(ds.first)}–${n(ds.last)}' : ds.map(n).join(', ');
  }
}

/// Khuyến mãi — collection `qa_khuyen_mai` (mục 3.3 Bước 4). Hệ thống tự tính tiền khi đặt
/// món (hộ kinh doanh); app chỉ hiển thị và không tự tính giảm giá.
class KhuyenMai {
  const KhuyenMai({
    required this.id,
    required this.quanId,
    required this.loai,
    required this.tieuDe,
    this.chuQuanId = '',
    this.phanTram,
    this.giamToiDa,
    this.giamTien,
    this.donToiThieu,
    this.combo,
    this.gioVang,
    this.batDau,
    this.ketThuc,
    this.trangThai = 'chay',
  });

  final String id;
  final String quanId;
  final String chuQuanId;

  /// giam_phan_tram | giam_tien | combo | gio_vang | sinh_vien
  final String loai;
  final String tieuDe;
  final num? phanTram;
  final num? giamToiDa;
  final num? giamTien;
  final num? donToiThieu;
  final ComboKm? combo;
  final GioVangKm? gioVang;
  final DateTime? batDau;
  final DateTime? ketThuc;

  /// chay | dung | het_han
  final String trangThai;

  String get loaiLabel => loaiKhuyenMaiLabels[loai] ?? loai;

  /// Đang chạy và nằm trong [batDau, ketThuc] (ngày kết thúc tính hết).
  bool conHieuLuc(DateTime now) =>
      trangThai == 'chay' &&
      (batDau == null || !now.isBefore(batDau!)) &&
      (ketThuc == null || !now.isAfter(ketThuc!));

  String _k(num v) => formatGiaGon(v);

  String get _dieuKien => donToiThieu != null && donToiThieu! > 0
      ? ' cho đơn từ ${_k(donToiThieu!)}'
      : '';

  /// Mô tả ngắn, ví dụ "Giảm 10% tối đa 20k cho đơn từ 50k".
  String get moTaNgan {
    switch (loai) {
      case 'giam_phan_tram':
        final toiDa = giamToiDa != null && giamToiDa! > 0
            ? ' tối đa ${_k(giamToiDa!)}'
            : '';
        return 'Giảm ${_pt(phanTram ?? 0)}%$toiDa$_dieuKien';
      case 'giam_tien':
        return 'Giảm ${_k(giamTien ?? 0)}$_dieuKien';
      case 'combo':
        final c = combo;
        final soMon = c?.mon.fold<int>(0, (s, m) => s + m.soLuong) ?? 0;
        return soMon > 0
            ? 'Combo $soMon món chỉ ${_k(c!.gia)}'
            : 'Combo ${_k(c?.gia ?? 0)}';
      case 'gio_vang':
        final g = gioVang;
        if (g == null) return tieuDe;
        final toiDa = g.giamToiDa != null && g.giamToiDa! > 0
            ? ' tối đa ${_k(g.giamToiDa!)}'
            : '';
        return 'Giờ vàng ${phutHienThi(g.tu)}–${phutHienThi(g.den)} ${g.ngayMoTa} '
            'giảm ${_pt(g.phanTram)}%$toiDa';
      case 'sinh_vien':
        final giam = phanTram != null && phanTram! > 0
            ? '${_pt(phanTram!)}%'
            : _k(giamTien ?? 0);
        return 'Ưu đãi sinh viên: giảm $giam$_dieuKien';
    }
    return tieuDe;
  }

  static String _pt(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  factory KhuyenMai.fromMap(String id, Map<String, dynamic> m) => KhuyenMai(
    id: id,
    quanId: m['quanId'] as String? ?? '',
    chuQuanId: m['chuQuanId'] as String? ?? '',
    loai: m['loai'] as String? ?? 'giam_tien',
    tieuDe: m['tieuDe'] as String? ?? '',
    phanTram: m['phanTram'] as num?,
    giamToiDa: m['giamToiDa'] as num?,
    giamTien: m['giamTien'] as num?,
    donToiThieu: m['donToiThieu'] as num?,
    combo: ComboKm.fromMap(m['combo']),
    gioVang: GioVangKm.fromMap(m['gioVang']),
    batDau: _t(m['batDau']),
    ketThuc: _t(m['ketThuc']),
    trangThai: m['trangThai'] as String? ?? 'chay',
  );

  /// Tham số hành động `luuKhuyenMai` (thời điểm gửi bằng mili giây).
  Map<String, dynamic> toApiMap() => {
    'quanId': quanId,
    if (id.isNotEmpty) 'khuyenMaiId': id,
    'loai': loai,
    'tieuDe': tieuDe,
    if (phanTram != null) 'phanTram': phanTram,
    if (giamToiDa != null) 'giamToiDa': giamToiDa,
    if (giamTien != null) 'giamTien': giamTien,
    if (donToiThieu != null) 'donToiThieu': donToiThieu,
    if (combo != null) 'combo': combo!.toMap(),
    if (gioVang != null) 'gioVang': gioVang!.toMap(),
    if (batDau != null) 'batDau': batDau!.millisecondsSinceEpoch,
    if (ketThuc != null) 'ketThuc': ketThuc!.millisecondsSinceEpoch,
  };
}
