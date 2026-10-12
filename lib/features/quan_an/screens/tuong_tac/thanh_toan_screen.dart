import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/thanh_toan.dart';
import '../../services/quan_an_api.dart' show ApiException;
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// QA-SV-07b Thanh toán đơn món: chuyển sang cổng (bản GIẢ LẬP thay PayPal / MoMo sandbox) và màn hình kết quả riêng.
/// Hệ thống chỉ ghi nhận "đã thanh toán" khi cổng báo về có chữ ký hợp lệ; bấm 2 lần không trừ tiền 2 lần.
class ThanhToanScreen extends StatefulWidget {
  const ThanhToanScreen({required this.dv, required this.donId, super.key});

  final QuanAnDichVu dv;
  final String donId;

  @override
  State<ThanhToanScreen> createState() => _ThanhToanScreenState();
}

class _ThanhToanScreenState extends State<ThanhToanScreen> {
  late Future<PhienThanhToan?> _phien = widget.dv.donMon.xemPhien(widget.donId);
  bool _dangXuLy = false;

  void _taiLai() => setState(() {
    _phien = widget.dv.donMon.xemPhien(widget.donId);
  });

  Future<void> _tra(String ketQua) async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    await chayThaoTac(
      context,
      () => widget.dv.donMon.thanhToan(widget.donId, ketQua),
    );
    if (!mounted) return;
    setState(() {
      _dangXuLy = false;
      _phien = widget.dv.donMon.xemPhien(widget.donId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán đơn món')),
      body: FutureBuilder<PhienThanhToan?>(
        future: _phien,
        builder: (context, snap) {
          if (snap.hasError) {
            return QuanAnErrorState(
              message: snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'Không tải được phiên thanh toán',
              onRetry: _taiLai,
            );
          }
          if (snap.connectionState != ConnectionState.done) {
            return const QuanAnSkeletonList(count: 1);
          }
          final p = snap.data;
          if (p == null) {
            return const QuanAnEmptyState(title: 'Không tìm thấy đơn món');
          }
          if (!p.choThanhToan) {
            return _KetQua(dv: widget.dv, p: p, donId: widget.donId);
          }
          return ListView(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            children: [
              if (p.hanThanhToan != null)
                Container(
                  padding: const EdgeInsets.all(QuanAnSpacing.md),
                  decoration: BoxDecoration(
                    color: QuanAnColors.warningSoft,
                    borderRadius: BorderRadius.circular(QuanAnRadius.button),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: QuanAnColors.warning,
                      ),
                      const SizedBox(width: QuanAnSpacing.sm),
                      Expanded(
                        child: Text(
                          'Thanh toán trước ${formatNgayGio(p.hanThanhToan!)} để giữ đơn',
                          style: QuanAnText.body.copyWith(
                            color: QuanAnColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: QuanAnSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(QuanAnSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: QuanAnColors.primary,
                          ),
                          SizedBox(width: QuanAnSpacing.sm),
                          Expanded(
                            child: Text(
                              'Cổng thanh toán giả lập',
                              style: QuanAnText.h2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: QuanAnSpacing.xs),
                      const Text(
                        'Bản thử nghiệm: chạy đủ luồng thanh toán nhưng không có tiền thật (thay cho PayPal / MoMo sandbox).',
                        style: QuanAnText.bodySmall,
                      ),
                      const Divider(height: QuanAnSpacing.xxl),
                      if (p.tenQuan.isNotEmpty)
                        Text(p.tenQuan, style: QuanAnText.body),
                      const SizedBox(height: QuanAnSpacing.sm),
                      Text(
                        formatPrice(p.soTien),
                        style: QuanAnText.display.copyWith(
                          color: QuanAnColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: QuanAnSpacing.xl),
              FilledButton(
                onPressed: _dangXuLy ? null : () => _tra('thanh_cong'),
                child: _dangXuLy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: QuanAnColors.white,
                        ),
                      )
                    : const Text('Xác nhận thanh toán'),
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              TextButton(
                onPressed: _dangXuLy ? null : () => _tra('that_bai'),
                child: const Text('Mô phỏng thanh toán thất bại'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Màn hình kết quả riêng cho thao tác về tiền (mục 3.19 "Thành công").
class _KetQua extends StatelessWidget {
  const _KetQua({required this.dv, required this.p, required this.donId});

  final QuanAnDichVu dv;
  final PhienThanhToan p;
  final String donId;

  @override
  Widget build(BuildContext context) {
    final (icon, mau, tieuDe, noiDung) = switch (p.trangThaiDon) {
      'expired' => (
        Icons.cancel,
        QuanAnColors.danger,
        'Thanh toán không thành công',
        'Đơn đã hết hạn thanh toán hoặc thanh toán thất bại, quán chưa nhận đơn. Bạn chưa bị trừ tiền.',
      ),
      'refunded' => (
        Icons.replay_circle_filled,
        QuanAnColors.warning,
        'Đã hoàn tiền',
        'Tiền về sau hạn thanh toán nên không được nhận. Bạn được hoàn 100%.',
      ),
      _ => (
        Icons.check_circle,
        QuanAnColors.success,
        'Thanh toán thành công',
        'Đơn đã gửi tới quán${p.tenQuan.isEmpty ? '' : ' ${p.tenQuan}'}, đang chờ quán xác nhận. App giữ tiền cho tới khi bạn nhận được món.',
      ),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QuanAnSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: mau, size: 72),
            const SizedBox(height: QuanAnSpacing.lg),
            Text(tieuDe, style: QuanAnText.h1, textAlign: TextAlign.center),
            const SizedBox(height: QuanAnSpacing.sm),
            Text(noiDung, style: QuanAnText.body, textAlign: TextAlign.center),
            const SizedBox(height: QuanAnSpacing.xl),
            FilledButton(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                QuanAnDieuHuong.don(nav.context, dv, donId);
              },
              child: const Text('Xem đơn'),
            ),
          ],
        ),
      ),
    );
  }
}
