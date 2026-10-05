import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/phong_tro.dart';

class PhongTroDetailScreen extends StatelessWidget {
  const PhongTroDetailScreen({required this.phongTro, super.key});

  final PhongTro phongTro;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(phongTro.title)),
      body: DetailLayout(
        media: phongTro.images.isEmpty
            ? AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: colors.primaryContainer,
                  child: const Icon(Icons.apartment, size: 72),
                ),
              )
            : ImageGallery(urls: phongTro.images),
        info: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    phongTro.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (phongTro.ownerVerified)
                  const Tooltip(
                    message: 'Chủ trọ đã xác thực',
                    child: Icon(Icons.verified),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(phongTro.address),
            const SizedBox(height: 18),
            Text(
              '${formatPrice(phongTro.price)}/tháng',
              style: TextStyle(
                fontSize: 26,
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _Row('Diện tích', '${phongTro.area.toStringAsFixed(0)} m²'),
            _Row('Số người tối đa', '${phongTro.maxPeople}'),
            _Row('Loại phòng', phongTro.roomType.label),
            _Row('Tiền điện', '${formatPrice(phongTro.electricPrice)}/số'),
            _Row('Tiền nước', '${formatPrice(phongTro.waterPrice)}/người'),
            if (phongTro.depositEnabled)
              const _Row('Đặt cọc giữ chỗ', 'Có nhận đặt cọc online'),
            if (phongTro.amenities.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Chips(
                phongTro.amenities
                    .map((code) => amenityLabels[code] ?? code)
                    .toList(),
              ),
            ],
            if (phongTro.lifestylePrefs.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Chips(
                phongTro.lifestylePrefs
                    .map((code) => lifestyleLabels[code] ?? code)
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat với chủ trọ sẽ sớm ra mắt')),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Liên hệ chủ trọ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))],
        ),
      );
}

class _Chips extends StatelessWidget {
  const _Chips(this.labels);

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final label in labels) Chip(label: Text(label))],
      );
}
