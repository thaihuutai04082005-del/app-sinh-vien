import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/thanh_toan.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'dang_quan_screen.dart';
import 'quan_ly_dat_ban_screen.dart';
import 'quan_ly_don_screen.dart';
import 'quan_ly_quan_screen.dart';
import 'vi_screen.dart';

/// Trung tâm của chủ quán: đơn mới cần nhận (có chuông), tiền đang giữ / đã nhận, chỉ số
/// công khai, danh sách quán của tôi và lối tắt Đơn hàng · Đặt bàn · Ví.
///
/// Quán chưa được duyệt (nháp / bị từ chối) mở form sửa; quán khác mở bảng quản lý.
/// Chỉ chủ quán đã OTP + xác nhận người thật mới gửi duyệt được.
class QuanLyTongQuanScreen extends StatefulWidget {
  const QuanLyTongQuanScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  State<QuanLyTongQuanScreen> createState() => _QuanLyTongQuanScreenState();
}

class _QuanLyTongQuanScreenState extends State<QuanLyTongQuanScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();

  QuanAnDichVu get dv => widget.dv;

  // Mỗi luồng tạo một lần (và cho nhiều nơi nghe) để số liệu không chớp khi màn hình dựng lại.
  late final Stream<int> _donMoi = dv.donMon
      .donMoiCuaQuan(dv.uid)
      .asBroadcastStream();
  late final Stream<int> _banCho = dv.datBan
      .banChoXacNhan(dv.uid)
      .asBroadcastStream();
  late final Stream<ViChuQuan> _vi = dv.donMon.vi(dv.uid).asBroadcastStream();
  late final Stream<ChiSoChuQuan> _chiSo = dv.quan
      .chiSoChu(dv.uid)
      .asBroadcastStream();
  late final Stream<XacThuc> _xacThuc = dv.xacThuc
      .cuaToi(dv.uid)
      .asBroadcastStream();

  @override
  void initState() {
    super.initState();
    dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
  }

  Future<void> _moDon() =>
      QuanAnDieuHuong.mo(context, (_) => QuanLyDonScreen(dv: dv));
  Future<void> _moBan() =>
      QuanAnDieuHuong.mo(context, (_) => QuanLyDatBanScreen(dv: dv));
  Future<void> _moVi() => QuanAnDieuHuong.mo(context, (_) => ViScreen(dv: dv));
  Future<void> _taoQuan() =>
      QuanAnDieuHuong.mo(context, (_) => DangQuanScreen(dv: dv));

  Future<void> _moQuan(QuanAn q) => QuanAnDieuHuong.mo(
    context,
    (_) => q.suaNhapDuoc
        ? DangQuanScreen(dv: dv, quan: q)
        : QuanLyQuanScreen(dv: dv, quanId: q.id),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý quán ăn'),
      actions: [ChuongDonMoi(stream: () => _donMoi, onTap: _moDon)],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _taoQuan,
      icon: const Icon(Icons.add_business_outlined),
      label: const Text('Tạo quán'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        QuanAnSpacing.screen,
        QuanAnSpacing.screen,
        QuanAnSpacing.screen,
        96,
      ),
      child: TrangRong(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CanhBaoXacThuc(dv: dv, stream: _xacThuc),
            _DonMoi(
              donMoi: _donMoi,
              banCho: _banCho,
              onDon: _moDon,
              onBan: _moBan,
            ),
            const SizedBox(height: QuanAnSpacing.md),
            _Vi(stream: _vi, onTap: _moVi),
            const SizedBox(height: QuanAnSpacing.md),
            _ChiSo(stream: _chiSo, cfg: _cfg),
            const SizedBox(height: QuanAnSpacing.md),
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _moDon,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Đơn hàng'),
                ),
                OutlinedButton.icon(
                  onPressed: _moBan,
                  icon: const Icon(Icons.event_seat_outlined),
                  label: const Text('Đặt bàn'),
                ),
                OutlinedButton.icon(
                  onPressed: _moVi,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Ví'),
                ),
              ],
            ),
            const SizedBox(height: QuanAnSpacing.xl),
            const Text('Quán của tôi', style: QuanAnText.h2),
            const SizedBox(height: QuanAnSpacing.sm),
            QuanAnStream<List<QuanAn>>(
              stream: () => dv.quan.quanCuaToi(dv.uid),
              thongBaoLoi: 'Không tải được danh sách quán',
              builder: (context, ds) => ds.isEmpty
                  ? QuanAnEmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Bạn chưa có quán nào',
                      message: 'Tạo quán (làm một lần), được duyệt rồi thêm menu và nhận đơn.',
                      actionLabel: 'Tạo quán',
                      onAction: _taoQuan,
                    )
                  : Column(
                      children: [
                        _ViecCanLam(quan: ds, onMo: _moQuan),
                        for (final q in ds)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: QuanAnSpacing.sm,
                            ),
                            child: _TheQuan(quan: q, onTap: () => _moQuan(q)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Chưa OTP / chưa xác nhận người thật: cảnh báo + nút xác thực (như Tìm trọ).
class _CanhBaoXacThuc extends StatelessWidget {
  const _CanhBaoXacThuc({required this.dv, required this.stream});

  final QuanAnDichVu dv;
  final Stream<XacThuc> stream;

  @override
  Widget build(BuildContext context) => StreamBuilder<XacThuc>(
    stream: stream,
    builder: (context, s) {
      if (!s.hasData) return const SizedBox.shrink();
      final xt = s.data!;
      if (xt.daOtp && xt.daXacThucDanhTinh) return const SizedBox.shrink();
      final chuaOtp = !xt.daOtp;
      return Padding(
        padding: const EdgeInsets.only(bottom: QuanAnSpacing.md),
        child: HopThongBao.canhBao(
          noiDung: chuaOtp
              ? 'Cần xác thực số điện thoại trước khi gửi quán đi duyệt.'
              : 'Chưa xác nhận người thật: ${XacThuc.danhTinhLabels[xt.danhTinh]}. '
                    'Bạn vẫn tạo và lưu nháp quán được, nhưng chưa gửi duyệt được.',
          child: chuaOtp || xt.danhTinh != 'cho_duyet'
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => QuanAnDieuHuong.mo(
                      context,
                      (_) => chuaOtp
                          ? XacThucSdtScreen(service: dv.xacThuc)
                          : XacNhanDanhTinhScreen(service: dv.xacThuc),
                    ),
                    child: Text(
                      chuaOtp
                          ? 'Xác thực số điện thoại'
                          : 'Xác nhận người thật',
                    ),
                  ),
                )
              : null,
        ),
      );
    },
  );
}

/// Thẻ "Đơn mới cần nhận" (đếm từ `donMoiCuaQuan`, có chuông) + đặt bàn chờ xác nhận.
class _DonMoi extends StatelessWidget {
  const _DonMoi({
    required this.donMoi,
    required this.banCho,
    required this.onDon,
    required this.onBan,
  });

  final Stream<int> donMoi;
  final Stream<int> banCho;
  final VoidCallback onDon;
  final VoidCallback onBan;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final hai = c.maxWidth >= 560;
      final don = StreamBuilder<int>(
        stream: donMoi,
        builder: (context, s) => _ODem(
          icon: (s.data ?? 0) > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          tieuDe: 'Đơn mới cần nhận',
          so: s.hasError ? null : s.data,
          phu: s.hasError
              ? 'Không tải được số đơn'
              : ((s.data ?? 0) > 0
                    ? 'Bấm để nhận hoặc từ chối'
                    : 'Chưa có đơn mới'),
          noiBat: (s.data ?? 0) > 0,
          onTap: onDon,
        ),
      );
      final ban = StreamBuilder<int>(
        stream: banCho,
        builder: (context, s) => _ODem(
          icon: Icons.event_seat_outlined,
          tieuDe: 'Đặt bàn chờ xác nhận',
          so: s.hasError ? null : s.data,
          phu: s.hasError
              ? 'Không tải được số bàn'
              : ((s.data ?? 0) > 0 ? 'Bấm để xác nhận' : 'Chưa có yêu cầu'),
          noiBat: (s.data ?? 0) > 0,
          onTap: onBan,
        ),
      );
      return hai
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: don),
                const SizedBox(width: QuanAnSpacing.md),
                Expanded(child: ban),
              ],
            )
          : Column(
              children: [
                don,
                const SizedBox(height: QuanAnSpacing.md),
                ban,
              ],
            );
    },
  );
}

class _ODem extends StatelessWidget {
  const _ODem({
    required this.icon,
    required this.tieuDe,
    required this.so,
    required this.phu,
    required this.noiBat,
    required this.onTap,
  });

  final IconData icon;
  final String tieuDe;
  final int? so;
  final String phu;
  final bool noiBat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: noiBat ? QuanAnColors.warningSoft : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(QuanAnRadius.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(QuanAnSpacing.lg),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: noiBat ? QuanAnColors.warning : QuanAnColors.primary,
            ),
            const SizedBox(width: QuanAnSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tieuDe, style: QuanAnText.bodySmall),
                  Text(
                    so == null ? '—' : '$so',
                    style: QuanAnText.display.copyWith(
                      color: noiBat
                          ? QuanAnColors.warning
                          : QuanAnColors.primary,
                    ),
                  ),
                  Text(phu, style: QuanAnText.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: QuanAnColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Vi extends StatelessWidget {
  const _Vi({required this.stream, required this.onTap});

  final Stream<ViChuQuan> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => StreamBuilder<ViChuQuan>(
    stream: stream,
    builder: (context, s) {
      final v = s.data;
      Widget o(String t, String gia, String phu, Color mau) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(QuanAnRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: QuanAnText.bodySmall),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(gia, style: QuanAnText.h1.copyWith(color: mau)),
                ),
                Text(phu, style: QuanAnText.bodySmall),
              ],
            ),
          ),
        ),
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: o(
              'Tiền app đang giữ',
              v == null ? '—' : formatPrice(v.dangGiu),
              'Chuyển khi đơn hoàn tất',
              QuanAnColors.primary,
            ),
          ),
          const SizedBox(width: QuanAnSpacing.md),
          Expanded(
            child: o(
              'Đã nhận',
              v == null ? '—' : formatPrice(v.daNhan),
              'Đơn trả trên app',
              QuanAnColors.success,
            ),
          ),
        ],
      );
    },
  );
}

/// Chỉ số công khai của chủ quán: tỷ lệ phản hồi · nhận đơn · giữ bàn.
class _ChiSo extends StatelessWidget {
  const _ChiSo({required this.stream, required this.cfg});

  final Stream<ChiSoChuQuan> stream;
  final QuanAnConfig cfg;

  @override
  Widget build(BuildContext context) => StreamBuilder<ChiSoChuQuan>(
    stream: stream,
    builder: (context, s) {
      final c = s.data;
      String pt(int? v) => v == null ? 'Chưa có' : '$v%';
      Widget o(String t, String v, String phu) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: QuanAnText.bodySmall),
            Text(v, style: QuanAnText.h2.copyWith(color: QuanAnColors.primary)),
            Text(phu, style: QuanAnText.bodySmall),
          ],
        ),
      );
      return KhoiThongTin(
        tieuDe: 'Chỉ số công khai',
        phu:
            'Khách thấy các chỉ số này ở trang quán (tính ${cfg.chiSoNgay} ngày gần nhất).',
        child: s.hasError
            ? const Text('Không tải được chỉ số.', style: QuanAnText.bodySmall)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      o('Phản hồi tin nhắn', pt(c?.tyLePhanHoi), 'Trả lời kịp'),
                      const SizedBox(width: QuanAnSpacing.sm),
                      o('Nhận đơn', pt(c?.tyLeNhanDon), 'Đơn quán nhận'),
                      const SizedBox(width: QuanAnSpacing.sm),
                      o('Giữ bàn', pt(c?.tyLeGiuBan), 'Bàn không hủy'),
                    ],
                  ),
                  if ((c?.soCanhCao ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                      child: Text(
                        'Có ${c!.soCanhCao} cảnh cáo gần đây.',
                        style: QuanAnText.bodySmall.copyWith(
                          color: QuanAnColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

/// Việc cần làm rút từ danh sách quán: bị từ chối, cần xác nhận còn hoạt động, khai sai loại.
class _ViecCanLam extends StatelessWidget {
  const _ViecCanLam({required this.quan, required this.onMo});

  final List<QuanAn> quan;
  final void Function(QuanAn) onMo;

  @override
  Widget build(BuildContext context) {
    final viec = <(IconData, String, QuanAn)>[];
    for (final q in quan) {
      if (q.trangThai == 'rejected') {
        viec.add((
          Icons.error_outline,
          '"${q.ten}" bị từ chối: ${q.lyDoTuChoi ?? 'xem chi tiết'}. Sửa rồi gửi lại.',
          q,
        ));
      }
      if (q.hanXacNhanHoatDong != null &&
          (q.trangThai == 'active' || q.trangThai == 'hidden')) {
        viec.add((
          Icons.update,
          '"${q.ten}": bấm "Quán vẫn hoạt động" trước ${formatNgayGio(q.hanXacNhanHoatDong!)}',
          q,
        ));
      }
      if (q.khaiSaiLoai?.hanChuyen != null) {
        viec.add((
          Icons.report_problem_outlined,
          '"${q.ten}" bị yêu cầu chuyển loại quán trước ${formatNgayGio(q.khaiSaiLoai!.hanChuyen!)}',
          q,
        ));
      }
    }
    if (viec.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: QuanAnSpacing.md),
      child: Card(
        color: QuanAnColors.warningSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Việc cần làm', style: QuanAnText.h3),
            ),
            for (final (i, t, q) in viec)
              ListTile(
                minVerticalPadding: 12,
                leading: Icon(i, color: QuanAnColors.warning),
                title: Text(t),
                onTap: () => onMo(q),
              ),
          ],
        ),
      ),
    );
  }
}

class _TheQuan extends StatelessWidget {
  const _TheQuan({required this.quan, required this.onTap});

  final QuanAn quan;
  final VoidCallback onTap;

  static QuanAnBadgeKind kieu(String s) => switch (s) {
    'active' => QuanAnBadgeKind.moCua,
    'pending_review' || 'draft' => QuanAnBadgeKind.canhBao,
    'hidden' => QuanAnBadgeKind.tamNghi,
    _ => QuanAnBadgeKind.dongCua,
  };

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final phu = [
      q.loaiQuanLabel,
      if (q.trangThai == 'active') '${q.soLieu.soMon} món',
      if (q.coBanChinhSua) 'có chỉnh sửa chờ duyệt',
      if (q.suaNhapDuoc) 'bấm để sửa và gửi duyệt',
    ].join(' · ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.ten.isEmpty ? '(Quán chưa đặt tên)' : q.ten,
                        style: QuanAnText.h3,
                      ),
                      Text(phu, style: QuanAnText.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: QuanAnSpacing.sm),
                Flexible(
                  child: QuanAnStatusBadge(
                    kind: kieu(q.trangThai),
                    label: q.trangThaiLabel,
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
