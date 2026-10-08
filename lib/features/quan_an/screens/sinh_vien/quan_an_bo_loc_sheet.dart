import 'package:flutter/material.dart';

import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/quan_an_filter.dart';
import '../../widgets/quan_an_map_marker.dart';
import '../../widgets/quan_an_theme.dart';

/// Các mức giá theo giá trung vị, dựng từ [QuanAnConfig.mocGia]:
/// "Dưới 20k" · "20–35k" · "35–50k" · "Trên 50k" → (nhãn, giaTu, giaDen).
List<(String, int?, int?)> mocGiaQuan(QuanAnConfig cfg) {
  final m = [...cfg.mocGia]..sort();
  if (m.isEmpty) return const [];
  String k(int v) => nhanKhoangGia(v, v) ?? '$v';
  return [
    ('Dưới ${k(m.first)}', null, m.first),
    for (var i = 0; i + 1 < m.length; i++)
      (nhanKhoangGia(m[i], m[i + 1]) ?? '', m[i], m[i + 1]),
    ('Trên ${k(m.last)}', m.last, null),
  ];
}

String _nhanBanKinh(int m) => m < 1000 ? '$m m' : '${m ~/ 1000} km';

/// QA-SV-02 Bảng bộ lọc (mục 3.4 Bước 1). Nút "Xem X quán" đổi số ngay khi chọn tiêu chí.
/// Trả về bộ lọc mới, hoặc null nếu người dùng đóng bảng mà không áp dụng.
Future<QuanAnFilter?> moBoLoc(
  BuildContext context, {
  required QuanAnFilter loc,
  required DiemGoc? goc,
  required List<QuanAn> quan,
  required QuanAnConfig cfg,
  required VoidCallback onChonGoc,
}) => showModalBottomSheet<QuanAnFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => Theme(
    data: Theme.of(context),
    child: QuanAnBoLocSheet(
      loc: loc,
      goc: goc,
      quan: quan,
      cfg: cfg,
      onChonGoc: onChonGoc,
    ),
  ),
);

class QuanAnBoLocSheet extends StatefulWidget {
  const QuanAnBoLocSheet({
    required this.loc,
    required this.goc,
    required this.quan,
    required this.cfg,
    required this.onChonGoc,
    super.key,
  });

  final QuanAnFilter loc;
  final DiemGoc? goc;
  final List<QuanAn> quan;
  final QuanAnConfig cfg;
  final VoidCallback onChonGoc;

  @override
  State<QuanAnBoLocSheet> createState() => _QuanAnBoLocSheetState();
}

class _QuanAnBoLocSheetState extends State<QuanAnBoLocSheet> {
  late QuanAnFilter _f = widget.loc;

  void _set(QuanAnFilter f) => setState(() => _f = f);

  Widget _tieuDe(String s) => Padding(
    padding: const EdgeInsets.only(
      top: QuanAnSpacing.lg,
      bottom: QuanAnSpacing.sm,
    ),
    child: Text(s, style: QuanAnText.h3),
  );

  Widget _chips<T>(List<(String, T)> ds, T? chon, ValueChanged<T?> onChon) =>
      Wrap(
        spacing: QuanAnSpacing.sm,
        runSpacing: QuanAnSpacing.sm,
        children: [
          for (final (nhan, gia) in ds)
            ChoiceChip(
              label: Text(nhan),
              selected: chon == gia,
              onSelected: (on) => onChon(on ? gia : null),
            ),
        ],
      );

  Set<String> _bat(Set<String> s, String k, bool on) =>
      on ? {...s, k} : ({...s}..remove(k));

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final soKetQua = locQuan(
      quan: widget.quan,
      filter: _f,
      goc: widget.goc,
      cfg: cfg,
    ).length;
    final moc = mocGiaQuan(cfg);
    final mocDangChon = moc.indexWhere(
      (m) => m.$2 == _f.giaTu && m.$3 == _f.giaDen,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, cuon) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuanAnSpacing.screen,
              QuanAnSpacing.md,
              QuanAnSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Bộ lọc', style: QuanAnText.h2)),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: cuon,
              padding: const EdgeInsets.symmetric(
                horizontal: QuanAnSpacing.screen,
              ),
              children: [
                _tieuDe('Loại món'),
                Wrap(
                  spacing: QuanAnSpacing.sm,
                  runSpacing: QuanAnSpacing.sm,
                  children: [
                    for (final e in loaiMonLabels.entries)
                      if (e.key != 'khac')
                        FilterChip(
                          label: Text(e.value),
                          selected: _f.loaiMon.contains(e.key),
                          onSelected: (on) => _set(
                            _f.copyWith(loaiMon: _bat(_f.loaiMon, e.key, on)),
                          ),
                        ),
                  ],
                ),
                _tieuDe('Mức giá (theo giá trung vị)'),
                _chips<int>(
                  [for (var i = 0; i < moc.length; i++) (moc[i].$1, i)],
                  mocDangChon < 0 ? null : mocDangChon,
                  (i) => _set(
                    i == null
                        ? _f.copyWith(giaTu: null, giaDen: null)
                        : _f.copyWith(giaTu: moc[i].$2, giaDen: moc[i].$3),
                  ),
                ),
                _tieuDe('Khoảng cách'),
                if (widget.goc == null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onChonGoc();
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Chọn điểm gốc trước'),
                  )
                else
                  _chips<int>(
                    [for (final m in cfg.banKinhMet) (_nhanBanKinh(m), m)],
                    _f.banKinhMet,
                    (v) => _set(_f.copyWith(banKinhMet: v)),
                  ),
                const SizedBox(height: QuanAnSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang mở cửa'),
                  value: _f.dangMo,
                  onChanged: (v) => _set(_f.copyWith(dangMo: v)),
                ),
                _tieuDe('Hình thức phục vụ'),
                Wrap(
                  spacing: QuanAnSpacing.sm,
                  runSpacing: QuanAnSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('Ăn tại quán'),
                      selected: _f.anTaiQuan,
                      onSelected: (v) => _set(_f.copyWith(anTaiQuan: v)),
                    ),
                    FilterChip(
                      label: const Text('Mang đi'),
                      selected: _f.mangDi,
                      onSelected: (v) => _set(_f.copyWith(mangDi: v)),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Giao hàng (đặt qua app)'),
                  subtitle: Text(
                    widget.goc == null
                        ? 'Chỉ quán nhận đơn có đến lấy. Chọn điểm gốc để thêm quán giao tận nơi tới chỗ bạn.'
                        : 'Chỉ quán nhận đơn và giao tới chỗ bạn được (hoặc có đến lấy).',
                  ),
                  value: _f.giaoHang,
                  onChanged: (v) => _set(_f.copyWith(giaoHang: v)),
                ),
                _tieuDe('Điểm đánh giá (đã xác minh)'),
                _chips<double>(
                  const [('Từ ★4 trở lên', 4.0), ('Từ ★3,5 trở lên', 3.5)],
                  _f.diemTu,
                  (v) => _set(_f.copyWith(diemTu: v)),
                ),
                _tieuDe('Tiện ích'),
                Wrap(
                  spacing: QuanAnSpacing.sm,
                  runSpacing: QuanAnSpacing.sm,
                  children: [
                    for (final k in tienIchLoc)
                      FilterChip(
                        label: Text(tienIchLabels[k] ?? k),
                        selected: _f.tienIch.contains(k),
                        onSelected: (on) =>
                            _set(_f.copyWith(tienIch: _bat(_f.tienIch, k, on))),
                      ),
                    FilterChip(
                      label: const Text('Nhận đặt bàn'),
                      selected: _f.nhanDatBan,
                      onSelected: (v) => _set(_f.copyWith(nhanDatBan: v)),
                    ),
                  ],
                ),
                _tieuDe('Loại quán'),
                _chips<String>(
                  [for (final e in loaiQuanLabels.entries) (e.value, e.key)],
                  _f.loaiQuan,
                  (v) => _set(_f.copyWith(loaiQuan: v)),
                ),
                const SizedBox(height: QuanAnSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Có khuyến mãi'),
                  value: _f.coKhuyenMai,
                  onChanged: (v) => _set(_f.copyWith(coKhuyenMai: v)),
                ),
                const SizedBox(height: QuanAnSpacing.xl),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(QuanAnSpacing.screen),
              decoration: BoxDecoration(
                color: QuanAnColors.white,
                boxShadow: QuanAnTheme.softShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _set(_f.xoaLoc()),
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _f),
                      child: Text('Xem $soKetQua quán'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
