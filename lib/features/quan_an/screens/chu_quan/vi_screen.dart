import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/don_mon.dart';
import '../../models/thanh_toan.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'chi_tiet_don_chu_quan_screen.dart';

/// QA-CQ-11 Ví chủ quán (chỉ để hiển thị): tiền app đang giữ, đã nhận, và các đơn
/// trả trên app liên quan. Rút tiền làm sau. Đơn tiền mặt không có tiền nào qua app.
class ViScreen extends StatelessWidget {
  const ViScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  /// Trạng thái tiền của đơn trả trên app, suy từ trạng thái đơn (bảng 3.5i).
  static (String, QuanAnBadgeKind) trangThaiTien(DonMon d) =>
      switch (d.status) {
        'completed' => ('Đã chuyển cho bạn', QuanAnBadgeKind.moCua),
        'refunded' ||
        'cancelled_student' ||
        'rejected' ||
        'expired_accept' ||
        'cancelled_restaurant' => (
          'Đã hoàn cho khách',
          QuanAnBadgeKind.dongCua,
        ),
        'partially_refunded' => ('Hoàn một phần', QuanAnBadgeKind.chung),
        _ => ('App đang giữ', QuanAnBadgeKind.canhBao),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ví chủ quán')),
    body: QuanAnStream<ViChuQuan>(
      stream: () => dv.donMon.vi(dv.uid),
      thongBaoLoi: 'Không tải được ví',
      builder: (context, v) => SingleChildScrollView(
        padding: const EdgeInsets.all(QuanAnSpacing.screen),
        child: TrangRong(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final hai = c.maxWidth >= 520;
                  final giu = _O(
                    tieuDe: 'Tiền app đang giữ',
                    phu: 'Chuyển cho bạn khi đơn hoàn tất',
                    gia: formatPrice(v.dangGiu),
                  );
                  final nhan = _O(
                    tieuDe: 'Đã nhận',
                    phu: 'Tiền đơn app đã chuyển cho bạn',
                    gia: formatPrice(v.daNhan),
                    nhan: true,
                  );
                  return hai
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: giu),
                            const SizedBox(width: QuanAnSpacing.md),
                            Expanded(child: nhan),
                          ],
                        )
                      : Column(
                          children: [
                            giu,
                            const SizedBox(height: QuanAnSpacing.md),
                            nhan,
                          ],
                        );
                },
              ),
              const SizedBox(height: QuanAnSpacing.md),
              const HopThongBao(
                noiDung:
                    'Bản thử nghiệm: tiền đi qua cổng thanh toán giả lập, không '
                    'có tiền thật. Chức năng rút tiền sẽ làm sau. Đơn tiền mặt '
                    'quán thu trực tiếp khi giao, không qua ví này.',
              ),
              const SizedBox(height: QuanAnSpacing.xl),
              const Text('Đơn trả trên app', style: QuanAnText.h2),
              const SizedBox(height: QuanAnSpacing.sm),
              QuanAnStream<List<DonMon>>(
                stream: () => dv.donMon.cuaChuQuan(dv.uid),
                thongBaoLoi: 'Không tải được danh sách đơn',
                builder: (context, tatCa) {
                  final ds = [
                    for (final d in tatCa)
                      if (d.traApp &&
                          d.status != 'pending_payment' &&
                          d.status != 'expired')
                        d,
                  ];
                  if (ds.isEmpty) {
                    return const QuanAnEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Chưa có đơn trả trên app',
                      message: 'Đơn khách trả bằng app sẽ hiện ở đây.',
                    );
                  }
                  return Column(
                    children: [
                      for (final d in ds) ...[
                        _DongDon(dv: dv, don: d),
                        const SizedBox(height: QuanAnSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _O extends StatelessWidget {
  const _O({
    required this.tieuDe,
    required this.phu,
    required this.gia,
    this.nhan = false,
  });

  final String tieuDe;
  final String phu;
  final String gia;
  final bool nhan;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe, style: QuanAnText.bodySmall),
          const SizedBox(height: QuanAnSpacing.xs),
          Text(
            gia,
            style: QuanAnText.display.copyWith(
              color: nhan ? QuanAnColors.success : QuanAnColors.primary,
            ),
          ),
          const SizedBox(height: QuanAnSpacing.xs),
          Text(phu, style: QuanAnText.bodySmall),
        ],
      ),
    ),
  );
}

class _DongDon extends StatelessWidget {
  const _DongDon({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final (nhan, kind) = ViScreen.trangThaiTien(don);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        onTap: () => QuanAnDieuHuong.mo(
          context,
          (_) => ChiTietDonChuQuanScreen(dv: dv, donId: don.id),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn ${maNgan(don.id)} · ${formatPrice(don.tong)}',
                        style: QuanAnText.label,
                      ),
                      Text(
                        [
                          don.trangThaiLabel,
                          if (don.taoLuc != null) formatNgayGio(don.taoLuc!),
                        ].join(' · '),
                        style: QuanAnText.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: QuanAnSpacing.sm),
                Flexible(
                  child: QuanAnStatusBadge(kind: kind, label: nhan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
