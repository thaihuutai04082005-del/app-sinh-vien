import 'package:flutter/material.dart';

import '../../auth/models/xac_thuc.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'dang_san_pham_screen.dart';
import 'don_hang_list_screen.dart';
import 'gio_hang_screen.dart';
import 'kenh_nguoi_ban_screen.dart';
import 'phan_xu_tra_hang_screen.dart';
import 'tra_gia_screen.dart';
import 'san_pham_detail_screen.dart';

/// Sảnh Shop đồ rẻ (mục 3.4): duyệt theo danh mục / mức giá, giỏ hàng,
/// đơn mua và kênh người bán.
class ShopScreen extends StatefulWidget {
  const ShopScreen({required this.dv, super.key});

  final ShopDichVu dv;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

const _mucGia = {100000: 'Dưới 100k', 150000: 'Dưới 150k'};

class _ShopScreenState extends State<ShopScreen> {
  late Future<List<Product>> _tatCa = widget.dv.products.getDanhSachSanPham();
  late Future<List<Product>> _hienThi = _loc();
  String? _danhMuc;
  int? _giaToiDa;
  late final Stream<QuyenAdmin> _quyen = widget.dv.xacThuc.quyenAdmin(
    widget.dv.uid,
  );

  Future<List<Product>> _loc() => _tatCa.then(
    (ds) => [
      for (final p in ds)
        if ((_danhMuc == null || p.category == _danhMuc) &&
            (_giaToiDa == null || p.price < _giaToiDa!))
          p,
    ],
  );

  Future<void> _reload() async {
    final future = widget.dv.products.getDanhSachSanPham();
    setState(() {
      _tatCa = future;
      _hienThi = _loc();
    });
    await future.catchError((_) => <Product>[]);
  }

  Future<void> _mo(Widget man) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => man));
    _reload();
  }

  Future<void> _openCreate() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => DangSanPhamScreen(dv: widget.dv)),
    );
    if (id == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã đăng sản phẩm.')));
    await _mo(SanPhamDetailScreen(dv: widget.dv, productId: id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop đồ rẻ'),
        actions: [
          StreamBuilder<QuyenAdmin>(
            stream: _quyen,
            builder: (context, snap) => snap.data?.shop == true
                ? IconButton(
                    tooltip: 'Phân xử trả hàng',
                    onPressed: () => _mo(PhanXuTraHangScreen(dv: widget.dv)),
                    icon: const Icon(Icons.gavel_outlined),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Trả giá của tôi',
            onPressed: () =>
                _mo(TraGiaScreen(dv: widget.dv, laNguoiBan: false)),
            icon: const Icon(Icons.handshake_outlined),
          ),
          IconButton(
            tooltip: 'Đơn mua',
            onPressed: () =>
                _mo(DonHangListScreen(dv: widget.dv, laNguoiBan: false)),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Kênh người bán',
            onPressed: () => _mo(KenhNguoiBanScreen(dv: widget.dv)),
            icon: const Icon(Icons.storefront_outlined),
          ),
          NutGioHang(
            gioHang: widget.dv.gioHang,
            onPressed: () => _mo(GioHangScreen(dv: widget.dv)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Đăng sản phẩm'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                for (final (key, label) in [
                  (null, 'Tất cả'),
                  ...productCategoryLabels.entries.map((e) => (e.key, e.value)),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _danhMuc == key,
                      onSelected: (_) => setState(() {
                        _danhMuc = key;
                        _hienThi = _loc();
                      }),
                    ),
                  ),
                const SizedBox(width: 8),
                for (final e in _mucGia.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _giaToiDa == e.key,
                      onSelected: (chon) => setState(() {
                        _giaToiDa = chon ? e.key : null;
                        _hienThi = _loc();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncListView<Product>(
              future: _hienThi,
              onRefresh: _reload,
              gridMaxExtent: 220,
              gridFooterHeight: 70,
              emptyIcon: Icons.shopping_bag_outlined,
              emptyText: _danhMuc == null && _giaToiDa == null
                  ? 'Chưa có sản phẩm nào. Bấm "Đăng sản phẩm" để bắt đầu.'
                  : 'Không có sản phẩm phù hợp bộ lọc.',
              itemBuilder: (context, product) => ProductCard(
                product: product,
                onTap: () => _mo(
                  SanPhamDetailScreen(dv: widget.dv, productId: product.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
