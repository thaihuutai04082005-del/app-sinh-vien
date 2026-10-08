import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import 'quan_an_theme.dart';

/// Dòng đếm ngược tới một mốc của đơn / lượt đặt bàn (hạn thanh toán, quán nhận,
/// 24 giờ "Chờ xác nhận nhận món"...). Cập nhật mỗi giây; hết giờ thì hiện "Đã tới hạn"
/// chứ không vỡ, và gọi [onHet] một lần để màn hình nhờ hệ thống xử lý hạn.
class DonDemNguocTile extends StatefulWidget {
  const DonDemNguocTile({
    required this.nhan,
    required this.moc,
    this.canhBao = false,
    this.onHet,
    super.key,
  });

  final String nhan;
  final DateTime moc;
  final bool canhBao;
  final VoidCallback? onHet;

  @override
  State<DonDemNguocTile> createState() => _DonDemNguocTileState();
}

class _DonDemNguocTileState extends State<DonDemNguocTile> {
  Timer? _timer;
  bool _daBao = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _baoNeuHet();
    });
  }

  @override
  void didUpdateWidget(covariant DonDemNguocTile old) {
    super.didUpdateWidget(old);
    // Mốc mới (ví dụ đơn sang bước khác): cho phép báo hết giờ lại.
    if (old.moc != widget.moc) _daBao = false;
  }

  void _baoNeuHet() {
    if (!_daBao && !DateTime.now().isBefore(widget.moc)) {
      _daBao = true;
      widget.onHet?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final con = widget.moc.difference(DateTime.now());
    final mau = widget.canhBao ? QuanAnColors.warning : QuanAnColors.primary;
    return Container(
      padding: const EdgeInsets.all(QuanAnSpacing.md),
      decoration: BoxDecoration(
        color: widget.canhBao
            ? QuanAnColors.warningSoft
            : QuanAnColors.primaryLight,
        borderRadius: BorderRadius.circular(QuanAnRadius.input),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: mau),
          const SizedBox(width: QuanAnSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nhan, style: QuanAnText.label.copyWith(color: mau)),
                Text(formatNgayGio(widget.moc), style: QuanAnText.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: QuanAnSpacing.sm),
          Flexible(
            child: Text(
              formatConLai(con),
              style: QuanAnText.h3.copyWith(color: mau),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dựng lại con theo chu kỳ để nút hiện / mờ đúng lúc khi tới mốc thời gian
/// (ví dụ nút "Chưa nhận được món" bấm được từ T_lấy) mà không cần chờ dữ liệu đổi.
class DongHoTick extends StatefulWidget {
  const DongHoTick({
    required this.builder,
    this.chuKy = const Duration(seconds: 5),
    super.key,
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration chuKy;

  @override
  State<DongHoTick> createState() => _DongHoTickState();
}

class _DongHoTickState extends State<DongHoTick> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.chuKy, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, DateTime.now());
}
