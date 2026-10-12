import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/don_mon.dart';
import '../models/quan_an_config.dart';
import 'quan_an_theme.dart';

/// Dòng thời gian của đơn: các mốc trong `lichSu` theo thứ tự, mốc cuối là trạng thái hiện tại
/// (nhãn tiếng Việt từ [trangThaiDonLabels]). Mốc không có nhãn (mã nội bộ) thì bỏ qua.
class DonTimeline extends StatelessWidget {
  const DonTimeline({required this.don, super.key});

  final DonMon don;

  List<MocLichSu> _cacMoc() {
    final ds = [
      for (final m in don.lichSu)
        if (trangThaiDonLabels.containsKey(m.trangThai)) m,
    ];
    // Bỏ mốc liền nhau trùng trạng thái (giữ mốc đầu).
    final gon = <MocLichSu>[];
    for (final m in ds) {
      if (gon.isNotEmpty && gon.last.trangThai == m.trangThai) continue;
      gon.add(m);
    }
    if (gon.isEmpty || gon.last.trangThai != don.status) {
      gon.add(
        MocLichSu(
          trangThai: don.status,
          luc: gon.isEmpty ? don.taoLuc : (don.capNhatLuc ?? don.ketThucLuc),
        ),
      );
    }
    return gon;
  }

  String _ghiChu(MocLichSu m) {
    final g = m.ghiChu.trim();
    if (g.isEmpty) return '';
    return lyDoHuyDonLabels[g] ?? g;
  }

  @override
  Widget build(BuildContext context) {
    final cacMoc = _cacMoc();
    return Column(
      children: [
        for (var i = 0; i < cacMoc.length; i++)
          _Dong(
            nhan:
                trangThaiDonLabels[cacMoc[i].trangThai] ?? cacMoc[i].trangThai,
            luc: cacMoc[i].luc,
            ghiChu: _ghiChu(cacMoc[i]),
            hienTai: i == cacMoc.length - 1,
            cuoi: i == cacMoc.length - 1,
          ),
      ],
    );
  }
}

class _Dong extends StatelessWidget {
  const _Dong({
    required this.nhan,
    required this.luc,
    required this.ghiChu,
    required this.hienTai,
    required this.cuoi,
  });

  final String nhan;
  final DateTime? luc;
  final String ghiChu;
  final bool hienTai;
  final bool cuoi;

  @override
  Widget build(BuildContext context) {
    final mau = hienTai ? QuanAnColors.primary : QuanAnColors.textDisabled;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: hienTai ? 16 : 12,
                  height: hienTai ? 16 : 12,
                  decoration: BoxDecoration(
                    color: hienTai ? QuanAnColors.primary : QuanAnColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: mau, width: 2),
                  ),
                ),
                if (!cuoi)
                  Expanded(
                    child: Container(width: 2, color: QuanAnColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: QuanAnSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: cuoi ? 0 : QuanAnSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nhan,
                    style: hienTai
                        ? QuanAnText.label.copyWith(color: QuanAnColors.primary)
                        : QuanAnText.body,
                  ),
                  if (luc != null)
                    Text(formatNgayGio(luc!), style: QuanAnText.bodySmall),
                  if (ghiChu.isNotEmpty)
                    Text(ghiChu, style: QuanAnText.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
