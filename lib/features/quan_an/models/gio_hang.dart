/// Một tùy chọn khách đã chọn cho món: nhóm ("Cỡ"), tên lựa chọn ("Lớn"), giá cộng thêm.
class TuyChonDaChon {
  const TuyChonDaChon({
    required this.nhom,
    required this.ten,
    this.giaThem = 0,
  });

  final String nhom;
  final String ten;
  final num giaThem;

  static TuyChonDaChon fromMap(Object? m) {
    final x = m as Map? ?? const {};
    return TuyChonDaChon(
      nhom: x['nhom'] as String? ?? '',
      // Giỏ lưu `ten`; đơn đã chốt cũng dùng `ten`; tham số API gọi là `lua`.
      ten: (x['ten'] ?? x['lua']) as String? ?? '',
      giaThem: x['giaThem'] as num? ?? 0,
    );
  }

  /// Dạng lưu (giỏ, đơn đã chốt).
  Map<String, dynamic> toMap() => {
    'nhom': nhom,
    'ten': ten,
    'giaThem': giaThem,
  };

  /// Dạng gửi lên `baoGiaDon` / `datMon`: không gửi giá, hệ thống tự tra.
  Map<String, dynamic> toApi() => {'nhom': nhom, 'lua': ten};

  @override
  bool operator ==(Object other) =>
      other is TuyChonDaChon && other.nhom == nhom && other.ten == ten;

  @override
  int get hashCode => Object.hash(nhom, ten);
}

/// Một dòng trong giỏ: món + tùy chọn + ghi chú + số lượng. `gia` là giá niêm yết lúc bỏ vào giỏ
/// (chỉ để hiển thị tạm tính; giá thật do hệ thống tính lại khi đặt).
class DongGioHang {
  const DongGioHang({
    required this.monId,
    required this.ten,
    required this.gia,
    this.soLuong = 1,
    this.tuyChon = const [],
    this.ghiChu = '',
    this.anh = '',
  });

  final String monId;
  final String ten;
  final num gia;
  final int soLuong;
  final List<TuyChonDaChon> tuyChon;
  final String ghiChu;
  final String anh;

  /// Giá một phần = giá món + giá cộng thêm của các tùy chọn.
  num get donGia => gia + tuyChon.fold<num>(0, (s, t) => s + t.giaThem);
  num get thanhTien => donGia * soLuong;

  /// Hai dòng cùng khóa thì gộp số lượng: cùng món, cùng tùy chọn (không phân thứ tự), cùng ghi chú.
  String get khoa {
    final tc = [for (final t in tuyChon) '${t.nhom}=${t.ten}']..sort();
    return '$monId|${tc.join(',')}|${ghiChu.trim()}';
  }

  DongGioHang copyWith({int? soLuong}) => DongGioHang(
    monId: monId,
    ten: ten,
    gia: gia,
    soLuong: soLuong ?? this.soLuong,
    tuyChon: tuyChon,
    ghiChu: ghiChu,
    anh: anh,
  );

  /// Một phần tử của tham số `items` (hợp đồng `baoGiaDon`): không có giá.
  Map<String, dynamic> toApiItem() => {
    'monId': monId,
    'soLuong': soLuong,
    'tuyChon': [for (final t in tuyChon) t.toApi()],
    'ghiChu': ghiChu.trim(),
  };

  Map<String, dynamic> toJson() => {
    'monId': monId,
    'ten': ten,
    'gia': gia,
    'soLuong': soLuong,
    'tuyChon': [for (final t in tuyChon) t.toMap()],
    'ghiChu': ghiChu,
    'anh': anh,
  };

  static DongGioHang? fromJson(Object? m) {
    if (m is! Map || m['monId'] is! String) return null;
    return DongGioHang(
      monId: m['monId'] as String,
      ten: m['ten'] as String? ?? '',
      gia: m['gia'] as num? ?? 0,
      soLuong: (m['soLuong'] as num?)?.toInt() ?? 1,
      tuyChon: [
        for (final t in m['tuyChon'] as List? ?? const [])
          TuyChonDaChon.fromMap(t),
      ],
      ghiChu: m['ghiChu'] as String? ?? '',
      anh: m['anh'] as String? ?? '',
    );
  }
}

/// Giỏ hàng thuần (không phụ thuộc Flutter), bất biến: mọi thao tác trả về giỏ mới.
///
/// Giỏ chỉ chứa món của MỘT quán (mục 3.4 Bước 5a). Thêm món quán khác: gọi [khacQuan] để hỏi
/// "Xóa giỏ hiện tại?", đồng ý thì dùng [GioHang.moi]. Giỏ KHÔNG tính khuyến mãi — hệ thống tính.
class GioHang {
  const GioHang({this.quanId = '', this.tenQuan = '', this.dong = const []});

  static const rong = GioHang();

  final String quanId;
  final String tenQuan;
  final List<DongGioHang> dong;

  bool get laRong => dong.isEmpty;

  /// Tổng số phần (cộng số lượng các dòng) — hiện ở nút "Xem giỏ (2 món · 70k)".
  int get soMon => dong.fold(0, (s, d) => s + d.soLuong);

  /// Tạm tính chỉ để hiển thị: tổng (giá món + tùy chọn) × số lượng, KHÔNG gồm phí giao, KHÔNG trừ khuyến mãi.
  num get tamTinh => dong.fold<num>(0, (s, d) => s + d.thanhTien);

  /// Số phần của món [monId] đang có trong giỏ (mọi dòng).
  int soLuongMon(String monId) =>
      dong.where((d) => d.monId == monId).fold(0, (s, d) => s + d.soLuong);

  /// Thêm món vào giỏ của chính quán này sẽ cần xác nhận xóa giỏ cũ không.
  bool khacQuan(String quanIdMoi) => !laRong && quanId != quanIdMoi;

  /// Giỏ mới chỉ chứa [d] của quán [quanIdMoi] (dùng sau khi khách đồng ý bỏ giỏ cũ).
  static GioHang moi(String quanIdMoi, String tenQuanMoi, DongGioHang d) =>
      GioHang(quanId: quanIdMoi, tenQuan: tenQuanMoi, dong: [d]);

  /// Thêm [d]; cùng khóa với dòng có sẵn thì cộng số lượng.
  /// Quán khác với quán trong giỏ: ném [StateError] (hãy kiểm tra [khacQuan] trước).
  GioHang them(
    DongGioHang d, {
    required String quanId,
    required String tenQuan,
  }) {
    if (khacQuan(quanId)) {
      throw StateError('Giỏ đang có món của quán khác.');
    }
    final ds = [...dong];
    final i = ds.indexWhere((x) => x.khoa == d.khoa);
    if (i >= 0) {
      ds[i] = ds[i].copyWith(soLuong: ds[i].soLuong + d.soLuong);
    } else {
      ds.add(d);
    }
    return GioHang(quanId: quanId, tenQuan: tenQuan, dong: ds);
  }

  /// Bớt [n] phần của dòng có khóa [khoa]; về 0 thì xóa dòng. Giỏ hết dòng thì thành giỏ rỗng.
  GioHang boBot(String khoa, [int n = 1]) {
    final ds = <DongGioHang>[];
    for (final d in dong) {
      if (d.khoa != khoa) {
        ds.add(d);
      } else if (d.soLuong - n > 0) {
        ds.add(d.copyWith(soLuong: d.soLuong - n));
      }
    }
    return _chuan(ds);
  }

  /// Xóa hẳn dòng có khóa [khoa].
  GioHang xoa(String khoa) => _chuan([
    for (final d in dong)
      if (d.khoa != khoa) d,
  ]);

  GioHang _chuan(List<DongGioHang> ds) => ds.isEmpty
      ? GioHang.rong
      : GioHang(quanId: quanId, tenQuan: tenQuan, dong: ds);

  /// Tham số `items` của `baoGiaDon` / `datMon` (không gửi giá).
  List<Map<String, dynamic>> toApiItems() => [
    for (final d in dong) d.toApiItem(),
  ];

  Map<String, dynamic> toJson() => {
    'quanId': quanId,
    'tenQuan': tenQuan,
    'dong': [for (final d in dong) d.toJson()],
  };

  static GioHang fromJson(Object? m) {
    if (m is! Map) return GioHang.rong;
    final ds = [
      for (final x in m['dong'] as List? ?? const []) ?DongGioHang.fromJson(x),
    ];
    final id = m['quanId'] as String? ?? '';
    if (ds.isEmpty || id.isEmpty) return GioHang.rong;
    return GioHang(
      quanId: id,
      tenQuan: m['tenQuan'] as String? ?? '',
      dong: ds,
    );
  }
}
