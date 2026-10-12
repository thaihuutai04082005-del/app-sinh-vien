import 'package:flutter/material.dart';

import '../models/nhom_mon.dart';
import 'quan_an_theme.dart';

/// Mã giả của mục "Nổi bật" đứng đầu thanh nhóm món.
const nhomNoiBatId = '__noi_bat__';

/// Thanh nhóm món cuộn ngang (mục 3.4 Bước 2, khối 3). Mục "Nổi bật" (nếu [coNoiBat])
/// luôn đứng đầu; bấm một mục gọi [onChon] với id nhóm (hoặc [nhomNoiBatId]).
class NhomMonTabBar extends StatelessWidget {
  const NhomMonTabBar({
    required this.nhom,
    required this.dangChon,
    required this.onChon,
    this.coNoiBat = false,
    super.key,
  });

  final List<NhomMon> nhom;
  final bool coNoiBat;
  final String? dangChon;
  final ValueChanged<String> onChon;

  @override
  Widget build(BuildContext context) {
    final muc = <(String, String)>[
      if (coNoiBat) (nhomNoiBatId, '⭐ Nổi bật'),
      for (final n in nhom) (n.id, n.ten),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: QuanAnSpacing.screen,
          vertical: QuanAnSpacing.sm,
        ),
        itemCount: muc.length,
        separatorBuilder: (_, _) => const SizedBox(width: QuanAnSpacing.sm),
        itemBuilder: (_, i) {
          final (id, ten) = muc[i];
          final chon = id == dangChon;
          return ChoiceChip(
            label: Text(ten),
            selected: chon,
            showCheckmark: false,
            labelStyle: QuanAnText.label.copyWith(
              color: chon ? QuanAnColors.primary : QuanAnColors.textPrimary,
            ),
            side: BorderSide(
              color: chon ? QuanAnColors.primary : QuanAnColors.border,
              width: chon ? 1.5 : 1,
            ),
            onSelected: (_) => onChon(id),
          );
        },
      ),
    );
  }
}
