import 'package:flutter/material.dart';

import 'quan_an_theme.dart';

enum QuanAnBadgeKind {
  moCua, // 🟢 Đang mở cửa
  sapDong, // 🟠 Sắp đóng cửa · Tạm ngưng nhận đơn
  dongCua, // 🔴 Đã đóng cửa
  tamNghi, // ⏸ Tạm nghỉ
  xacThuc, // ✔ Đã xác thực
  nhan, // 🛵 Đã đặt món · 🍽 Đã đến theo đặt bàn · 📍 Check-in tại quán
  canhBao, // ⚠ Đang khiếu nại, chờ xác nhận nhận món...
  chung, // thông tin chung
}

/// Huy hiệu trạng thái (mục 3.19 "Huy hiệu"). Luôn có chữ + icon, không dùng màu làm tín hiệu duy nhất.
/// Với [QuanAnBadgeKind.nhan], truyền [icon] riêng (🛵 🍽 📍) nếu muốn đổi biểu tượng.
class QuanAnStatusBadge extends StatelessWidget {
  const QuanAnStatusBadge({
    required this.kind,
    required this.label,
    this.icon,
    super.key,
  });

  final QuanAnBadgeKind kind;
  final String label;

  /// Biểu tượng riêng (tùy chọn); mặc định theo [kind].
  final IconData? icon;

  (Color bg, Color fg, IconData icon) get _style => switch (kind) {
    QuanAnBadgeKind.moCua => (
      QuanAnColors.successSoft,
      QuanAnColors.success,
      Icons.check_circle_rounded,
    ),
    QuanAnBadgeKind.sapDong => (
      QuanAnColors.warningSoft,
      QuanAnColors.warning,
      Icons.schedule_rounded,
    ),
    QuanAnBadgeKind.dongCua => (
      QuanAnColors.dangerSoft,
      QuanAnColors.danger,
      Icons.block_rounded,
    ),
    QuanAnBadgeKind.tamNghi => (
      QuanAnColors.warningSoft,
      QuanAnColors.warning,
      Icons.pause_circle_rounded,
    ),
    QuanAnBadgeKind.xacThuc => (
      QuanAnColors.primaryLight,
      QuanAnColors.primary,
      Icons.verified_rounded,
    ),
    QuanAnBadgeKind.nhan => (
      QuanAnColors.labelSoft,
      QuanAnColors.primary,
      Icons.task_alt_rounded,
    ),
    QuanAnBadgeKind.canhBao => (
      QuanAnColors.warningSoft,
      QuanAnColors.warning,
      Icons.warning_amber_rounded,
    ),
    QuanAnBadgeKind.chung => (
      QuanAnColors.infoSoft,
      QuanAnColors.info,
      Icons.info_outline_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bieuTuong) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuanAnSpacing.sm,
        vertical: QuanAnSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QuanAnRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? bieuTuong, size: 16, color: fg),
          const SizedBox(width: QuanAnSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
