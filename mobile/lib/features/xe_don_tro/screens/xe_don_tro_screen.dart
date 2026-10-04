import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../models/booking_xe.dart';
import '../services/booking_xe_service.dart';
import 'booking_xe_detail_screen.dart';
import 'dat_xe_screen.dart';

/// Danh sách yêu cầu chuyển trọ chờ tài xế báo giá + nút đặt xe (mục 3.3).
class XeDonTroScreen extends StatefulWidget {
  const XeDonTroScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final BookingXeService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<XeDonTroScreen> createState() => _XeDonTroScreenState();
}

class _XeDonTroScreenState extends State<XeDonTroScreen> {
  late Future<List<BookingXe>> _bookings = widget.service.getDanhSachYeuCau();

  Future<void> _reload() async {
    final future = widget.service.getDanhSachYeuCau();
    setState(() {
      _bookings = future;
    });
    await future.catchError((_) => <BookingXe>[]);
  }

  void _openDetail(BookingXe booking) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingXeDetailScreen(booking: booking),
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<BookingXe>(
      MaterialPageRoute(
        builder: (_) => DatXeScreen(
          service: widget.service,
          storage: widget.storage,
          pickImages: widget.pickImages,
        ),
      ),
    );
    if (created == null || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu, chờ tài xế báo giá.')),
    );
    _openDetail(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xe dọn trọ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Đặt xe'),
      ),
      body: AsyncListView<BookingXe>(
        future: _bookings,
        onRefresh: _reload,
        emptyIcon: Icons.local_shipping_outlined,
        emptyText:
            'Chưa có yêu cầu chuyển trọ nào. Bấm "Đặt xe" để gửi yêu cầu.',
        itemBuilder: (context, booking) =>
            _BookingCard(booking: booking, onTap: () => _openDetail(booking)),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final BookingXe booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: booking.itemPhotos.isEmpty
                      ? const SizedBox.shrink()
                      : NetworkPhoto(booking.itemPhotos.first),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.fromAddress} → ${booking.toAddress}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatBookingTime(booking.scheduledAt),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BookingStatusChip(status: booking.status),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.videos.isEmpty
                              ? '${booking.itemPhotos.length} ảnh'
                              : '${booking.itemPhotos.length} ảnh · 1 video',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
