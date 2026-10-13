import 'package:flutter/material.dart';

import '../../../shared/widgets/async_list_view.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'san_pham_detail_screen.dart';

/// Gian hàng công khai của một người bán.
class GianHangScreen extends StatefulWidget {
  const GianHangScreen({
    required this.dv,
    required this.shopId,
    required this.shopName,
    super.key,
  });

  final ShopDichVu dv;
  final String shopId;
  final String shopName;

  @override
  State<GianHangScreen> createState() => _GianHangScreenState();
}

class _GianHangScreenState extends State<GianHangScreen> {
  late Future<List<Product>> _sp = widget.dv.products.getSanPhamCuaShop(
    widget.shopId,
  );

  Future<void> _reload() async {
    final f = widget.dv.products.getSanPhamCuaShop(widget.shopId);
    setState(() {
      _sp = f;
    });
    await f.catchError((_) => <Product>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName)),
      body: AsyncListView<Product>(
        future: _sp,
        onRefresh: _reload,
        gridMaxExtent: 220,
        gridFooterHeight: 70,
        emptyIcon: Icons.storefront_outlined,
        emptyText: 'Shop chưa có sản phẩm nào.',
        itemBuilder: (context, p) => ProductCard(
          product: p,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SanPhamDetailScreen(dv: widget.dv, productId: p.id),
            ),
          ),
        ),
      ),
    );
  }
}
