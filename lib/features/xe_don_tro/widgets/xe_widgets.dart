import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';

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
    final (bg, fg) = switch (status) {
      'cancelled' => (colors.errorContainer, colors.onErrorContainer),
      'done' => (colors.tertiaryContainer, colors.onTertiaryContainer),
      'quoted' => (colors.primaryContainer, colors.onPrimaryContainer),
      _ => (colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          BookingXe.statusLabels[status] ?? status,
          style: TextStyle(fontSize: 12, color: fg),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.booking,
    required this.onTap,
    this.laTaiXe = false,
    super.key,
  });

  final BookingXe booking;
  final VoidCallback onTap;

  /// Tài xế xem thì hiện tên khách, sinh viên xem thì hiện tên tài xế.
  final bool laTaiXe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doiTac = laTaiXe ? booking.userName : booking.driverName;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: booking.itemPhotos.isEmpty
                      ? const SizedBox.shrink()
                      : NetworkPhoto(booking.itemPhotos.first),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.fromAddress} → ${booking.toAddress}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        formatBookingTime(booking.scheduledAt),
                        if (doiTac.isNotEmpty) doiTac,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        BookingStatusChip(status: booking.status),
                        if (booking.quotedPrice != null)
                          Text(
                            formatPrice(booking.quotedPrice!),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaiXeCard extends StatelessWidget {
  const TaiXeCard({
    required this.taiXe,
    this.onDatXe,
    this.trailing,
    super.key,
  });

  final TaiXe taiXe;
  final VoidCallback? onDatXe;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (taiXe.vehiclePhotos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.square(
                      dimension: 52,
                      child: NetworkPhoto(taiXe.vehiclePhotos.first),
                    ),
                  )
                else
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      taiXe.vehicleType == 'xe_may'
                          ? Icons.two_wheeler
                          : Icons.local_shipping_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              taiXe.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (taiXe.driverVerified) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Đã xác thực danh tính',
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        [
                          taiXe.loaiXe,
                          if (taiXe.licensePlate.isNotEmpty) taiXe.licensePlate,
                          taiXe.area,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(taiXe.priceReference)),
              ],
            ),
            if (taiXe.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(taiXe.description, style: theme.textTheme.bodySmall),
            ],
            if (onDatXe != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onDatXe,
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Đặt xe, xin báo giá'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
