import 'package:flutter/material.dart';

import '../models/gio_mo_cua.dart';
import 'quan_an_status_badge.dart';

/// Huy hiệu trạng thái mở cửa của quán (mục 3.2 "Giờ mở cửa"): 🟢 Đang mở · 🟠 Sắp đóng ·
/// 🔴 Đã đóng cửa · ⏸ Tạm nghỉ. Mặc định hiện câu đầy đủ ("Đang mở · Đóng lúc 21:00");
/// [chiNhan] = true chỉ hiện tên trạng thái ("Đang mở cửa").
class TrangThaiMoCuaBadge extends StatelessWidget {
  const TrangThaiMoCuaBadge({
    required this.tinhTrang,
    this.chiNhan = false,
    super.key,
  });

  final TinhTrangMoCua tinhTrang;
  final bool chiNhan;

  @override
  Widget build(BuildContext context) {
    final tt = tinhTrang.trangThai;
    return QuanAnStatusBadge(
      kind: switch (tt) {
        TrangThaiMoCua.mo => QuanAnBadgeKind.moCua,
        TrangThaiMoCua.sapDong => QuanAnBadgeKind.sapDong,
        TrangThaiMoCua.dong => QuanAnBadgeKind.dongCua,
        TrangThaiMoCua.tamNghi => QuanAnBadgeKind.tamNghi,
      },
      label: chiNhan ? tt.label : tinhTrang.thongDiep,
    );
  }
}
