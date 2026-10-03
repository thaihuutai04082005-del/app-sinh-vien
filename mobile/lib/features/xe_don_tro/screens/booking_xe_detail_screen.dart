import 'package:flutter/material.dart';

import '../../../core/utils/format_price.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/video_player_view.dart';
import '../models/booking_xe.dart';

const _statusLabels = {
  'pending': 'Chờ báo giá',
  'confirmed': 'Đã xác nhận',
  'in_progress': 'Đang chuyển',
  'done': 'Hoàn thành',
};

String formatBookingTime(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} '
      '${two(value.day)}/${two(value.month)}/${value.year}';
}

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          _statusLabels[status] ?? status,
          style: TextStyle(fontSize: 12, color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}

class BookingXeDetailScreen extends StatelessWidget {
  const BookingXeDetailScreen({required this.booking, super.key});

  final BookingXe booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu chuyển trọ')),
      body: DetailLayout(
        media: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageGallery(urls: booking.itemPhotos, aspectRatio: 4 / 3),
            for (final url in booking.videos) ...[
              const SizedBox(height: 16),
              VideoPlayerView(url: url),
            ],
          ],
        ),
        info: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingStatusChip(status: booking.status),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.trip_origin,
              label: 'Điểm đi',
              value: booking.fromAddress,
            ),
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Điểm đến',
              value: booking.toAddress,
            ),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Thời gian',
              value: formatBookingTime(booking.scheduledAt),
            ),
            _InfoRow(
              icon: Icons.request_quote_outlined,
              label: 'Giá trọn gói',
              value: booking.quotedPrice == null
                  ? 'Tài xế chưa báo giá'
                  : formatPrice(booking.quotedPrice!),
            ),
            const SizedBox(height: 8),
            Text(
              'Chạm vào ảnh để xem toàn màn hình.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
