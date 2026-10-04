import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../core/utils/format_price.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'dang_san_pham_screen.dart';
import 'san_pham_detail_screen.dart';

/// Danh sách sản phẩm mọi người đã đăng + nút đăng sản phẩm mới (mục 3.4).
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final ProductService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<List<Product>> _products = widget.service.getDanhSachSanPham();

  Future<void> _reload() async {
    final future = widget.service.getDanhSachSanPham();
    setState(() {
      _products = future;
    });
    await future.catchError((_) => <Product>[]);
  }

  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SanPhamDetailScreen(product: product),
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => DangSanPhamScreen(
          service: widget.service,
          storage: widget.storage,
          pickImages: widget.pickImages,
        ),
      ),
    );
    if (created == null || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã đăng sản phẩm.')));
    _openDetail(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop đồ rẻ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Đăng sản phẩm'),
      ),
      body: AsyncListView<Product>(
        future: _products,
        onRefresh: _reload,
        gridMaxExtent: 220,
        gridFooterHeight: 70,
        emptyIcon: Icons.shopping_bag_outlined,
        emptyText: 'Chưa có sản phẩm nào. Bấm "Đăng sản phẩm" để bắt đầu.',
        itemBuilder: (context, product) =>
            _ProductCard(product: product, onTap: () => _openDetail(product)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

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
                      child: _Badge(
                        icon: Icons.photo_library_outlined,
                        text: '${product.images.length}',
                      ),
                    ),
                  if (product.videos.isNotEmpty)
                    const Positioned(
                      right: 8,
                      bottom: 8,
                      child: _Badge(icon: Icons.play_arrow, text: 'Video'),
                    ),
                  if (product.status == 'out_of_stock')
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: _Badge(text: 'Hết hàng'),
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
                  Text(
                    formatPrice(product.price),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon});

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
