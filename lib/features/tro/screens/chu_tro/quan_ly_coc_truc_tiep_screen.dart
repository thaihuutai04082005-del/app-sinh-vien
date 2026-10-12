import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/coc_truc_tiep.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';

/// TRO-CT-07 Quản lý — Cọc trực tiếp: "Đã cho thuê" · "Người cọc không thuê nữa" · sửa ngày nhận phòng dự kiến.
/// App chỉ ghi nhận, không giữ / hoàn tiền (mục 2.5d).
class QuanLyCocTrucTiepScreen extends StatelessWidget {
  const QuanLyCocTrucTiepScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cọc trực tiếp')),
    body: TroStream<List<CocTrucTiep>>(
      stream: () => dv.cocTrucTiep.cuaChuTro(dv.uid),
      builder: (context, ds) => ds.isEmpty
          ? const TroEmptyState(
              icon: Icons.handshake_outlined,
              title: 'Chưa có cọc trực tiếp nào',
            )
          : ListView(
              padding: const EdgeInsets.all(TroSpacing.screen),
              children: [
                const Text(
                  'Nhớ cập nhật ngay khi có kết quả: app không tự biết giao dịch tiền mặt ngoài đời.',
                  style: TroText.bodySmall,
                ),
                const SizedBox(height: TroSpacing.sm),
                for (final c in ds)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(TroSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phòng ${c.tenPhong}', style: TroText.h3),
                          Text(
                            'Nhận phòng dự kiến: ${formatNgay(c.ngayNhanDuKien)} · ${CocTrucTiep.ketQuaLabels[c.ketQua]}',
                            style: TroText.bodySmall,
                          ),
                          if (c.sdtNguoiCoc != null)
                            Text(
                              'SĐT người cọc: ${c.sdtNguoiCoc}',
                              style: TroText.bodySmall,
                            ),
                          if (c.dangCho)
                            Wrap(
                              spacing: TroSpacing.sm,
                              children: [
                                FilledButton(
                                  onPressed: () => chayThaoTac(
                                    context,
                                    () => dv.cocTrucTiep.capNhat(
                                      c.id,
                                      'da_cho_thue',
                                    ),
                                    thanhCong: 'Đã cho thuê',
                                  ),
                                  child: const Text('Đã cho thuê'),
                                ),
                                OutlinedButton(
                                  onPressed: () => chayThaoTac(
                                    context,
                                    () => dv.cocTrucTiep.capNhat(
                                      c.id,
                                      'khong_thue',
                                    ),
                                    thanhCong: 'Phòng đã mở lại',
                                  ),
                                  child: const Text('Người cọc không thuê nữa'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 120),
                                      ),
                                      initialDate: c.ngayNhanDuKien,
                                    );
                                    if (d != null && context.mounted) {
                                      await chayThaoTac(
                                        context,
                                        () => dv.cocTrucTiep.capNhat(
                                          c.id,
                                          'sua_ngay',
                                          ngayNhanDuKien: d,
                                        ),
                                        thanhCong: 'Đã sửa ngày',
                                      );
                                    }
                                  },
                                  child: const Text('Sửa ngày dự kiến'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
