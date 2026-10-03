import 'package:flutter/material.dart';

import '../../../core/utils/format_price.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/video_player_view.dart';
import '../models/product.dart';

const productCategoryLabels = {
  'ao': 'Áo',
  'quan': 'Quần',
  'phu_kien': 'Phụ kiện',
};

class SanPhamDetailScreen extends StatelessWidget {
  const SanPhamDetailScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: DetailLayout(
        media: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageGallery(urls: product.images),
            for (final url in product.videos) ...[
              const SizedBox(height: 16),
              VideoPlayerView(url: url),
            ],
          ],
        ),
        info: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              formatPrice(product.price),
              style: TextStyle(
                fontSize: 26,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    productCategoryLabels[product.category] ?? product.category,
                  ),
                ),
                Chip(
                  label: Text(
                    product.status == 'out_of_stock'
                        ? 'Hết hàng'
                        : 'Còn ${product.stock}',
                  ),
                ),
              ],
            ),
            if (product.sizes.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Size',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in product.sizes) Chip(label: Text(size)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
