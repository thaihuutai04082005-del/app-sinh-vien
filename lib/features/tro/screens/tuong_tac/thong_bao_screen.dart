import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/thong_bao.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tro_shell.dart';

/// TRO-SV-14 Thông báo của module (chuông trong Tìm trọ): bấm để mở đúng trang, đánh dấu đã đọc.
class ThongBaoScreen extends StatelessWidget {
  const ThongBaoScreen({required this.dv, this.onVeTrangChu, super.key});

  final TroDichVu dv;
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
              TroDieuHuong.mo(context, (_) => CaiDatThongBaoScreen(dv: dv)),
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: TroStream<List<ThongBao>>(
      stream: () => dv.thongBao.cuaToi(dv.uid),
      builder: (context, ds) => ds.isEmpty
          ? const TroEmptyState(
              icon: Icons.notifications_none,
              title: 'Chưa có thông báo',
            )
          : ListView.separated(
              itemCount: ds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = ds[i];
                return ListTile(
                  tileColor: t.daDoc ? null : TroColors.primaryLight,
                  leading: Icon(_icon(t.nhom), color: TroColors.primary),
                  title: Text(
                    t.tieuDe,
                    style: t.daDoc ? TroText.body : TroText.h3,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.noiDung),
                      if (t.taoLuc != null)
                        Text(
                          formatNgayGio(t.taoLuc!),
                          style: TroText.bodySmall,
                        ),
                    ],
                  ),
                  onTap: () {
                    if (!t.daDoc) dv.thongBao.daDoc(t.id).catchError((_) {});
                    TroDieuHuong.theoThongBao(context, dv, t.moTrang);
                  },
                );
              },
            ),
    ),
  );

  static IconData _icon(String nhom) => switch (nhom) {
    'giao_dich' => Icons.payments_outlined,
    'khieu_nai' => Icons.report_problem_outlined,
    'khang_nghi' => Icons.gavel_outlined,
    'tin_nhan' => Icons.chat_bubble_outline,
    'nha_tro_da_luu' => Icons.favorite_border,
    'danh_gia' => Icons.rate_review_outlined,
    _ => Icons.notifications_none,
  };
}

/// Cài đặt thông báo của module: tắt được từng nhóm, TRỪ tiền cọc, nhận phòng, yêu cầu thay đổi,
/// khiếu nại, kháng nghị (mục 2.11).
class CaiDatThongBaoScreen extends StatelessWidget {
  const CaiDatThongBaoScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt thông báo')),
    body: TroStream<Map<String, bool>>(
      stream: () => dv.thongBao.caiDat(dv.uid),
      builder: (context, cd) => ListView(
        children: [
          for (final (nhom, ten, khoa) in nhomThongBao)
            SwitchListTile(
              title: Text(ten),
              subtitle: khoa
                  ? const Text(
                      'Luôn bật (liên quan tiền cọc / quyền lợi của bạn)',
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
