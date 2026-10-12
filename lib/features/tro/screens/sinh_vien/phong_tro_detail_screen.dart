import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../../../shared/widgets/location_map.dart';
import '../../../../shared/widgets/video_player_view.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/gia_dien_nuoc_table.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import 'dat_coc_screen.dart';
import 'tro_sanh_screen.dart';

/// TRO-SV-06 Chi tiết phòng: nút theo trạng thái, mỗi trang chỉ 1 nút chính (mục 2.4 Bước 2).
class PhongTroDetailScreen extends StatelessWidget {
  const PhongTroDetailScreen({
    required this.dv,
    required this.phongId,
    super.key,
  });

  final TroDichVu dv;
  final String phongId;

  @override
  Widget build(BuildContext context) {
    return TroStream<PhongTro?>(
      stream: () => dv.nhaTro.phong(phongId),
      builder: (context, p) {
        if (p == null || p.daXoa) {
          return Scaffold(
            appBar: AppBar(),
            body: const TroEmptyState(
              title: 'Phòng không tồn tại hoặc đã bị ẩn',
            ),
          );
        }
        final n = p.nhaTro;
        return Scaffold(
          appBar: AppBar(
            title: Text('Phòng ${p.ten}'),
            actions: [
              if (p.chuTroId != dv.uid)
                IconButton(
                  tooltip: 'Báo cáo',
                  onPressed: () =>
                      moBaoCao(context, dv, loai: 'phong', id: p.id),
                  icon: const Icon(Icons.flag_outlined),
                ),
            ],
          ),
          bottomNavigationBar: PhongActionBar(dv: dv, phong: p),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(TroSpacing.screen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.anh.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TroRadius.card),
                        child: ImageGallery(urls: p.anh, aspectRatio: 1),
                      ),
                    for (final v in p.video) ...[
                      const SizedBox(height: TroSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TroRadius.card),
                        child: VideoPlayerView(url: v, maxHeight: 360),
                      ),
                    ],
                    const SizedBox(height: TroSpacing.lg),
                    Text(
                      [
                        p.ten,
                        if (p.khu.isNotEmpty) p.khu,
                        if (p.tang != null) 'Tầng ${p.tang}',
                      ].join(' · '),
                      style: TroText.h1,
                    ),
                    if (n != null)
                      InkWell(
                        onTap: () =>
                            TroDieuHuong.nhaTro(context, dv, p.nhaTroId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: TroSpacing.xs,
                          ),
                          child: Text(
                            '${n.ten} · ${n.diaChi}',
                            style: TroText.bodySmall.copyWith(
                              color: TroColors.primary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: TroSpacing.xs),
                    Text(
                      [
                        if (p.coGac != null) p.coGac! ? 'Có gác' : 'Không gác',
                        p.moTaDienTich,
                        if (p.soPhongNgu != null) '${p.soPhongNgu} phòng ngủ',
                        if (p.soWc != null) '${p.soWc} WC',
                        if (p.coBep == true) 'Có bếp',
                      ].join(' · '),
                      style: TroText.body,
                    ),
                    const SizedBox(height: TroSpacing.md),
                    if (p.tienIch.isNotEmpty)
                      Wrap(
                        spacing: TroSpacing.sm,
                        runSpacing: TroSpacing.sm,
                        children: [
                          for (final t in p.tienIch)
                            Chip(label: Text(tienIchPhongLabels[t] ?? t)),
                        ],
                      ),
                    const SizedBox(height: TroSpacing.lg),
                    GiaDienNuocTable(phong: p),
                    const SizedBox(height: TroSpacing.lg),
                    if (p.ngayVaoO != null)
                      Text(
                        'Ngày có thể vào ở: ${formatNgay(p.ngayVaoO!)}',
                        style: TroText.body,
                      ),
                    if (p.moTa.isNotEmpty) ...[
                      const SizedBox(height: TroSpacing.md),
                      const Text('Mô tả phòng', style: TroText.h2),
                      const SizedBox(height: TroSpacing.sm),
                      Text(p.moTa, style: TroText.body),
                    ],
                    const SizedBox(height: TroSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TroSpacing.md),
                      decoration: BoxDecoration(
                        color: TroColors.warningSoft,
                        borderRadius: BorderRadius.circular(TroRadius.input),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: TroColors.warning),
                          SizedBox(width: TroSpacing.sm),
                          Expanded(
                            child: Text(nhacDiXemPhong, style: TroText.body),
                          ),
                        ],
                      ),
                    ),
                    if (n?.viTri != null) ...[
                      const SizedBox(height: TroSpacing.lg),
                      LocationMap(
                        latitude: n!.viTri!.latitude,
                        longitude: n.viTri!.longitude,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thanh hành động dưới cùng: giá bên trái + nút chính bên phải; nút phụ Nhắn tin / Gọi / Chỉ đường.
class PhongActionBar extends StatelessWidget {
  const PhongActionBar({required this.dv, required this.phong, super.key});

  final TroDichVu dv;
  final PhongTro phong;

  Future<void> _goi(BuildContext context) async {
    final sdt = await dv.nhaTro
        .laySdtChuTro(phong.nhaTroId)
        .catchError((_) => null);
    if (sdt == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chủ trọ chưa có số điện thoại.')),
        );
      }
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: sdt));
  }

  @override
  Widget build(BuildContext context) {
    final p = phong;
    final laCuaToi = p.chuTroId == dv.uid;
    final dangKhoa = p.dangKhoaThanhToan();
    final viTri = p.nhaTro?.viTri;
    final phu = <Widget>[
      if (!laCuaToi)
        OutlinedButton.icon(
          onPressed: () =>
              TroDieuHuong.chat(context, dv, p.chuTroId, phongId: p.id),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Nhắn tin'),
        ),
      if (!laCuaToi && p.conTrong)
        OutlinedButton.icon(
          onPressed: () => _goi(context),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Gọi'),
        ),
      if (viTri != null && p.conTrong && !dangKhoa)
        OutlinedButton.icon(
          onPressed: () => launchUrl(
            directionsUri(viTri.latitude, viTri.longitude),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Chỉ đường'),
        ),
      if (!p.conTrong && !laCuaToi)
        NutLuuNhaTro(dv: dv, nhaTroId: p.nhaTroId, chuTroId: p.chuTroId),
    ];
    Widget chinh;
    if (laCuaToi) {
      chinh = const Text('Đây là phòng của bạn', style: TroText.label);
    } else if (p.trangThai == 'reserved') {
      chinh = const TroStatusBadge(
        kind: TroBadgeKind.reserved,
        label: 'Đã có người cọc',
      );
    } else if (p.trangThai == 'rented') {
      chinh = const TroStatusBadge(
        kind: TroBadgeKind.rented,
        label: 'Đã cho thuê',
      );
    } else if (!p.conTrong) {
      chinh = Text(
        trangThaiPhongLabels[p.trangThai] ?? '',
        style: TroText.label,
      );
    } else {
      chinh = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: dangKhoa
                ? null
                : () => TroDieuHuong.mo(
                    context,
                    (_) => DatCocScreen(dv: dv, phong: p),
                  ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Đặt cọc giữ phòng'),
          ),
          if (dangKhoa)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Đang có người thanh toán, thử lại sau ít phút',
                style: TextStyle(color: TroColors.warning, fontSize: 12),
              ),
            ),
        ],
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TroSpacing.screen,
          TroSpacing.md,
          TroSpacing.screen,
          TroSpacing.md,
        ),
        decoration: BoxDecoration(
          color: TroColors.white,
          boxShadow: TroTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${formatPrice(p.giaThue)}/tháng',
                        style: TroText.price,
                      ),
                      Text(
                        'Cọc ${formatPrice(p.tienCoc)}',
                        style: TroText.bodySmall,
                      ),
                    ],
                  ),
                ),
                chinh,
              ],
            ),
            if (phu.isNotEmpty) ...[
              const SizedBox(height: TroSpacing.sm),
              Wrap(
                spacing: TroSpacing.sm,
                runSpacing: TroSpacing.sm,
                children: phu,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
