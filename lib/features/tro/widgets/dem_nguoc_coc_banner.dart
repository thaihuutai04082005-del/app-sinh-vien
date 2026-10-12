import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import 'tro_theme.dart';

/// Banner đếm ngược tới một mốc (thời điểm nhận phòng, hạn trả lời, 12 giờ phản đối, 48 giờ...).
class DemNguocCocBanner extends StatefulWidget {
  const DemNguocCocBanner({
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
  State<DemNguocCocBanner> createState() => _DemNguocCocBannerState();
}

class _DemNguocCocBannerState extends State<DemNguocCocBanner> {
  Timer? _timer;
  bool _daBao = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_daBao && !DateTime.now().isBefore(widget.moc)) {
        _daBao = true;
        widget.onHet?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final con = widget.moc.difference(DateTime.now());
    final mau = widget.canhBao ? TroColors.warning : TroColors.primary;
    return Container(
      padding: const EdgeInsets.all(TroSpacing.md),
      decoration: BoxDecoration(
        color: widget.canhBao ? TroColors.warningSoft : TroColors.primaryLight,
        borderRadius: BorderRadius.circular(TroRadius.input),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: mau),
          const SizedBox(width: TroSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nhan, style: TroText.label.copyWith(color: mau)),
                Text(formatNgayGio(widget.moc), style: TroText.bodySmall),
              ],
            ),
          ),
          Text(formatConLai(con), style: TroText.h3.copyWith(color: mau)),
        ],
      ),
    );
  }
}
