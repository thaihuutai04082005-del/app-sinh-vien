import 'package:flutter/material.dart';

import '../models/tro_config.dart';
import 'tro_theme.dart';

/// Chính sách cọc (mục 2.5a) + điều khoản nhận phòng 48 giờ; phải tick đồng ý mới thanh toán được.
class ChinhSachCocBox extends StatelessWidget {
  const ChinhSachCocBox({
    required this.dongYChinhSach,
    required this.dongYDieuKhoan,
    required this.onChinhSach,
    required this.onDieuKhoan,
    super.key,
  });

  final bool dongYChinhSach;
  final bool dongYDieuKhoan;
  final ValueChanged<bool> onChinhSach;
  final ValueChanged<bool> onDieuKhoan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Chính sách cọc', style: TroText.h2),
      const SizedBox(height: TroSpacing.sm),
      for (final dong in chinhSachCoc)
        Padding(
          padding: const EdgeInsets.only(bottom: TroSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TroText.body),
              Expanded(child: Text(dong, style: TroText.body)),
            ],
          ),
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: dongYChinhSach,
        onChanged: (v) => onChinhSach(v ?? false),
        title: const Text('Tôi đã đọc và đồng ý chính sách cọc'),
      ),
      const SizedBox(height: TroSpacing.sm),
      const Text('Điều khoản nhận phòng', style: TroText.h2),
      const SizedBox(height: TroSpacing.sm),
      Container(
        padding: const EdgeInsets.all(TroSpacing.md),
        decoration: BoxDecoration(
          color: TroColors.primaryLight,
          borderRadius: BorderRadius.circular(TroRadius.input),
        ),
        child: const Text(dieuKhoanNhanPhong, style: TroText.body),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: dongYDieuKhoan,
        onChanged: (v) => onDieuKhoan(v ?? false),
        title: const Text('Tôi đồng ý điều khoản nhận phòng 48 giờ'),
      ),
    ],
  );
}
