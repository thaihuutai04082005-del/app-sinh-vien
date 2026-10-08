import 'package:flutter/material.dart';

import 'quan_an_theme.dart';

/// Khung xương nhấp nháy khi đang tải (thay cho vòng xoay trên nền trắng).
class QuanAnSkeletonBox extends StatefulWidget {
  const QuanAnSkeletonBox({
    this.height = 16,
    this.width,
    this.radius = 8,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<QuanAnSkeletonBox> createState() => _QuanAnSkeletonBoxState();
}

class _QuanAnSkeletonBoxState extends State<QuanAnSkeletonBox>
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
        color: QuanAnColors.skeleton,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Danh sách khung xương đúng hình thẻ thật (ảnh bìa 16:9 + 3 dòng chữ).
class QuanAnSkeletonList extends StatelessWidget {
  const QuanAnSkeletonList({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => ListView.separated(
    // shrinkWrap: dùng được cả khi nằm trong trang cuộn khác (không bị "unbounded height").
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(QuanAnSpacing.screen),
    itemCount: count,
    separatorBuilder: (_, _) => const SizedBox(height: QuanAnSpacing.cardGap),
    itemBuilder: (_, _) => Container(
      decoration: BoxDecoration(
        color: QuanAnColors.white,
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        border: Border.all(color: QuanAnColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: QuanAnSkeletonBox(
              height: double.infinity,
              radius: QuanAnRadius.card,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(QuanAnSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuanAnSkeletonBox(height: 18, width: 200),
                SizedBox(height: QuanAnSpacing.sm),
                QuanAnSkeletonBox(height: 14, width: 140),
                SizedBox(height: QuanAnSpacing.sm),
                QuanAnSkeletonBox(height: 16, width: 90),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Trạng thái rỗng: icon xanh + 1 dòng giải thích + (tùy chọn) 1 nút gợi ý.
class QuanAnEmptyState extends StatelessWidget {
  const QuanAnEmptyState({
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
      padding: const EdgeInsets.all(QuanAnSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: QuanAnColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: QuanAnColors.primary),
          ),
          const SizedBox(height: QuanAnSpacing.lg),
          Text(title, style: QuanAnText.h2, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: QuanAnSpacing.sm),
            Text(
              message!,
              style: QuanAnText.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: QuanAnSpacing.xl),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Trạng thái lỗi: icon cảnh báo + thông báo + nút [Thử lại].
class QuanAnErrorState extends StatelessWidget {
  const QuanAnErrorState({
    required this.onRetry,
    this.message = 'Không tải được dữ liệu',
    super.key,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: QuanAnColors.danger,
          ),
          const SizedBox(height: QuanAnSpacing.lg),
          Text(message, style: QuanAnText.body, textAlign: TextAlign.center),
          const SizedBox(height: QuanAnSpacing.xl),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

/// Khung cảnh báo lừa đảo: nền đỏ nhạt, viền trái đỏ, icon ⚠.
class QuanAnWarningBox extends StatelessWidget {
  const QuanAnWarningBox({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(QuanAnSpacing.md),
    decoration: BoxDecoration(
      color: QuanAnColors.dangerSoft,
      borderRadius: BorderRadius.circular(QuanAnRadius.button),
      border: const Border(
        left: BorderSide(color: QuanAnColors.danger, width: 4),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, color: QuanAnColors.danger),
        const SizedBox(width: QuanAnSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: QuanAnText.body.copyWith(color: QuanAnColors.danger),
          ),
        ),
      ],
    ),
  );
}
