import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/don_mon.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/don_chu_quan_actions.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// Chi tiết một đơn cho chủ quán: cùng bộ nút xử lý với danh sách, dòng thời gian,
/// thông tin người nhận (số điện thoại người nhận hiện cho chủ quán), nhắn tin với sinh viên.
class ChiTietDonChuQuanScreen extends StatefulWidget {
  const ChiTietDonChuQuanScreen({
    required this.dv,
    required this.donId,
    this.layViTri,
    super.key,
  });

  final QuanAnDichVu dv;
  final String donId;

  /// Thay cách lấy GPS (dùng khi thử); mặc định geolocator.
  final LayViTriGps? layViTri;

  @override
  State<ChiTietDonChuQuanScreen> createState() =>
      _ChiTietDonChuQuanScreenState();
}

class _ChiTietDonChuQuanScreenState extends State<ChiTietDonChuQuanScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();

  @override
  void initState() {
    super.initState();
    widget.dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
    // Mở lại đơn: nhờ hệ thống xử lý các hạn đã tới để thấy đúng trạng thái.
    widget.dv.donMon.xuLyHan(widget.donId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Đơn ${maNgan(widget.donId)}')),
    body: QuanAnStream<DonMon?>(
      stream: () => widget.dv.donMon.donMon(widget.donId),
      thongBaoLoi: 'Không tải được đơn',
      builder: (context, d) => d == null
          ? const QuanAnEmptyState(title: 'Không tìm thấy đơn')
          : _NoiDung(
              dv: widget.dv,
              don: d,
              cfg: _cfg,
              layViTri: widget.layViTri,
            ),
    ),
  );
}

class _NoiDung extends StatelessWidget {
  const _NoiDung({
    required this.dv,
    required this.don,
    required this.cfg,
    this.layViTri,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final QuanAnConfig cfg;
  final LayViTriGps? layViTri;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final rong = c.maxWidth >= 900;
      final trai = [
        _TrangThai(dv: dv, don: don, cfg: cfg, layViTri: layViTri),
        _Mon(don: don),
        _NguoiNhan(dv: dv, don: don),
        ..._ghiNhan(don),
      ];
      final phai = [_DongThoiGian(don: don)];
      return SingleChildScrollView(
        padding: const EdgeInsets.all(QuanAnSpacing.screen),
        child: TrangRong(
          rongToiDa: 1200,
          child: rong
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _cot(trai)),
                    const SizedBox(width: QuanAnSpacing.cardGap),
                    Expanded(flex: 2, child: _cot(phai)),
                  ],
                )
              : _cot([...trai, ...phai]),
        ),
      );
    },
  );

  static Widget _cot(List<Widget> ds) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final w in ds) ...[w, const SizedBox(height: QuanAnSpacing.cardGap)],
    ],
  );

  /// Khối ghi nhận đặc biệt: ảnh giao, khách không nhận, khiếu nại.
  static List<Widget> _ghiNhan(DonMon d) => [
    if (d.anhGiao != null && d.anhGiao!.url.isNotEmpty)
      KhoiThongTin(
        tieuDe: 'Ảnh giao hàng',
        phu: d.anhGiao!.khoangCachM == null
            ? null
            : 'Cách điểm giao ${formatKhoangCach(d.anhGiao!.khoangCachM!.toDouble())}',
        child: _Anh(d.anhGiao!.url),
      ),
    if (d.khongNhan != null) _KhongNhan(k: d.khongNhan!),
    if (d.khieuNai != null) _KhieuNai(k: d.khieuNai!),
  ];
}

class _Anh extends StatelessWidget {
  const _Anh(this.url);

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(QuanAnRadius.button),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: AspectRatio(aspectRatio: 16 / 9, child: NetworkPhoto(url)),
    ),
  );
}

class _TrangThai extends StatelessWidget {
  const _TrangThai({
    required this.dv,
    required this.don,
    required this.cfg,
    this.layViTri,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final QuanAnConfig cfg;
  final LayViTriGps? layViTri;

  @override
  Widget build(BuildContext context) => QuanAnDongHo(
    builder: (context, now) {
      final moc = don.mocDemNguoc(now, cfg);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: QuanAnSpacing.sm,
                runSpacing: QuanAnSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  huyHieuTrangThaiDon(don),
                  QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.chung,
                    label: don.cachNhanLabel,
                    icon: don.laGiao
                        ? Icons.delivery_dining_rounded
                        : Icons.storefront_rounded,
                  ),
                  if (don.laTienMat)
                    const QuanAnStatusBadge(
                      kind: QuanAnBadgeKind.canhBao,
                      label: 'Tiền mặt, không qua app',
                      icon: Icons.payments_outlined,
                    )
                  else
                    const QuanAnStatusBadge(
                      kind: QuanAnBadgeKind.xacThuc,
                      label: 'Trả trên app',
                      icon: Icons.credit_score_rounded,
                    ),
                ],
              ),
              if (don.status == 'placed' && don.hanQuanNhan != null) ...[
                const SizedBox(height: QuanAnSpacing.md),
                Text(
                  don.hanQuanNhan!.isAfter(now)
                      ? 'Còn ${phutGiay(don.hanQuanNhan!.difference(now))} để nhận hoặc từ chối'
                      : 'Đã quá hạn xác nhận',
                  style: QuanAnText.h3.copyWith(color: QuanAnColors.warning),
                ),
              ] else if (moc != null) ...[
                const SizedBox(height: QuanAnSpacing.md),
                Text(
                  '${moc.$1}: ${formatNgayGio(moc.$2)} '
                  '(${formatConLai(moc.$2.difference(now))})',
                  style: QuanAnText.body,
                ),
              ],
              if (don.lyDoHuy != null && don.lyDoHuy!.isNotEmpty) ...[
                const SizedBox(height: QuanAnSpacing.sm),
                Text(
                  'Lý do: ${lyDoHuyDonLabels[don.lyDoHuy] ?? don.lyDoHuy}',
                  style: QuanAnText.bodySmall,
                ),
              ],
              if (don.laTienMat && !don.ketThuc && don.status != 'placed') ...[
                const SizedBox(height: QuanAnSpacing.sm),
                Text(
                  'Thu ${formatPrice(don.tong)} tiền mặt khi giao món. '
                  'Không có giữ tiền hay hoàn tiền qua app.',
                  style: QuanAnText.bodySmall,
                ),
              ],
              const SizedBox(height: QuanAnSpacing.md),
              DonChuQuanActions(
                dv: dv,
                don: don,
                cfg: cfg,
                now: now,
                layViTri: layViTri,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Mon extends StatelessWidget {
  const _Mon({required this.don});

  final DonMon don;

  Widget _dong(String trai, String phai, {TextStyle? kieu}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(trai, style: kieu ?? QuanAnText.body)),
        const SizedBox(width: QuanAnSpacing.sm),
        Text(phai, style: kieu ?? QuanAnText.body),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => KhoiThongTin(
    tieuDe: 'Món khách đặt',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in don.monAn) ...[
          _dong(
            '${m.soLuong} × ${m.ten}',
            formatPrice(m.thanhTien),
            kieu: QuanAnText.label,
          ),
          if (m.tuyChon.isNotEmpty)
            Text(m.tuyChonMoTa, style: QuanAnText.bodySmall),
          if (m.ghiChu.isNotEmpty)
            Text('Ghi chú: ${m.ghiChu}', style: QuanAnText.bodySmall),
          const SizedBox(height: QuanAnSpacing.sm),
        ],
        const Divider(),
        const SizedBox(height: QuanAnSpacing.xs),
        _dong('Tiền món', formatPrice(don.tienMon)),
        if (don.giamCombo > 0)
          _dong('Giảm combo', '-${formatPrice(don.giamCombo)}'),
        if (don.giamGia > 0)
          _dong('Giảm khuyến mãi', '-${formatPrice(don.giamGia)}'),
        for (final k in don.khuyenMaiApDung)
          Text('· ${k.tieuDe}', style: QuanAnText.bodySmall),
        if (don.laGiao) _dong('Phí giao', formatPrice(don.phiGiao)),
        const SizedBox(height: QuanAnSpacing.xs),
        _dong('Tổng', formatPrice(don.tong), kieu: QuanAnText.price),
        if (don.laTienMat)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
            child: Text(
              'Thu ${formatPrice(don.tong)} tiền mặt khi khách nhận món.',
              style: QuanAnText.bodySmall.copyWith(color: QuanAnColors.warning),
            ),
          ),
      ],
    ),
  );
}

class _NguoiNhan extends StatelessWidget {
  const _NguoiNhan({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  Future<void> _goi(BuildContext context, String sdt) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(Uri(scheme: 'tel', path: sdt))) return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: sdt));
    messenger.showSnackBar(
      SnackBar(content: Text('Đã sao chép số $sdt (máy này không gọi được)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gio = don.laHenGio
        ? (don.gioHen == null
              ? 'Hẹn giờ'
              : 'Hẹn giờ: ${formatNgayGio(don.gioHen!)}')
        : 'Càng sớm càng tốt';
    return KhoiThongTin(
      tieuDe: 'Người nhận',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: QuanAnColors.primary),
              const SizedBox(width: QuanAnSpacing.sm),
              Expanded(
                child: Text(
                  don.sdtNhan.isEmpty ? 'Chưa có số điện thoại' : don.sdtNhan,
                  style: QuanAnText.h3,
                ),
              ),
              if (don.sdtNhan.isNotEmpty)
                OutlinedButton(
                  onPressed: () => _goi(context, don.sdtNhan),
                  child: const Text('Gọi'),
                ),
            ],
          ),
          if (don.svSdt.isNotEmpty && don.svSdt != don.sdtNhan)
            Padding(
              padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
              child: Text(
                'Số tài khoản đặt: ${don.svSdt}',
                style: QuanAnText.bodySmall,
              ),
            ),
          const SizedBox(height: QuanAnSpacing.sm),
          Text(
            'Cách nhận: ${don.cachNhanLabel} · $gio',
            style: QuanAnText.body,
          ),
          if (don.laGiao && don.diaChiGiao != null) ...[
            const SizedBox(height: QuanAnSpacing.xs),
            Text('Giao đến: ${don.diaChiGiao!.dong}', style: QuanAnText.body),
            if (don.diaChiGiao!.khoangCachKm != null)
              Text(
                'Cách quán ${don.diaChiGiao!.khoangCachKm} km',
                style: QuanAnText.bodySmall,
              ),
          ],
          if (don.ghiChuQuan.isNotEmpty) ...[
            const SizedBox(height: QuanAnSpacing.xs),
            Text('Ghi chú cho quán: ${don.ghiChuQuan}', style: QuanAnText.body),
          ],
          const SizedBox(height: QuanAnSpacing.md),
          OutlinedButton.icon(
            onPressed: () => QuanAnDieuHuong.chat(
              context,
              dv,
              don.svId,
              quanId: don.quanId,
              donId: don.id,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Nhắn tin với sinh viên'),
          ),
        ],
      ),
    );
  }
}

class _KhongNhan extends StatelessWidget {
  const _KhongNhan({required this.k});

  final KhongNhan k;

  @override
  Widget build(BuildContext context) => KhoiThongTin(
    tieuDe: 'Quán báo khách không nhận',
    phu:
        'Lúc ${formatNgayGio(k.luc)}. Đây mới là báo cáo của quán, chưa phải kết luận.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (k.anh.isNotEmpty) _Anh(k.anh),
        const SizedBox(height: QuanAnSpacing.sm),
        if (k.phanDoi)
          HopThongBao.canhBao(
            noiDung:
                'Khách đã phản đối${k.moTaPhanDoi == null ? '' : ': ${k.moTaPhanDoi}'}. '
                'Admin sẽ xét.',
          )
        else
          Text(
            'Khách có thể phản đối đến ${formatNgayGio(k.hanPhanDoi)}.',
            style: QuanAnText.bodySmall,
          ),
      ],
    ),
  );
}

class _KhieuNai extends StatelessWidget {
  const _KhieuNai({required this.k});

  final KhieuNaiDon k;

  @override
  Widget build(BuildContext context) => KhoiThongTin(
    tieuDe: k.loaiLabel,
    mau: QuanAnColors.warningSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (k.lyDo.isNotEmpty)
          Text('Lý do: ${k.lyDoLabel}', style: QuanAnText.label),
        if (k.moTa.isNotEmpty) Text(k.moTa, style: QuanAnText.body),
        if (k.anh.isNotEmpty) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [
              for (final u in k.anh)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(QuanAnRadius.input),
                    child: NetworkPhoto(u),
                  ),
                ),
            ],
          ),
        ],
        if (k.hanChuTraLoi != null && k.chuTraLoi == null)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
            child: Text(
              'Quán trả lời trước ${formatNgayGio(k.hanChuTraLoi!)}',
              style: QuanAnText.bodySmall,
            ),
          ),
        if (k.chuTraLoi != null)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
            child: Text(
              'Quán đã trả lời: ${k.chuTraLoi}'
              '${k.deNghiHoan == null ? '' : ' (đề nghị ${quyetDinhKhieuNaiLabels[k.deNghiHoan] ?? k.deNghiHoan})'}',
              style: QuanAnText.body,
            ),
          ),
        if (k.daQuyet)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
            child: Text(
              'Admin quyết: ${k.quyetDinhLabel}'
              '${k.soTienHoan == null ? '' : ' (${formatPrice(k.soTienHoan!)})'}'
              '${k.lyDoQuyet == null ? '' : '. ${k.lyDoQuyet}'}',
              style: QuanAnText.label,
            ),
          ),
      ],
    ),
  );
}

class _DongThoiGian extends StatelessWidget {
  const _DongThoiGian({required this.don});

  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final ds = [...don.lichSu]
      ..sort((a, b) => (a.luc ?? DateTime(0)).compareTo(b.luc ?? DateTime(0)));
    return KhoiThongTin(
      tieuDe: 'Dòng thời gian',
      child: ds.isEmpty
          ? Text(
              don.taoLuc == null
                  ? 'Chưa có mốc nào.'
                  : 'Đặt lúc ${formatNgayGio(don.taoLuc!)}',
              style: QuanAnText.bodySmall,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < ds.length; i++)
                  _Moc(
                    moc: ds[i],
                    cuoi: i == ds.length - 1,
                    dangO: i == ds.length - 1 && !don.ketThuc,
                  ),
              ],
            ),
    );
  }
}

class _Moc extends StatelessWidget {
  const _Moc({required this.moc, required this.cuoi, required this.dangO});

  final MocLichSu moc;
  final bool cuoi;
  final bool dangO;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dangO
                      ? QuanAnColors.primary
                      : QuanAnColors.primarySoft,
                ),
              ),
              if (!cuoi)
                const Expanded(child: VerticalDivider(width: 2, thickness: 2)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: QuanAnSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trangThaiDonLabels[moc.trangThai] ?? moc.trangThai,
                  style: QuanAnText.label,
                ),
                if (moc.luc != null)
                  Text(formatNgayGio(moc.luc!), style: QuanAnText.bodySmall),
                if (moc.ghiChu.isNotEmpty)
                  Text(
                    lyDoHuyDonLabels[moc.ghiChu] ?? moc.ghiChu,
                    style: QuanAnText.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
