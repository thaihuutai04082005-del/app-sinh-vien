import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../models/don_hang.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';

/// Chi tiết đơn hàng + các nút theo vai (mục 3.4):
/// shop xác nhận → giao → đã giao; người mua xác nhận đã nhận; hủy khi còn được hủy.
class DonHangDetailScreen extends StatefulWidget {
  const DonHangDetailScreen({
    required this.dv,
    required this.orderId,
    super.key,
  });

  final ShopDichVu dv;
  final String orderId;

  @override
  State<DonHangDetailScreen> createState() => _DonHangDetailScreenState();
}

class _DonHangDetailScreenState extends State<DonHangDetailScreen> {
  late Future<DonHang> _don = widget.dv.donHang.getDon(widget.orderId);
  bool _dangLam = false;

  void _reload() => setState(() {
    _don = widget.dv.donHang.getDon(widget.orderId);
  });

  Future<void> _lam(
    String hanhDong, {
    required String thongBao,
    String? reason,
  }) async {
    setState(() => _dangLam = true);
    try {
      await widget.dv.donHang.thaoTac(widget.orderId, hanhDong, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(thongBao)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _dangLam = false);
    }
  }

  Future<void> _danhGia() async {
    final xong = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VietDanhGiaScreen(
          tieuDe: 'Đánh giá đơn hàng',
          tieuChi: tieuChiShop,
          storage: widget.dv.storage,
          pickImages: widget.dv.pickImages,
          gui: (dg) => widget.dv.donHang.danhGia(widget.orderId, dg),
        ),
      ),
    );
    if (xong != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
    _reload();
  }

  Future<void> _huy() async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: 'Hủy đơn',
      nutXacNhan: 'Hủy đơn',
    );
    if (lyDo != null) await _lam('huy', reason: lyDo, thongBao: 'Đã hủy đơn.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: FutureBuilder<DonHang>(
        future: _don,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: FilledButton.tonal(
                onPressed: _reload,
                child: Text('${snap.error} · Thử lại'),
              ),
            );
          }
          return _noiDung(context, snap.data!);
        },
      ),
    );
  }

  Widget _noiDung(BuildContext context, DonHang d) {
    final theme = Theme.of(context);
    final laShop = d.shopId == widget.dv.uid;
    final tieuDe = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        laShop ? 'Khách: ${d.buyerName}' : d.shopName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DonStatusChip(status: d.status),
                  ],
                ),
                if (d.status == 'pending_confirmation' &&
                    d.confirmDeadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Shop cần xác nhận trước ${formatNgayGio(d.confirmDeadline!)} '
                      '(còn ${formatConLai(d.confirmDeadline!.difference(DateTime.now()))}), '
                      'quá hạn đơn tự hủy.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (d.status == 'cancelled' && d.cancelReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Lý do hủy (${DonHang.nguoiLamLabels[d.cancelledBy] ?? ''}): '
                      '${d.cancelReason}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 14),
                for (final m in d.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox.square(
                      dimension: 52,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.image.isEmpty
                            ? const ColoredBox(color: Colors.black12)
                            : NetworkPhoto(m.image),
                      ),
                    ),
                    title: Text(m.name),
                    subtitle: Text(
                      [
                        if (m.size.isNotEmpty) 'Size ${m.size}',
                        '${formatPrice(m.price)} x${m.quantity}',
                      ].join(' · '),
                    ),
                    trailing: Text(formatPrice(m.price * m.quantity)),
                  ),
                const Divider(),
                Row(
                  children: [
                    const Expanded(child: Text('Tổng tiền (COD)')),
                    Text(
                      formatPrice(d.totalPrice),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Nhận hàng', style: tieuDe),
                const SizedBox(height: 6),
                SelectableText(
                  [
                    DonHang.deliveryLabels[d.deliveryMethod] ??
                        d.deliveryMethod,
                    '${d.receiverName} · ${d.phone}',
                    if (d.address.isNotEmpty) d.address,
                    if (d.note.isNotEmpty) 'Lời nhắn: ${d.note}',
                  ].join('\n'),
                ),
                const SizedBox(height: 12),
                ..._nutBam(d, laShop),
                if (d.lichSu.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Lịch sử', style: tieuDe),
                  const SizedBox(height: 8),
                  StatusTimeline(
                    moc: d.lichSu,
                    nhanTrangThai: DonHang.statusLabels,
                    nhanNguoiLam: DonHang.nguoiLamLabels,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _nutBam(DonHang d, bool laShop) {
    final tat = _dangLam;
    Widget nut(String nhan, String hanhDong, String thongBao) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FilledButton(
        onPressed: tat ? null : () => _lam(hanhDong, thongBao: thongBao),
        child: Text(nhan),
      ),
    );
    final ds = <Widget>[
      if (laShop && d.status == 'pending_confirmation')
        nut('Xác nhận đơn', 'xacNhan', 'Đã xác nhận, chuẩn bị hàng nhé.'),
      if (laShop && d.status == 'to_ship')
        nut('Bắt đầu giao hàng', 'giaoHang', 'Đơn đang được giao.'),
      if (laShop && d.status == 'shipping')
        nut('Đã giao cho khách', 'daGiao', 'Đã báo giao hàng.'),
      if (!laShop && (d.status == 'shipping' || d.status == 'delivered'))
        nut('Đã nhận hàng đúng mô tả', 'daNhan', 'Cảm ơn bạn đã mua hàng!'),
      if (!laShop && d.status == 'buyer_confirmed')
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: d.reviewed
              ? const Text('Bạn đã đánh giá đơn này.')
              : FilledButton.icon(
                  onPressed: tat ? null : _danhGia,
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Đánh giá đơn hàng'),
                ),
        ),
    ];
    final duocHuy = laShop
        ? ['pending_confirmation', 'to_ship'].contains(d.status)
        : d.status == 'pending_confirmation';
    if (duocHuy) {
      ds.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton(
            onPressed: tat ? null : _huy,
            child: const Text('Hủy đơn'),
          ),
        ),
      );
    }
    return ds;
  }
}
