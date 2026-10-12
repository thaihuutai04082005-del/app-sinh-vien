import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/nha_tro.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/phong_tro_tile.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import 'tao_nha_tro_screen.dart';
import 'them_phong_screen.dart';

/// TRO-CT-05 Quản lý — Nhà trọ / phòng: sửa (bản chỉnh sửa chờ duyệt), ẩn / hiện, gia hạn "Vẫn còn cho thuê",
/// thêm phòng, nhân bản, đăng lại, "Đã cho thuê ngoài app", "Xác nhận phòng đã có người cọc trực tiếp".
class QuanLyNhaTroScreen extends StatelessWidget {
  const QuanLyNhaTroScreen({
    required this.dv,
    required this.nhaTroId,
    super.key,
  });

  final TroDichVu dv;
  final String nhaTroId;

  @override
  Widget build(BuildContext context) => TroStream<NhaTro?>(
    stream: () => dv.nhaTro.nhaTro(nhaTroId),
    builder: (context, n) {
      if (n == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const TroEmptyState(title: 'Không tìm thấy nhà trọ'),
        );
      }
      final nhap = ['draft', 'rejected'].contains(n.trangThai);
      return Scaffold(
        appBar: AppBar(title: Text(n.ten.isEmpty ? 'Nhà trọ' : n.ten)),
        floatingActionButton: n.trangThai == 'active' || n.trangThai == 'hidden'
            ? FloatingActionButton.extended(
                onPressed: () => TroDieuHuong.mo(
                  context,
                  (_) => ThemPhongScreen(dv: dv, nhaTro: n),
                ),
                icon: const Icon(Icons.add),
                label: Text(n.laNguyenCan ? 'Thông tin căn nhà' : 'Thêm phòng'),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            TroSpacing.screen,
            TroSpacing.screen,
            TroSpacing.screen,
            96,
          ),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(TroSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái: ${trangThaiNhaTroLabels[n.trangThai]}',
                      style: TroText.h3,
                    ),
                    if (n.trangThai == 'rejected')
                      Text(
                        'Lý do: ${n.lyDoTuChoi ?? ''}',
                        style: const TextStyle(color: TroColors.danger),
                      ),
                    if (n.trangThai == 'pending_review')
                      const Text(
                        'Admin đang duyệt hồ sơ.',
                        style: TroText.bodySmall,
                      ),
                    if (n.hetHanLuc != null &&
                        (n.trangThai == 'active' || n.trangThai == 'expired'))
                      Text(
                        'Hạn hiển thị: ${formatNgay(n.hetHanLuc!)}',
                        style: TroText.bodySmall,
                      ),
                    if (n.banChinhSua != null)
                      Text(
                        n.banChinhSua!['trangThai'] == 'cho'
                            ? 'Có bản chỉnh sửa (ảnh / video / vị trí) đang chờ duyệt; bản cũ vẫn hiện.'
                            : 'Bản chỉnh sửa bị từ chối: ${n.banChinhSua!['lyDoTuChoi'] ?? ''}. Bản cũ vẫn hiện.',
                        style: TroText.bodySmall,
                      ),
                    if (n.anBoi == 'admin')
                      const Text(
                        'Admin đã ẩn nhà trọ này. Bạn có thể kháng nghị trong 7 ngày.',
                        style: TextStyle(color: TroColors.danger),
                      ),
                    const SizedBox(height: TroSpacing.sm),
                    Wrap(
                      spacing: TroSpacing.sm,
                      runSpacing: TroSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: n.trangThai == 'pending_review'
                              ? null
                              : () => TroDieuHuong.mo(
                                  context,
                                  (_) => TaoNhaTroScreen(dv: dv, nhaTro: n),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            nhap ? 'Tiếp tục soạn / gửi duyệt' : 'Sửa nhà trọ',
                          ),
                        ),
                        if (n.trangThai == 'active' || n.trangThai == 'expired')
                          FilledButton.icon(
                            onPressed: () => chayThaoTac(
                              context,
                              () => dv.nhaTro.thaoTac('giaHanNhaTro', {
                                'nhaTroId': n.id,
                              }),
                              thanhCong: 'Đã gia hạn 30 ngày',
                            ),
                            icon: const Icon(Icons.update),
                            label: const Text('Vẫn còn cho thuê'),
                          ),
                        if (n.trangThai == 'active')
                          OutlinedButton(
                            onPressed: () => chayThaoTac(
                              context,
                              () => dv.nhaTro.thaoTac('anHienNhaTro', {
                                'nhaTroId': n.id,
                                'an': true,
                              }),
                              thanhCong: 'Đã ẩn nhà trọ',
                            ),
                            child: const Text('Tạm ẩn'),
                          ),
                        if (n.trangThai == 'hidden' && n.anBoi == 'chu')
                          OutlinedButton(
                            onPressed: () => chayThaoTac(
                              context,
                              () => dv.nhaTro.thaoTac('anHienNhaTro', {
                                'nhaTroId': n.id,
                                'an': false,
                              }),
                              thanhCong: 'Đã hiện lại',
                            ),
                            child: const Text('Hiện lại'),
                          ),
                        if (n.trangThai == 'draft')
                          TextButton(
                            onPressed: () async {
                              if (await xacNhan(
                                    context,
                                    tieuDe: 'Xóa bản nháp?',
                                    noiDung: 'Bản nháp nhà trọ sẽ bị xóa.',
                                    nguyHiem: true,
                                  ) &&
                                  context.mounted) {
                                await chayThaoTac(
                                  context,
                                  () => dv.nhaTro.xoaNhap('nha_tro', n.id),
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: const Text('Xóa nháp'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TroSpacing.lg),
            Text(n.laNguyenCan ? 'Căn nhà' : 'Phòng', style: TroText.h2),
            const SizedBox(height: TroSpacing.sm),
            if (!(n.trangThai == 'active' || n.trangThai == 'hidden'))
              const Text(
                'Nhà trọ được duyệt mới thêm phòng được.',
                style: TroText.bodySmall,
              )
            else
              TroStream<List<PhongTro>>(
                stream: () => dv.nhaTro.phongCuaNha(n.id),
                builder: (context, ds) => ds.isEmpty
                    ? const TroEmptyState(
                        icon: Icons.bed_outlined,
                        title: 'Chưa có phòng',
                      )
                    : Column(
                        children: [
                          for (final p in [
                            ...ds,
                          ]..sort((a, b) => a.ten.compareTo(b.ten)))
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: TroSpacing.sm,
                              ),
                              child: PhongTroTile(
                                phong: p,
                                onTap: () =>
                                    TroDieuHuong.phong(context, dv, p.id),
                                trailing: _MenuPhong(dv: dv, n: n, p: p),
                              ),
                            ),
                        ],
                      ),
              ),
          ],
        ),
      );
    },
  );
}

class _MenuPhong extends StatelessWidget {
  const _MenuPhong({required this.dv, required this.n, required this.p});

  final TroDichVu dv;
  final NhaTro n;
  final PhongTro p;

  Future<void> _api(
    BuildContext context,
    String hanhDong, {
    Map<String, dynamic> them = const {},
    String? ok,
  }) => chayThaoTac(
    context,
    () => dv.nhaTro.thaoTac(hanhDong, {'phongId': p.id, ...them}),
    thanhCong: ok,
  );

  Future<void> _cocTrucTiep(BuildContext context) async {
    DateTime? ngay;
    final sdt = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(
            'Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Phòng chuyển "Đã cọc", không ai cọc qua app được nữa. App không giữ / hoàn tiền của khoản này.',
                style: TroText.bodySmall,
              ),
              const SizedBox(height: TroSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 120)),
                    initialDate: DateTime.now(),
                  );
                  if (d != null) setS(() => ngay = d);
                },
                icon: const Icon(Icons.event),
                label: Text(
                  ngay == null ? 'Ngày nhận phòng dự kiến' : formatNgay(ngay!),
                ),
              ),
              TextField(
                controller: sdt,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'SĐT người cọc (tùy chọn, để họ được đánh giá)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: ngay == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && ngay != null && context.mounted) {
      await chayThaoTac(
        context,
        () => dv.cocTrucTiep.xacNhan(
          phongId: p.id,
          ngayNhanDuKien: ngay!,
          sdtNguoiCoc: sdt.text,
        ),
        thanhCong: 'Đã ghi nhận cọc trực tiếp',
      );
    }
  }

  Future<void> _dangLai(BuildContext context) async {
    try {
      await dv.nhaTro.thaoTac('dangLaiPhong', {'phongId': p.id});
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã đăng lại phòng')));
      }
    } catch (e) {
      // Video quá 90 ngày: phải gửi video mới để duyệt lại.
      if (!context.mounted || !e.toString().contains('90 ngày')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
      var video = <String>[];
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Cần video phòng mới'),
            content: TroMediaField(
              storage: dv.storage,
              folder: 'tro_video',
              laVideo: true,
              nhan: 'Video phòng mới',
              toiThieu: 1,
              toiDa: 2,
              giaTri: video,
              onChanged: (v) => setS(() => video = v),
              pickVideo: dv.pickVideo,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gửi duyệt lại'),
              ),
            ],
          ),
        ),
      );
      if (ok == true && context.mounted) {
        await chayThaoTac(
          context,
          () => dv.nhaTro.thaoTac('dangLaiPhong', {
            'phongId': p.id,
            'videoMoi': video,
          }),
          thanhCong: 'Đã gửi duyệt lại',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mo = <(String, Future<void> Function())>[
      if (['draft', 'rejected'].contains(p.trangThai))
        (
          'Tiếp tục soạn / gửi duyệt',
          () => TroDieuHuong.mo(
            context,
            (_) => ThemPhongScreen(dv: dv, nhaTro: n, phong: p),
          ),
        ),
      if (['available', 'reserved', 'rented', 'hidden'].contains(p.trangThai))
        (
          'Sửa phòng',
          () => TroDieuHuong.mo(
            context,
            (_) => ThemPhongScreen(dv: dv, nhaTro: n, phong: p),
          ),
        ),
      if (!n.laNguyenCan)
        (
          'Nhân bản phòng',
          () => TroDieuHuong.mo(
            context,
            (_) => ThemPhongScreen(dv: dv, nhaTro: n, nhanBanTu: p),
          ),
        ),
      if (p.trangThai == 'available') ...[
        (
          'Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng',
          () => _cocTrucTiep(context),
        ),
        (
          'Đã cho thuê ngoài app',
          () => _api(
            context,
            'daChoThueNgoaiApp',
            ok: 'Phòng chuyển "Đã cho thuê"',
          ),
        ),
        (
          'Tạm ẩn phòng',
          () => _api(
            context,
            'anHienPhong',
            them: {'an': true},
            ok: 'Đã ẩn phòng',
          ),
        ),
      ],
      if (p.trangThai == 'hidden')
        (
          'Hiện lại phòng',
          () => _api(
            context,
            'anHienPhong',
            them: {'an': false},
            ok: 'Đã hiện phòng',
          ),
        ),
      if (p.trangThai == 'rented') ('Đăng lại phòng', () => _dangLai(context)),
      if (p.trangThai != 'reserved')
        (
          'Xóa phòng',
          () async {
            if (await xacNhan(
                  context,
                  tieuDe: 'Xóa phòng?',
                  noiDung: 'Phòng không còn hiện và không nhận cọc nữa. Lịch sử và đánh giá vẫn giữ.',
                  nguyHiem: true,
                ) &&
                context.mounted) {
              await (['draft', 'rejected'].contains(p.trangThai)
                  ? chayThaoTac(
                      context,
                      () => dv.nhaTro.xoaNhap('phong_tro', p.id),
                    )
                  : _api(context, 'xoaPhong', ok: 'Đã xóa phòng'));
            }
          },
        ),
    ];
    return PopupMenuButton<int>(
      tooltip: 'Thao tác',
      onSelected: (i) => mo[i].$2(),
      itemBuilder: (_) => [
        for (var i = 0; i < mo.length; i++)
          PopupMenuItem(value: i, child: Text(mo[i].$1)),
      ],
    );
  }
}
