import 'package:flutter/material.dart';

import '../models/nha_tro.dart';
import 'tro_theme.dart';

/// Nội quy nhà trọ ở trang chi tiết (4 tiêu chí) và icon nổi bật trên thẻ (mục 2.4).
class NoiQuyBlock extends StatelessWidget {
  const NoiQuyBlock({required this.noiQuy, super.key});

  final NoiQuy noiQuy;

  @override
  Widget build(BuildContext context) {
    Widget dong(IconData icon, String ten, String gia) => Padding(
      padding: const EdgeInsets.symmetric(vertical: TroSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TroColors.primary),
          const SizedBox(width: TroSpacing.sm),
          Expanded(child: Text(ten, style: TroText.body)),
          Text(gia, style: TroText.label),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nội quy', style: TroText.h2),
        const SizedBox(height: TroSpacing.sm),
        dong(Icons.schedule_rounded, 'Giờ giấc ra vào', noiQuy.gioGiacLabel),
        dong(
          Icons.pets_rounded,
          'Nuôi thú cưng',
          noiQuy.thuCung ? 'Cho phép' : 'Không cho phép',
        ),
        dong(
          Icons.bed_rounded,
          'Bạn bè / người thân ở qua đêm',
          noiQuy.oQuaDem ? 'Cho phép' : 'Không cho phép',
        ),
        dong(
          Icons.event_rounded,
          'Báo trước khi trả phòng',
          '${noiQuy.baoTruocTuan} tuần',
        ),
      ],
    );
  }
}

/// Icon nội quy nổi bật trên thẻ: 🕐 Tự do 24/24 hoặc 🕐 Đóng cửa 22:00 · 🐶 Cho nuôi thú cưng.
class NoiQuyIcons extends StatelessWidget {
  const NoiQuyIcons({required this.noiQuy, super.key});

  final NoiQuy noiQuy;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData i, String s) => Container(
      margin: const EdgeInsets.only(right: TroSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: TroSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: TroColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(TroRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 14, color: TroColors.primary),
          const SizedBox(width: 4),
          Text(
            s,
            style: const TextStyle(fontSize: 12, color: TroColors.textPrimary),
          ),
        ],
      ),
    );
    return Wrap(
      children: [
        chip(Icons.schedule_rounded, noiQuy.gioGiacLabel),
        if (noiQuy.thuCung) chip(Icons.pets_rounded, 'Cho nuôi thú cưng'),
      ],
    );
  }
}
