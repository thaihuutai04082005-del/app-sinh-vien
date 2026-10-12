import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/thong_bao.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../quan_an_shell.dart';

/// QA-SV-15 Thông báo của module (chuông trong Quán ăn): bấm để mở đúng trang, đánh dấu đã đọc.
class ThongBaoScreen extends StatelessWidget {
  const ThongBaoScreen({required this.dv, this.onVeTrangChu, super.key});

  final QuanAnDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: NutVeTrangChu(onPressed: onVeTrangChu),
      title: const Text('Thông báo'),
      actions: [
        IconButton(
          tooltip: 'Cài đặt thông báo',
          onPressed: () =>
              QuanAnDieuHuong.mo(context, (_) => CaiDatThongBaoScreen(dv: dv)),
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: QuanAnStream<List<ThongBao>>(
      stream: () => dv.thongBao.cuaToi(dv.uid),
      builder: (context, ds) => ds.isEmpty
          ? const QuanAnEmptyState(
              icon: Icons.notifications_none,
              title: 'Chưa có thông báo',
            )
          : ListView.separated(
              itemCount: ds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = ds[i];
                return ListTile(
                  minVerticalPadding: QuanAnSpacing.md,
                  tileColor: t.daDoc ? null : QuanAnColors.primaryLight,
                  leading: Icon(_icon(t.nhom), color: QuanAnColors.primary),
                  title: Text(
                    t.tieuDe,
                    style: t.daDoc ? QuanAnText.body : QuanAnText.h3,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.noiDung),
                      if (t.taoLuc != null)
                        Text(
                          formatNgayGio(t.taoLuc!),
                          style: QuanAnText.bodySmall,
                        ),
                    ],
                  ),
                  trailing: t.daDoc
                      ? null
                      : const Icon(
                          Icons.circle,
                          size: 10,
                          color: QuanAnColors.primary,
                          semanticLabel: 'Chưa đọc',
                        ),
                  onTap: () {
                    if (!t.daDoc) dv.thongBao.daDoc(t.id).catchError((_) {});
                    QuanAnDieuHuong.theoThongBao(context, dv, t.moTrang);
                  },
                );
              },
            ),
    ),
  );

  static IconData _icon(String nhom) => switch (nhom) {
    'giao_dich' => Icons.payments_outlined,
    'don_hang' => Icons.receipt_long_outlined,
    'dat_ban' => Icons.table_restaurant_outlined,
    'khieu_nai' => Icons.report_problem_outlined,
    'khang_nghi' => Icons.gavel_outlined,
    'tin_nhan' => Icons.chat_bubble_outline,
    'quan_da_luu' => Icons.favorite_border,
    'danh_gia' || 'nhac_danh_gia' => Icons.rate_review_outlined,
    _ => Icons.notifications_none,
  };
}

/// Cài đặt thông báo của module: tắt được từng nhóm, TRỪ tiền, đơn hàng, đặt bàn,
/// khiếu nại, kháng nghị (mục 3.11).
class CaiDatThongBaoScreen extends StatelessWidget {
  const CaiDatThongBaoScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt thông báo')),
    body: QuanAnStream<Map<String, bool>>(
      stream: () => dv.thongBao.caiDat(dv.uid),
      builder: (context, cd) => ListView(
        children: [
          for (final (nhom, ten, khoa) in nhomThongBao)
            SwitchListTile(
              title: Text(ten),
              subtitle: khoa
                  ? const Text(
                      'Luôn bật (liên quan tiền, đơn hàng / quyền lợi của bạn)',
                    )
                  : null,
              value: khoa || (cd[nhom] ?? true),
              onChanged: khoa
                  ? null
                  : (v) => chayThaoTac(
                      context,
                      () => dv.thongBao.doiCaiDat(dv.uid, nhom, v),
                    ),
            ),
        ],
      ),
    ),
  );
}
