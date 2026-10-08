import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/khuyen_mai.dart';
import 'quan_an_theme.dart';

/// Một khuyến mãi đang chạy trên trang quán (mục 3.4 Bước 2, khối 2).
/// Chỉ hiển thị: hệ thống mới là nơi tính giảm giá khi đặt món.
class KhuyenMaiBanner extends StatelessWidget {
  const KhuyenMaiBanner({required this.khuyenMai, super.key});

  final KhuyenMai khuyenMai;

  @override
  Widget build(BuildContext context) {
    final km = khuyenMai;
    final han = km.ketThuc == null ? null : 'Đến hết ${formatNgay(km.ketThuc!)}';
    return Semantics(
      label: 'Khuyến mãi ${km.tieuDe}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(QuanAnSpacing.md),
        decoration: BoxDecoration(
          color: QuanAnColors.primaryLight,
          borderRadius: BorderRadius.circular(QuanAnRadius.button),
          border: Border.all(color: QuanAnColors.primarySoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏷', style: TextStyle(fontSize: 20)),
            const SizedBox(width: QuanAnSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    km.tieuDe.isEmpty ? km.loaiLabel : km.tieuDe,
                    style: QuanAnText.h3.copyWith(
                      color: QuanAnColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.xs),
                  Text(km.moTaNgan, style: QuanAnText.body),
                  if (han != null) ...[
                    const SizedBox(height: QuanAnSpacing.xs),
                    Text(han, style: QuanAnText.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
