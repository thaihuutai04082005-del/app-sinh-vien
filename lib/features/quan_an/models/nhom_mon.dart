/// Nhóm món của quán — collection `qa_nhom_mon` (mục 3.2 "Menu").
class NhomMon {
  const NhomMon({
    required this.id,
    required this.quanId,
    required this.ten,
    this.chuQuanId = '',
    this.thuTu = 0,
    this.laDoUong = false,
  });

  final String id;
  final String quanId;
  final String chuQuanId;
  final String ten;
  final int thuTu;

  /// Nhóm "đồ uống / món thêm": không tính vào mức giá của quán.
  final bool laDoUong;

  factory NhomMon.fromMap(String id, Map<String, dynamic> m) => NhomMon(
    id: id,
    quanId: m['quanId'] as String? ?? '',
    chuQuanId: m['chuQuanId'] as String? ?? '',
    ten: m['ten'] as String? ?? '',
    thuTu: (m['thuTu'] as num?)?.toInt() ?? 0,
    laDoUong: m['laDoUong'] as bool? ?? false,
  );

  /// Tham số hành động `luuNhomMon`.
  Map<String, dynamic> toApiMap() => {
    'quanId': quanId,
    if (id.isNotEmpty) 'nhomId': id,
    'ten': ten,
    'laDoUong': laDoUong,
    'thuTu': thuTu,
  };
}
