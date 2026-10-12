import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../services/dat_coc_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/chinh_sach_coc_box.dart';
import '../../widgets/chon_thoi_diem_nhan_phong.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tuong_tac/thanh_toan_screen.dart';

/// TRO-SV-07 Đặt cọc: chọn thời điểm nhận phòng (ngày + giờ), chính sách cọc, điều khoản nhận phòng 48 giờ,
/// số lần hủy miễn phí còn lại. Cần đã OTP và không bị khóa cọc (mục 2.4 Bước 3).
class DatCocScreen extends StatefulWidget {
  const DatCocScreen({required this.dv, required this.phong, super.key});

  final TroDichVu dv;
  final PhongTro phong;

  @override
  State<DatCocScreen> createState() => _DatCocScreenState();
}

class _DatCocScreenState extends State<DatCocScreen> {
  DateTime? _t;
  String? _loiT;
  bool _dongYChinhSach = false;
  bool _dongYDieuKhoan = false;
  bool _dangGui = false;
  late final Future<TroConfig> _cfg = widget.dv.datCoc.cauHinh();
  Future<ThongTinDatCoc>? _thongTin;

  Future<void> _gui(TroConfig cfg) async {
    final now = DateTime.now();
    final loi = kiemTraThoiDiem(
      _t,
      now: now,
      itNhat: TroConfig.phut(cfg.nhanPhongSauItNhatPhut),
      toiDa: TroConfig.phut(cfg.nhanPhongToiDaPhut),
      ngayVaoO: widget.phong.ngayVaoO,
      moc: 'lúc cọc',
    );
    setState(() => _loiT = loi);
    if (loi != null || !_dongYChinhSach || !_dongYDieuKhoan) return;
    setState(() => _dangGui = true);
    String? id;
    final ok = await chayThaoTac(
      context,
      () async =>
          id = await widget.dv.datCoc.taoCoc(phongId: widget.phong.id, t: _t!),
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok && id != null) {
      await Navigator.of(context).pushReplacement(
        troRoute((_) => ThanhToanScreen(dv: widget.dv, datCocId: id!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt cọc giữ phòng')),
      body: TroStream<XacThuc>(
        stream: () => widget.dv.xacThuc.cuaToi(widget.dv.uid),
        builder: (context, xt) {
          if (!xt.daOtp) {
            return TroEmptyState(
              icon: Icons.phone_iphone,
              title: 'Cần xác thực số điện thoại',
              message: 'Đặt cọc trên app cần số điện thoại đã xác thực (OTP).',
              actionLabel: 'Xác thực ngay',
              onAction: () => TroDieuHuong.mo(
                context,
                (_) => XacThucSdtScreen(service: widget.dv.xacThuc),
              ),
            );
          }
          _thongTin ??= widget.dv.datCoc.thongTin();
          return FutureBuilder<(TroConfig, ThongTinDatCoc)>(
            future: Future.wait([_cfg, _thongTin!])
                .then((v) => (v[0] as TroConfig, v[1] as ThongTinDatCoc)),
            builder: (context, s) {
              if (s.hasError) {
                return TroErrorState(
                  onRetry: () =>
                      setState(() => _thongTin = widget.dv.datCoc.thongTin()),
                );
              }
              if (!s.hasData) return const TroSkeletonList(count: 1);
              final (cfg, tt) = s.data!;
              if (tt.khoaCocDen != null &&
                  tt.khoaCocDen!.isAfter(DateTime.now())) {
                return TroEmptyState(
                  icon: Icons.lock_clock,
                  title: 'Bạn đang bị khóa đặt cọc trên app',
                  message:
                      'Tới ${formatNgayGio(tt.khoaCocDen!)}. Bạn có thể kháng nghị trong mục "Của tôi".',
                );
              }
              return _noiDung(cfg, tt);
            },
          );
        },
      ),
    );
  }

  Widget _noiDung(TroConfig cfg, ThongTinDatCoc tt) {
    final p = widget.phong;
    return ListView(
      padding: const EdgeInsets.all(TroSpacing.screen),
      children: [
        Card(
          child: ListTile(
            title: Text('Phòng ${p.ten}', style: TroText.h3),
            subtitle: Text(p.nhaTro?.ten ?? ''),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Tiền cọc', style: TroText.bodySmall),
                Text(formatPrice(p.tienCoc), style: TroText.price),
              ],
            ),
          ),
        ),
        const SizedBox(height: TroSpacing.lg),
        ChonThoiDiemNhanPhong(
          giaTri: _t,
          loi: _loiT,
          onChanged: (t) => setState(() {
            _t = t;
            _loiT = null;
          }),
        ),
        const SizedBox(height: TroSpacing.xs),
        Text(
          'Cách lúc cọc ít nhất ${TroConfig.phut(cfg.nhanPhongSauItNhatPhut).inHours} giờ, không trước ngày có thể vào ở'
          '${p.ngayVaoO != null ? ' (${formatNgay(p.ngayVaoO!)})' : ''}, không quá ${TroConfig.phut(cfg.nhanPhongToiDaPhut).inDays} ngày.',
          style: TroText.bodySmall,
        ),
        const SizedBox(height: TroSpacing.lg),
        Container(
          padding: const EdgeInsets.all(TroSpacing.md),
          decoration: BoxDecoration(
            color: tt.conHuyMienPhi > 0
                ? TroColors.successSoft
                : TroColors.warningSoft,
            borderRadius: BorderRadius.circular(TroRadius.input),
          ),
          child: Text(
            tt.conHuyMienPhi > 0
                ? 'Bạn còn ${tt.conHuyMienPhi} lần hủy miễn phí (hủy trong ${cfg.huyMienPhiPhut} phút đầu được hoàn 100%).'
                : 'Bạn đã dùng hết ${cfg.huyMienPhiSoLan} lần hủy miễn phí trong 30 ngày: khoản cọc này không có nút hủy miễn phí.',
            style: TroText.body,
          ),
        ),
        const SizedBox(height: TroSpacing.lg),
        ChinhSachCocBox(
          dongYChinhSach: _dongYChinhSach,
          dongYDieuKhoan: _dongYDieuKhoan,
          onChinhSach: (v) => setState(() => _dongYChinhSach = v),
          onDieuKhoan: (v) => setState(() => _dongYDieuKhoan = v),
        ),
        const SizedBox(height: TroSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: !_dongYChinhSach || !_dongYDieuKhoan || _dangGui
                ? null
                : () => _gui(cfg),
            child: _dangGui
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TroColors.white,
                    ),
                  )
                : Text('Thanh toán ${formatPrice(p.tienCoc)}'),
          ),
        ),
        const SizedBox(height: TroSpacing.sm),
        Text(
          'Phòng được khóa cho riêng bạn trong ${cfg.choThanhToanPhut} phút để thanh toán. Tiền cọc được app giữ tới khi bạn nhận phòng.',
          style: TroText.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
