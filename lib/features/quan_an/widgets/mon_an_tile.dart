import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/mon_an.dart';
import 'quan_an_theme.dart';

/// Một món trong menu (mục 3.4 Bước 2, khối 3): ảnh 1:1, tên, mô tả, giá, nút ＋.
/// Món hết hiện mờ kèm chữ "Hết món"; nút ＋ chỉ hiện khi [onThem] khác null
/// (quán nhận đặt món) và bấm không được khi [choThem] = false.
class MonAnTile extends StatelessWidget {
  const MonAnTile({
    required this.mon,
    this.onTap,
    this.onThem,
    this.choThem = true,
    this.soTrongGio = 0,
    super.key,
  });

  final MonAn mon;
  final VoidCallback? onTap;

  /// Bấm nút ＋ (thường mở bảng chọn món). Null = không hiện nút.
  final VoidCallback? onThem;

  /// Có cho bấm ＋ không (quán đang đóng / tạm ngưng thì false).
  final bool choThem;

  /// Số phần của món này đang có trong giỏ (hiện chấm số trên nút ＋).
  final int soTrongGio;

  @override
  Widget build(BuildContext context) {
    final het = !mon.conHang;
    final them = onThem != null && !het && choThem;
    final gia = mon.coTuyChon && mon.gia <= 0
        ? 'Tùy chọn'
        : formatPrice(mon.gia);
    return Semantics(
      label: '${mon.ten}, $gia${het ? ', hết món' : ''}',
      child: Opacity(
        opacity: het ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: QuanAnColors.white,
            borderRadius: BorderRadius.circular(QuanAnRadius.card),
            border: Border.all(color: QuanAnColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(QuanAnSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(QuanAnRadius.button),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: mon.anh.isEmpty
                          ? const ColoredBox(
                              color: QuanAnColors.primaryLight,
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: QuanAnColors.primary,
                              ),
                            )
                          : NetworkPhoto(mon.anh),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mon.ten,
                          style: QuanAnText.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (mon.moTa.isNotEmpty) ...[
                          const SizedBox(height: QuanAnSpacing.xs),
                          Text(
                            mon.moTa,
                            style: QuanAnText.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: QuanAnSpacing.xs),
                        Wrap(
                          spacing: QuanAnSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(gia, style: QuanAnText.price),
                            if (het)
                              const Text(
                                'Hết món',
                                style: TextStyle(
                                  color: QuanAnColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onThem != null)
                    Badge(
                      isLabelVisible: soTrongGio > 0,
                      label: Text('$soTrongGio'),
                      backgroundColor: QuanAnColors.danger,
                      child: IconButton.filledTonal(
                        tooltip: het ? 'Món đã hết' : 'Thêm ${mon.ten}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: them ? onThem : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
