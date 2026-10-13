import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/video_player_view.dart';
import '../models/gio_hang.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'dang_san_pham_screen.dart';
import 'dat_hang_screen.dart';
import 'gian_hang_screen.dart';
import 'gio_hang_screen.dart';

/// Chi tiết sản phẩm: chọn size, số lượng, thêm vào giỏ / mua ngay.
/// Chủ sản phẩm thấy nút sửa, xóa thay cho nút mua.
class SanPhamDetailScreen extends StatefulWidget {
  const SanPhamDetailScreen({
    required this.dv,
    required this.productId,
    super.key,
  });

  final ShopDichVu dv;
  final String productId;

  @override
  State<SanPhamDetailScreen> createState() => _SanPhamDetailScreenState();
}

class _SanPhamDetailScreenState extends State<SanPhamDetailScreen> {
  late Future<Product> _product = widget.dv.products.getSanPham(
    widget.productId,
  );
  String? _size;
  int _soLuong = 1;
  bool _dangXoa = false;

  void _reload() => setState(() {
    _product = widget.dv.products.getSanPham(widget.productId);
  });

  DongGio? _dongDaChon(Product p) {
    if (p.sizes.isNotEmpty && _size == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn size trước đã.')));
      return null;
    }
    return DongGio.tu(p, size: _size ?? '', quantity: _soLuong);
  }

  void _themVaoGio(Product p) {
    final d = _dongDaChon(p);
    if (d == null) return;
    widget.dv.gioHang.them(d);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ.'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GioHangScreen(dv: widget.dv),
            ),
          ),
        ),
      ),
    );
  }

  void _muaNgay(Product p) {
    final d = _dongDaChon(p);
    if (d == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DatHangScreen(dv: widget.dv, dong: [d]),
      ),
    );
  }

  Future<void> _sua(Product p) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DangSanPhamScreen(dv: widget.dv, sanPham: p),
      ),
    );
    if (id != null) _reload();
  }

  Future<void> _xoa(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text(
          '"${p.name}" sẽ biến mất khỏi shop. Đơn đã đặt vẫn giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Thôi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _dangXoa = true);
    try {
      await widget.dv.products.xoaSanPham(p.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXoa = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _product,
      builder: (context, snap) {
        final p = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(p?.name ?? 'Sản phẩm'),
            actions: [
              NutGioHang(
                gioHang: widget.dv.gioHang,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GioHangScreen(dv: widget.dv),
                  ),
                ),
              ),
            ],
          ),
          body: switch (snap) {
            AsyncSnapshot(connectionState: != ConnectionState.done) =>
              const Center(child: CircularProgressIndicator()),
            AsyncSnapshot(hasError: true) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            _ => _noiDung(context, p!),
          },
        );
      },
    );
  }

  Widget _noiDung(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final laChu = product.shopId == widget.dv.uid;
    final toiDa = product.stock.clamp(1, GioHang.soLuongToiDa);
    return DetailLayout(
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
          const SizedBox(height: 12),
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
                  product.conHang ? 'Còn ${product.stock}' : 'Hết hàng',
                ),
              ),
            ],
          ),
          if (product.shopName.isNotEmpty) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront),
              title: Text(product.shopName),
              subtitle: const Text('Xem gian hàng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GianHangScreen(
                    dv: widget.dv,
                    shopId: product.shopId,
                    shopName: product.shopName,
                  ),
                ),
              ),
            ),
          ],
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(product.description),
          ],
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
                for (final size in product.sizes)
                  laChu
                      ? Chip(label: Text(size))
                      : ChoiceChip(
                          label: Text(size),
                          selected: _size == size,
                          onSelected: (_) => setState(() => _size = size),
                        ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (laChu)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _dangXoa ? null : () => _sua(product),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _dangXoa ? null : () => _xoa(product),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_dangXoa ? 'Đang xóa...' : 'Xóa'),
                  ),
                ),
              ],
            )
          else if (product.conHang) ...[
            Row(
              children: [
                const Text('Số lượng'),
                const Spacer(),
                ChonSoLuong(
                  value: _soLuong.clamp(1, toiDa),
                  max: toiDa,
                  onChanged: (v) => setState(() => _soLuong = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _themVaoGio(product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Thêm vào giỏ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _muaNgay(product),
                    child: const Text('Mua ngay'),
                  ),
                ),
              ],
            ),
          ] else
            const Text('Sản phẩm đã hết hàng.'),
        ],
      ),
    );
  }
}
