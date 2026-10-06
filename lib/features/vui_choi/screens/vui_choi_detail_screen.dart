import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/vui_choi_model.dart';

class VuiChoiDetailScreen extends StatelessWidget {
  const VuiChoiDetailScreen({required this.item, super.key});

  final VuiChoiModel item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: DetailLayout(
        media: item.images.isEmpty
            ? AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: colors.primaryContainer,
                  child: const Icon(Icons.place, size: 72),
                ),
              )
            : ImageGallery(urls: item.images),
        info: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            if (vuiChoiCategoryLabels[item.category] != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(vuiChoiCategoryLabels[item.category]!)),
            ],
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.location_on_outlined, text: item.address),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time,
              text: 'Giờ mở cửa: ${item.openHour} - ${item.closeHour}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.confirmation_number_outlined,
              text:
                  'Giá vé: ${item.ticketPrice == 0 ? 'Miễn phí' : formatPrice(item.ticketPrice)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ),
    ],
  );
}
