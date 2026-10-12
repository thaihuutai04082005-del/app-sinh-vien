import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/coc_truc_tiep.dart';
import '../../models/dat_coc.dart';
import '../../models/nha_tro.dart';
import '../../models/thanh_toan.dart';
import '../../models/tro_config.dart';
import '../../services/nha_tro_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import 'quan_ly_coc_truc_tiep_screen.dart';
import 'quan_ly_dat_coc_screen.dart';
import 'quan_ly_nha_tro_screen.dart';
import 'tao_nha_tro_screen.dart';
import 'vi_screen.dart';

/// TRO-CT-04 Quản lý — Tổng quan: việc cần làm, tiền cọc đang giữ, chỉ số uy tín, nhà trọ của tôi.
class QuanLyTongQuanScreen extends StatelessWidget {
  const QuanLyTongQuanScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý nhà trọ')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => TroDieuHuong.mo(context, (_) => TaoNhaTroScreen(dv: dv)),
      icon: const Icon(Icons.add_home_work_outlined),
      label: const Text('Tạo nhà trọ'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        TroSpacing.screen,
        TroSpacing.screen,
        TroSpacing.screen,
        96,
      ),
      children: [
        _ViecCanLam(dv: dv),
        const SizedBox(height: TroSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<ViChuTro>(
                stream: dv.datCoc.vi(dv.uid),
                builder: (context, s) => _O(
                  tieuDe: 'Tiền cọc đang giữ',
                  gia: formatPrice(s.data?.dangGiu ?? 0),
                  onTap: () =>
                      TroDieuHuong.mo(context, (_) => ViScreen(dv: dv)),
                ),
              ),
            ),
            const SizedBox(width: TroSpacing.md),
            Expanded(
              child: StreamBuilder<ChiSoChu>(
                stream: dv.nhaTro.chiSoChu(dv.uid),
                builder: (context, s) => _O(
                  tieuDe: 'Giữ đúng cam kết',
                  gia: s.data?.tyLeCamKet == null
                      ? '—'
                      : '${s.data!.tyLeCamKet}%',
                  phu:
                      'Phản hồi: ${s.data?.tyLePhanHoi == null ? '—' : '${s.data!.tyLePhanHoi}%'} · Vi phạm 90 ngày: ${s.data?.soViPham90 ?? 0}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TroSpacing.md),
        Wrap(
          spacing: TroSpacing.sm,
          runSpacing: TroSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  TroDieuHuong.mo(context, (_) => QuanLyDatCocScreen(dv: dv)),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Tiền cọc'),
            ),
            OutlinedButton.icon(
              onPressed: () => TroDieuHuong.mo(
                context,
                (_) => QuanLyCocTrucTiepScreen(dv: dv),
              ),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Cọc trực tiếp'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  TroDieuHuong.mo(context, (_) => ViScreen(dv: dv)),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Ví'),
            ),
          ],
        ),
        const SizedBox(height: TroSpacing.xl),
        const Text('Nhà trọ của tôi', style: TroText.h2),
        const SizedBox(height: TroSpacing.sm),
        TroStream<List<NhaTro>>(
          stream: () => dv.nhaTro.nhaTroCuaToi(dv.uid),
          builder: (context, ds) => ds.isEmpty
              ? TroEmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'Bạn chưa có nhà trọ nào',
                  message:
                      'Tạo nhà trọ (làm 1 lần), được duyệt rồi thêm phòng.',
                  actionLabel: 'Tạo nhà trọ',
                  onAction: () =>
                      TroDieuHuong.mo(context, (_) => TaoNhaTroScreen(dv: dv)),
                )
              : Column(
                  children: [
                    for (final n in ds)
                      Card(
                        child: ListTile(
                          title: Text(
                            n.ten.isEmpty ? '(Nhà trọ chưa đặt tên)' : n.ten,
                          ),
                          subtitle: Text(
                            [
                              '${n.soLieu.soPhongTrong}/${n.soLieu.soPhong} phòng trống',
                              if (n.hetHanLuc != null &&
                                  n.trangThai == 'active')
                                'hết hạn ${formatNgay(n.hetHanLuc!)}',
                              if (n.banChinhSua?['trangThai'] == 'cho')
                                'có chỉnh sửa chờ duyệt',
                            ].join(' · '),
                          ),
                          trailing: TroStatusBadge(
                            kind: _kieu(n.trangThai),
                            label:
                                trangThaiNhaTroLabels[n.trangThai] ??
                                n.trangThai,
                          ),
                          onTap: () => TroDieuHuong.mo(
                            context,
                            (_) => QuanLyNhaTroScreen(dv: dv, nhaTroId: n.id),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );

  static TroBadgeKind _kieu(String s) => switch (s) {
    'active' => TroBadgeKind.available,
    'pending_review' || 'draft' => TroBadgeKind.reserved,
    _ => TroBadgeKind.full,
  };
}

class _O extends StatelessWidget {
  const _O({required this.tieuDe, required this.gia, this.phu, this.onTap});

  final String tieuDe;
  final String gia;
  final String? phu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(TroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tieuDe, style: TroText.bodySmall),
            Text(gia, style: TroText.h2.copyWith(color: TroColors.primary)),
            if (phu != null) Text(phu!, style: TroText.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Việc cần làm: yêu cầu thay đổi chờ trả lời, khiếu nại cần trả lời, sắp tới thời điểm nhận phòng,
/// cọc trực tiếp chưa cập nhật, tin bị từ chối / sắp hết hạn.
class _ViecCanLam extends StatelessWidget {
  const _ViecCanLam({required this.dv});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DatCoc>>(
    stream: dv.datCoc.cuaChuTro(dv.uid),
    builder: (context, coc) => StreamBuilder<List<CocTrucTiep>>(
      stream: dv.cocTrucTiep.cuaChuTro(dv.uid),
      builder: (context, ctt) => StreamBuilder<List<NhaTro>>(
        stream: dv.nhaTro.nhaTroCuaToi(dv.uid),
        builder: (context, nha) {
          final now = DateTime.now();
          final viec = <(IconData, String, VoidCallback)>[];
          for (final d in coc.data ?? const <DatCoc>[]) {
            if (d.coTraLoiDoi) {
              viec.add((
                Icons.schedule,
                'Trả lời yêu cầu đổi thời điểm nhận ${d.tenPhong} trước ${formatNgayGio(d.doi!.hanTraLoi)}',
                () => TroDieuHuong.datCoc(context, dv, d.id),
              ));
            }
            if (d.coTraLoiKhieuNai) {
              viec.add((
                Icons.report_problem_outlined,
                'Trả lời khiếu nại ${d.tenPhong}',
                () => TroDieuHuong.datCoc(context, dv, d.id),
              ));
            }
            if (d.dangGiu &&
                d.t.isAfter(now) &&
                d.t.difference(now).inHours < 48) {
              viec.add((
                Icons.key_outlined,
                'Sắp tới thời điểm nhận ${d.tenPhong}: ${formatNgayGio(d.t)}',
                () => TroDieuHuong.datCoc(context, dv, d.id),
              ));
            }
          }
          for (final c in ctt.data ?? const <CocTrucTiep>[]) {
            if (c.dangCho && now.isAfter(c.ngayNhanDuKien)) {
              viec.add((
                Icons.handshake_outlined,
                'Cập nhật cọc trực tiếp ${c.tenPhong}',
                () => TroDieuHuong.mo(
                  context,
                  (_) => QuanLyCocTrucTiepScreen(dv: dv),
                ),
              ));
            }
          }
          for (final n in nha.data ?? const <NhaTro>[]) {
            if (n.trangThai == 'rejected') {
              viec.add((
                Icons.error_outline,
                '"${n.ten}" bị từ chối: ${n.lyDoTuChoi ?? ''}',
                () => TroDieuHuong.mo(
                  context,
                  (_) => QuanLyNhaTroScreen(dv: dv, nhaTroId: n.id),
                ),
              ));
            }
            if (n.trangThai == 'expired' ||
                (n.hetHanLuc != null &&
                    n.trangThai == 'active' &&
                    n.hetHanLuc!.difference(now).inDays < 3)) {
              viec.add((
                Icons.update,
                '"${n.ten}" ${n.trangThai == 'expired' ? 'đã hết hạn' : 'sắp hết hạn'} — bấm "Vẫn còn cho thuê"',
                () => TroDieuHuong.mo(
                  context,
                  (_) => QuanLyNhaTroScreen(dv: dv, nhaTroId: n.id),
                ),
              ));
            }
          }
          if (viec.isEmpty) return const SizedBox.shrink();
          return Card(
            color: TroColors.warningSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Việc cần làm', style: TroText.h3),
                ),
                for (final (i, t, f) in viec)
                  ListTile(
                    dense: true,
                    leading: Icon(i, color: TroColors.warning),
                    title: Text(t),
                    onTap: f,
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Nhãn trạng thái phòng / nhà trọ dùng chung trong các màn hình quản lý.
String nhanTrangThaiPhong(String s) => trangThaiPhongLabels[s] ?? s;
