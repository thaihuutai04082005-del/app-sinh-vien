import 'package:flutter/material.dart';

import '../../auth/services/xac_thuc_service.dart';
import 'tro_states.dart';

/// Hiển thị stream đủ 3 trạng thái: đang tải (khung xương) · lỗi (Thử lại) · có dữ liệu (mục 2.19).
class TroStream<T> extends StatefulWidget {
  const TroStream({
    required this.stream,
    required this.builder,
    this.dangTai,
    this.thongBaoLoi = 'Không tải được dữ liệu',
    super.key,
  });

  final Stream<T> Function() stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? dangTai;
  final String thongBaoLoi;

  @override
  State<TroStream<T>> createState() => _TroStreamState<T>();
}

class _TroStreamState<T> extends State<TroStream<T>> {
  late Stream<T> _stream = widget.stream();

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    builder: (context, snap) {
      if (snap.hasError) {
        return TroErrorState(
          message: widget.thongBaoLoi,
          onRetry: () => setState(() {
            _stream = widget.stream();
          }),
        );
      }
      if (!snap.hasData) {
        return widget.dangTai ?? const TroSkeletonList(count: 2);
      }
      return widget.builder(context, snap.data as T);
    },
  );
}

/// Chạy một thao tác gọi hệ thống: hiện lỗi dễ hiểu bằng snackbar, trả về true nếu thành công.
Future<bool> chayThaoTac(
  BuildContext context,
  Future<void> Function() viec, {
  String? thanhCong,
}) async {
  final m = ScaffoldMessenger.of(context);
  try {
    await viec();
    if (thanhCong != null) {
      m.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(thanhCong)),
            ],
          ),
        ),
      );
    }
    return true;
  } on ApiException catch (e) {
    m.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    m.showSnackBar(
      const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')),
    );
  }
  return false;
}

/// Hộp xác nhận có nhắc rõ hậu quả (ví dụ "mất cọc").
Future<bool> xacNhan(
  BuildContext context, {
  required String tieuDe,
  required String noiDung,
  String dongY = 'Đồng ý',
  bool nguyHiem = false,
}) async {
  final kq = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tieuDe),
      content: Text(noiDung),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          style: nguyHiem
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(dongY),
        ),
      ],
    ),
  );
  return kq ?? false;
}
