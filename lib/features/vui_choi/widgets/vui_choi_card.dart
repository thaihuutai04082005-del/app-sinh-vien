import 'package:flutter/material.dart';
import '../models/vui_choi_model.dart';

class VuiChoiCard extends StatelessWidget {
  final VuiChoiModel item;
  final VoidCallback onTap;

  const VuiChoiCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.images.isNotEmpty
              ? Image.network(
                  item.images.first,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.place, size: 40),
                )
              : const Icon(Icons.place, size: 40),
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
            Text('⏰ ${item.openHour} - ${item.closeHour}'),
          ],
        ),
        trailing: Text(
          item.ticketPrice == 0 ? 'Miễn phí' : '${item.ticketPrice.toInt()}đ',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}