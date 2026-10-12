import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/dat_ban.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// QA-CQ-04 Quản lý đặt bàn: danh sách bàn theo trạng thái, đếm ngược hạn xác nhận.
///
/// Nút: Xác nhận · Từ chối · Khách đã đến · Khách không đến (chỉ sau [QuanAnConfig.giuBanPhut]
/// phút giữ bàn, vô hiệu nếu sinh viên đã check-in hợp lệ) · Hủy bàn (giảm tỷ lệ giữ bàn).
/// Hệ thống vẫn kiểm tra lại khi bấm; mọi thao tác gửi `version`.
class QuanLyDatBanScreen extends StatefulWidget {
  const QuanLyDatBanScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  State<QuanLyDatBanScreen> createState() => _QuanLyDatBanScreenState();
}

class _QuanLyDatBanScreenState extends State<QuanLyDatBanScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();
  final _daXuLyHan = <String>{};

  static const _tab = [
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đã xong',
    'Đã hủy / hết hạn',
  ];

  @override
  void initState() {
    super.initState();
    widget.dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
  }

  static int tabCua(DatBan b) => switch (b.status) {
    'pending' => 0,
    'confirmed' => 1,
    'arrived' || 'no_show' => 2,
    _ => 3,
  };

  void _xuLyHanNeuCan(List<DatBan> ds) {
    final now = DateTime.now();
    for (final b in ds) {
      final han = b.hanXacNhan;
      if (b.status == 'pending' &&
          han != null &&
          now.isAfter(han) &&
          _daXuLyHan.add(b.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.dv.datBan.xuLyHan(b.id).catchError((_) {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt bàn')),
    body: QuanAnStream<List<DatBan>>(
      stream: () => widget.dv.datBan.cuaChuQuan(widget.dv.uid),
      thongBaoLoi: 'Không tải được danh sách đặt bàn',
      builder: (context, ds) {
        _xuLyHanNeuCan(ds);
        final theoTab = List.generate(_tab.length, (_) => <DatBan>[]);
        for (final b in ds) {
          theoTab[tabCua(b)].add(b);
        }
        // Chờ xác nhận: sắp hết hạn lên đầu; đã xác nhận: giờ hẹn gần nhất lên đầu.
        theoTab[0].sort(
          (a, b) => (a.hanXacNhan ?? a.gio).compareTo(b.hanXacNhan ?? b.gio),
        );
        theoTab[1].sort((a, b) => a.gio.compareTo(b.gio));
        return DefaultTabController(
          length: _tab.length,
          child: Column(
            children: [
              Material(
                color: QuanAnColors.white,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (var i = 0; i < _tab.length; i++)
                      Tab(
                        text: i > 1 || theoTab[i].isEmpty
                            ? _tab[i]
                            : '${_tab[i]} (${theoTab[i].length})',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (var i = 0; i < _tab.length; i++)
                      theoTab[i].isEmpty
                          ? QuanAnEmptyState(
                              icon: Icons.event_seat_outlined,
                              title: 'Chưa có lượt đặt bàn nào ở mục này',
                              message: i == 0
                                  ? 'Yêu cầu đặt bàn mới sẽ hiện ở đây.'
                                  : null,
                            )
                          : LuoiCuon(
                              children: [
                                for (final b in theoTab[i])
                                  _TheBan(
                                    key: ValueKey(b.id),
                                    dv: widget.dv,
                                    ban: b,
                                    cfg: _cfg,
                                  ),
                              ],
                            ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _TheBan extends StatelessWidget {
  const _TheBan({
    required this.dv,
    required this.ban,
    required this.cfg,
    super.key,
  });

  final QuanAnDichVu dv;
  final DatBan ban;
  final QuanAnConfig cfg;

  Future<void> _gui(BuildContext context, String loai, String thanhCong) =>
      chayThaoTac(
        context,
        () => dv.datBan.thaoTac(ban.id, ban.version, loai),
        thanhCong: thanhCong,
      );

  Future<void> _tuChoi(BuildContext context) async {
    final ok = await xacNhan(
      context,
      tieuDe: 'Từ chối đặt bàn?',
      noiDung:
          'Khách được báo bàn bị từ chối. Việc này không tính lỗi của khách.',
      dongY: 'Từ chối',
      nguyHiem: true,
    );
    if (ok && context.mounted) {
      await _gui(context, 'QUAN_TU_CHOI', 'Đã từ chối đặt bàn');
    }
  }

  Future<void> _huy(BuildContext context) async {
    final ok = await xacNhan(
      context,
      tieuDe: 'Hủy bàn đã xác nhận?',
      noiDung:
          'Hủy bàn đã xác nhận sẽ làm giảm tỷ lệ giữ bàn công khai của quán '
          'và khách được báo ngay. Chỉ hủy khi thật sự không giữ được bàn.',
      dongY: 'Hủy bàn',
      nguyHiem: true,
    );
    if (ok && context.mounted) {
      await _gui(context, 'QUAN_HUY', 'Đã hủy bàn');
    }
  }

  @override
  Widget build(BuildContext context) => QuanAnDongHo(
    builder: (context, now) {
      final b = ban;
      final khongDen = b.quanKhachKhongDen(now, cfg);
      final moc = b.mocDemNguoc(now, cfg);
      final nut = <Widget>[];
      final ghiChu = <String>[];
      if (b.status == 'pending') {
        if (b.coQuanXacNhan(now)) {
          nut.add(
            FilledButton.icon(
              onPressed: () =>
                  _gui(context, 'QUAN_XAC_NHAN', 'Đã xác nhận đặt bàn'),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Xác nhận'),
            ),
          );
          nut.add(
            OutlinedButton(
              style: kieuNutNguyHiem(),
              onPressed: () => _tuChoi(context),
              child: const Text('Từ chối'),
            ),
          );
        } else {
          ghiChu.add('Đã quá hạn xác nhận, hệ thống đang đóng yêu cầu này.');
        }
      }
      if (b.coQuanKhachDen) {
        nut.add(
          FilledButton(
            onPressed: () =>
                _gui(context, 'QUAN_KHACH_DEN', 'Đã ghi nhận khách đến'),
            child: const Text('Khách đã đến'),
          ),
        );
      }
      if (khongDen.hien) {
        nut.add(
          OutlinedButton(
            style: kieuNutNguyHiem(),
            onPressed: khongDen.bam
                ? () => _gui(
                    context,
                    'QUAN_KHONG_DEN',
                    'Đã ghi nhận khách không đến',
                  )
                : null,
            child: const Text('Khách không đến'),
          ),
        );
        if (!khongDen.bam && khongDen.giaiThich != null) {
          ghiChu.add(khongDen.giaiThich!);
        }
      }
      if (b.coQuanHuy(now, cfg)) {
        nut.add(
          OutlinedButton(
            style: kieuNutNguyHiem(),
            onPressed: () => _huy(context),
            child: const Text('Hủy bàn'),
          ),
        );
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bàn ${maNgan(b.id)} · ${b.soNguoi} người',
                      style: QuanAnText.h3,
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  Flexible(
                    child: QuanAnStatusBadge(
                      kind: switch (b.status) {
                        'pending' => QuanAnBadgeKind.canhBao,
                        'confirmed' => QuanAnBadgeKind.nhan,
                        'arrived' => QuanAnBadgeKind.moCua,
                        _ => QuanAnBadgeKind.dongCua,
                      },
                      label: b.trangThaiLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              Text('Giờ hẹn: ${formatNgayGio(b.gio)}', style: QuanAnText.body),
              if (b.tenQuan.isNotEmpty)
                Text(b.tenQuan, style: QuanAnText.bodySmall),
              if (b.svSdt.isNotEmpty)
                Text(
                  'Điện thoại khách: ${b.svSdt}',
                  style: QuanAnText.bodySmall,
                ),
              if (b.ghiChu.isNotEmpty)
                Text('Ghi chú: ${b.ghiChu}', style: QuanAnText.bodySmall),
              if (b.daCheckIn)
                const Padding(
                  padding: EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.nhan,
                    label: 'Khách đã check-in tại quán',
                    icon: Icons.place_rounded,
                  ),
                ),
              if (moc != null)
                Padding(
                  padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: b.status == 'pending'
                            ? QuanAnColors.warning
                            : QuanAnColors.textSecondary,
                      ),
                      const SizedBox(width: QuanAnSpacing.xs),
                      Expanded(
                        child: Text(
                          '${moc.$1}: ${formatNgayGio(moc.$2)} '
                          '(${b.status == 'pending' ? 'còn ${phutGiay(moc.$2.difference(now))}' : formatConLai(moc.$2.difference(now))})',
                          style: QuanAnText.bodySmall.copyWith(
                            color: b.status == 'pending'
                                ? QuanAnColors.warning
                                : null,
                            fontWeight: b.status == 'pending'
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (nut.isNotEmpty) ...[
                const SizedBox(height: QuanAnSpacing.md),
                Wrap(
                  spacing: QuanAnSpacing.sm,
                  runSpacing: QuanAnSpacing.sm,
                  children: nut,
                ),
              ],
              for (final g in ghiChu)
                Padding(
                  padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: Text(g, style: QuanAnText.bodySmall),
                ),
              if (b.status == 'confirmed')
                Padding(
                  padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: Text(
                    '"Khách đã đến" chỉ để quản lý bàn, không cấp nhãn 🍽 cho đánh giá của khách.',
                    style: QuanAnText.bodySmall,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => QuanAnDieuHuong.chat(
                    context,
                    dv,
                    b.svId,
                    quanId: b.quanId,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Nhắn tin với khách'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
