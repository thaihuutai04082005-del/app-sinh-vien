import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/don_mon_service.dart' show ThongTinSinhVien;
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'chi_tiet_dat_ban_screen.dart';

String _dai(Duration d) => d.inDays >= 1
    ? '${d.inDays} ngày'
    : d.inHours >= 1
    ? '${d.inHours} giờ'
    : '${d.inMinutes} phút';

/// Kiểm tra giờ hẹn đặt bàn (mục 3.4 Bước 4): ≥ [QuanAnConfig.datBanCachItNhatPhut] kể từ bây giờ,
/// trong [QuanAnConfig.datBanTruocToiDaNgay] ngày tới, trong giờ mở cửa của quán và không rơi vào lúc
/// quán tạm nghỉ. Trả về lỗi tiếng Việt hoặc null. Hệ thống kiểm tra lại khi gửi.
String? kiemTraGioDatBan(
  DateTime? t, {
  required DateTime now,
  required QuanAnConfig cfg,
  required QuanAn quan,
}) {
  if (t == null) return 'Chọn ngày và giờ đến.';
  final itNhat = QuanAnConfig.phut(cfg.datBanCachItNhatPhut);
  if (t.isBefore(now.add(itNhat))) {
    return 'Giờ hẹn phải cách bây giờ ít nhất ${_dai(itNhat)}.';
  }
  if (t.isAfter(now.add(Duration(days: cfg.datBanTruocToiDaNgay)))) {
    return 'Chỉ đặt bàn trong ${cfg.datBanTruocToiDaNgay} ngày tới.';
  }
  final nghi = quan.tamNghiDen;
  if (nghi != null && t.isBefore(nghi)) {
    return 'Quán đang tạm nghỉ vào giờ này, chọn giờ khác.';
  }
  if (!coMoTai(quan.gioMoCua, t)) {
    return 'Giờ này quán không mở cửa, chọn giờ trong giờ mở cửa.';
  }
  return null;
}

/// Chọn ngày + giờ (giờ Việt Nam), dùng cho đặt bàn và hẹn giờ lấy món — cùng kiểu với
/// bộ chọn thời điểm nhận phòng của Tìm trọ.
class ChonNgayGioQuanAn extends StatelessWidget {
  const ChonNgayGioQuanAn({
    required this.giaTri,
    required this.onChanged,
    this.loi,
    this.nhan = 'Ngày giờ',
    this.ngayDau,
    this.ngayCuoi,
    super.key,
  });

  final DateTime? giaTri;
  final ValueChanged<DateTime> onChanged;
  final String? loi;
  final String nhan;
  final DateTime? ngayDau;
  final DateTime? ngayCuoi;

  Future<void> _chon(BuildContext context) async {
    final now = DateTime.now();
    final dau = DateTime(
      (ngayDau ?? now).year,
      (ngayDau ?? now).month,
      (ngayDau ?? now).day,
    );
    final cuoi = ngayCuoi ?? now.add(const Duration(days: 7));
    var khoiTao = giaTri ?? now.add(const Duration(hours: 2));
    if (khoiTao.isBefore(dau)) khoiTao = dau;
    if (khoiTao.isAfter(cuoi)) khoiTao = cuoi;
    final ngay = await showDatePicker(
      context: context,
      initialDate: khoiTao,
      firstDate: dau,
      lastDate: cuoi.isBefore(dau) ? dau : cuoi,
      helpText: 'Chọn ngày',
    );
    if (ngay == null || !context.mounted) return;
    final gio = await showTimePicker(
      context: context,
      initialTime: giaTri == null
          ? TimeOfDay.fromDateTime(khoiTao)
          : TimeOfDay.fromDateTime(giaTri!),
      helpText: 'Chọn giờ',
    );
    if (gio == null) return;
    // Người dùng chọn theo giờ Việt Nam (UTC+7).
    onChanged(
      DateTime.utc(
        ngay.year,
        ngay.month,
        ngay.day,
        gio.hour,
        gio.minute,
      ).subtract(const Duration(hours: 7)).toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _chon(context),
    borderRadius: BorderRadius.circular(QuanAnRadius.input),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: nhan,
          errorText: loi,
          errorMaxLines: 3,
          suffixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(
          giaTri == null ? 'Chọn ngày + giờ' : formatNgayGio(giaTri!),
          style: QuanAnText.body,
        ),
      ),
    ),
  );
}

/// QA-SV-10 Đặt bàn (không thu tiền): ngày giờ, số người, ghi chú; nêu rõ quy tắc hủy sát giờ,
/// bỏ hẹn và khóa. Cần đã OTP và không bị khóa đặt bàn (mục 3.4 Bước 4, 3.5e).
class DatBanScreen extends StatefulWidget {
  const DatBanScreen({required this.dv, required this.quan, super.key});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<DatBanScreen> createState() => _DatBanScreenState();
}

class _DatBanScreenState extends State<DatBanScreen> {
  DateTime? _gio;
  String? _loiGio;
  int _soNguoi = 2;
  final _ghiChu = TextEditingController();
  bool _dangGui = false;
  late final Future<(QuanAnConfig, ThongTinSinhVien)> _nap = _taiNap();

  Future<(QuanAnConfig, ThongTinSinhVien)> _taiNap() async {
    final cfg = await widget.dv.donMon.cauHinh();
    ThongTinSinhVien tt;
    try {
      tt = await widget.dv.donMon.thongTinSinhVien();
    } catch (_) {
      tt = const ThongTinSinhVien();
    }
    return (cfg, tt);
  }

  @override
  void dispose() {
    _ghiChu.dispose();
    super.dispose();
  }

  Future<void> _gui(QuanAnConfig cfg) async {
    if (_dangGui) return;
    final loi = kiemTraGioDatBan(
      _gio,
      now: DateTime.now(),
      cfg: cfg,
      quan: widget.quan,
    );
    setState(() => _loiGio = loi);
    if (loi != null) return;
    setState(() => _dangGui = true);
    String? id;
    final ok = await chayThaoTac(
      context,
      () async => id = await widget.dv.datBan.guiDatBan(
        quanId: widget.quan.id,
        gio: _gio!,
        soNguoi: _soNguoi,
        ghiChu: _ghiChu.text.trim(),
      ),
      thanhCong: 'Đã gửi yêu cầu đặt bàn',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok && id != null) {
      await Navigator.of(context).pushReplacement(
        quanAnRoute((_) => ChiTietDatBanScreen(dv: widget.dv, banId: id!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt bàn')),
    body: !widget.quan.nhanDatBanQuaApp
        ? const QuanAnEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Quán chưa nhận đặt bàn qua app',
            message: 'Bạn có thể nhắn tin hoặc gọi điện cho quán.',
          )
        : QuanAnStream<XacThuc>(
            stream: () => widget.dv.xacThuc.cuaToi(widget.dv.uid),
            builder: (context, xt) {
              if (!xt.daOtp) {
                return QuanAnEmptyState(
                  icon: Icons.phone_iphone,
                  title: 'Cần xác thực số điện thoại',
                  message: 'Đặt bàn cần số điện thoại đã xác thực (OTP).',
                  actionLabel: 'Xác thực ngay',
                  onAction: () => QuanAnDieuHuong.mo(
                    context,
                    (_) => XacThucSdtScreen(service: widget.dv.xacThuc),
                  ),
                );
              }
              return FutureBuilder<(QuanAnConfig, ThongTinSinhVien)>(
                future: _nap,
                builder: (context, s) {
                  if (s.hasError) {
                    return QuanAnErrorState(onRetry: () => setState(() {}));
                  }
                  if (!s.hasData) return const QuanAnSkeletonList(count: 1);
                  final (cfg, tt) = s.data!;
                  if (tt.datBanBiKhoa(DateTime.now())) {
                    return QuanAnEmptyState(
                      icon: Icons.lock_clock,
                      title: 'Bạn đang bị khóa đặt bàn',
                      message:
                          'Tới ${formatNgayGio(tt.khoaDatBanDen!)}. Bạn có thể kháng nghị trong mục "Của tôi".',
                    );
                  }
                  return _form(cfg);
                },
              );
            },
          ),
  );

  Widget _form(QuanAnConfig cfg) {
    final nMin = cfg.datBanSoNguoiToiThieu;
    final nMax = cfg.datBanSoNguoiToiDa;
    final huySat = _dai(QuanAnConfig.phut(cfg.huySatGioPhut));
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(QuanAnSpacing.screen),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.table_restaurant_outlined,
                        color: QuanAnColors.primary,
                      ),
                      title: Text(
                        widget.quan.ten,
                        style: QuanAnText.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        widget.quan.diaChi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(QuanAnSpacing.md),
                    decoration: BoxDecoration(
                      color: QuanAnColors.successSoft,
                      borderRadius: BorderRadius.circular(QuanAnRadius.input),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.money_off_rounded,
                          color: QuanAnColors.success,
                        ),
                        SizedBox(width: QuanAnSpacing.sm),
                        Expanded(
                          child: Text(
                            'Không thu tiền: đặt bàn chỉ để quán giữ chỗ cho bạn.',
                            style: QuanAnText.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  ChonNgayGioQuanAn(
                    nhan: 'Ngày giờ đến',
                    giaTri: _gio,
                    loi: _loiGio,
                    ngayCuoi: DateTime.now().add(
                      Duration(days: cfg.datBanTruocToiDaNgay),
                    ),
                    onChanged: (t) => setState(() {
                      _gio = t;
                      _loiGio = null;
                    }),
                  ),
                  const SizedBox(height: QuanAnSpacing.xs),
                  Text(
                    'Cách bây giờ ít nhất ${_dai(QuanAnConfig.phut(cfg.datBanCachItNhatPhut))}, trong ${cfg.datBanTruocToiDaNgay} ngày tới và trong giờ mở cửa của quán.',
                    style: QuanAnText.bodySmall,
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Số người', style: QuanAnText.h3),
                      ),
                      IconButton(
                        tooltip: 'Bớt một người',
                        onPressed: _soNguoi > nMin
                            ? () => setState(() => _soNguoi--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_soNguoi',
                          style: QuanAnText.h2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Thêm một người',
                        onPressed: _soNguoi < nMax
                            ? () => setState(() => _soNguoi++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Từ $nMin đến $nMax người.',
                    style: QuanAnText.bodySmall,
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  TextField(
                    controller: _ghiChu,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú cho quán (không bắt buộc)',
                      hintText: 'Ví dụ: cần ghế trẻ em, ngồi gần cửa sổ',
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(QuanAnSpacing.md),
                    decoration: BoxDecoration(
                      color: QuanAnColors.warningSoft,
                      borderRadius: BorderRadius.circular(QuanAnRadius.input),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quy tắc cần biết', style: QuanAnText.label),
                        const SizedBox(height: QuanAnSpacing.xs),
                        _Dong(
                          'Quán xác nhận trong ${cfg.datBanQuanXacNhanPhut} phút nhưng không muộn hơn giờ hẹn − ${cfg.datBanTruocGioHenPhut} phút; không trả lời thì yêu cầu tự hết hạn.',
                        ),
                        _Dong(
                          'Quán giữ bàn ${cfg.giuBanPhut} phút kể từ giờ hẹn. Tới nơi, hãy check-in trong app.',
                        ),
                        _Dong(
                          'Hủy khi quán chưa xác nhận: không bị phạt. Bàn đã xác nhận: hủy trước giờ hẹn ít nhất $huySat thì không phạt; hủy sát giờ (dưới $huySat) hoặc không đến tính 1 lần bỏ hẹn.',
                        ),
                        _Dong(
                          '${cfg.khoaDatBanSoLan} lần bỏ hẹn trong ${cfg.chiSoNgay} ngày: khóa đặt bàn ${cfg.khoaDatBanNgay} ngày (kháng nghị được).',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _ThanhDuoi(dangGui: _dangGui, onGui: () => _gui(cfg)),
      ],
    );
  }
}

class _Dong extends StatelessWidget {
  const _Dong(this.noiDung);

  final String noiDung;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: QuanAnText.bodySmall),
        Expanded(child: Text(noiDung, style: QuanAnText.bodySmall)),
      ],
    ),
  );
}

class _ThanhDuoi extends StatelessWidget {
  const _ThanhDuoi({required this.dangGui, required this.onGui});

  final bool dangGui;
  final VoidCallback onGui;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: QuanAnColors.white,
      boxShadow: [
        BoxShadow(
          color: QuanAnColors.primary.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: dangGui ? null : onGui,
                child: dangGui
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: QuanAnColors.white,
                        ),
                      )
                    : const Text('Gửi yêu cầu đặt bàn'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
