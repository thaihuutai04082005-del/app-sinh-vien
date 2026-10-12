import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/don_mon.dart';
import '../../models/gio_hang.dart';
import '../../models/quan_an_config.dart';
import '../../models/thanh_toan.dart';
import '../../services/quan_an_api.dart' show ApiException;
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/don_dem_nguoc_tile.dart';
import '../../widgets/don_timeline.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import '../tuong_tac/thanh_toan_screen.dart';
import 'danh_gia_quan_screen.dart';
import 'gio_hang_screen.dart';
import 'khieu_nai_don_screen.dart';

/// QA-SV-08 Theo dõi đơn (sinh viên): dòng thời gian, đếm ngược, mã nhận món, ảnh bằng chứng và các nút
/// hiện theo trạng thái + thời điểm. Hệ thống vẫn kiểm tra lại mọi điều kiện khi bấm (mục 3.4 Bước 5c-5d, 3.5).
/// Mở màn hình là nhờ hệ thống xử lý các hạn đã tới (thấy đúng trạng thái sau hạn).
class TheoDoiDonScreen extends StatefulWidget {
  const TheoDoiDonScreen({required this.dv, required this.donId, super.key});

  final QuanAnDichVu dv;
  final String donId;

  @override
  State<TheoDoiDonScreen> createState() => _TheoDoiDonScreenState();
}

class _TheoDoiDonScreenState extends State<TheoDoiDonScreen> {
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh();

  @override
  void initState() {
    super.initState();
    widget.dv.donMon.xuLyHan(widget.donId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Theo dõi đơn')),
    body: FutureBuilder<QuanAnConfig>(
      future: _cfg,
      builder: (context, c) {
        if (c.hasError) {
          return QuanAnErrorState(onRetry: () => setState(() {}));
        }
        if (!c.hasData) return const QuanAnSkeletonList(count: 1);
        return QuanAnStream<DonMon?>(
          stream: () => widget.dv.donMon.donMon(widget.donId),
          builder: (context, d) => d == null
              ? const QuanAnEmptyState(title: 'Không tìm thấy đơn')
              : _NoiDung(dv: widget.dv, don: d, cfg: c.data!),
        );
      },
    ),
  );
}

QuanAnBadgeKind _kieuBadge(String s) => switch (s) {
  'completed' => QuanAnBadgeKind.moCua,
  'pending_payment' || 'placed' => QuanAnBadgeKind.sapDong,
  'delivered' || 'not_received' || 'disputed' => QuanAnBadgeKind.canhBao,
  'expired' ||
  'cancelled_student' ||
  'rejected' ||
  'expired_accept' ||
  'cancelled_restaurant' => QuanAnBadgeKind.dongCua,
  _ => QuanAnBadgeKind.chung,
};

class _NoiDung extends StatefulWidget {
  const _NoiDung({required this.dv, required this.don, required this.cfg});

  final QuanAnDichVu dv;
  final DonMon don;
  final QuanAnConfig cfg;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  bool _dangXuLy = false;

  QuanAnDichVu get dv => widget.dv;
  DonMon get d => widget.don;

  /// Gửi một thao tác của sinh viên kèm `version` hiện tại; chặn bấm 2 lần.
  Future<void> _lam(Map<String, dynamic> su, {String? ok}) async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    final m = ScaffoldMessenger.of(context);
    try {
      await dv.donMon.thaoTac(d.id, d.version, su);
      if (ok != null) m.showSnackBar(SnackBar(content: Text(ok)));
    } on ApiException catch (e) {
      m.showSnackBar(
        SnackBar(
          content: Text(
            e.message.contains('đã thay đổi')
                ? 'Đơn vừa có thay đổi. Màn hình đã cập nhật, hãy xem lại rồi thử lại.'
                : e.message,
          ),
        ),
      );
    } catch (_) {
      m.showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')),
      );
    }
    if (mounted) setState(() => _dangXuLy = false);
  }

  Future<void> _hoi({
    required String tieuDe,
    required String noiDung,
    required String dongY,
    required Map<String, dynamic> su,
    required String ok,
    bool nguyHiem = false,
  }) async {
    if (await xacNhan(
          context,
          tieuDe: tieuDe,
          noiDung: noiDung,
          dongY: dongY,
          nguyHiem: nguyHiem,
        ) &&
        mounted) {
      await _lam(su, ok: ok);
    }
  }

  void _mo(WidgetBuilder b) => QuanAnDieuHuong.mo(context, b);

  Future<void> _datLai() async {
    final g = dv.gioHang;
    if (g.gio.khacQuan(d.quanId)) {
      final dongY = await xacNhan(
        context,
        tieuDe: 'Xóa giỏ hiện tại?',
        noiDung: 'Giỏ đang có món của quán khác. Đặt lại sẽ xóa giỏ đó và đưa các món của đơn này vào giỏ.',
        dongY: 'Xóa và đặt lại',
      );
      if (!dongY || !mounted) return;
      g.xoaHet();
    }
    for (final m in d.monAn) {
      g.them(
        quanId: d.quanId,
        tenQuan: d.tenQuan,
        dong: DongGioHang(
          monId: m.monId,
          ten: m.ten,
          gia: m.gia,
          soLuong: m.soLuong,
          tuyChon: m.tuyChon,
          ghiChu: m.ghiChu,
          anh: d.anhBia,
        ),
      );
    }
    _mo((_) => GioHangScreen(dv: dv));
  }

  @override
  Widget build(BuildContext context) => DongHoTick(
    chuKy: const Duration(seconds: 1),
    builder: (context, now) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(QuanAnSpacing.screen),
          children: [
            _dau(),
            const SizedBox(height: QuanAnSpacing.md),
            ..._baoDong(now),
            ..._maNhanMon(),
            ..._thongBaoTrangThai(now),
            _chiTietDon(),
            const SizedBox(height: QuanAnSpacing.cardGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(QuanAnSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diễn biến đơn', style: QuanAnText.h3),
                    const SizedBox(height: QuanAnSpacing.md),
                    DonTimeline(don: d),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QuanAnSpacing.xl),
            ..._nut(now),
          ],
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------- Phần đầu

  Widget _dau() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.tenQuan.isEmpty ? 'Đơn món' : d.tenQuan,
              style: QuanAnText.h2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${d.cachNhanLabel} · ${d.laTienMat ? 'Tiền mặt khi nhận' : 'Trả trên app'}',
              style: QuanAnText.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(width: QuanAnSpacing.sm),
      Flexible(
        child: QuanAnStatusBadge(
          kind: _kieuBadge(d.status),
          label: d.trangThaiLabel,
        ),
      ),
    ],
  );

  List<Widget> _baoDong(DateTime now) {
    final moc = d.mocDemNguoc(now, widget.cfg);
    if (moc == null) return const [];
    final nhan = d.status == 'delivered'
        ? 'Chờ xác nhận nhận món, tự hoàn tất sau'
        : moc.$1;
    return [
      DonDemNguocTile(
        nhan: nhan,
        moc: moc.$2,
        canhBao: const {
          'delivered',
          'not_received',
          'disputed',
          'pending_payment',
        }.contains(d.status),
        onHet: () => dv.donMon.xuLyHan(d.id).catchError((_) {}),
      ),
      const SizedBox(height: QuanAnSpacing.md),
    ];
  }

  /// Mã nhận món 4 số: chỉ sinh viên thấy, hiện khi đơn đến lấy "Sẵn sàng".
  List<Widget> _maNhanMon() {
    if (!(d.status == 'ready' && d.laDenLay && d.coNhapMa)) return const [];
    return [
      Card(
        color: QuanAnColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.lg),
          child: Column(
            children: [
              const Text(
                'Mã nhận món của bạn',
                style: QuanAnText.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              StreamBuilder<String?>(
                stream: dv.donMon.maNhanMon(d.id),
                builder: (context, s) {
                  if (s.hasError) {
                    return const Text(
                      'Không tải được mã, hãy mở lại màn hình.',
                      textAlign: TextAlign.center,
                    );
                  }
                  final ma = s.data;
                  if (ma == null || ma.isEmpty) {
                    return const Text(
                      'Đang tạo mã...',
                      style: QuanAnText.bodySmall,
                    );
                  }
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Semantics(
                      label: 'Mã nhận món ${ma.split('').join(' ')}',
                      child: Text(
                        ma.split('').join(' '),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: QuanAnColors.primaryDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              const Text(
                'Đọc mã này cho quán khi tới lấy món. Chỉ đọc cho nhân viên quán, không gửi cho ai khác.',
                style: QuanAnText.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: QuanAnSpacing.md),
    ];
  }

  // ---------------------------------------------------------------- Thông báo theo trạng thái

  List<Widget> _thongBaoTrangThai(DateTime now) {
    final ds = <Widget>[];
    void them(Widget w) =>
        ds.addAll([w, const SizedBox(height: QuanAnSpacing.md)]);

    final ly = d.lyDoHuy ?? d.lyDoKetThuc;
    if (d.ketThuc && ly != null && ly.isNotEmpty) {
      them(
        _Chu(
          Icons.info_outline,
          'Lý do kết thúc: ${lyDoHuyDonLabels[ly] ?? ly}',
        ),
      );
    }

    if (d.ruaSoatLuaDao) {
      them(
        const QuanAnWarningBox(
          message: 'Đơn đang được admin rà soát. Tiền (nếu trả trên app) tiếp tục được giữ cho tới khi có kết luận.',
        ),
      );
    } else if (d.coQuaHan) {
      them(
        const QuanAnWarningBox(
          message: 'Đơn đã quá hạn mà chưa có bằng chứng giao / nhận, đã chuyển admin xem xét. Tiền (nếu trả trên app) tiếp tục được giữ.',
        ),
      );
    }

    if (d.anhGiao != null && d.anhGiao!.url.isNotEmpty) {
      them(
        _BangChung(
          tieuDe: 'Ảnh giao hàng do quán chụp trong app',
          anh: d.anhGiao!.url,
          phu: d.bangChungLuc == null
              ? null
              : 'Ghi nhận lúc ${formatNgayGio(d.bangChungLuc!)}',
        ),
      );
    } else if (d.bangChungLoai == 'ma' && d.bangChungLuc != null) {
      them(
        _Chu(
          Icons.verified_outlined,
          'Quán đã nhập đúng mã nhận món lúc ${formatNgayGio(d.bangChungLuc!)}.',
        ),
      );
    }

    final kn = d.khongNhan;
    if (kn != null) {
      them(
        QuanAnWarningBox(
          message: kn.phanDoi
              ? 'Quán báo bạn không nhận món lúc ${formatNgayGio(kn.luc)}. Bạn đã phản đối${kn.phanDoiLuc == null ? '' : ' lúc ${formatNgayGio(kn.phanDoiLuc!)}'}, admin sẽ xem xét.${(kn.moTaPhanDoi ?? '').isEmpty ? '' : '\nLý do bạn nêu: ${kn.moTaPhanDoi}'}'
              : 'Quán báo bạn không nhận món lúc ${formatNgayGio(kn.luc)}. Đây mới là báo cáo của quán, chưa phải kết luận. Nếu bạn đã nhận món hoặc có mặt đúng hẹn, hãy bấm "Phản đối" trước hạn.',
        ),
      );
      if (kn.anh.isNotEmpty) {
        them(_BangChung(tieuDe: 'Ảnh quán gửi kèm', anh: kn.anh));
      }
    }

    final k = d.khieuNai;
    if (k != null) them(_KhoiKhieuNai(k: k, laTienMat: d.laTienMat));

    if (d.traApp) {
      them(
        StreamBuilder<KhoanTien?>(
          stream: dv.donMon.khoanTien(d.id),
          builder: (context, s) => s.data == null
              ? const SizedBox.shrink()
              : _Chu(
                  Icons.account_balance_wallet_outlined,
                  'Tiền: ${KhoanTien.labels[s.data!.trangThai] ?? s.data!.trangThai} (${formatPrice(s.data!.soTien)})',
                ),
        ),
      );
    }
    return ds;
  }

  // ---------------------------------------------------------------- Chi tiết đơn

  Widget _chiTietDon() {
    final km = d.khuyenMaiApDung;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(QuanAnSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Món đã đặt (giá đã chốt)', style: QuanAnText.h3),
            const SizedBox(height: QuanAnSpacing.sm),
            for (final m in d.monAn)
              _DongTien(
                '${m.ten} × ${m.soLuong}'
                '${m.tuyChonMoTa.isEmpty ? '' : '\n${m.tuyChonMoTa}'}'
                '${m.ghiChu.trim().isEmpty ? '' : '\nGhi chú: ${m.ghiChu.trim()}'}',
                formatPrice(m.thanhTien),
              ),
            const Divider(height: QuanAnSpacing.xxl),
            _DongTien('Tiền món', formatPrice(d.tienMon)),
            if (d.giamCombo > 0)
              _DongTien(
                'Giảm combo',
                '-${formatPrice(d.giamCombo)}',
                xanh: true,
              ),
            if (d.giamGia > 0)
              _DongTien(
                km.isEmpty
                    ? 'Giảm giá'
                    : 'Giảm giá (${km.map((x) => x.tieuDe).join(', ')})',
                '-${formatPrice(d.giamGia)}',
                xanh: true,
              ),
            if (d.laGiao)
              _DongTien(
                'Phí giao',
                d.phiGiao <= 0 ? 'Miễn phí' : formatPrice(d.phiGiao),
              ),
            const Divider(height: QuanAnSpacing.xxl),
            _DongTien('Tổng', formatPrice(d.tong), dam: true),
            const SizedBox(height: QuanAnSpacing.md),
            if (d.laGiao && d.diaChiGiao != null)
              _Chu(
                Icons.place_outlined,
                'Giao tới: ${d.diaChiGiao!.dong.isEmpty ? 'địa chỉ đã chọn' : d.diaChiGiao!.dong}',
              ),
            if (d.gioDuKien != null)
              _Chu(
                Icons.schedule_rounded,
                d.laHenGio
                    ? 'Giờ hẹn: ${formatNgayGio(d.gioDuKien!)}'
                    : 'Dự kiến sẵn sàng: ${formatNgayGio(d.gioDuKien!)}',
              ),
            if (d.laDenLay && d.tNhanMonDuKien != null)
              _Chu(
                Icons.storefront_outlined,
                'Nhận món dự kiến: ${formatNgayGio(d.tNhanMonDuKien!)}',
              ),
            if (d.sdtNhan.isNotEmpty)
              _Chu(Icons.phone_outlined, 'SĐT người nhận: ${d.sdtNhan}'),
            if (d.ghiChuQuan.trim().isNotEmpty)
              _Chu(
                Icons.sticky_note_2_outlined,
                'Ghi chú cho quán: ${d.ghiChuQuan.trim()}',
              ),
            if (d.taoLuc != null)
              _Chu(
                Icons.receipt_long_outlined,
                'Đặt lúc ${formatNgayGio(d.taoLuc!)}',
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Nút

  List<Widget> _nut(DateTime now) {
    final ds = <Widget>[];
    var daCoNutChinh = false;
    final khoa = _dangXuLy;

    void them(Widget w) =>
        ds.addAll([w, const SizedBox(height: QuanAnSpacing.sm)]);

    /// Nút chính (nền xanh đặc): tối đa 1 nút mỗi màn hình.
    void chinh(String nhan, VoidCallback onTap, {IconData? icon}) {
      if (daCoNutChinh) {
        them(OutlinedButton(onPressed: khoa ? null : onTap, child: Text(nhan)));
        return;
      }
      daCoNutChinh = true;
      them(
        icon == null
            ? FilledButton(onPressed: khoa ? null : onTap, child: Text(nhan))
            : FilledButton.icon(
                onPressed: khoa ? null : onTap,
                icon: Icon(icon),
                label: Text(nhan),
              ),
      );
    }

    void phu(String nhan, VoidCallback? onTap, {bool nguyHiem = false}) => them(
      OutlinedButton(
        style: nguyHiem
            ? OutlinedButton.styleFrom(
                foregroundColor: QuanAnColors.danger,
                side: BorderSide(
                  color: onTap == null
                      ? QuanAnColors.border
                      : QuanAnColors.danger,
                  width: 1.5,
                ),
              )
            : null,
        onPressed: khoa ? null : onTap,
        child: Text(nhan, textAlign: TextAlign.center),
      ),
    );

    final traApp = d.traApp;

    if (d.coThanhToan(now)) {
      chinh(
        'Tiếp tục thanh toán · ${formatPrice(d.tong)}',
        () => _mo((_) => ThanhToanScreen(dv: dv, donId: d.id)),
      );
    }

    if (d.coDaNhanMon && d.khongNhan == null) {
      chinh(
        'Đã nhận món',
        () => _hoi(
          tieuDe: 'Xác nhận đã nhận món?',
          noiDung: traApp
              ? 'Bấm "Đã nhận món" là chốt: bạn không khiếu nại được nữa và tiền được chuyển cho quán. Chỉ bấm khi đã nhận đủ, đúng món.'
              : 'Bấm "Đã nhận món" là chốt: bạn không khiếu nại được nữa và đơn hoàn tất. Chỉ bấm khi đã nhận đủ, đúng món.',
          dongY: 'Đã nhận món',
          su: const {'loai': 'SV_DA_NHAN'},
          ok: 'Đã xác nhận nhận món',
        ),
        icon: Icons.check_circle_outline,
      );
    }

    if (d.coPhanDoi(now)) {
      chinh(
        'Phản đối "Khách không nhận"',
        () => _mo((_) => KhieuNaiDonScreen(dv: dv, don: d, phanDoi: true)),
      );
    }

    if (d.coDanhGia(now)) {
      chinh(
        'Viết đánh giá',
        () => _mo(
          (_) =>
              DanhGiaQuanScreen(dv: dv, quanId: d.quanId, tenQuan: d.tenQuan),
        ),
        icon: Icons.rate_review_outlined,
      );
    }

    if (d.coDatLai) chinh('Đặt lại', _datLai, icon: Icons.replay_rounded);

    if (d.coHuy) {
      phu(
        'Hủy đơn',
        () => _hoi(
          tieuDe: 'Hủy đơn?',
          noiDung: traApp
              ? 'Quán chưa nhận đơn nên bạn hủy được và được hoàn 100%.'
              : 'Quán chưa nhận đơn nên bạn hủy được.',
          dongY: 'Hủy đơn',
          su: const {'loai': 'SV_HUY'},
          ok: traApp ? 'Đã hủy đơn, tiền được hoàn 100%' : 'Đã hủy đơn',
          nguyHiem: true,
        ),
        nguyHiem: true,
      );
    }

    if (d.coHuyQuanCham(now, cfg: widget.cfg)) {
      phu(
        'Hủy vì quán chậm',
        () => _hoi(
          tieuDe: 'Hủy vì quán chậm?',
          noiDung: traApp
              ? 'Quán đã quá giờ dự kiến ${widget.cfg.quanChamPhut} phút mà chưa báo sẵn sàng. Bạn được hoàn 100%.'
              : 'Quán đã quá giờ dự kiến ${widget.cfg.quanChamPhut} phút mà chưa báo sẵn sàng. Đơn sẽ được hủy.',
          dongY: 'Hủy vì quán chậm',
          su: const {'loai': 'SV_HUY_QUAN_CHAM'},
          ok: traApp ? 'Đã hủy, tiền được hoàn 100%' : 'Đã hủy đơn',
          nguyHiem: true,
        ),
        nguyHiem: true,
      );
    }

    final cnm = d.chuaNhanMon(now, widget.cfg);
    if (cnm.hien) {
      phu(
        'Chưa nhận được món',
        cnm.bam
            ? () => _hoi(
                tieuDe: 'Báo chưa nhận được món?',
                noiDung: traApp
                    ? 'Tiền của đơn tiếp tục được giữ và đơn chuyển sang khiếu nại để admin xem xét.'
                    : 'Đơn chuyển sang xác minh giao nhận để admin xem xét.',
                dongY: 'Báo chưa nhận được',
                su: const {'loai': 'SV_CHUA_NHAN_MON'},
                ok: 'Đã báo chưa nhận được món',
                nguyHiem: true,
              )
            : null,
        nguyHiem: true,
      );
      if (!cnm.bam && cnm.giaiThich != null) {
        ds.removeLast();
        ds.add(
          Padding(
            padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
            child: Text(
              cnm.giaiThich!,
              style: QuanAnText.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    if (d.coKhieuNai(now)) {
      phu(
        'Khiếu nại đơn',
        () => _mo((_) => KhieuNaiDonScreen(dv: dv, don: d)),
        nguyHiem: true,
      );
    }

    them(
      OutlinedButton.icon(
        onPressed: () => QuanAnDieuHuong.chat(
          context,
          dv,
          d.chuQuanId,
          quanId: d.quanId,
          donId: d.id,
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Nhắn tin với quán'),
      ),
    );
    them(
      TextButton(
        onPressed: () => moBaoCao(context, dv, loai: 'quan', id: d.quanId),
        child: Text(
          d.laTienMat && d.status != 'placed'
              ? 'Báo cáo quán (thiếu món, sai món...)'
              : 'Báo cáo quán',
        ),
      ),
    );
    return ds;
  }
}

// ==================================================================== Thành phần nhỏ

class _Chu extends StatelessWidget {
  const _Chu(this.icon, this.noiDung);

  final IconData icon;
  final String noiDung;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: QuanAnColors.primary),
        const SizedBox(width: QuanAnSpacing.sm),
        Expanded(child: Text(noiDung, style: QuanAnText.body)),
      ],
    ),
  );
}

class _DongTien extends StatelessWidget {
  const _DongTien(
    this.nhan,
    this.giaTri, {
    this.dam = false,
    this.xanh = false,
  });

  final String nhan;
  final String giaTri;
  final bool dam;
  final bool xanh;

  @override
  Widget build(BuildContext context) {
    final kieu = dam
        ? QuanAnText.price.copyWith(fontSize: 18)
        : QuanAnText.body.copyWith(color: xanh ? QuanAnColors.success : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(nhan, style: kieu)),
          const SizedBox(width: QuanAnSpacing.sm),
          Text(giaTri, style: kieu),
        ],
      ),
    );
  }
}

class _BangChung extends StatelessWidget {
  const _BangChung({required this.tieuDe, required this.anh, this.phu});

  final String tieuDe;
  final String anh;
  final String? phu;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe, style: QuanAnText.label),
          if (phu != null) Text(phu!, style: QuanAnText.bodySmall),
          const SizedBox(height: QuanAnSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(QuanAnRadius.button),
            child: Image.network(
              anh,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Không tải được ảnh',
                    style: QuanAnText.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Kết quả khiếu nại: lý do, mô tả, ảnh, quán trả lời, quyết định của admin.
class _KhoiKhieuNai extends StatelessWidget {
  const _KhoiKhieuNai({required this.k, required this.laTienMat});

  final KhieuNaiDon k;
  final bool laTienMat;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.loaiLabel, style: QuanAnText.h3),
          if (k.luc != null)
            Text(
              'Gửi lúc ${formatNgayGio(k.luc!)}',
              style: QuanAnText.bodySmall,
            ),
          if (k.lyDo.isNotEmpty) ...[
            const SizedBox(height: QuanAnSpacing.sm),
            Text('Lý do: ${k.lyDoLabel}', style: QuanAnText.body),
          ],
          if (k.moTa.isNotEmpty) Text(k.moTa, style: QuanAnText.body),
          if (k.anh.isNotEmpty) ...[
            const SizedBox(height: QuanAnSpacing.sm),
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.sm,
              children: [
                for (final u in k.anh)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(QuanAnRadius.button),
                    child: Image.network(
                      u,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (k.chuTraLoi != null && k.chuTraLoi!.isNotEmpty) ...[
            const Divider(height: QuanAnSpacing.xxl),
            const Text('Quán trả lời', style: QuanAnText.label),
            Text(k.chuTraLoi!, style: QuanAnText.body),
            if (!laTienMat && k.deNghiHoan != null)
              Text(
                k.deNghiHoan == 'hoan_toan'
                    ? 'Quán đề nghị hoàn toàn bộ.'
                    : 'Quán đề nghị hoàn một phần.',
                style: QuanAnText.bodySmall,
              ),
          ],
          if (k.daQuyet) ...[
            const Divider(height: QuanAnSpacing.xxl),
            const Text('Kết luận của admin', style: QuanAnText.label),
            Text(k.quyetDinhLabel ?? '', style: QuanAnText.body),
            if (!laTienMat && k.soTienHoan != null && k.soTienHoan! > 0)
              Text(
                'Số tiền hoàn: ${formatPrice(k.soTienHoan!)}',
                style: QuanAnText.body,
              ),
            if (k.lyDoQuyet != null && k.lyDoQuyet!.isNotEmpty)
              Text('Lý do: ${k.lyDoQuyet}', style: QuanAnText.bodySmall),
            if (k.tinhBomHang)
              const Text(
                'Lần này được tính là 1 lần không nhận món.',
                style: QuanAnText.bodySmall,
              ),
          ] else if (k.chuTraLoi == null || k.chuTraLoi!.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: QuanAnSpacing.sm),
              child: Text(
                'Đang chờ quán trả lời hoặc admin xem xét.',
                style: QuanAnText.bodySmall,
              ),
            ),
        ],
      ),
    ),
  );
}
