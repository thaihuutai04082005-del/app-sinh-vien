import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';
import 'dang_san_pham_screen.dart';
import 'don_hang_list_screen.dart';
import 'san_pham_detail_screen.dart';

/// Kênh người bán: sản phẩm của mình (sửa / xóa trong màn chi tiết) và đơn bán.
class KenhNguoiBanScreen extends StatefulWidget {
  const KenhNguoiBanScreen({required this.dv, super.key});

  final ShopDichVu dv;

  @override
  State<KenhNguoiBanScreen> createState() => _KenhNguoiBanScreenState();
}

class _KenhNguoiBanScreenState extends State<KenhNguoiBanScreen> {
  late Future<List<Product>> _sp = widget.dv.products.getSanPhamCuaShop(
    widget.dv.uid,
  );

  Future<void> _reload() async {
    final f = widget.dv.products.getSanPhamCuaShop(widget.dv.uid);
    setState(() {
      _sp = f;
    });
    await f.catchError((_) => <Product>[]);
  }

  Future<void> _mo(Widget man) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => man));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kênh người bán'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                _mo(DonHangListScreen(dv: widget.dv, laNguoiBan: true)),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Đơn bán'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final id = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => DangSanPhamScreen(dv: widget.dv)),
          );
          if (id != null) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Đăng sản phẩm'),
      ),
      body: AsyncListView<Product>(
        future: _sp,
        onRefresh: _reload,
        emptyIcon: Icons.storefront_outlined,
        emptyText: 'Bạn chưa đăng sản phẩm nào.',
        itemBuilder: (context, p) => Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () =>
                _mo(SanPhamDetailScreen(dv: widget.dv, productId: p.id)),
            leading: SizedBox.square(
              dimension: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: p.images.isEmpty
                    ? const ColoredBox(color: Colors.black12)
                    : NetworkPhoto(p.images.first),
              ),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${formatPrice(p.price)} · '
              '${p.conHang ? 'Còn ${p.stock}' : 'Hết hàng'}',
              style: p.conHang
                  ? null
                  : TextStyle(color: theme.colorScheme.error),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
