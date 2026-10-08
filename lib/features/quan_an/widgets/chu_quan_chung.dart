import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'quan_an_theme.dart';

/// Thành phần dùng chung của các màn hình phía chủ quán (không phải màn hình riêng).

/// Khung lỗi đỏ cố định (đặt ngay trên nút bấm, không phải cuộn mới thấy).
/// Lỗi báo bằng chữ, không chỉ đổi màu viền.
class KhungLoiDo extends StatelessWidget {
  const KhungLoiDo(
    this.loi, {
    this.tieuDe = 'Chưa qua được bước này, cần sửa:',
    super.key,
  });

  final List<String> loi;
  final String tieuDe;

  @override
  Widget build(BuildContext context) => loi.isEmpty
      ? const SizedBox.shrink()
      : Container(
          width: double.infinity,
          color: QuanAnColors.dangerSoft,
          padding: const EdgeInsets.symmetric(
            horizontal: QuanAnSpacing.screen,
            vertical: QuanAnSpacing.md,
          ),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tieuDe,
                  style: const TextStyle(
                    color: QuanAnColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final l in loi)
                  Text(
                    '• $l',
                    style: const TextStyle(color: QuanAnColors.danger),
                  ),
              ],
            ),
          ),
        );
}

/// Thanh dưới cùng cố định: khung lỗi đỏ + hàng nút (nút chính nằm trong [children]).
class ThanhDuoiForm extends StatelessWidget {
  const ThanhDuoiForm({required this.child, this.loi = const [], super.key});

  final Widget child;
  final List<String> loi;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KhungLoiDo(loi, tieuDe: 'Chưa lưu được, cần sửa:'),
      Container(
        decoration: BoxDecoration(
          color: QuanAnColors.white,
          boxShadow: QuanAnTheme.softShadow,
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(QuanAnSpacing.screen),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Căn giữa nội dung với bề rộng tối đa (màn rộng không bị kéo dãn).
class TrangRong extends StatelessWidget {
  const TrangRong({required this.child, this.rongToiDa = 960, super.key});

  final Widget child;
  final double rongToiDa;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: rongToiDa),
      child: child,
    ),
  );
}

/// Danh sách thẻ cuộn được: 1 cột trên điện thoại, nhiều cột khi màn rộng.
class LuoiCuon extends StatelessWidget {
  const LuoiCuon({
    required this.children,
    this.cotToiDa = 2,
    this.chanTren = 0,
    super.key,
  });

  final List<Widget> children;
  final int cotToiDa;
  final double chanTren;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final rong = c.maxWidth;
      final cot = rong >= 1000 ? cotToiDa : 1;
      final le = EdgeInsets.fromLTRB(
        QuanAnSpacing.screen,
        QuanAnSpacing.screen + chanTren,
        QuanAnSpacing.screen,
        QuanAnSpacing.xxxl,
      );
      if (cot == 1) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.separated(
              padding: le,
              itemCount: children.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: QuanAnSpacing.cardGap),
              itemBuilder: (_, i) => children[i],
            ),
          ),
        );
      }
      final dai = (rong < 1400 ? rong : 1400) - le.horizontal;
      final rongCot = (dai - (cot - 1) * QuanAnSpacing.cardGap) / cot;
      return SingleChildScrollView(
        padding: le,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Wrap(
              spacing: QuanAnSpacing.cardGap,
              runSpacing: QuanAnSpacing.cardGap,
              children: [
                for (final w in children) SizedBox(width: rongCot, child: w),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Khối nội dung có tiêu đề, trong thẻ trắng.
class KhoiThongTin extends StatelessWidget {
  const KhoiThongTin({
    required this.tieuDe,
    required this.child,
    this.phu,
    this.mau,
    super.key,
  });

  final String tieuDe;
  final String? phu;
  final Widget child;
  final Color? mau;

  @override
  Widget build(BuildContext context) => Card(
    color: mau,
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe, style: QuanAnText.h3),
          if (phu != null) ...[
            const SizedBox(height: QuanAnSpacing.xs),
            Text(phu!, style: QuanAnText.bodySmall),
          ],
          const SizedBox(height: QuanAnSpacing.md),
          child,
        ],
      ),
    ),
  );
}

/// Khung thông báo nền màu nhạt có icon (cảnh báo / thông tin / thành công).
class HopThongBao extends StatelessWidget {
  const HopThongBao({
    required this.noiDung,
    this.icon = Icons.info_outline_rounded,
    this.nen = QuanAnColors.infoSoft,
    this.chu = QuanAnColors.primaryDark,
    this.child,
    super.key,
  });

  const HopThongBao.canhBao({required this.noiDung, this.child, super.key})
    : icon = Icons.warning_amber_rounded,
      nen = QuanAnColors.warningSoft,
      chu = QuanAnColors.warning;

  const HopThongBao.loi({required this.noiDung, this.child, super.key})
    : icon = Icons.error_outline_rounded,
      nen = QuanAnColors.dangerSoft,
      chu = QuanAnColors.danger;

  const HopThongBao.thanhCong({required this.noiDung, this.child, super.key})
    : icon = Icons.check_circle_outline_rounded,
      nen = QuanAnColors.successSoft,
      chu = QuanAnColors.success;

  final String noiDung;
  final IconData icon;
  final Color nen;
  final Color chu;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(QuanAnSpacing.md),
    decoration: BoxDecoration(
      color: nen,
      borderRadius: BorderRadius.circular(QuanAnRadius.button),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: chu),
            const SizedBox(width: QuanAnSpacing.sm),
            Expanded(
              child: Text(noiDung, style: QuanAnText.body.copyWith(color: chu)),
            ),
          ],
        ),
        if (child != null) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          child!,
        ],
      ],
    ),
  );
}

/// Dựng lại mỗi [chuKy] để đếm ngược / mở nút theo giờ (cấp [DateTime.now]).
class QuanAnDongHo extends StatefulWidget {
  const QuanAnDongHo({
    required this.builder,
    this.chuKy = const Duration(seconds: 1),
    super.key,
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration chuKy;

  @override
  State<QuanAnDongHo> createState() => _QuanAnDongHoState();
}

class _QuanAnDongHoState extends State<QuanAnDongHo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.chuKy, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// "04:32" cho đếm ngược ngắn (không âm).
String phutGiay(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  final p = (s ~/ 60).toString().padLeft(2, '0');
  final g = (s % 60).toString().padLeft(2, '0');
  return '$p:$g';
}

/// "#AB12CD" — mã ngắn của đơn / lượt đặt bàn để chủ quán gọi cho dễ.
String maNgan(String id) {
  final s = id.length > 6 ? id.substring(0, 6) : id;
  return '#${s.toUpperCase()}';
}

/// Số lượng từ kết quả server: số, danh sách hoặc không có.
int demKetQua(Object? v) => switch (v) {
  num n => n.toInt(),
  List l => l.length,
  _ => 0,
};

/// Chuông đơn mới: biểu tượng chuông có số đơn; có đơn mới thì rung + âm báo của hệ thống
/// + thông báo nổi (chỉ khi màn hình này đang ở trên cùng, tránh kêu hai lần).
class ChuongDonMoi extends StatefulWidget {
  const ChuongDonMoi({required this.stream, this.onTap, super.key});

  final Stream<int> Function() stream;
  final VoidCallback? onTap;

  @override
  State<ChuongDonMoi> createState() => _ChuongDonMoiState();
}

class _ChuongDonMoiState extends State<ChuongDonMoi> {
  StreamSubscription<int>? _sub;
  int _so = 0;
  int? _truoc;
  bool _dangOTren = true;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream().listen((n) {
      if (!mounted) return;
      final tang = _truoc != null && n > _truoc!;
      _truoc = n;
      setState(() => _so = n);
      if (tang) _bao();
    }, onError: (_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dangOTren = ModalRoute.of(context)?.isCurrent ?? true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bao() async {
    if (!_dangOTren) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Có đơn mới cần nhận. Hãy xác nhận sớm.')),
    );
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Máy / trình duyệt không hỗ trợ âm báo: bỏ qua, vẫn có số đơn trên chuông.
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _so > 0 ? 'Có $_so đơn mới cần nhận' : 'Chưa có đơn mới',
    onPressed: widget.onTap,
    icon: Badge(
      isLabelVisible: _so > 0,
      backgroundColor: QuanAnColors.danger,
      label: Text('$_so'),
      child: Icon(
        _so > 0
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
      ),
    ),
  );
}

/// Một lối tắt trong trang quản lý.
class MucLoiTat {
  const MucLoiTat({
    required this.icon,
    required this.nhan,
    this.moTa,
    this.onTap,
    this.nguyHiem = false,
    this.dem = 0,
  });

  final IconData icon;
  final String nhan;
  final String? moTa;

  /// null = chưa dùng được (mờ).
  final VoidCallback? onTap;
  final bool nguyHiem;
  final int dem;
}

/// Lưới lối tắt: 1 cột trên điện thoại, 2–3 cột khi màn rộng. Vùng bấm cao ≥ 56.
class LuoiLoiTat extends StatelessWidget {
  const LuoiLoiTat({required this.muc, super.key});

  final List<MucLoiTat> muc;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cot = c.maxWidth >= 840 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
      final rong = (c.maxWidth - (cot - 1) * QuanAnSpacing.md) / cot;
      return Wrap(
        spacing: QuanAnSpacing.md,
        runSpacing: QuanAnSpacing.md,
        children: [
          for (final m in muc)
            SizedBox(
              width: rong,
              child: _LoiTat(m: m),
            ),
        ],
      );
    },
  );
}

class _LoiTat extends StatelessWidget {
  const _LoiTat({required this.m});

  final MucLoiTat m;

  @override
  Widget build(BuildContext context) {
    final bat = m.onTap != null;
    final mau = !bat
        ? QuanAnColors.textDisabled
        : (m.nguyHiem ? QuanAnColors.danger : QuanAnColors.primary);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        onTap: m.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QuanAnSpacing.md,
              vertical: QuanAnSpacing.sm,
            ),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: m.dem > 0,
                  backgroundColor: QuanAnColors.danger,
                  label: Text('${m.dem}'),
                  child: Icon(m.icon, color: mau),
                ),
                const SizedBox(width: QuanAnSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.nhan,
                        style: QuanAnText.label.copyWith(
                          color: bat
                              ? (m.nguyHiem
                                    ? QuanAnColors.danger
                                    : QuanAnColors.textPrimary)
                              : QuanAnColors.textSecondary,
                        ),
                      ),
                      if (m.moTa != null)
                        Text(m.moTa!, style: QuanAnText.bodySmall),
                    ],
                  ),
                ),
                if (bat)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: QuanAnColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kiểu nút viền đỏ cho hành động nguy hiểm (từ chối, hủy, xóa).
ButtonStyle kieuNutNguyHiem() => OutlinedButton.styleFrom(
  foregroundColor: QuanAnColors.danger,
  side: const BorderSide(color: QuanAnColors.danger, width: 1.5),
);

/// Ngày (giờ Việt Nam) → mốc 00:00 giờ Việt Nam, đổi sang UTC.
DateTime dauNgayVn(DateTime ngay) => DateTime.utc(
  ngay.year,
  ngay.month,
  ngay.day,
).subtract(const Duration(hours: 7));

/// Ngày (giờ Việt Nam) → mốc 23:59:59 giờ Việt Nam, đổi sang UTC ("ngày kết thúc tính hết").
DateTime cuoiNgayVn(DateTime ngay) => DateTime.utc(
  ngay.year,
  ngay.month,
  ngay.day,
  23,
  59,
  59,
).subtract(const Duration(hours: 7));
