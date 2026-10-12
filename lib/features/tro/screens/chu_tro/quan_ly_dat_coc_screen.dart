import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/dat_coc.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';

/// TRO-CT-06 Quản lý — Tiền cọc: đang giữ (đếm ngược), đang khiếu nại, đã nhận, đã hoàn.
/// Bấm vào một khoản để Hủy cọc / Đồng ý–Từ chối yêu cầu thay đổi / báo "không đến" / trả lời khiếu nại.
class QuanLyDatCocScreen extends StatelessWidget {
  const QuanLyDatCocScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Tiền cọc'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Đang giữ'),
            Tab(text: 'Khiếu nại'),
            Tab(text: 'Đã nhận'),
            Tab(text: 'Đã hoàn / khác'),
          ],
        ),
      ),
      body: TroStream<List<DatCoc>>(
        stream: () => dv.datCoc.cuaChuTro(dv.uid),
        builder: (context, ds) {
          List<DatCoc> loc(bool Function(DatCoc) f) => ds.where(f).toList();
          return TabBarView(
            children: [
              _DanhSach(
                dv: dv,
                ds: loc(
                  (d) => d.status == 'held' || d.status == 'pending_payment',
                ),
              ),
              _DanhSach(dv: dv, ds: loc((d) => d.status == 'disputed')),
              _DanhSach(
                dv: dv,
                ds: loc(
                  (d) => d.status == 'released' || d.status == 'forfeited',
                ),
              ),
              _DanhSach(
                dv: dv,
                ds: loc(
                  (d) => [
                    'refunded',
                    'cancelled_grace',
                    'expired',
                  ].contains(d.status),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _DanhSach extends StatelessWidget {
  const _DanhSach({required this.dv, required this.ds});

  final TroDichVu dv;
  final List<DatCoc> ds;

  @override
  Widget build(BuildContext context) => ds.isEmpty
      ? const TroEmptyState(
          icon: Icons.payments_outlined,
          title: 'Không có khoản cọc nào',
        )
      : ListView(
          padding: const EdgeInsets.all(TroSpacing.screen),
          children: [
            for (final d in ds)
              Card(
                child: ListTile(
                  title: Text('${d.tenPhong} · ${formatPrice(d.soTien)}'),
                  subtitle: Text(
                    [
                      'Nhận phòng ${formatNgayGio(d.t)}',
                      if (d.doi?.dangCho ?? false)
                        'Có yêu cầu thay đổi — trả lời trước ${formatNgayGio(d.doi!.hanTraLoi)}',
                      if (d.khieuNai?.coKhan ?? false) 'Cờ khẩn',
                    ].join('\n'),
                  ),
                  trailing: TroStatusBadge(
                    kind: d.dangDienRa
                        ? TroBadgeKind.reserved
                        : TroBadgeKind.rented,
                    label: d.trangThaiLabel,
                  ),
                  onTap: () => TroDieuHuong.datCoc(context, dv, d.id),
                ),
              ),
          ],
        );
}
