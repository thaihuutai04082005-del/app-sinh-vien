import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/vui_choi_model.dart';

class VuiChoiCard extends StatelessWidget {
  const VuiChoiCard({required this.item, required this.onTap, super.key});

  final VuiChoiModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 70,
            height: 70,
            child: item.images.isEmpty
                ? ColoredBox(
                    color: colors.primaryContainer,
                    child: const Icon(Icons.place, size: 40),
                  )
                : NetworkPhoto(item.images.first),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Mở cửa: ${item.openHour} - ${item.closeHour}'),
          ],
        ),
        trailing: Text(
          item.ticketPrice == 0 ? 'Miễn phí' : formatPrice(item.ticketPrice),
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
