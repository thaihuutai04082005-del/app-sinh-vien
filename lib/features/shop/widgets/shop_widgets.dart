import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.images.isNotEmpty)
                    NetworkPhoto(product.images.first),
                  if (product.images.length > 1)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: ShopBadge(
                        icon: Icons.photo_library_outlined,
                        text: '${product.images.length}',
                      ),
                    ),
                  if (product.videos.isNotEmpty)
                    const Positioned(
                      right: 8,
                      bottom: 8,
                      child: ShopBadge(icon: Icons.play_arrow, text: 'Video'),
                    ),
                  if (!product.conHang)
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: ShopBadge(text: 'Hết hàng'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(product.price),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SaoTrungBinh(diem: product.diem, gon: true),
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

class ShopBadge extends StatelessWidget {
  const ShopBadge({required this.text, this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút giỏ hàng trên AppBar, có số món.
class NutGioHang extends StatelessWidget {
  const NutGioHang({required this.gioHang, required this.onPressed, super.key});

  final GioHang gioHang;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gioHang,
      builder: (context, _) => IconButton(
        tooltip: 'Giỏ hàng',
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: gioHang.soMon > 0,
          label: Text('${gioHang.soMon}'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}

class DonStatusChip extends StatelessWidget {
  const DonStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      'cancelled' => (colors.errorContainer, colors.onErrorContainer),
      'buyer_confirmed' => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
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
          DonHang.statusLabels[status] ?? status,
          style: TextStyle(fontSize: 12, color: fg),
        ),
      ),
    );
  }
}

class DonCard extends StatelessWidget {
  const DonCard({
    required this.don,
    required this.onTap,
    required this.laNguoiBan,
    super.key,
  });

  final DonHang don;
  final VoidCallback onTap;
  final bool laNguoiBan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dau = don.items.isEmpty ? null : don.items.first;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    laNguoiBan ? Icons.person_outline : Icons.storefront,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      laNguoiBan ? don.buyerName : don.shopName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DonStatusChip(status: don.status),
                ],
              ),
              const Divider(height: 18),
              if (dau != null)
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: dau.image.isEmpty
                            ? const ColoredBox(color: Colors.black12)
                            : NetworkPhoto(dau.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dau.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (dau.size.isNotEmpty) 'Size ${dau.size}',
                              'x${dau.quantity}',
                              if (don.items.length > 1)
                                '+${don.items.length - 1} món khác',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text.rich(
                  TextSpan(
                    text: '${don.soLuong} sản phẩm · Tổng: ',
                    style: theme.textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: formatPrice(don.totalPrice),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút −/+ chọn số lượng.
class ChonSoLuong extends StatelessWidget {
  const ChonSoLuong({
    required this.value,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Bớt',
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Thêm',
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
