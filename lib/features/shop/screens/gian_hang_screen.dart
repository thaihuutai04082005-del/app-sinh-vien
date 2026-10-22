import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../models/product.dart';
import '../models/uu_dai.dart';
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

  late final Future<List<Voucher>> _voucher = widget.dv.uuDai
      .voucherCuaShop(widget.shopId)
      .then(
        (ds) => [
          for (final v in ds)
            if (v.conDung) v,
        ],
      )
      .catchError((_) => <Voucher>[]);

  late final Future<DiemDanhGia> _diem = widget.dv.products.diemShop(
    widget.shopId,
  );

  void _xemDanhGia(DiemDanhGia diem) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Đánh giá ${widget.shopName}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DanhGiaSection(
              taiDanhGia: () =>
                  widget.dv.danhGia.theoDoiTuong('shop', widget.shopId),
              diem: diem,
              tieuChi: tieuChiShop,
            ),
          ],
        ),
      ),
    ),
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
      body: Column(
        children: [
          FutureBuilder<DiemDanhGia>(
            future: _diem,
            builder: (context, snap) {
              final diem = snap.data ?? DiemDanhGia.chuaCo;
              return ListTile(
                leading: const Icon(Icons.storefront),
                title: SaoTrungBinh(diem: diem),
                trailing: diem.soLuot == 0
                    ? null
                    : TextButton(
                        onPressed: () => _xemDanhGia(diem),
                        child: const Text('Xem đánh giá'),
                      ),
              );
            },
          ),
          FutureBuilder<List<Voucher>>(
            future: _voucher,
            builder: (context, snap) {
              final ds = snap.data ?? const <Voucher>[];
              if (ds.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final v in ds)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                          ),
                          label: Text('${v.code} · ${v.moTa(formatGiaGon)}'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: _danhSach()),
        ],
      ),
    );
  }

  Widget _danhSach() {
    return AsyncListView<Product>(
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
            builder: (_) => SanPhamDetailScreen(dv: widget.dv, productId: p.id),
          ),
        ),
      ),
    );
  }
}
