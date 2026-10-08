import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../models/quan_an_filter.dart';
import '../services/quan_an_dich_vu.dart';
import 'quan_an_async.dart';
import 'quan_an_theme.dart';
import 'trang_thai_mo_cua_badge.dart';

String _d1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Thẻ quán ở sảnh và bản đồ (mục 3.4 Bước 1, 3.19 "Thẻ"): ảnh bìa 16:9, ❤️, các nhãn
/// 🏷 🛵 🔥 🆕, tên + huy hiệu, ★ điểm xác minh, loại món, khoảng giá, khoảng cách, trạng thái mở cửa.
class QuanAnCard extends StatefulWidget {
  const QuanAnCard({
    required this.ketQua,
    required this.nutLuu,
    this.onTap,
    super.key,
  });

  final KetQuaQuan ketQua;

  /// Nút ❤️ ở góc phải ảnh (thường là [NutLuuQuan]).
  final Widget nutLuu;
  final VoidCallback? onTap;

  @override
  State<QuanAnCard> createState() => _QuanAnCardState();
}

class _QuanAnCardState extends State<QuanAnCard> {
  bool _giu = false;

  @override
  Widget build(BuildContext context) {
    final k = widget.ketQua;
    final q = k.quan;
    final sl = q.soLieu;
    final anh = q.anhBia.isNotEmpty
        ? q.anhBia
        : (q.anhMatTien.isNotEmpty ? q.anhMatTien.first : '');
    final nhan = q.nhanHuyHieu;
    final phu = [if (q.loaiMon.isNotEmpty) q.loaiMonLabel].join(' · ');
    final viTri = [
      if (k.khoangCach != null) 'Cách bạn ${formatKhoangCach(k.khoangCach!)}',
      if (q.phuong.isNotEmpty) q.phuong,
    ].join(' · ');
    return AnimatedScale(
      scale: _giu ? 0.98 : 1,
      duration: const Duration(milliseconds: 150),
      child: Semantics(
        button: true,
        label: 'Quán ${q.ten}',
        child: Container(
          decoration: BoxDecoration(
            color: QuanAnColors.white,
            borderRadius: BorderRadius.circular(QuanAnRadius.card),
            border: Border.all(color: QuanAnColors.border),
            boxShadow: QuanAnTheme.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _giu = v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (anh.isEmpty)
                        const ColoredBox(
                          color: QuanAnColors.primaryLight,
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 48,
                            color: QuanAnColors.primary,
                          ),
                        )
                      else
                        NetworkPhoto(anh),
                      Positioned(
                        right: QuanAnSpacing.sm,
                        top: QuanAnSpacing.sm,
                        child: widget.nutLuu,
                      ),
                      if (nhan.isNotEmpty)
                        Positioned(
                          left: QuanAnSpacing.sm,
                          right: QuanAnSpacing.sm + 40,
                          bottom: QuanAnSpacing.sm,
                          child: Wrap(
                            spacing: QuanAnSpacing.xs,
                            runSpacing: QuanAnSpacing.xs,
                            children: [for (final n in nhan) _NhanNho(n)],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(QuanAnSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              q.ten,
                              style: QuanAnText.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: QuanAnSpacing.xs),
                          Tooltip(
                            message: q.daXacThucLabel,
                            child: const Icon(
                              Icons.verified_rounded,
                              color: QuanAnColors.primary,
                              size: 20,
                              semanticLabel: 'Đã xác thực',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: QuanAnSpacing.xs),
                      Text(
                        sl.coDiemXacMinh
                            ? '★ ${_d1(sl.diemTong!)} (${sl.soDanhGia})'
                            : 'Chưa có đánh giá xác minh',
                        style: sl.coDiemXacMinh
                            ? QuanAnText.label.copyWith(
                                color: QuanAnColors.primary,
                              )
                            : QuanAnText.bodySmall,
                      ),
                      if (phu.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
                          child: Text(
                            phu,
                            style: QuanAnText.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (viTri.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
                          child: Text(
                            viTri,
                            style: QuanAnText.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: QuanAnSpacing.sm),
                      Wrap(
                        spacing: QuanAnSpacing.md,
                        runSpacing: QuanAnSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (q.giaHienThi != '—')
                            Text(q.giaHienThi, style: QuanAnText.price),
                          TrangThaiMoCuaBadge(tinhTrang: k.moCua),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NhanNho extends StatelessWidget {
  const _NhanNho(this.chu);

  final String chu;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: QuanAnSpacing.sm,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: QuanAnColors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(QuanAnRadius.pill),
    ),
    child: Text(
      chu,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: QuanAnColors.textPrimary,
      ),
    ),
  );
}

/// Nút ❤️ lưu quán (mục 3.4 "Những việc khác"). Chủ quán không lưu được quán của mình;
/// khách chưa đăng nhập bấm thì được nhắc đăng nhập (mục 3.13).
class NutLuuQuan extends StatelessWidget {
  const NutLuuQuan({
    required this.dv,
    required this.quanId,
    required this.chuQuanId,
    super.key,
  });

  final QuanAnDichVu dv;
  final String quanId;
  final String chuQuanId;

  @override
  Widget build(BuildContext context) {
    if (dv.uid.isNotEmpty && chuQuanId == dv.uid) {
      return const SizedBox.shrink();
    }
    Widget nut(bool luu) => IconButton(
      tooltip: luu ? 'Bỏ lưu' : 'Lưu quán',
      style: IconButton.styleFrom(
        backgroundColor: QuanAnColors.white,
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
      ),
      onPressed: () {
        if (dv.uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để lưu quán.')),
          );
          return;
        }
        chayThaoTac(
          context,
          () => dv.quan.luu(dv.uid, quanId, luu: !luu),
          thanhCong: luu
              ? 'Đã bỏ lưu'
              : 'Đã lưu quán — bạn sẽ được báo khi có khuyến mãi mới',
        );
      },
      icon: Icon(
        luu ? Icons.favorite : Icons.favorite_border,
        color: luu ? QuanAnColors.danger : QuanAnColors.primary,
      ),
    );
    if (dv.uid.isEmpty) return nut(false);
    return StreamBuilder<bool>(
      stream: dv.quan.daLuu(dv.uid, quanId),
      builder: (context, s) => nut(s.data ?? false),
    );
  }
}
