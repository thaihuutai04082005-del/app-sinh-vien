import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/phong_tro.dart';

class PhongTroCard extends StatelessWidget {
  const PhongTroCard({required this.phongTro, required this.onTap, super.key});

  final PhongTro phongTro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: phongTro.images.isEmpty
                      ? ColoredBox(
                          color: colors.primaryContainer,
                          child: const Icon(Icons.apartment, size: 34),
                        )
                      : NetworkPhoto(phongTro.images.first),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            phongTro.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (phongTro.ownerVerified)
                          const Tooltip(
                            message: 'Chủ trọ đã xác thực',
                            child: Icon(Icons.verified, size: 19),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phongTro.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${formatPrice(phongTro.price)}/tháng · '
                      '${phongTro.area.toStringAsFixed(0)} m²',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
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
