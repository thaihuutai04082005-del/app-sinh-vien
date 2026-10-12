import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/thanh_toan.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_theme.dart';

/// TRO-CT-08 Ví chủ trọ (chỉ để hiển thị): tiền cọc app đang giữ và đã nhận. Rút tiền làm sau (mục 2.24).
class ViScreen extends StatelessWidget {
  const ViScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ví chủ trọ')),
    body: TroStream<ViChuTro>(
      stream: () => dv.datCoc.vi(dv.uid),
      builder: (context, v) => ListView(
        padding: const EdgeInsets.all(TroSpacing.screen),
        children: [
          Card(
            child: ListTile(
              title: const Text('Tiền cọc app đang giữ'),
              subtitle: const Text('Chuyển cho bạn khi giao dịch hoàn tất'),
              trailing: Text(formatPrice(v.dangGiu), style: TroText.price),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Đã nhận'),
              trailing: Text(formatPrice(v.daNhan), style: TroText.price),
            ),
          ),
          const SizedBox(height: TroSpacing.md),
          const Text(
            'Bản thử nghiệm: tiền đi qua cổng thanh toán giả lập, không có tiền thật. Chức năng rút tiền sẽ làm sau.',
            style: TroText.bodySmall,
          ),
        ],
      ),
    ),
  );
}
