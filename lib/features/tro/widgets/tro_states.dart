import 'package:flutter/material.dart';

import 'tro_theme.dart';

/// Khung xương nhấp nháy khi đang tải (thay cho vòng xoay trên nền trắng).
class TroSkeletonBox extends StatefulWidget {
  const TroSkeletonBox({
    this.height = 16,
    this.width,
    this.radius = 8,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<TroSkeletonBox> createState() => _TroSkeletonBoxState();
}

class _TroSkeletonBoxState extends State<TroSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
    child: Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: TroColors.skeleton,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Danh sách khung xương đúng hình thẻ thật (ảnh bìa 16:9 + 3 dòng chữ).
class TroSkeletonList extends StatelessWidget {
  const TroSkeletonList({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => ListView.separated(
    // shrinkWrap: dùng được cả khi nằm trong trang cuộn khác (không bị "unbounded height").
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(TroSpacing.screen),
    itemCount: count,
    separatorBuilder: (_, _) => const SizedBox(height: TroSpacing.cardGap),
    itemBuilder: (_, _) => Container(
      decoration: BoxDecoration(
        color: TroColors.white,
        borderRadius: BorderRadius.circular(TroRadius.card),
        border: Border.all(color: TroColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: TroSkeletonBox(
              height: double.infinity,
              radius: TroRadius.card,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(TroSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TroSkeletonBox(height: 18, width: 200),
                SizedBox(height: TroSpacing.sm),
                TroSkeletonBox(height: 14, width: 140),
                SizedBox(height: TroSpacing.sm),
                TroSkeletonBox(height: 16, width: 90),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Trạng thái rỗng: icon xanh + 1 dòng giải thích + (tùy chọn) 1 nút gợi ý.
class TroEmptyState extends StatelessWidget {
  const TroEmptyState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.search_off_rounded,
    super.key,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TroSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: TroColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: TroColors.primary),
          ),
          const SizedBox(height: TroSpacing.lg),
          Text(title, style: TroText.h2, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: TroSpacing.sm),
            Text(
              message!,
              style: TroText.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: TroSpacing.xl),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Trạng thái lỗi: icon cảnh báo + thông báo + nút [Thử lại].
class TroErrorState extends StatelessWidget {
  const TroErrorState({
    required this.onRetry,
    this.message = 'Không tải được dữ liệu',
    super.key,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TroSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: TroColors.danger,
          ),
          const SizedBox(height: TroSpacing.lg),
          Text(message, style: TroText.body, textAlign: TextAlign.center),
          const SizedBox(height: TroSpacing.xl),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

/// Khung cảnh báo lừa đảo: nền đỏ nhạt, viền trái đỏ, icon ⚠.
class TroWarningBox extends StatelessWidget {
  const TroWarningBox({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(TroSpacing.md),
    decoration: BoxDecoration(
      color: TroColors.dangerSoft,
      borderRadius: BorderRadius.circular(TroRadius.button),
      border: const Border(left: BorderSide(color: TroColors.danger, width: 4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, color: TroColors.danger),
        const SizedBox(width: TroSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: TroText.body.copyWith(color: TroColors.danger),
          ),
        ),
      ],
    ),
  );
}
