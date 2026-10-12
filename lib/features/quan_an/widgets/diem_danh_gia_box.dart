import 'package:flutter/material.dart';

import '../models/danh_gia.dart';
import '../models/quan_an.dart';
import 'quan_an_theme.dart';

String _d1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Khối điểm đánh giá của quán (mục 3.4 Bước 6): ⭐ điểm tổng thể ĐÃ XÁC MINH · số lượt ·
/// điểm 4 tiêu chí; điểm của các đánh giá chưa xác minh chỉ hiện phụ, màu nhạt.
class DiemDanhGiaBox extends StatelessWidget {
  const DiemDanhGiaBox({required this.soLieu, super.key});

  final SoLieuQuan soLieu;

  static const _bieuTuong = {
    'monAn': '🍜',
    'giaCa': '💰',
    'veSinh': '🧹',
    'phucVu': '🙋',
  };

  @override
  Widget build(BuildContext context) {
    final sl = soLieu;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      decoration: BoxDecoration(
        color: QuanAnColors.white,
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        border: Border.all(color: QuanAnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sl.coDiemXacMinh)
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '⭐ '),
                  TextSpan(
                    text: _d1(sl.diemTong!),
                    style: QuanAnText.display.copyWith(
                      color: QuanAnColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: '  Tổng thể · ${sl.soDanhGia} đánh giá xác minh',
                    style: QuanAnText.bodySmall,
                  ),
                ],
              ),
            )
          else
            const Text('Chưa có đánh giá xác minh', style: QuanAnText.h3),
          if (sl.diemTieuChi.isNotEmpty) ...[
            const SizedBox(height: QuanAnSpacing.md),
            Wrap(
              spacing: QuanAnSpacing.lg,
              runSpacing: QuanAnSpacing.sm,
              children: [
                for (final (ma, nhan) in tieuChiDanhGia)
                  if (sl.diemTieuChi[ma] != null)
                    Semantics(
                      label: '$nhan ${_d1(sl.diemTieuChi[ma]!)}',
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${_bieuTuong[ma] ?? ''} $nhan '),
                            TextSpan(
                              text: _d1(sl.diemTieuChi[ma]!),
                              style: QuanAnText.label.copyWith(
                                color: QuanAnColors.primary,
                              ),
                            ),
                          ],
                        ),
                        style: QuanAnText.body,
                      ),
                    ),
              ],
            ),
          ],
          if (sl.diemChuaXm != null && sl.soDanhGiaChuaXm > 0) ...[
            const SizedBox(height: QuanAnSpacing.md),
            Text(
              'Chưa xác minh: ★ ${_d1(sl.diemChuaXm!)} '
              '(${sl.soDanhGiaChuaXm} đánh giá, không tính vào điểm chính)',
              style: QuanAnText.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
