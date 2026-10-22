import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/gio_hang.dart';
import '../models/uu_dai.dart';
import '../services/shop_dich_vu.dart';
import 'dat_hang_screen.dart';

/// Trả giá (Make an offer, mục 3.4). Người mua: xem shop trả lời, rút lại, mua theo giá
/// đã được đồng ý. Shop: chấp nhận / từ chối.
class TraGiaScreen extends StatefulWidget {
  const TraGiaScreen({required this.dv, required this.laNguoiBan, super.key});

  final ShopDichVu dv;
  final bool laNguoiBan;

  @override
  State<TraGiaScreen> createState() => _TraGiaScreenState();
}

class _TraGiaScreenState extends State<TraGiaScreen> {
  late Future<List<TraGia>> _ds = _tai();
  bool _dangLam = false;

  Future<List<TraGia>> _tai() =>
      widget.dv.uuDai.danhSachTraGia(laNguoiBan: widget.laNguoiBan);

  Future<void> _reload() async {
    final f = _tai();
    setState(() {
      _ds = f;
    });
    await f.catchError((_) => <TraGia>[]);
  }

  Future<void> _phanHoi(TraGia t, String hanhDong, String thongBao) async {
    setState(() => _dangLam = true);
    try {
      await widget.dv.uuDai.phanHoiTraGia(t.id, hanhDong);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(thongBao)));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _dangLam = false);
    }
  }

  Future<void> _mua(TraGia t) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DatHangScreen(
          dv: widget.dv,
          dong: [
            DongGio(
              productId: t.productId,
              shopId: t.shopId,
              shopName: t.shopName,
              name: t.productName,
              image: t.productImage,
              price: t.offerPrice,
              size: t.size,
              quantity: 1,
              stock: 1,
              offerId: t.id,
            ),
          ],
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.laNguoiBan ? 'Khách trả giá' : 'Trả giá của tôi'),
      ),
      body: AsyncListView<TraGia>(
        future: _ds,
        onRefresh: _reload,
        emptyIcon: Icons.handshake_outlined,
        emptyText: widget.laNguoiBan
            ? 'Chưa có khách nào trả giá.'
            : 'Bạn chưa trả giá sản phẩm nào.',
        itemBuilder: (context, t) => _the(context, t),
      ),
    );
  }

  Widget _the(BuildContext context, TraGia t) {
    final theme = Theme.of(context);
    final tat = _dangLam;
    final nut = <Widget>[
      if (widget.laNguoiBan && t.status == 'pending') ...[
        OutlinedButton(
          onPressed: tat
              ? null
              : () => _phanHoi(t, 'tuChoi', 'Đã từ chối trả giá.'),
          child: const Text('Từ chối'),
        ),
        FilledButton(
          onPressed: tat
              ? null
              : () => _phanHoi(
                  t,
                  'chapNhan',
                  'Đã đồng ý. Khách có 24 giờ để mua theo giá này.',
                ),
          child: const Text('Đồng ý'),
        ),
      ],
      if (!widget.laNguoiBan && t.status == 'pending')
        OutlinedButton(
          onPressed: tat
              ? null
              : () => _phanHoi(t, 'huy', 'Đã rút lại trả giá.'),
          child: const Text('Rút lại'),
        ),
      if (!widget.laNguoiBan && t.conMuaDuoc)
        FilledButton(
          onPressed: tat ? null : () => _mua(t),
          child: Text('Mua với giá ${formatPrice(t.offerPrice)}'),
        ),
    ];
    final hetHan = t.status == 'accepted' && !t.conMuaDuoc;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: t.productImage.isEmpty
                        ? const ColoredBox(color: Colors.black12)
                        : NetworkPhoto(t.productImage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          widget.laNguoiBan ? t.buyerName : t.shopName,
                          if (t.size.isNotEmpty) 'Size ${t.size}',
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatPrice(t.price),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const TextSpan(text: '  →  '),
                            TextSpan(
                              text: formatPrice(t.offerPrice),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    hetHan
                        ? 'Hết hạn mua'
                        : TraGia.statusLabels[t.status] ?? t.status,
                  ),
                ),
              ],
            ),
            if (t.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('“${t.message}”'),
              ),
            if (t.conMuaDuoc && t.expiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Mua theo giá này trước ${formatNgayGio(t.expiresAt!)}.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (nut.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: nut,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
