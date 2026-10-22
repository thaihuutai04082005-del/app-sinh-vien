import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../../../shared/widgets/video_player_view.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';
import '../widgets/xe_widgets.dart';

/// Chi tiết đơn đặt xe, kèm các nút theo vai: sinh viên chấp nhận báo giá / hủy;
/// tài xế báo giá, bắt đầu, hoàn thành, từ chối (mục 3.3).
class BookingXeDetailScreen extends StatefulWidget {
  const BookingXeDetailScreen({
    required this.dv,
    required this.bookingId,
    super.key,
  });

  final XeDichVu dv;
  final String bookingId;

  @override
  State<BookingXeDetailScreen> createState() => _BookingXeDetailScreenState();
}

class _BookingXeDetailScreenState extends State<BookingXeDetailScreen> {
  late Future<BookingXe> _booking = widget.dv.xe.getBooking(widget.bookingId);
  bool _dangLam = false;

  void _reload() => setState(() {
    _booking = widget.dv.xe.getBooking(widget.bookingId);
  });

  Future<void> _lam(
    String hanhDong, {
    int? price,
    String? reason,
    required String thongBao,
  }) async {
    setState(() => _dangLam = true);
    try {
      await widget.dv.xe.thaoTac(
        widget.bookingId,
        hanhDong,
        price: price,
        reason: reason,
      );
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

  Future<void> _baoGia(BookingXe b) async {
    final gia = await _hoiGia(context, b.quotedPrice);
    if (gia == null) return;
    await _lam('baoGia', price: gia, thongBao: 'Đã gửi báo giá cho khách.');
  }

  Future<void> _danhGia() async {
    final xong = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VietDanhGiaScreen(
          tieuDe: 'Đánh giá tài xế',
          tieuChi: tieuChiXe,
          storage: widget.dv.storage,
          pickImages: widget.dv.pickImages,
          gui: (dg) => widget.dv.xe.danhGia(widget.bookingId, dg),
        ),
      ),
    );
    if (xong != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
    _reload();
  }

  Future<void> _huy({required bool laTaiXe}) async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: laTaiXe ? 'Từ chối / hủy chuyến' : 'Hủy yêu cầu',
      nutXacNhan: 'Hủy đơn',
    );
    if (lyDo == null) return;
    await _lam('huy', reason: lyDo, thongBao: 'Đã hủy đơn.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn chuyển trọ')),
      body: FutureBuilder<BookingXe>(
        future: _booking,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
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
            );
          }
          return _noiDung(context, snap.data!);
        },
      ),
    );
  }

  Widget _noiDung(BuildContext context, BookingXe b) {
    final theme = Theme.of(context);
    final laTaiXe = b.driverId == widget.dv.uid;
    return DetailLayout(
      media: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageGallery(urls: b.itemPhotos, aspectRatio: 4 / 3),
          for (final url in b.videos) ...[
            const SizedBox(height: 16),
            VideoPlayerView(url: url),
          ],
        ],
      ),
      info: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingStatusChip(status: b.status),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.trip_origin,
            label: 'Điểm đi',
            value: b.fromAddress,
          ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Điểm đến',
            value: b.toAddress,
          ),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Thời gian',
            value: formatBookingTime(b.scheduledAt),
          ),
          _InfoRow(
            icon: Icons.request_quote_outlined,
            label: 'Giá trọn gói',
            value: b.quotedPrice == null
                ? 'Tài xế chưa báo giá'
                : formatPrice(b.quotedPrice!),
          ),
          if (laTaiXe)
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Khách',
              value: [
                b.userName,
                b.contactPhone,
              ].where((s) => s.isNotEmpty).join(' · '),
            )
          else if (b.driverName.isNotEmpty)
            _InfoRow(
              icon: Icons.local_shipping_outlined,
              label: 'Tài xế',
              value: [
                b.driverName,
                TaiXe.loaiXeLabels[b.vehicleType] ?? '',
                b.driverPhone ??
                    (b.dangMo ? 'Số điện thoại hiện sau khi chốt giá' : ''),
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
          if (b.note.isNotEmpty)
            _InfoRow(
              icon: Icons.sticky_note_2_outlined,
              label: 'Ghi chú',
              value: b.note,
            ),
          if (b.status == 'cancelled' && b.cancelReason != null)
            _InfoRow(
              icon: Icons.block,
              label:
                  'Lý do hủy (${BookingXe.nguoiLamLabels[b.cancelledBy] ?? ''})',
              value: b.cancelReason!,
            ),
          const SizedBox(height: 8),
          ..._nutBam(b, laTaiXe),
          if (b.lichSu.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Lịch sử',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            StatusTimeline(
              moc: b.lichSu,
              nhanTrangThai: BookingXe.statusLabels,
              nhanNguoiLam: BookingXe.nguoiLamLabels,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _nutBam(BookingXe b, bool laTaiXe) {
    final tat = _dangLam;
    final nut = <Widget>[];
    void them(Widget w) => nut.add(
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(width: double.infinity, child: w),
      ),
    );
    if (laTaiXe) {
      if (b.status == 'pending' || b.status == 'quoted') {
        them(
          FilledButton.icon(
            onPressed: tat ? null : () => _baoGia(b),
            icon: const Icon(Icons.request_quote_outlined),
            label: Text(b.status == 'pending' ? 'Báo giá' : 'Báo lại giá'),
          ),
        );
      }
      if (b.status == 'confirmed') {
        them(
          FilledButton.icon(
            onPressed: tat
                ? null
                : () => _lam('batDau', thongBao: 'Đã bắt đầu chuyến.'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu chuyển'),
          ),
        );
      }
      if (b.status == 'in_progress') {
        them(
          FilledButton.icon(
            onPressed: tat
                ? null
                : () => _lam('hoanThanh', thongBao: 'Đã hoàn thành chuyến.'),
            icon: const Icon(Icons.check),
            label: const Text('Hoàn thành'),
          ),
        );
      }
    } else if (b.status == 'quoted') {
      them(
        FilledButton.icon(
          onPressed: tat
              ? null
              : () => _lam(
                  'chapNhan',
                  thongBao: 'Đã chốt giá. Tài xế sẽ liên hệ bạn.',
                ),
          icon: const Icon(Icons.handshake_outlined),
          label: Text('Chấp nhận giá ${formatPrice(b.quotedPrice ?? 0)}'),
        ),
      );
    }
    if (!laTaiXe && b.status == 'done') {
      them(
        b.reviewed
            ? const Text('Bạn đã đánh giá chuyến này.')
            : FilledButton.icon(
                onPressed: tat ? null : _danhGia,
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Đánh giá tài xế'),
              ),
      );
    }
    if (['pending', 'quoted', 'confirmed'].contains(b.status)) {
      them(
        OutlinedButton(
          onPressed: tat ? null : () => _huy(laTaiXe: laTaiXe),
          child: Text(
            laTaiXe
                ? (b.status == 'confirmed' ? 'Hủy chuyến' : 'Từ chối')
                : 'Hủy yêu cầu',
          ),
        ),
      );
    }
    return nut;
  }
}

Future<int?> _hoiGia(BuildContext context, num? giaCu) {
  final ctrl = TextEditingController(text: giaCu?.round().toString() ?? '');
  String? loi;
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Báo giá trọn gói'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Giá',
            suffixText: 'đ',
            errorText: loi,
            helperText: 'Đã gồm bốc xếp, không phát sinh thêm.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thôi'),
          ),
          FilledButton(
            onPressed: () {
              final gia = int.tryParse(ctrl.text) ?? 0;
              if (gia < 1000) {
                setState(() => loi = 'Nhập giá từ 1.000đ');
                return;
              }
              Navigator.pop(context, gia);
            },
            child: const Text('Gửi báo giá'),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                SelectableText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
