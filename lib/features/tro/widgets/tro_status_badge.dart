import 'package:flutter/material.dart';

import 'tro_theme.dart';

enum TroBadgeKind {
  verified, // ✔ Đã xác thực
  available, // 🟢 Còn phòng
  reserved, // 🟠 Đã cọc / đang có người thanh toán / sắp hết hạn
  full, // 🔴 Hết phòng
  rented, // ✔ Đã thuê
}

/// Huy hiệu trạng thái (mục 2.19). Luôn có chữ + icon, không dùng màu làm tín hiệu duy nhất.
class TroStatusBadge extends StatelessWidget {
  const TroStatusBadge({required this.kind, required this.label, super.key});

  final TroBadgeKind kind;
  final String label;

  (Color bg, Color fg, IconData icon) get _style => switch (kind) {
    TroBadgeKind.verified => (
      TroColors.primaryLight,
      TroColors.primary,
      Icons.verified_rounded,
    ),
    TroBadgeKind.available => (
      TroColors.successSoft,
      TroColors.success,
      Icons.check_circle_rounded,
    ),
    TroBadgeKind.reserved => (
      TroColors.warningSoft,
      TroColors.warning,
      Icons.schedule_rounded,
    ),
    TroBadgeKind.full => (
      TroColors.dangerSoft,
      TroColors.danger,
      Icons.block_rounded,
    ),
    TroBadgeKind.rented => (
      TroColors.primaryLight,
      TroColors.primary,
      Icons.task_alt_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TroSpacing.sm,
        vertical: TroSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TroRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: TroSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
