import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/mon_an.dart';
import 'quan_an_theme.dart';

/// Một nhóm tùy chọn của món (Cỡ, Topping...): bắt buộc hay không, chọn 1 hay nhiều,
/// giá cộng thêm của từng lựa chọn (mục 3.2 "Menu", 3.4 Bước 5a).
class TuyChonMonGroup extends StatelessWidget {
  const TuyChonMonGroup({
    required this.nhom,
    required this.dangChon,
    required this.onChanged,
    this.loi,
    super.key,
  });

  final NhomTuyChon nhom;

  /// Tên các lựa chọn đang chọn trong nhóm này.
  final List<String> dangChon;
  final ValueChanged<List<String>> onChanged;

  /// Dòng lỗi bằng chữ (ví dụ chưa chọn phần bắt buộc).
  final String? loi;

  void _bam(String ten) {
    final da = dangChon.contains(ten);
    if (!nhom.chonNhieu) {
      // Chọn 1: bấm lại món đang chọn thì bỏ chọn (chỉ khi không bắt buộc).
      if (da) {
        if (!nhom.batBuoc) onChanged(const []);
      } else {
        onChanged([ten]);
      }
      return;
    }
    if (da) {
      onChanged([
        for (final x in dangChon)
          if (x != ten) x,
      ]);
    } else if (dangChon.length < nhom.toiDa) {
      onChanged([...dangChon, ten]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gioiHan = nhom.chonNhieu
        ? 'Chọn tối đa ${nhom.toiDa}'
        : (nhom.batBuoc ? 'Chọn 1' : 'Chọn 1 (tùy chọn)');
    final day = nhom.chonNhieu && dangChon.length >= nhom.toiDa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(nhom.ten, style: QuanAnText.h3)),
            if (nhom.batBuoc)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: QuanAnSpacing.sm,
                  vertical: QuanAnSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: QuanAnColors.warningSoft,
                  borderRadius: BorderRadius.circular(QuanAnRadius.pill),
                ),
                child: const Text(
                  'Bắt buộc',
                  style: TextStyle(
                    color: QuanAnColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        Text(gioiHan, style: QuanAnText.bodySmall),
        const SizedBox(height: QuanAnSpacing.xs),
        for (final l in nhom.lua)
          Builder(
            builder: (context) {
              final chon = dangChon.contains(l.ten);
              final khoa = nhom.chonNhieu && day && !chon;
              return Semantics(
                button: true,
                selected: chon,
                enabled: !khoa,
                label:
                    '${l.ten}${l.giaThem > 0 ? ', cộng ${formatPrice(l.giaThem)}' : ''}',
                child: InkWell(
                  onTap: khoa ? null : () => _bam(l.ten),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Icon(
                          nhom.chonNhieu
                              ? (chon
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded)
                              : (chon
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded),
                          color: chon
                              ? QuanAnColors.primary
                              : (khoa
                                    ? QuanAnColors.textDisabled
                                    : QuanAnColors.textSecondary),
                        ),
                        const SizedBox(width: QuanAnSpacing.md),
                        Expanded(
                          child: Text(
                            l.ten,
                            style: khoa
                                ? QuanAnText.body.copyWith(
                                    color: QuanAnColors.textDisabled,
                                  )
                                : QuanAnText.body,
                          ),
                        ),
                        if (l.giaThem > 0)
                          Text(
                            '+${formatPrice(l.giaThem)}',
                            style: QuanAnText.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (loi != null)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
            child: Text(
              loi!,
              style: const TextStyle(color: QuanAnColors.danger),
            ),
          ),
      ],
    );
  }
}
