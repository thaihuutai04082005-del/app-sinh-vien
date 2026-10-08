import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/coc_truc_tiep.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import 'danh_gia_tro_screen.dart';

/// TRO-SV-12 Cọc trực tiếp: người cọc (số điện thoại chủ trọ đã nhập) bấm "Tôi đã thuê phòng này"
/// trong 7 ngày sau khi chủ bấm "Đã cho thuê" để được viết đánh giá có nhãn.
class XacNhanDaThueScreen extends StatelessWidget {
  const XacNhanDaThueScreen({required this.dv, required this.id, super.key});

  final TroDichVu dv;
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cọc trực tiếp')),
    body: TroStream<CocTrucTiep?>(
      stream: () => dv.cocTrucTiep.theoId(id),
      builder: (context, c) {
        if (c == null) return const TroEmptyState(title: 'Không tìm thấy');
        final now = DateTime.now();
        return ListView(
          padding: const EdgeInsets.all(TroSpacing.screen),
          children: [
            const TroWarningBox(
              message: 'Khoản cọc trực tiếp ngoài app KHÔNG được app giữ tiền hay bảo vệ. Lần sau hãy đặt cọc trên app.',
            ),
            const SizedBox(height: TroSpacing.lg),
            Text('Phòng ${c.tenPhong}', style: TroText.h2),
            Text(
              'Ngày nhận phòng dự kiến: ${formatNgay(c.ngayNhanDuKien)}',
              style: TroText.body,
            ),
            Text(
              'Trạng thái: ${CocTrucTiep.ketQuaLabels[c.ketQua]}',
              style: TroText.body,
            ),
            const SizedBox(height: TroSpacing.xl),
            if (c.coXacNhanDaThue(now))
              FilledButton(
                onPressed: () => chayThaoTac(
                  context,
                  () => dv.cocTrucTiep.toiDaThue(id),
                  thanhCong: 'Đã xác nhận, bạn có thể viết đánh giá',
                ),
                child: Text(
                  'Tôi đã thuê phòng này (hạn ${formatNgayGio(c.hanXacNhanDaThue!)})',
                ),
              )
            else if (c.nguoiCocXacNhanLuc != null)
              FilledButton.icon(
                onPressed: () => TroDieuHuong.mo(
                  context,
                  (_) => DanhGiaTroScreen(
                    dv: dv,
                    loaiNguon: 'coc_truc_tiep',
                    idNguon: id,
                    tenPhong: c.tenPhong,
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết / cập nhật đánh giá'),
              )
            else if (c.ketQua == 'da_cho_thue')
              const Text('Đã quá 7 ngày để xác nhận.', style: TroText.bodySmall)
            else
              const Text(
                'Chờ chủ trọ cập nhật "Đã cho thuê".',
                style: TroText.bodySmall,
              ),
          ],
        );
      },
    ),
  );
}
