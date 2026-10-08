import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../../../shared/widgets/location_map.dart';
import '../../models/tro_config.dart';
import '../../services/admin_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/gia_dien_nuoc_table.dart';
import '../../widgets/noi_quy_block.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_theme.dart';

/// TRO-AD-01 Duyệt nhà trọ / phòng / bản chỉnh sửa (mục 2.12): kiểm tra giấy tờ, địa chỉ, ghim, ảnh / video,
/// giá, tiền cọc ≤ 1 tháng; từ chối bằng lý do có sẵn.
class DuyetTroScreen extends StatelessWidget {
  const DuyetTroScreen({required this.dv, required this.viec, super.key});

  final TroDichVu dv;
  final ViecAdmin viec;

  Future<void> _quyet(BuildContext context, bool dongY) async {
    String? lyDo;
    if (!dongY) {
      lyDo = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Lý do từ chối'),
          children: [
            for (final l in lyDoTuChoiLabels)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, l),
                child: Text(l),
              ),
          ],
        ),
      );
      if (lyDo == null) return;
    }
    if (!context.mounted) return;
    final ok = await chayThaoTac(
      context,
      () => dv.admin.goi('adminDuyet', {
        'loai': viec.loai,
        'id': viec.id,
        'dongY': dongY,
        'lyDo': lyDo,
      }),
      thanhCong: dongY ? 'Đã duyệt' : 'Đã từ chối',
    );
    if (ok && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final laNha = viec.loai == 'nha_tro' || viec.loai == 'chinh_sua_nha';
    final suaDoi = viec.loai.startsWith('chinh_sua');
    final ban = suaDoi
        ? (viec.duLieu['banChinhSua'] as Map?)?.cast<String, dynamic>() ??
              const {}
        : const <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: Text(ViecAdmin.loaiLabels[viec.loai] ?? '')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TroSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _quyet(context, false),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: TroSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => _quyet(context, true),
                  child: const Text('Duyệt'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TroSpacing.screen),
        children: [
          if (viec.duLieu['coGanCo'] == true)
            const Text(
              '⚠ Hồ sơ bị gắn cờ do nhiều báo cáo',
              style: TextStyle(color: TroColors.danger),
            ),
          if (laNha)
            ..._nha(context, suaDoi ? {...viec.duLieu, ...ban} : viec.duLieu)
          else
            ..._phong(suaDoi ? {...viec.duLieu, ...ban} : viec.duLieu),
          if (suaDoi) ...[
            const Divider(height: 32),
            const Text(
              'Đây là bản chỉnh sửa: chỉ duyệt phần thay đổi (ảnh / video / vị trí).',
              style: TroText.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _media(Map<String, dynamic> m) => [
    if ((m['anh'] as List?)?.isNotEmpty ?? false)
      ImageGallery(
        urls: List<String>.from(m['anh'] as List),
        aspectRatio: 16 / 9,
      ),
    for (final v in List<String>.from(m['video'] as List? ?? const []))
      TextButton.icon(
        onPressed: () => launchUrl(Uri.parse(v)),
        icon: const Icon(Icons.play_circle_outline),
        label: Text('Xem video: $v', overflow: TextOverflow.ellipsis),
      ),
  ];

  List<Widget> _nha(BuildContext context, Map<String, dynamic> m) {
    final n = nhaTuViec(
      ViecAdmin(
        loai: viec.loai,
        id: viec.id,
        tieuDe: '',
        moTa: '',
        luc: viec.luc,
        duLieu: m,
      ),
    );
    return [
      Text(n.ten, style: TroText.h1),
      Text(
        '${loaiHinhLabels[n.loaiHinh]} · ${n.tongSoPhong ?? '?'} phòng · ${n.soTang ?? '?'} tầng',
        style: TroText.bodySmall,
      ),
      const SizedBox(height: TroSpacing.md),
      ..._media(m),
      const SizedBox(height: TroSpacing.md),
      Text('Địa chỉ: ${n.diaChi}', style: TroText.body),
      if (n.viTri != null)
        LocationMap(latitude: n.viTri!.latitude, longitude: n.viTri!.longitude),
      const SizedBox(height: TroSpacing.md),
      if (n.noiQuy != null) NoiQuyBlock(noiQuy: n.noiQuy!),
      const SizedBox(height: TroSpacing.md),
      Text(n.moTa, style: TroText.body),
      const SizedBox(height: TroSpacing.md),
      const Text('Giấy tờ nhà (riêng tư)', style: TroText.h3),
      FutureBuilder<List<String>>(
        future: dv.admin.giayTo(viec.id),
        builder: (context, s) => s.hasData
            ? Wrap(
                spacing: TroSpacing.sm,
                children: [
                  for (final g in s.data!)
                    SizedBox(
                      width: 160,
                      height: 120,
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(g)),
                        child: NetworkPhoto(g),
                      ),
                    ),
                  if (s.data!.isEmpty) const Text('Chưa có giấy tờ'),
                ],
              )
            : const LinearProgressIndicator(),
      ),
      const SizedBox(height: TroSpacing.sm),
      const Text(
        'Đối chiếu: tên trên giấy tờ khớp họ tên đã xác thực (hoặc có hợp đồng thuê) · địa chỉ khớp ghim · video khớp ảnh.',
        style: TroText.bodySmall,
      ),
    ];
  }

  List<Widget> _phong(Map<String, dynamic> m) {
    final p = phongTuViec(
      ViecAdmin(
        loai: viec.loai,
        id: viec.id,
        tieuDe: '',
        moTa: '',
        luc: viec.luc,
        duLieu: m,
      ),
    );
    return [
      Text('Phòng ${p.ten} · ${p.nhaTro?.ten ?? ''}', style: TroText.h1),
      Text(p.moTaDienTich, style: TroText.bodySmall),
      const SizedBox(height: TroSpacing.md),
      ..._media(m),
      const SizedBox(height: TroSpacing.md),
      GiaDienNuocTable(phong: p),
      if (p.tienCoc > p.giaThue)
        const Text(
          '⚠ Tiền cọc lớn hơn 1 tháng thuê',
          style: TextStyle(color: TroColors.danger),
        ),
      if (p.ngayVaoO != null) Text('Vào ở từ ${formatNgay(p.ngayVaoO!)}'),
      Text(p.moTa),
    ];
  }
}
