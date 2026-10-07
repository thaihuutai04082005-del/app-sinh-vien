import 'package:flutter/material.dart';

import '../../models/nha_tro.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../models/tro_filter.dart';
import '../../widgets/tro_theme.dart';

/// TRO-SV-02 Bảng bộ lọc. Nút "Xem X kết quả" đổi số ngay khi chọn tiêu chí.
Future<TroFilter?> moBoLoc(
  BuildContext context, {
  required TroFilter loc,
  required DiemGoc? goc,
  required List<NhaTro> nhaTro,
  required List<PhongTro> phong,
  required VoidCallback onChonGoc,
}) => showModalBottomSheet<TroFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => Theme(
    data: Theme.of(context),
    child: TroBoLocSheet(
      loc: loc,
      goc: goc,
      nhaTro: nhaTro,
      phong: phong,
      onChonGoc: onChonGoc,
    ),
  ),
);

class TroBoLocSheet extends StatefulWidget {
  const TroBoLocSheet({
    required this.loc,
    required this.goc,
    required this.nhaTro,
    required this.phong,
    required this.onChonGoc,
    super.key,
  });

  final TroFilter loc;
  final DiemGoc? goc;
  final List<NhaTro> nhaTro;
  final List<PhongTro> phong;
  final VoidCallback onChonGoc;

  @override
  State<TroBoLocSheet> createState() => _TroBoLocSheetState();
}

class _TroBoLocSheetState extends State<TroBoLocSheet> {
  late TroFilter _f = widget.loc;

  void _set(TroFilter f) => setState(() => _f = f);

  Widget _tieuDe(String s) => Padding(
    padding: const EdgeInsets.only(top: TroSpacing.lg, bottom: TroSpacing.sm),
    child: Text(s, style: TroText.h3),
  );

  Widget _chips<T>(List<(String, T)> ds, T? chon, ValueChanged<T?> onChon) =>
      Wrap(
        spacing: TroSpacing.sm,
        runSpacing: TroSpacing.sm,
        children: [
          for (final (nhan, gia) in ds)
            ChoiceChip(
              label: Text(nhan),
              selected: chon == gia,
              onSelected: (on) => onChon(on ? gia : null),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final soKetQua = locNhaTro(
      nhaTro: widget.nhaTro,
      phong: widget.phong,
      filter: _f,
      goc: widget.goc,
    ).soNhaTro;
    final mocGia = mocGiaNhanh.indexWhere(
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
              TroSpacing.screen,
              TroSpacing.md,
              TroSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Bộ lọc', style: TroText.h2)),
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
                horizontal: TroSpacing.screen,
              ),
              children: [
                _tieuDe('Loại hình'),
                _chips(
                  [for (final e in loaiHinhLabels.entries) (e.value, e.key)],
                  _f.loaiHinh,
                  (v) => _set(
                    _f.copyWith(
                      loaiHinh: v,
                      coGac: v == 'phong' ? _f.coGac : null,
                    ),
                  ),
                ),
                if (_f.loaiHinh == 'phong') ...[
                  _tieuDe('Loại phòng'),
                  _chips(
                    [('Có gác', true), ('Không gác', false)],
                    _f.coGac,
                    (v) => _set(_f.copyWith(coGac: v)),
                  ),
                ],
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
                  _chips(
                    [
                      for (final m in const [300, 500, 1000, 2000, 3000, 5000])
                        (m < 1000 ? '$m m' : '${m ~/ 1000} km', m),
                    ],
                    _f.banKinhMet,
                    (v) => _set(_f.copyWith(banKinhMet: v)),
                  ),
                _tieuDe('Giá'),
                _chips(
                  [
                    for (var i = 0; i < mocGiaNhanh.length; i++)
                      (mocGiaNhanh[i].$1, i),
                  ],
                  mocGia < 0 ? null : mocGia,
                  (i) {
                    _set(
                      i == null
                          ? _f.copyWith(giaTu: null, giaDen: null)
                          : _f.copyWith(
                              giaTu: mocGiaNhanh[i].$2,
                              giaDen: mocGiaNhanh[i].$3,
                            ),
                    );
                  },
                ),
                _GiaKeo(
                  tu: _f.giaTu,
                  den: _f.giaDen,
                  onChanged: (tu, den) =>
                      _set(_f.copyWith(giaTu: tu, giaDen: den)),
                ),
                _tieuDe('Tiện ích'),
                Wrap(
                  spacing: TroSpacing.sm,
                  runSpacing: TroSpacing.sm,
                  children: [
                    for (final (k, nhan) in const [
                      ('may_lanh', 'Máy lạnh'),
                      ('wc_rieng', 'WC riêng'),
                      ('wifi', 'Wifi'),
                      ('cho_de_xe', 'Chỗ để xe'),
                      ('camera', 'Camera an ninh'),
                      ('may_giat', 'Máy giặt'),
                    ])
                      FilterChip(
                        label: Text(nhan),
                        selected: _f.tienIch.contains(k),
                        onSelected: (on) => _set(
                          _f.copyWith(
                            tienIch: on
                                ? {..._f.tienIch, k}
                                : ({..._f.tienIch}..remove(k)),
                          ),
                        ),
                      ),
                  ],
                ),
                _tieuDe('🕐 Giờ giấc ra vào'),
                Wrap(
                  spacing: TroSpacing.sm,
                  runSpacing: TroSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Tự do 24/24'),
                      selected: _f.tuDo24,
                      onSelected: (on) =>
                          _set(_f.copyWith(tuDo24: on, veMuonToi: null)),
                    ),
                    for (final g in const ['22:00', '23:00', '00:00'])
                      ChoiceChip(
                        label: Text('Về muộn được tới ít nhất $g'),
                        selected: _f.veMuonToi == g,
                        onSelected: (on) => _set(
                          _f.copyWith(veMuonToi: on ? g : null, tuDo24: false),
                        ),
                      ),
                  ],
                ),
                _tieuDe('🐶 Nuôi thú cưng · 🛏️ Ở qua đêm'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cho phép nuôi thú cưng'),
                  value: _f.thuCung,
                  onChanged: (v) => _set(_f.copyWith(thuCung: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cho bạn bè / người thân ở qua đêm'),
                  value: _f.oQuaDem,
                  onChanged: (v) => _set(_f.copyWith(oQuaDem: v)),
                ),
                _tieuDe('📅 Báo trước khi trả phòng'),
                _chips(
                  [
                    ('Tối đa 1 tuần', 1),
                    ('Tối đa 2 tuần', 2),
                    ('Tối đa 3 tuần', 3),
                  ],
                  _f.baoTruocToiDa,
                  (v) => _set(_f.copyWith(baoTruocToiDa: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chỉ hiện nơi còn phòng'),
                  value: _f.chiConPhong,
                  onChanged: (v) => _set(_f.copyWith(chiConPhong: v)),
                ),
                const SizedBox(height: TroSpacing.xl),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(TroSpacing.screen),
              decoration: BoxDecoration(
                color: TroColors.white,
                boxShadow: TroTheme.softShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _set(_f.xoaLoc()),
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: TroSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _f),
                      child: Text('Xem $soKetQua kết quả'),
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

/// Thanh kéo giá từ – đến (0 – 6 triệu, bước 100 nghìn).
class _GiaKeo extends StatelessWidget {
  const _GiaKeo({required this.tu, required this.den, required this.onChanged});

  final int? tu;
  final int? den;
  final void Function(int? tu, int? den) onChanged;

  static const _max = 6000000.0;

  @override
  Widget build(BuildContext context) {
    final r = RangeValues(
      (tu ?? 0).toDouble(),
      (den ?? _max).toDouble().clamp(0, _max),
    );
    String nhan(double v) => v >= _max
        ? 'Không giới hạn'
        : '${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')}tr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: r,
          max: _max,
          divisions: 60,
          labels: RangeLabels(nhan(r.start), nhan(r.end)),
          onChanged: (v) => onChanged(
            v.start <= 0 ? null : v.start.round(),
            v.end >= _max ? null : v.end.round(),
          ),
        ),
        Text(
          'Từ ${nhan(r.start)} đến ${nhan(r.end)}',
          style: TroText.bodySmall,
        ),
      ],
    );
  }
}
