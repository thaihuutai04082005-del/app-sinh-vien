import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import 'tro_theme.dart';

/// Ghim nhà trọ dạng viên thuốc hiện giá ("từ 1,5tr"); xám khi hết phòng, to hơn khi đang chọn (mục 2.19 "Bản đồ").
class TroMapMarker extends StatelessWidget {
  const TroMapMarker({
    required this.gia,
    required this.conPhong,
    this.dangChon = false,
    super.key,
  });

  final num? gia;
  final bool conPhong;
  final bool dangChon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: dangChon ? 12 : 8,
      vertical: dangChon ? 6 : 4,
    ),
    decoration: BoxDecoration(
      color: conPhong ? TroColors.primary : TroColors.markerGrey,
      borderRadius: BorderRadius.circular(TroRadius.pill),
      border: Border.all(color: TroColors.white, width: dangChon ? 3 : 1.5),
      boxShadow: TroTheme.softShadow,
    ),
    child: Text(
      gia == null ? 'Nhà trọ' : 'từ ${formatGiaGon(gia!)}',
      style: TextStyle(
        color: TroColors.white,
        fontWeight: FontWeight.w700,
        fontSize: dangChon ? 14 : 12,
      ),
    ),
  );
}

/// Cụm nhiều ghim gần nhau: vòng tròn màu chính có số ở giữa.
class TroMapCluster extends StatelessWidget {
  const TroMapCluster({required this.soLuong, super.key});

  final int soLuong;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: TroColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: TroColors.white, width: 2),
      boxShadow: TroTheme.softShadow,
    ),
    child: Text(
      '$soLuong',
      style: const TextStyle(
        color: TroColors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
