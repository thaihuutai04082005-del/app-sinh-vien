import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import 'quan_an_theme.dart';

/// Nhãn khoảng giá cho ghim: "25–40k"; một mức giá thì "25k"; chưa có giá thì null.
String? nhanKhoangGia(num? tu, num? den) {
  if (tu == null && den == null) return null;
  final a = tu ?? den!;
  final b = den ?? tu!;
  final x = formatGiaGon(a);
  final y = formatGiaGon(b);
  if (x == y) return x;
  // "25k–40k" → "25–40k" khi cùng đơn vị.
  if (x.endsWith('k') && y.endsWith('k')) {
    return '${x.substring(0, x.length - 1)}–$y';
  }
  if (x.endsWith('tr') && y.endsWith('tr')) {
    return '${x.substring(0, x.length - 2)}–$y';
  }
  return '$x–$y';
}

/// Ghim quán dạng viên thuốc hiện khoảng giá ("25–40k"); xanh khi đang mở, xám `#64748B` khi đã đóng,
/// to hơn + viền trắng dày khi đang chọn (mục 3.19 "Bản đồ").
class QuanAnMapMarker extends StatelessWidget {
  const QuanAnMapMarker({
    required this.nhanGia,
    required this.dangMo,
    this.dangChon = false,
    super.key,
  });

  /// Dựng từ khoảng giá (thường là giá P25 – P75 của quán).
  QuanAnMapMarker.theoGia({
    required num? giaTu,
    required num? giaDen,
    required this.dangMo,
    this.dangChon = false,
    super.key,
  }) : nhanGia = nhanKhoangGia(giaTu, giaDen);

  /// Chữ trên ghim; null thì hiện "Quán".
  final String? nhanGia;
  final bool dangMo;
  final bool dangChon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${nhanGia ?? 'Quán'}, ${dangMo ? 'đang mở cửa' : 'đã đóng cửa'}',
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: dangChon ? 12 : 8,
        vertical: dangChon ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: dangMo ? QuanAnColors.primary : QuanAnColors.markerGrey,
        borderRadius: BorderRadius.circular(QuanAnRadius.pill),
        border: Border.all(
          color: QuanAnColors.white,
          width: dangChon ? 3 : 1.5,
        ),
        boxShadow: QuanAnTheme.softShadow,
      ),
      child: Text(
        nhanGia ?? 'Quán',
        style: TextStyle(
          color: QuanAnColors.white,
          fontWeight: FontWeight.w700,
          fontSize: dangChon ? 14 : 12,
        ),
      ),
    ),
  );
}

/// Cụm nhiều ghim gần nhau: vòng tròn màu chính có số ở giữa.
class QuanAnMapCluster extends StatelessWidget {
  const QuanAnMapCluster({required this.soLuong, super.key});

  final int soLuong;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: QuanAnColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: QuanAnColors.white, width: 2),
      boxShadow: QuanAnTheme.softShadow,
    ),
    child: Text(
      '$soLuong',
      style: const TextStyle(
        color: QuanAnColors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Điểm gốc (vị trí của sinh viên / điểm đã chọn): chấm `accent` có quầng sáng.
/// Vòng tròn bán kính viền `primary` nét đứt, nền mờ 8% do màn bản đồ vẽ riêng (cần bán kính theo mét).
class QuanAnDiemGoc extends StatelessWidget {
  const QuanAnDiemGoc({this.kichThuoc = 20, super.key});

  final double kichThuoc;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Điểm gốc của bạn',
    child: Container(
      width: kichThuoc * 2,
      height: kichThuoc * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QuanAnColors.originDot.withValues(alpha: 0.25),
      ),
      child: Container(
        width: kichThuoc * 0.7,
        height: kichThuoc * 0.7,
        decoration: BoxDecoration(
          color: QuanAnColors.originDot,
          shape: BoxShape.circle,
          border: Border.all(color: QuanAnColors.white, width: 2),
        ),
      ),
    ),
  );
}
