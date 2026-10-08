/// Một lựa chọn trong nhóm tùy chọn (ví dụ "Lớn" +5.000đ).
class LuaChon {
  const LuaChon({required this.ten, this.giaThem = 0});

  final String ten;
  final num giaThem;

  static LuaChon fromMap(Object? m) => LuaChon(
    ten: m is Map ? m['ten'] as String? ?? '' : '',
    giaThem: m is Map ? m['giaThem'] as num? ?? 0 : 0,
  );

  Map<String, dynamic> toMap() => {'ten': ten, 'giaThem': giaThem};
}

/// Nhóm tùy chọn của món (Cỡ, Topping...). `toiDa` = 1: chọn 1; > 1: chọn nhiều.
class NhomTuyChon {
  const NhomTuyChon({
    required this.ten,
    this.batBuoc = false,
    this.toiDa = 1,
    this.lua = const [],
  });

  final String ten;
  final bool batBuoc;
  final int toiDa;
  final List<LuaChon> lua;

  bool get chonNhieu => toiDa > 1;

  static NhomTuyChon fromMap(Object? m) {
    final x = m as Map? ?? const {};
    return NhomTuyChon(
      ten: x['ten'] as String? ?? '',
      batBuoc: x['batBuoc'] as bool? ?? false,
      toiDa: (x['toiDa'] as num?)?.toInt() ?? 1,
      lua: [for (final l in x['lua'] as List? ?? const []) LuaChon.fromMap(l)],
    );
  }

  Map<String, dynamic> toMap() => {
    'ten': ten,
    'batBuoc': batBuoc,
    'toiDa': toiDa,
    'lua': [for (final l in lua) l.toMap()],
  };
}

/// Món ăn — collection `qa_mon`. Giá lưu số nguyên (VND), chỉ định dạng khi hiển thị.
class MonAn {
  const MonAn({
    required this.id,
    required this.quanId,
    required this.nhomId,
    required this.ten,
    required this.gia,
    this.chuQuanId = '',
    this.moTa = '',
    this.anh = '',
    this.noiBat = false,
    this.conHang = true,
    this.thuTu = 0,
    this.laDoUong = false,
    this.daXoa = false,
    this.tuyChon = const [],
  });

  final String id;
  final String quanId;
  final String nhomId;
  final String chuQuanId;
  final String ten;
  final String moTa;
  final num gia;
  final String anh;
  final bool noiBat;
  final bool conHang;
  final int thuTu;
  final bool laDoUong;
  final bool daXoa;
  final List<NhomTuyChon> tuyChon;

  bool get coTuyChon => tuyChon.isNotEmpty;
  bool get coTuyChonBatBuoc => tuyChon.any((t) => t.batBuoc);

  factory MonAn.fromMap(String id, Map<String, dynamic> m) => MonAn(
    id: id,
    quanId: m['quanId'] as String? ?? '',
    nhomId: m['nhomId'] as String? ?? '',
    chuQuanId: m['chuQuanId'] as String? ?? '',
    ten: m['ten'] as String? ?? '',
    moTa: m['moTa'] as String? ?? '',
    gia: m['gia'] as num? ?? 0,
    anh: m['anh'] as String? ?? '',
    noiBat: m['noiBat'] as bool? ?? false,
    conHang: m['conHang'] as bool? ?? true,
    thuTu: (m['thuTu'] as num?)?.toInt() ?? 0,
    laDoUong: m['laDoUong'] as bool? ?? false,
    daXoa: m['daXoa'] as bool? ?? false,
    tuyChon: [
      for (final t in m['tuyChon'] as List? ?? const []) NhomTuyChon.fromMap(t),
    ],
  );

  /// Tham số hành động `luuMon` (không gửi `laDoUong`, `daXoa`: hệ thống tự đặt).
  Map<String, dynamic> toApiMap() => {
    'quanId': quanId,
    if (id.isNotEmpty) 'monId': id,
    'nhomId': nhomId,
    'ten': ten,
    'moTa': moTa,
    'gia': gia,
    'anh': anh,
    'noiBat': noiBat,
    'conHang': conHang,
    'thuTu': thuTu,
    'tuyChon': [for (final t in tuyChon) t.toMap()],
  };

  /// Kiểm tra lựa chọn của khách: [chon] ánh xạ tên nhóm → các tên lựa chọn đã chọn.
  /// Trả thông báo lỗi tiếng Việt đầu tiên, hoặc null nếu hợp lệ.
  String? kiemTraTuyChon(Map<String, List<String>> chon) {
    for (final nhom in tuyChon) {
      final da = chon[nhom.ten] ?? const <String>[];
      if (nhom.batBuoc && da.isEmpty) {
        return 'Vui lòng chọn "${nhom.ten}".';
      }
      if (da.length > nhom.toiDa) {
        return nhom.toiDa == 1
            ? '"${nhom.ten}" chỉ chọn được 1.'
            : '"${nhom.ten}" chọn tối đa ${nhom.toiDa}.';
      }
      for (final l in da) {
        if (!nhom.lua.any((x) => x.ten == l)) {
          return '"$l" không còn trong "${nhom.ten}".';
        }
      }
    }
    return null;
  }
}
