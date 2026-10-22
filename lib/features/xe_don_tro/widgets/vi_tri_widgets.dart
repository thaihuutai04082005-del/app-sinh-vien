import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/location_map.dart';
import '../models/booking_xe.dart';
import '../services/vi_tri.dart';
import '../services/xe_dich_vu.dart';

/// Tài xế: tự gửi vị trí khi đơn đang chuyển, tối đa mỗi [khoangCach] một lần.
/// Dừng khi rời màn hình (bản web: phải giữ tab mở).
class ChiaSeViTri extends StatefulWidget {
  const ChiaSeViTri({
    required this.dv,
    required this.bookingId,
    this.khoangCach = const Duration(seconds: 15),
    super.key,
  });

  final XeDichVu dv;
  final String bookingId;
  final Duration khoangCach;

  @override
  State<ChiaSeViTri> createState() => _ChiaSeViTriState();
}

class _ChiaSeViTriState extends State<ChiaSeViTri> {
  StreamSubscription<ToaDo>? _sub;
  DateTime? _guiLuc;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _sub = widget.dv.viTri().listen(
      _gui,
      onError: (Object e) => setState(() => _loi = '$e'),
    );
  }

  Future<void> _gui(ToaDo p) async {
    final now = DateTime.now();
    if (_guiLuc != null && now.difference(_guiLuc!) < widget.khoangCach) {
      return;
    }
    _guiLuc = now;
    try {
      await widget.dv.xe.capNhatViTri(widget.bookingId, p.lat, p.lng);
      if (mounted) setState(() => _loi = null);
    } catch (e) {
      if (mounted) setState(() => _loi = '$e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          _loi == null ? Icons.my_location : Icons.location_disabled,
          color: _loi == null ? colors.primary : colors.error,
        ),
        title: Text(
          _loi == null
              ? 'Đang chia sẻ vị trí cho khách'
              : 'Chưa chia sẻ được vị trí',
        ),
        subtitle: Text(
          _loi ??
              (_guiLuc == null
                  ? 'Đang lấy vị trí... Giữ màn hình này mở trong lúc chuyển.'
                  : 'Gửi lúc ${formatNgayGio(_guiLuc!)}. '
                        'Giữ màn hình này mở trong lúc chuyển.'),
        ),
      ),
    );
  }
}

/// Sinh viên: bản đồ vị trí tài xế, cập nhật realtime khi đơn đang chuyển.
class BanDoTaiXe extends StatefulWidget {
  const BanDoTaiXe({required this.dv, required this.bookingId, super.key});

  final XeDichVu dv;
  final String bookingId;

  @override
  State<BanDoTaiXe> createState() => _BanDoTaiXeState();
}

class _BanDoTaiXeState extends State<BanDoTaiXe> {
  late final Stream<BookingXe> _don = widget.dv.xe.theoDoiBooking(
    widget.bookingId,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookingXe>(
      stream: _don,
      builder: (context, snap) {
        final b = snap.data;
        final p = b?.driverLastLocation;
        if (p == null) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.location_searching),
              title: Text('Tài xế chưa chia sẻ vị trí'),
              subtitle: Text('Vị trí hiện ở đây khi tài xế mở đơn trên máy.'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vị trí tài xế',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            // Đổi key theo tọa độ để bản đồ dời tâm tới vị trí mới.
            LocationMap(key: ValueKey(p), latitude: p.lat, longitude: p.lng),
            if (b!.driverLocationAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Cập nhật lúc ${formatNgayGio(b.driverLocationAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
