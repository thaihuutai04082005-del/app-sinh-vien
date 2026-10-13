import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/gio_hang.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'dat_hang_screen.dart';

/// Giỏ hàng, nhóm theo shop. Đặt hàng thì mỗi shop thành một đơn riêng.
class GioHangScreen extends StatelessWidget {
  const GioHangScreen({required this.dv, super.key});

  final ShopDichVu dv;

  @override
  Widget build(BuildContext context) {
    final gio = dv.gioHang;
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: ListenableBuilder(
        listenable: gio,
        builder: (context, _) {
          if (gio.dong.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Giỏ hàng trống. Chọn sản phẩm rồi bấm "Thêm vào giỏ".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final theoShop = <String, List<DongGio>>{};
          for (final d in gio.dong) {
            (theoShop[d.shopId] ??= []).add(d);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              for (final ds in theoShop.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              ds.first.shopName.isEmpty
                                  ? 'Shop'
                                  : ds.first.shopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        for (final d in ds) _DongGioTile(gio: gio, dong: d),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: gio,
        builder: (context, _) => gio.dong.isEmpty
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tạm tính'),
                            Text(
                              formatPrice(gio.tamTinh),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DatHangScreen(
                              dv: dv,
                              dong: gio.dong,
                              tuGioHang: true,
                            ),
                          ),
                        ),
                        child: Text('Đặt hàng (${gio.soMon})'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DongGioTile extends StatelessWidget {
  const _DongGioTile({required this.gio, required this.dong});

  final GioHang gio;
  final DongGio dong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dong.image.isEmpty
                  ? const ColoredBox(color: Colors.black12)
                  : NetworkPhoto(dong.image),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dong.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [
                    if (dong.size.isNotEmpty) 'Size ${dong.size}',
                    formatPrice(dong.price),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ChonSoLuong(
            value: dong.quantity,
            max: dong.stock.clamp(1, GioHang.soLuongToiDa),
            onChanged: (v) => gio.datSoLuong(dong.khoa, v),
          ),
          IconButton(
            tooltip: 'Bỏ khỏi giỏ',
            onPressed: () => gio.xoa(dong.khoa),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
