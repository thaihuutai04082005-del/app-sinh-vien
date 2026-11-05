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

  late final Future<ThongKeShop> _thongKe = widget.dv.products.thongKeShop(
    widget.shopId,
  );
  late Future<int> _soTheoDoi = widget.dv.theoDoi.soNguoiTheoDoi(widget.shopId);
  bool? _dangTheoDoi;
  bool _dangDoi = false;

  @override
  void initState() {
    super.initState();
    widget.dv.theoDoi
        .dangTheoDoi('shop', widget.shopId)
        .then((v) => mounted ? setState(() => _dangTheoDoi = v) : null)
        .catchError((_) => null);
  }

  Future<void> _doiTheoDoi() async {
    final dang = _dangTheoDoi ?? false;
    setState(() => _dangDoi = true);
    try {
      dang
          ? await widget.dv.theoDoi.boTheoDoi('shop', widget.shopId)
          : await widget.dv.theoDoi.theoDoi('shop', widget.shopId);
      setState(() {
        _dangTheoDoi = !dang;
        _soTheoDoi = widget.dv.theoDoi.soNguoiTheoDoi(widget.shopId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _dangDoi = false);
    }
  }

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
      appBar: AppBar(
        title: Text(widget.shopName),
        actions: [
          if (widget.shopId != widget.dv.uid && _dangTheoDoi != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _dangTheoDoi!
                  ? OutlinedButton(
                      onPressed: _dangDoi ? null : _doiTheoDoi,
                      child: const Text('Đang theo dõi'),
                    )
                  : FilledButton.icon(
                      onPressed: _dangDoi ? null : _doiTheoDoi,
                      icon: const Icon(Icons.add),
                      label: const Text('Theo dõi'),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<ThongKeShop>(
            future: _thongKe,
            builder: (context, snap) {
              final tk = snap.data ?? ThongKeShop.trong;
              return ListTile(
                leading: const Icon(Icons.storefront),
                title: SaoTrungBinh(diem: tk.diem),
                subtitle: FutureBuilder<int>(
                  future: _soTheoDoi,
                  builder: (context, so) => Text(
                    [
                      '${so.data ?? 0} người theo dõi',
                      ..._hieuSuat(tk),
                    ].join(' · '),
                  ),
                ),
                trailing: tk.diem.soLuot == 0
                    ? null
                    : TextButton(
                        onPressed: () => _xemDanhGia(tk.diem),
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

  /// "Shop hủy 5% đơn", "Xác nhận trong ~3 giờ" (mục 3.4: điểm hiệu suất công khai).
  static List<String> _hieuSuat(ThongKeShop tk) => [
    if (tk.tyLeHuy case final t?) 'Shop hủy ${(t * 100).round()}% đơn',
    if (tk.xacNhanTrungBinh case final d?)
      d.inHours >= 1
          ? 'Xác nhận trong ~${d.inHours} giờ'
          : 'Xác nhận trong ~${d.inMinutes.clamp(1, 59)} phút',
  ];

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
