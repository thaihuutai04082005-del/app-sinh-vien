import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/quan_an.dart';
import '../screens/quan_an_routes.dart';
import '../screens/sinh_vien/gio_hang_screen.dart';
import '../services/quan_an_dich_vu.dart';
import 'quan_an_theme.dart';

/// Thanh nổi dưới cùng của trang quán: "🛒 Xem giỏ (2 món · 70k)". Chỉ hiện khi giỏ thuộc
/// đúng [quan] và không trống; nút chính mở giỏ hàng (mục 3.4 Bước 5a).
class GioHangBar extends StatelessWidget {
  const GioHangBar({required this.dv, required this.quan, super.key});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: dv.gioHang,
    builder: (context, _) {
      final gio = dv.gioHang.gio;
      if (gio.laRong || gio.quanId != quan.id) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              margin: const EdgeInsets.all(QuanAnSpacing.screen),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(QuanAnRadius.button),
                boxShadow: QuanAnTheme.softShadow,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      QuanAnDieuHuong.mo(context, (_) => GioHangScreen(dv: dv)),
                  child: Text(
                    '🛒 Xem giỏ (${gio.soMon} món · ${formatGiaGon(gio.tamTinh)})',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
