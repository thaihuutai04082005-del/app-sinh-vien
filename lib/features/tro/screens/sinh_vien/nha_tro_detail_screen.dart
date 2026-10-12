import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../../../shared/widgets/location_map.dart';
import '../../../../shared/widgets/video_player_view.dart';
import '../../models/danh_gia.dart';
import '../../models/nha_tro.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../services/nha_tro_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/noi_quy_block.dart';
import '../../widgets/phong_tro_tile.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import 'tro_sanh_screen.dart';

/// TRO-SV-05 Chi tiết nhà trọ: trên là thông tin chung, dưới là danh sách phòng, cuối trang là đánh giá.
class NhaTroDetailScreen extends StatelessWidget {
  const NhaTroDetailScreen({
    required this.dv,
    required this.nhaTroId,
    this.phongPhuHop = const {},
    super.key,
  });

  final TroDichVu dv;
  final String nhaTroId;

  /// Phòng phù hợp bộ lọc ở sảnh: nằm trên cùng.
  final Set<String> phongPhuHop;

  @override
  Widget build(BuildContext context) {
    return TroStream<NhaTro?>(
      stream: () => dv.nhaTro.nhaTro(nhaTroId),
      builder: (context, n) {
        if (n == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const TroEmptyState(
              title: 'Nhà trọ không tồn tại hoặc đã bị ẩn',
            ),
          );
        }
        final laCuaToi = n.chuTroId == dv.uid;
        return Scaffold(
          appBar: AppBar(
            title: Text(n.ten),
            actions: [
              if (!laCuaToi)
                NutLuuNhaTro(dv: dv, nhaTroId: n.id, chuTroId: n.chuTroId),
              if (!laCuaToi)
                IconButton(
                  tooltip: 'Báo cáo',
                  onPressed: () =>
                      moBaoCao(context, dv, loai: 'nha_tro', id: n.id),
                  icon: const Icon(Icons.flag_outlined),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(TroSpacing.screen),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Media(anh: n.anh, video: n.video),
                      const SizedBox(height: TroSpacing.lg),
                      _ThongTinChung(n: n),
                      if (n.noiQuy != null) ...[
                        const SizedBox(height: TroSpacing.xl),
                        NoiQuyBlock(noiQuy: n.noiQuy!),
                      ],
                      const SizedBox(height: TroSpacing.xl),
                      const Text('Mô tả', style: TroText.h2),
                      const SizedBox(height: TroSpacing.sm),
                      Text(n.moTa, style: TroText.body),
                      const SizedBox(height: TroSpacing.xl),
                      const Text('Địa chỉ', style: TroText.h2),
                      const SizedBox(height: TroSpacing.sm),
                      Text(n.diaChi, style: TroText.body),
                      if (n.viTri != null) ...[
                        const SizedBox(height: TroSpacing.md),
                        LocationMap(
                          latitude: n.viTri!.latitude,
                          longitude: n.viTri!.longitude,
                        ),
                      ],
                      const SizedBox(height: TroSpacing.xl),
                      _ChuTro(dv: dv, n: n, laCuaToi: laCuaToi),
                      const SizedBox(height: TroSpacing.xl),
                      Text(
                        n.laNguyenCan ? 'Thông tin căn nhà' : 'Danh sách phòng',
                        style: TroText.h2,
                      ),
                      const SizedBox(height: TroSpacing.sm),
                      _DanhSachPhong(dv: dv, n: n, phongPhuHop: phongPhuHop),
                      const SizedBox(height: TroSpacing.xl),
                      _DanhGia(dv: dv, n: n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.anh, required this.video});

  final List<String> anh;
  final List<String> video;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (anh.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(TroRadius.card),
          child: ImageGallery(urls: anh, aspectRatio: 16 / 9),
        ),
      for (final v in video) ...[
        const SizedBox(height: TroSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(TroRadius.card),
          child: VideoPlayerView(url: v, maxHeight: 360),
        ),
      ],
    ],
  );
}

class _ThongTinChung extends StatelessWidget {
  const _ThongTinChung({required this.n});

  final NhaTro n;

  @override
  Widget build(BuildContext context) {
    final sl = n.soLieu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(n.ten, style: TroText.h1)),
            if (n.daXacThucNha)
              const TroStatusBadge(
                kind: TroBadgeKind.verified,
                label: 'Đã xác thực nhà',
              ),
          ],
        ),
        const SizedBox(height: TroSpacing.xs),
        Text(
          [
            if (sl.diem != null)
              '★ ${sl.diem!.toStringAsFixed(1)} (${sl.soDanhGia} đánh giá)'
            else
              'Chưa có đánh giá xác minh',
            loaiHinhLabels[n.loaiHinh] ?? '',
            if (n.tongSoPhong != null && !n.laNguyenCan)
              '${n.tongSoPhong} phòng',
            if (n.soTang != null) '${n.soTang} tầng',
          ].join(' · '),
          style: TroText.bodySmall,
        ),
        const SizedBox(height: TroSpacing.sm),
        if (sl.giaMin != null)
          Text(
            sl.giaMax == null || sl.giaMax == sl.giaMin
                ? '${formatPrice(sl.giaMin!)}/tháng'
                : '${formatPrice(sl.giaMin!)} – ${formatPrice(sl.giaMax!)}/tháng',
            style: TroText.price.copyWith(fontSize: 20),
          ),
        const SizedBox(height: TroSpacing.md),
        if (n.tienIchChung.isNotEmpty) ...[
          const Text('Tiện ích chung', style: TroText.h2),
          const SizedBox(height: TroSpacing.sm),
          Wrap(
            spacing: TroSpacing.sm,
            runSpacing: TroSpacing.sm,
            children: [
              for (final t in n.tienIchChung)
                Chip(label: Text(tienIchChungLabels[t] ?? t)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChuTro extends StatelessWidget {
  const _ChuTro({required this.dv, required this.n, required this.laCuaToi});

  final TroDichVu dv;
  final NhaTro n;
  final bool laCuaToi;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TroSpacing.lg),
      child: StreamBuilder<ChiSoChu>(
        stream: dv.nhaTro.chiSoChu(n.chuTroId),
        builder: (context, s) {
          final cs = s.data ?? const ChiSoChu();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: TroColors.primaryLight,
                    child: Icon(Icons.person, color: TroColors.primary),
                  ),
                  const SizedBox(width: TroSpacing.md),
                  Expanded(
                    child: Text(cs.hoTen ?? 'Chủ trọ', style: TroText.h3),
                  ),
                  if (cs.daXacThucDanhTinh)
                    const TroStatusBadge(
                      kind: TroBadgeKind.verified,
                      label: 'Đã xác thực danh tính',
                    ),
                ],
              ),
              const SizedBox(height: TroSpacing.sm),
              Text(
                'Tỷ lệ phản hồi: ${cs.tyLePhanHoi == null ? 'chưa có' : '${cs.tyLePhanHoi}%'} · '
                'Giữ đúng cam kết: ${cs.tyLeCamKet == null ? 'chưa có' : '${cs.tyLeCamKet}%'}',
                style: TroText.bodySmall,
              ),
              if (!laCuaToi) ...[
                const SizedBox(height: TroSpacing.md),
                _NutLienHe(dv: dv, n: n),
              ],
            ],
          );
        },
      ),
    ),
  );
}

/// Số điện thoại chỉ hiện cho người đã đăng nhập (mục 2.13), lấy từ hệ thống.
class _NutLienHe extends StatefulWidget {
  const _NutLienHe({required this.dv, required this.n});

  final TroDichVu dv;
  final NhaTro n;

  @override
  State<_NutLienHe> createState() => _NutLienHeState();
}

class _NutLienHeState extends State<_NutLienHe> {
  late final Future<String?> _sdt = widget.dv.nhaTro
      .laySdtChuTro(widget.n.id)
      .catchError((_) => null);

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _sdt,
    builder: (context, s) => Wrap(
      spacing: TroSpacing.sm,
      runSpacing: TroSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: () =>
              TroDieuHuong.chat(context, widget.dv, widget.n.chuTroId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Nhắn tin'),
        ),
        if (s.data != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: s.data)),
            icon: const Icon(Icons.call_outlined),
            label: Text('Gọi ${s.data}'),
          ),
      ],
    ),
  );
}

class _DanhSachPhong extends StatelessWidget {
  const _DanhSachPhong({
    required this.dv,
    required this.n,
    required this.phongPhuHop,
  });

  final TroDichVu dv;
  final NhaTro n;
  final Set<String> phongPhuHop;

  @override
  Widget build(BuildContext context) => TroStream<List<PhongTro>>(
    stream: () => dv.nhaTro.phongHienThi(n.id),
    builder: (context, ds) {
      if (ds.isEmpty) {
        return const TroEmptyState(
          title: 'Chưa có phòng',
          icon: Icons.bed_outlined,
        );
      }
      int hang(PhongTro p) =>
          p.conTrong ? (phongPhuHop.contains(p.id) ? 0 : 1) : 2;
      final sx = [...ds]
        ..sort((a, b) {
          final h = hang(a).compareTo(hang(b));
          if (h != 0) return h;
          final k = a.khu.compareTo(b.khu);
          return k != 0 ? k : a.ten.compareTo(b.ten);
        });
      // Phòng có ghi Khu/Dãy thì tự gom theo khu.
      String? khuTruoc;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in sx) ...[
            if (p.conTrong && p.khu.isNotEmpty && p.khu != khuTruoc) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: TroSpacing.sm,
                  bottom: TroSpacing.xs,
                ),
                child: Text(khuTruoc = p.khu, style: TroText.label),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: TroSpacing.sm),
              child: PhongTroTile(
                phong: p,
                phuHop: phongPhuHop.contains(p.id),
                onTap: () => TroDieuHuong.phong(context, dv, p.id),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _DanhGia extends StatelessWidget {
  const _DanhGia({required this.dv, required this.n});

  final TroDichVu dv;
  final NhaTro n;

  @override
  Widget build(BuildContext context) => TroStream<List<DanhGia>>(
    stream: () => dv.danhGia.cuaNhaTro(n.id),
    builder: (context, ds) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đánh giá (${ds.length})', style: TroText.h2),
        const SizedBox(height: TroSpacing.sm),
        if (ds.isEmpty)
          const Text('Chưa có đánh giá.', style: TroText.bodySmall),
        for (final d in ds)
          DanhGiaTile(dv: dv, d: d, laChu: n.chuTroId == dv.uid),
      ],
    ),
  );
}

/// Một đánh giá: nhãn xác minh, "Đã ở phòng ...", trả lời của chủ (chủ trả lời 1 lần), báo cáo.
class DanhGiaTile extends StatelessWidget {
  const DanhGiaTile({
    required this.dv,
    required this.d,
    this.laChu = false,
    super.key,
  });

  final TroDichVu dv;
  final DanhGia d;
  final bool laChu;

  Future<void> _traLoi(BuildContext context) async {
    final c = TextEditingController();
    final nd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trả lời công khai (1 lần)'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Nội dung trả lời'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (nd == null || nd.isEmpty || !context.mounted) return;
    await chayThaoTac(
      context,
      () => dv.danhGia.traLoi(d.id, nd),
      thanhCong: 'Đã trả lời đánh giá',
    );
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: d.tinhDiem ? 1 : 0.6,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: TroSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '★ ${d.diemTB.toStringAsFixed(1)}',
                style: TroText.label.copyWith(color: TroColors.primary),
              ),
              const SizedBox(width: TroSpacing.sm),
              Expanded(child: Text(d.tenNguoiViet, style: TroText.label)),
              TroStatusBadge(
                kind: d.nhan == null
                    ? TroBadgeKind.reserved
                    : TroBadgeKind.rented,
                label: d.nhanLabel,
              ),
            ],
          ),
          if (d.tenPhong.isNotEmpty)
            Text(
              'Đã ở phòng ${d.tenPhong}${d.daCapNhat ? ' · Đã cập nhật' : ''}',
              style: TroText.bodySmall,
            ),
          const SizedBox(height: TroSpacing.xs),
          if (d.the.isNotEmpty)
            Wrap(
              spacing: TroSpacing.xs,
              children: [
                for (final t in d.the)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(theNhanhDanhGiaLabels[t] ?? t),
                  ),
              ],
            ),
          Text(d.nhanXet, style: TroText.body),
          if (d.anh.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: TroSpacing.xs),
              child: Wrap(
                spacing: TroSpacing.xs,
                children: [
                  for (final a in d.anh)
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkPhoto(a),
                      ),
                    ),
                ],
              ),
            ),
          if (d.chuTraLoi != null)
            Container(
              margin: const EdgeInsets.only(top: TroSpacing.sm),
              padding: const EdgeInsets.all(TroSpacing.sm),
              decoration: BoxDecoration(
                color: TroColors.primaryLight,
                borderRadius: BorderRadius.circular(TroRadius.input),
              ),
              child: Text(
                'Chủ trọ trả lời: ${d.chuTraLoi}',
                style: TroText.bodySmall.copyWith(color: TroColors.textPrimary),
              ),
            ),
          Row(
            children: [
              if (laChu && d.chuTraLoi == null)
                TextButton(
                  onPressed: () => _traLoi(context),
                  child: const Text('Trả lời'),
                ),
              const Spacer(),
              if (d.nguoiViet != dv.uid)
                TextButton(
                  onPressed: () =>
                      moBaoCao(context, dv, loai: 'danh_gia', id: d.id),
                  child: const Text('Báo cáo'),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    ),
  );
}
