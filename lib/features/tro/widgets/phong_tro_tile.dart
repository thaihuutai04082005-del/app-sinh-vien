import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/phong_tro.dart';
import '../models/tro_config.dart';
import 'tro_status_badge.dart';
import 'tro_theme.dart';

/// Một dòng phòng trong trang nhà trọ. Phòng đã cọc / đã cho thuê hiện mờ, có nhãn.
class PhongTroTile extends StatelessWidget {
  const PhongTroTile({
    required this.phong,
    required this.onTap,
    this.phuHop = false,
    this.trailing,
    super.key,
  });

  final PhongTro phong;
  final VoidCallback onTap;
  final bool phuHop;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final mo =
        !phong.conTrong && ['reserved', 'rented'].contains(phong.trangThai);
    final nhan = switch (phong.trangThai) {
      'available' when phong.dangKhoaThanhToan() => const TroStatusBadge(
        kind: TroBadgeKind.reserved,
        label: 'Đang có người thanh toán',
      ),
      'available' => const TroStatusBadge(
        kind: TroBadgeKind.available,
        label: 'Còn trống',
      ),
      'reserved' => const TroStatusBadge(
        kind: TroBadgeKind.reserved,
        label: 'Đã có người cọc',
      ),
      'rented' => const TroStatusBadge(
        kind: TroBadgeKind.rented,
        label: 'Đã cho thuê',
      ),
      _ => TroStatusBadge(
        kind: TroBadgeKind.reserved,
        label: trangThaiPhongLabels[phong.trangThai] ?? phong.trangThai,
      ),
    };
    return Opacity(
      opacity: mo ? 0.55 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TroSpacing.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(TroRadius.input),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: phong.anhBia.isEmpty
                        ? const ColoredBox(
                            color: TroColors.primaryLight,
                            child: Icon(
                              Icons.bed_outlined,
                              color: TroColors.primary,
                            ),
                          )
                        : NetworkPhoto(phong.anhBia),
                  ),
                ),
                const SizedBox(width: TroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          phong.ten,
                          if (phong.khu.isNotEmpty) phong.khu,
                          if (phong.tang != null) 'Tầng ${phong.tang}',
                        ].join(' · '),
                        style: TroText.h3,
                      ),
                      const SizedBox(height: 2),
                      Text(phong.moTaDienTich, style: TroText.bodySmall),
                      const SizedBox(height: TroSpacing.xs),
                      Text(
                        '${formatPrice(phong.giaThue)}/tháng',
                        style: TroText.price,
                      ),
                      const SizedBox(height: TroSpacing.xs),
                      Wrap(
                        spacing: TroSpacing.xs,
                        runSpacing: TroSpacing.xs,
                        children: [
                          nhan,
                          if (phuHop)
                            const TroStatusBadge(
                              kind: TroBadgeKind.verified,
                              label: 'Phù hợp bộ lọc',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
