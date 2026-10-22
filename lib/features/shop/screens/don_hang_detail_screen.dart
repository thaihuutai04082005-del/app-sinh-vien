import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'gio_hang_screen.dart';
import 'yeu_cau_tra_hang_screen.dart';

/// Chi tiết đơn hàng + các nút theo vai (mục 3.4):
/// shop xác nhận → giao → đã giao; người mua xác nhận đã nhận hoặc yêu cầu trả hàng;
/// shop đồng ý / từ chối trả hàng; người mua khiếu nại; admin Shop phân xử.
class DonHangDetailScreen extends StatefulWidget {
  const DonHangDetailScreen({
    required this.dv,
    required this.orderId,
    this.laAdmin = false,
    super.key,
  });

  final ShopDichVu dv;
  final String orderId;

  /// Mở từ màn phân xử của admin Shop: hiện nút phân xử khiếu nại.
  final bool laAdmin;

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
  }) => _chay(
    () => widget.dv.donHang.thaoTac(widget.orderId, hanhDong, reason: reason),
    thongBao,
  );

  Future<void> _chay(Future<void> Function() viec, String thongBao) async {
    setState(() => _dangLam = true);
    try {
      await viec();
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

  /// Thêm lại các món còn bán vào giỏ (theo giá hiện tại) rồi mở giỏ.
  Future<void> _muaLai(DonHang d) async {
    var them = 0;
    for (final m in d.items) {
      try {
        final p = await widget.dv.products.getSanPham(m.productId);
        if (!p.conHang || (p.sizes.isNotEmpty && !p.sizes.contains(m.size))) {
          continue;
        }
        widget.dv.gioHang.them(
          DongGio.tu(p, size: m.size, quantity: m.quantity.clamp(1, p.stock)),
        );
        them++;
      } catch (_) {
        // Sản phẩm đã bị xóa: bỏ qua.
      }
    }
    if (!mounted) return;
    if (them == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Các sản phẩm trong đơn đã hết hàng.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GioHangScreen(dv: widget.dv)),
    );
  }

  Future<void> _yeuCauTraHang() async {
    final xong = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            YeuCauTraHangScreen(dv: widget.dv, orderId: widget.orderId),
      ),
    );
    if (xong != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu, chờ shop trả lời.')),
    );
    _reload();
  }

  Future<void> _hoiRoiLam(
    String hanhDong, {
    required String tieuDe,
    required String nut,
    required String thongBao,
  }) async {
    final lyDo = await hoiLyDo(context, tieuDe: tieuDe, nutXacNhan: nut);
    if (lyDo != null) await _lam(hanhDong, reason: lyDo, thongBao: thongBao);
  }

  Future<void> _phanXu({required bool dongY}) async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: dongY ? 'Hoàn tiền cho người mua' : 'Bác khiếu nại',
      nutXacNhan: 'Xác nhận',
    );
    if (lyDo == null) return;
    await _chay(
      () => widget.dv.donHang.xuLyKhieuNai(
        widget.orderId,
        dongY: dongY,
        lyDo: lyDo,
      ),
      'Đã phân xử.',
    );
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
                if (_hanChot(d, laShop) case final h?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(h, style: theme.textTheme.bodySmall),
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
                        if (m.listPrice != null)
                          'giá đã trả (niêm yết ${formatPrice(m.listPrice!)})',
                      ].join(' · '),
                    ),
                    trailing: Text(formatPrice(m.price * m.quantity)),
                  ),
                const Divider(),
                if (d.discountAmount > 0) ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Tạm tính')),
                      Text(formatPrice(d.subtotal ?? d.totalPrice)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Voucher ${d.voucherCode ?? ''}')),
                      Text('-${formatPrice(d.discountAmount)}'),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tổng tiền (${d.paymentMethod == 'online' ? 'online' : 'COD'})',
                      ),
                    ),
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
                if (d.trangThaiTien case final t?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t, style: theme.textTheme.bodySmall),
                  ),
                ..._traHang(d, tieuDe),
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

  /// Hạn đang chạy của đơn, nói theo vai người xem.
  String? _hanChot(DonHang d, bool laShop) {
    String con(DateTime t) =>
        '${formatNgayGio(t)} (còn ${formatConLai(t.difference(DateTime.now()))})';
    if (d.status == 'delivered' && d.returnDeadline != null) {
      return laShop
          ? 'Đơn tự hoàn tất lúc ${con(d.returnDeadline!)} nếu khách không yêu cầu trả hàng.'
          : 'Bạn có thể yêu cầu trả hàng trước ${con(d.returnDeadline!)}, '
                'sau đó đơn tự hoàn tất.';
    }
    if (d.status == 'return_requested' && d.returnResponseDeadline != null) {
      return 'Shop cần trả lời trước ${con(d.returnResponseDeadline!)}, '
          'quá hạn coi như đồng ý trả hàng.';
    }
    return null;
  }

  /// Lý do, ảnh trả hàng, lý do từ chối, khiếu nại, kết luận của admin.
  List<Widget> _traHang(DonHang d, TextStyle? tieuDe) {
    if (d.returnReason == null) return const [];
    final theme = Theme.of(context);
    Widget dong(String nhan, String noiDung) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$nhan: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: noiDung),
          ],
        ),
      ),
    );
    return [
      const SizedBox(height: 18),
      Text('Trả hàng / hoàn tiền', style: tieuDe),
      dong('Lý do của người mua', d.returnReason!),
      if (d.returnImages.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final url in d.returnImages)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 72,
                    child: NetworkPhoto(url),
                  ),
                ),
            ],
          ),
        ),
      if (d.returnRejectReason != null)
        dong('Shop từ chối', d.returnRejectReason!),
      if (d.disputeReason != null) dong('Khiếu nại', d.disputeReason!),
      if (d.disputeResult != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Kết luận của admin: ${d.disputeResult}',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
    ];
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
    Widget phu(String nhan, VoidCallback onPressed) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        onPressed: tat ? null : onPressed,
        child: Text(nhan),
      ),
    );
    if (widget.laAdmin) {
      return [
        if (d.status == 'return_disputed') ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton(
              onPressed: tat ? null : () => _phanXu(dongY: true),
              child: const Text('Hoàn tiền cho người mua'),
            ),
          ),
          phu('Bác khiếu nại, tiền về shop', () => _phanXu(dongY: false)),
        ],
      ];
    }
    final ds = <Widget>[
      if (laShop && d.status == 'pending_confirmation')
        nut('Xác nhận đơn', 'xacNhan', 'Đã xác nhận, chuẩn bị hàng nhé.'),
      if (laShop && d.status == 'to_ship')
        nut('Bắt đầu giao hàng', 'giaoHang', 'Đơn đang được giao.'),
      if (laShop && d.status == 'shipping')
        nut('Đã giao cho khách', 'daGiao', 'Đã báo giao hàng.'),
      if (!laShop && (d.status == 'shipping' || d.status == 'delivered'))
        nut('Đã nhận hàng đúng mô tả', 'daNhan', 'Cảm ơn bạn đã mua hàng!'),
      if (!laShop && d.status == 'delivered')
        phu('Yêu cầu trả hàng / hoàn tiền', _yeuCauTraHang),
      if (laShop && d.status == 'return_requested') ...[
        nut(
          'Đồng ý trả hàng, hoàn tiền',
          'dongYTraHang',
          'Đã đồng ý trả hàng.',
        ),
        phu(
          'Từ chối trả hàng',
          () => _hoiRoiLam(
            'tuChoiTraHang',
            tieuDe: 'Từ chối trả hàng',
            nut: 'Từ chối',
            thongBao: 'Đã từ chối. Người mua có thể khiếu nại lên admin.',
          ),
        ),
      ],
      if (!laShop && d.status == 'return_rejected') ...[
        nut('Chấp nhận, đã nhận hàng', 'daNhan', 'Đơn đã hoàn tất.'),
        phu(
          'Khiếu nại lên admin',
          () => _hoiRoiLam(
            'khieuNai',
            tieuDe: 'Khiếu nại',
            nut: 'Gửi khiếu nại',
            thongBao: 'Đã gửi khiếu nại, admin Shop sẽ xem xét.',
          ),
        ),
      ],
      if (!laShop && d.status == 'buyer_confirmed')
        phu('Mua lại', () => _muaLai(d)),
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
