import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/dat_ban.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/don_dem_nguoc_tile.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'check_in_screen.dart';

/// Chi tiết một lượt đặt bàn của sinh viên: trạng thái, đếm ngược, Hủy, Check-in, nhắn tin, mở quán.
/// Mở màn hình là nhờ hệ thống xử lý các hạn đã tới (thấy đúng trạng thái sau hạn).
class ChiTietDatBanScreen extends StatefulWidget {
  const ChiTietDatBanScreen({required this.dv, required this.banId, super.key});

  final QuanAnDichVu dv;
  final String banId;

  @override
  State<ChiTietDatBanScreen> createState() => _ChiTietDatBanScreenState();
}

class _ChiTietDatBanScreenState extends State<ChiTietDatBanScreen> {
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh();

  @override
  void initState() {
    super.initState();
    widget.dv.datBan.xuLyHan(widget.banId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt bàn')),
    body: FutureBuilder<QuanAnConfig>(
      future: _cfg,
      builder: (context, c) => !c.hasData
          ? const QuanAnSkeletonList(count: 1)
          : QuanAnStream<DatBan?>(
              stream: () => widget.dv.datBan.datBan(widget.banId),
              builder: (context, b) => b == null
                  ? const QuanAnEmptyState(title: 'Không tìm thấy lượt đặt bàn')
                  : _NoiDung(dv: widget.dv, ban: b, cfg: c.data!),
            ),
    ),
  );
}

QuanAnBadgeKind _kieuBadge(String s) => switch (s) {
  'confirmed' || 'arrived' => QuanAnBadgeKind.moCua,
  'pending' => QuanAnBadgeKind.sapDong,
  'rejected' ||
  'expired' ||
  'cancelled_restaurant' ||
  'no_show' => QuanAnBadgeKind.dongCua,
  _ => QuanAnBadgeKind.chung,
};

class _NoiDung extends StatefulWidget {
  const _NoiDung({required this.dv, required this.ban, required this.cfg});

  final QuanAnDichVu dv;
  final DatBan ban;
  final QuanAnConfig cfg;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  bool _dangXuLy = false;

  QuanAnDichVu get dv => widget.dv;
  DatBan get b => widget.ban;

  Future<void> _huy(DateTime now) async {
    final phat = b.huyBiTinhBoHen(now, widget.cfg);
    final ok = await xacNhan(
      context,
      tieuDe: 'Hủy đặt bàn?',
      noiDung: phat
          ? 'Còn dưới ${widget.cfg.huySatGioPhut >= 60 ? '${widget.cfg.huySatGioPhut ~/ 60} giờ' : '${widget.cfg.huySatGioPhut} phút'} tới giờ hẹn: hủy lúc này sẽ tính 1 lần bỏ hẹn đặt bàn. ${widget.cfg.khoaDatBanSoLan} lần bỏ hẹn trong ${widget.cfg.chiSoNgay} ngày sẽ bị khóa đặt bàn ${widget.cfg.khoaDatBanNgay} ngày.'
          : 'Hủy lúc này không bị phạt.',
      dongY: 'Hủy đặt bàn',
      nguyHiem: true,
    );
    if (!ok || !mounted) return;
    setState(() => _dangXuLy = true);
    await chayThaoTac(
      context,
      () => dv.datBan.thaoTac(b.id, b.version, 'SV_HUY'),
      thanhCong: 'Đã hủy đặt bàn',
    );
    if (mounted) setState(() => _dangXuLy = false);
  }

  Future<void> _checkIn() async {
    setState(() => _dangXuLy = true);
    QuanAn? quan;
    final ok = await chayThaoTac(context, () async {
      quan = await dv.quan.quan(b.quanId).first;
    });
    if (!mounted) return;
    setState(() => _dangXuLy = false);
    final q = quan;
    if (!ok) return;
    if (q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy quán này nữa.')),
      );
      return;
    }
    await QuanAnDieuHuong.mo(context, (_) => CheckInScreen(dv: dv, quan: q));
  }

  @override
  Widget build(BuildContext context) => DongHoTick(
    builder: (context, now) {
      final moc = b.mocDemNguoc(now, widget.cfg);
      final nutHuy = b.coSvHuy(now, widget.cfg);
      final nutCheckIn = b.coSvCheckIn(now, widget.cfg);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.tenQuan.isEmpty ? 'Đặt bàn' : b.tenQuan,
                      style: QuanAnText.h2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  Flexible(
                    child: QuanAnStatusBadge(
                      kind: _kieuBadge(b.status),
                      label: b.trangThaiLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QuanAnSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(QuanAnSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Dong(
                        Icons.event_rounded,
                        'Giờ hẹn',
                        formatNgayGio(b.gio),
                      ),
                      _Dong(
                        Icons.group_outlined,
                        'Số người',
                        '${b.soNguoi} người',
                      ),
                      if (b.ghiChu.trim().isNotEmpty)
                        _Dong(
                          Icons.sticky_note_2_outlined,
                          'Ghi chú',
                          b.ghiChu.trim(),
                        ),
                      const _Dong(
                        Icons.money_off_rounded,
                        'Chi phí',
                        'Không thu tiền',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: QuanAnSpacing.md),
              if (moc != null)
                DonDemNguocTile(
                  nhan: moc.$1,
                  moc: moc.$2,
                  canhBao: b.status == 'pending',
                  onHet: () => dv.datBan.xuLyHan(b.id).catchError((_) {}),
                ),
              if (b.daCheckIn) ...[
                const SizedBox(height: QuanAnSpacing.md),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.nhan,
                    label: '🍽 Đã đến theo đặt bàn (check-in tại quán)',
                  ),
                ),
              ],
              if (b.status == 'confirmed' &&
                  b.ghiNhanDen == null &&
                  now.isBefore(b.gio)) ...[
                const SizedBox(height: QuanAnSpacing.md),
                Text(
                  'Check-in mở từ giờ hẹn tới khi hết giờ giữ bàn (${widget.cfg.giuBanPhut} phút sau giờ hẹn).',
                  style: QuanAnText.bodySmall,
                ),
              ],
              if (b.status == 'confirmed' &&
                  b.huyBiTinhBoHen(now, widget.cfg)) ...[
                const SizedBox(height: QuanAnSpacing.md),
                const QuanAnWarningBox(
                  message: 'Đã sát giờ hẹn: hủy lúc này sẽ tính 1 lần bỏ hẹn đặt bàn.',
                ),
              ],
              const SizedBox(height: QuanAnSpacing.xl),
              if (nutCheckIn) ...[
                FilledButton.icon(
                  onPressed: _dangXuLy ? null : _checkIn,
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Check-in tại quán'),
                ),
                const SizedBox(height: QuanAnSpacing.sm),
              ],
              if (nutHuy) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuanAnColors.danger,
                    side: const BorderSide(
                      color: QuanAnColors.danger,
                      width: 1.5,
                    ),
                  ),
                  onPressed: _dangXuLy ? null : () => _huy(now),
                  child: const Text('Hủy đặt bàn'),
                ),
                const SizedBox(height: QuanAnSpacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: () => QuanAnDieuHuong.chat(
                  context,
                  dv,
                  b.chuQuanId,
                  quanId: b.quanId,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhắn tin với quán'),
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              TextButton(
                onPressed: () => QuanAnDieuHuong.quan(context, dv, b.quanId),
                child: const Text('Xem trang quán'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Dong extends StatelessWidget {
  const _Dong(this.icon, this.nhan, this.giaTri);

  final IconData icon;
  final String nhan;
  final String giaTri;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: QuanAnColors.primary),
        const SizedBox(width: QuanAnSpacing.sm),
        Text('$nhan: ', style: QuanAnText.bodySmall),
        Expanded(child: Text(giaTri, style: QuanAnText.body)),
      ],
    ),
  );
}
