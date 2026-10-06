import 'package:flutter/material.dart';
import '../models/vui_choi_model.dart';

class VuiChoiDetailScreen extends StatelessWidget {
  final VuiChoiModel item;

  const VuiChoiDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide Ảnh hoặc Ảnh bìa
            if (item.images.isNotEmpty)
              Image.network(
                item.images.first,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 220,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.address)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue, size: 20),
                      const SizedBox(width: 4),
                      Text('Giờ mở cửa: ${item.openHour} - ${item.closeHour}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Giá vé: ${item.ticketPrice == 0 ? "Miễn phí" : "${item.ticketPrice.toInt()}đ"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}