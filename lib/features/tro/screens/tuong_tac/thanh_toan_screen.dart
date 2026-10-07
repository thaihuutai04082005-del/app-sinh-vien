import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/dat_coc.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/dem_nguoc_coc_banner.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../sinh_vien/dat_coc_detail_screen.dart';
import '../tro_routes.dart';

/// TRO-SV-16 Thanh toán: chuyển sang cổng (bản GIẢ LẬP thay PayPal / MoMo sandbox) và màn hình kết quả riêng.
/// Hệ thống chỉ ghi nhận "đã thanh toán" khi cổng báo về có chữ ký hợp lệ; bấm 2 lần không trừ tiền 2 lần.
class ThanhToanScreen extends StatefulWidget {
  const ThanhToanScreen({required this.dv, required this.datCocId, super.key});

  final TroDichVu dv;
  final String datCocId;

  @override
  State<ThanhToanScreen> createState() => _ThanhToanScreenState();
}

class _ThanhToanScreenState extends State<ThanhToanScreen> {
  bool _dangXuLy = false;

  Future<void> _tra(String ketQua) async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    await chayThaoTac(
      context,
      () => widget.dv.datCoc.thanhToan(widget.datCocId, ketQua),
    );
    if (mounted) setState(() => _dangXuLy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán tiền cọc')),
      body: TroStream<DatCoc?>(
        stream: () => widget.dv.datCoc.datCoc(widget.datCocId),
        builder: (context, d) {
          if (d == null) {
            return const TroEmptyState(title: 'Không tìm thấy khoản cọc');
          }
          if (d.status != 'pending_payment') {
            return _KetQua(dv: widget.dv, d: d);
          }
          return ListView(
            padding: const EdgeInsets.all(TroSpacing.screen),
            children: [
              if (d.hanThanhToan != null)
                DemNguocCocBanner(
                  nhan: 'Phòng đang khóa cho bạn, thanh toán trước',
                  moc: d.hanThanhToan!,
                  canhBao: true,
                  onHet: () =>
                      widget.dv.datCoc.xuLyHan(d.id).catchError((_) {}),
                ),
              const SizedBox(height: TroSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(TroSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: TroColors.primary,
                          ),
                          SizedBox(width: TroSpacing.sm),
                          Text('Cổng thanh toán giả lập', style: TroText.h2),
                        ],
                      ),
                      const SizedBox(height: TroSpacing.xs),
                      const Text(
                        'Bản thử nghiệm: chạy đủ luồng thanh toán nhưng không có tiền thật (thay cho PayPal / MoMo sandbox).',
                        style: TroText.bodySmall,
                      ),
                      const Divider(height: TroSpacing.xxl),
                      Text(
                        '${d.tenPhong} · ${d.tenNhaTro}',
                        style: TroText.body,
                      ),
                      const SizedBox(height: TroSpacing.sm),
                      Text(
                        formatPrice(d.soTien),
                        style: TroText.display.copyWith(
                          color: TroColors.primary,
                        ),
                      ),
                      Text(
                        'Nhận phòng: ${formatNgayGio(d.t)}',
                        style: TroText.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TroSpacing.xl),
              FilledButton(
                onPressed: _dangXuLy ? null : () => _tra('thanh_cong'),
                child: _dangXuLy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TroColors.white,
                        ),
                      )
                    : const Text('Xác nhận thanh toán'),
              ),
              const SizedBox(height: TroSpacing.sm),
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

/// Màn hình kết quả riêng cho thao tác về tiền (mục 2.19 "Thành công").
class _KetQua extends StatelessWidget {
  const _KetQua({required this.dv, required this.d});

  final TroDichVu dv;
  final DatCoc d;

  @override
  Widget build(BuildContext context) {
    final (icon, mau, tieuDe, noiDung) = switch (d.status) {
      'held' => (
        Icons.check_circle,
        TroColors.success,
        'Đặt cọc thành công',
        'Phòng đã được giữ cho bạn. Thời điểm nhận phòng: ${formatNgayGio(d.t)}.'
            '${d.coQuyenHuyMienPhi && d.hanHuyMienPhi != null ? ' Hủy miễn phí tới ${formatNgayGio(d.hanHuyMienPhi!)}.' : ''}',
      ),
      'refunded' => (
        Icons.replay_circle_filled,
        TroColors.warning,
        'Đã hoàn tiền',
        'Tiền về sau hạn thanh toán nên không được nhận. Bạn được hoàn 100%.',
      ),
      _ => (
        Icons.cancel,
        TroColors.danger,
        'Thanh toán không thành công',
        'Khoản cọc đã hết hạn hoặc thanh toán thất bại, phòng không được giữ. Bạn chưa bị trừ tiền.',
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TroSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: mau, size: 72),
            const SizedBox(height: TroSpacing.lg),
            Text(tieuDe, style: TroText.h1, textAlign: TextAlign.center),
            const SizedBox(height: TroSpacing.sm),
            Text(noiDung, style: TroText.body, textAlign: TextAlign.center),
            const SizedBox(height: TroSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                troRoute((_) => DatCocDetailScreen(dv: dv, datCocId: d.id)),
              ),
              child: const Text('Xem khoản cọc'),
            ),
          ],
        ),
      ),
    );
  }
}
