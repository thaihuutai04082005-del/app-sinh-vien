import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/phong_tro.dart';
import 'tro_theme.dart';

/// Bảng chi phí của phòng: thuê, cọc, điện, nước, phí khác, hợp đồng tối thiểu (mục 2.4 Bước 2).
class GiaDienNuocTable extends StatelessWidget {
  const GiaDienNuocTable({required this.phong, super.key});

  final PhongTro phong;

  static String chiPhi(ChiPhi? c, {required bool dien}) {
    if (c == null) return '—';
    final gia = formatPrice(c.gia);
    return switch (c.cach) {
      'theo_so' => '$gia/kWh',
      'theo_khoi' => '$gia/m³',
      'theo_nguoi' => '$gia/người/tháng',
      _ => '$gia/tháng',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dong = <(String, String)>[
      ('Giá thuê', '${formatPrice(phong.giaThue)}/tháng'),
      ('Tiền cọc (cọc qua app)', formatPrice(phong.tienCoc)),
      ('Tiền điện', chiPhi(phong.tienDien, dien: true)),
      ('Tiền nước', chiPhi(phong.tienNuoc, dien: false)),
      for (final p in phong.phiKhac) (p.ten, '${formatPrice(p.gia)}/tháng'),
      if (phong.hopDongToiThieu != null)
        ('Hợp đồng tối thiểu', '${phong.hopDongToiThieu} tháng'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chi phí', style: TroText.h2),
        const SizedBox(height: TroSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: TroColors.border),
            borderRadius: BorderRadius.circular(TroRadius.input),
          ),
          child: Column(
            children: [
              for (var i = 0; i < dong.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TroSpacing.md,
                    vertical: TroSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: TroColors.border),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(dong[i].$1, style: TroText.body)),
                      Text(
                        dong[i].$2,
                        style: i == 0 ? TroText.price : TroText.label,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
