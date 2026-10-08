import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/tro_config.dart';
import '../models/tro_filter.dart';
import 'noi_quy_block.dart';
import 'tro_status_badge.dart';
import 'tro_theme.dart';

/// Thẻ nhà trọ ở sảnh (mục 2.4 Bước 1, 2.19 "Thẻ").
class NhaTroCard extends StatelessWidget {
  const NhaTroCard({
    required this.ketQua,
    required this.onTap,
    this.dangLoc = false,
    this.nutLuu,
    super.key,
  });

  final KetQuaNhaTro ketQua;
  final VoidCallback onTap;
  final bool dangLoc;
  final Widget? nutLuu;

  @override
  Widget build(BuildContext context) {
    final n = ketQua.nhaTro;
    final sl = n.soLieu;
    final gia = sl.giaMin == null
        ? ''
        : n.laNguyenCan || sl.giaMax == null || sl.giaMax == sl.giaMin
        ? formatPrice(sl.giaMin!)
        : '${formatGiaGon(sl.giaMin!)} – ${formatGiaGon(sl.giaMax!)}';
    final phu = [
      if (sl.diem != null) '★ ${sl.diem!.toStringAsFixed(1)}',
      loaiHinhLabels[n.loaiHinh] ?? '',
      if (ketQua.khoangCach != null)
        'Cách bạn ${formatKhoangCach(ketQua.khoangCach!)}',
      if (n.phuong.isNotEmpty) n.phuong,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Semantics(
      button: true,
      label: 'Nhà trọ ${n.ten}',
      child: Container(
        decoration: BoxDecoration(
          color: TroColors.white,
          borderRadius: BorderRadius.circular(TroRadius.card),
          border: Border.all(color: TroColors.border),
          boxShadow: TroTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (n.anhBia.isEmpty)
                      const ColoredBox(
                        color: TroColors.primaryLight,
                        child: Icon(
                          Icons.home_work_outlined,
                          size: 48,
                          color: TroColors.primary,
                        ),
                      )
                    else
                      NetworkPhoto(n.anhBia),
                    if (nutLuu != null)
                      Positioned(
                        right: TroSpacing.sm,
                        top: TroSpacing.sm,
                        child: nutLuu!,
                      ),
                    if (n.noiQuy != null)
                      Positioned(
                        left: TroSpacing.sm,
                        bottom: TroSpacing.sm,
                        child: NoiQuyIcons(noiQuy: n.noiQuy!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(TroSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.ten,
                            style: TroText.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (n.daXacThucNha)
                          const Tooltip(
                            message: 'Đã xác thực nhà',
                            child: Icon(
                              Icons.verified_rounded,
                              color: TroColors.primary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: TroSpacing.xs),
                    Text(
                      phu,
                      style: TroText.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TroSpacing.sm),
                    Row(
                      children: [
                        if (gia.isNotEmpty) Text(gia, style: TroText.price),
                        const Spacer(),
                        if (ketQua.hetPhong || !n.conPhong)
                          TroStatusBadge(
                            kind: TroBadgeKind.full,
                            label: n.laNguyenCan ? 'Đã cho thuê' : 'Hết phòng',
                          )
                        else
                          TroStatusBadge(
                            kind: TroBadgeKind.available,
                            label: n.laNguyenCan
                                ? 'Còn trống'
                                : 'Còn ${n.soLieu.soPhongTrong} phòng',
                          ),
                      ],
                    ),
                    if (dangLoc && !ketQua.hetPhong && !n.laNguyenCan) ...[
                      const SizedBox(height: TroSpacing.xs),
                      Text(
                        '${ketQua.phongPhuHop.length} phòng phù hợp',
                        style: TroText.bodySmall.copyWith(
                          color: TroColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
