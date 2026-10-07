import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/dat_coc.dart';
import '../../models/khieu_nai.dart';
import '../../models/thanh_toan.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/chon_thoi_diem_nhan_phong.dart';
import '../../widgets/dem_nguoc_coc_banner.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import '../tuong_tac/thanh_toan_screen.dart';
import 'danh_gia_tro_screen.dart';
import 'khieu_nai_screen.dart';

/// TRO-SV-08 Chi tiết khoản cọc (sinh viên) — cũng là màn hình khoản cọc của chủ trọ (TRO-CT-06).
/// Nút hiện theo vai trò và thời điểm; hệ thống vẫn kiểm tra lại khi bấm.
/// Mở màn hình là nhờ hệ thống xử lý các hạn đã tới (thấy đúng trạng thái sau hạn, mục 2.18).
class DatCocDetailScreen extends StatefulWidget {
  const DatCocDetailScreen({
    required this.dv,
    required this.datCocId,
    super.key,
  });

  final TroDichVu dv;
  final String datCocId;

  @override
  State<DatCocDetailScreen> createState() => _DatCocDetailScreenState();
}

class _DatCocDetailScreenState extends State<DatCocDetailScreen> {
  late final Future<TroConfig> _cfg = widget.dv.datCoc.cauHinh();

  @override
  void initState() {
    super.initState();
    widget.dv.datCoc.xuLyHan(widget.datCocId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khoản cọc')),
      body: FutureBuilder<TroConfig>(
        future: _cfg,
        builder: (context, c) => !c.hasData
            ? const TroSkeletonList(count: 1)
            : TroStream<DatCoc?>(
                stream: () => widget.dv.datCoc.datCoc(widget.datCocId),
                builder: (context, d) => d == null
                    ? const TroEmptyState(title: 'Không tìm thấy khoản cọc')
                    : _NoiDung(dv: widget.dv, d: d, cfg: c.data!),
              ),
      ),
    );
  }
}

class _NoiDung extends StatelessWidget {
  const _NoiDung({required this.dv, required this.d, required this.cfg});

  final TroDichVu dv;
  final DatCoc d;
  final TroConfig cfg;

  bool get _laSv => d.sinhVienId == dv.uid;
  bool get _laChu => d.chuTroId == dv.uid;

  Future<void> _lam(
    BuildContext context,
    Map<String, dynamic> su, {
    String? ok,
  }) => chayThaoTac(
    context,
    () => dv.datCoc.thaoTac(d.id, d.version, su),
    thanhCong: ok,
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final moc = d.mocDemNguoc(now, cfg);
    final ki = _kieuBadge(d.status);
    return ListView(
      padding: const EdgeInsets.all(TroSpacing.screen),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${d.tenPhong} · ${d.tenNhaTro}', style: TroText.h2),
            ),
            TroStatusBadge(kind: ki, label: d.trangThaiLabel),
          ],
        ),
        const SizedBox(height: TroSpacing.xs),
        Text(
          'Tiền cọc ${formatPrice(d.soTien)} · Nhận phòng ${formatNgayGio(d.t)}',
          style: TroText.bodySmall,
        ),
        if (d.lyDoKetThuc != null) ...[
          const SizedBox(height: TroSpacing.xs),
          Text(
            'Kết thúc: ${lyDoKetThucLabels[d.lyDoKetThuc] ?? d.lyDoKetThuc}',
            style: TroText.bodySmall,
          ),
        ],
        const SizedBox(height: TroSpacing.md),
        if (moc != null)
          DemNguocCocBanner(
            nhan: moc.$1,
            moc: moc.$2,
            canhBao: d.khongDen != null || (d.doi?.dangCho ?? false),
            onHet: () => dv.datCoc.xuLyHan(d.id).catchError((_) {}),
          ),
        const SizedBox(height: TroSpacing.md),
        StreamBuilder<KhoanTien?>(
          stream: dv.datCoc.khoanTien(d.id),
          builder: (context, s) => s.data == null
              ? const SizedBox.shrink()
              : Text(
                  'Tiền: ${KhoanTien.labels[s.data!.trangThai] ?? s.data!.trangThai}',
                  style: TroText.label,
                ),
        ),
        if (d.doi != null) _KhoiDoi(d: d),
        if (d.khongDen != null) _KhoiKhongDen(d: d),
        if (d.khieuNai != null) _KhoiKhieuNai(k: d.khieuNai!),
        const SizedBox(height: TroSpacing.lg),
        ..._nut(context, now),
        const SizedBox(height: TroSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => TroDieuHuong.chat(
            context,
            dv,
            _laSv ? d.chuTroId : d.sinhVienId,
            phongId: _laSv ? d.phongId : null,
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(_laSv ? 'Nhắn tin chủ trọ' : 'Nhắn tin sinh viên'),
        ),
        if (d.chupThongTin != null) ...[
          const SizedBox(height: TroSpacing.sm),
          TextButton(
            onPressed: () => _xemBanChup(context),
            child: const Text('Xem thông tin phòng lúc cọc (bản chụp)'),
          ),
        ],
      ],
    );
  }

  TroBadgeKind _kieuBadge(String s) => switch (s) {
    'held' || 'pending_payment' || 'disputed' => TroBadgeKind.reserved,
    'released' => TroBadgeKind.rented,
    'refunded' || 'cancelled_grace' => TroBadgeKind.available,
    _ => TroBadgeKind.full,
  };

  List<Widget> _nut(BuildContext context, DateTime now) {
    final ds = <Widget>[];
    void them(Widget w) =>
        ds.addAll([w, const SizedBox(height: TroSpacing.sm)]);
    final nguyHiem = OutlinedButton.styleFrom(
      foregroundColor: TroColors.danger,
      side: const BorderSide(color: TroColors.danger, width: 1.5),
    );

    if (_laSv) {
      if (d.status == 'pending_payment') {
        them(
          FilledButton(
            onPressed: () => TroDieuHuong.mo(
              context,
              (_) => ThanhToanScreen(dv: dv, datCocId: d.id),
            ),
            child: const Text('Tiếp tục thanh toán'),
          ),
        );
      }
      if (d.coPhanDoi(now)) {
        them(
          FilledButton(
            onPressed: () => TroDieuHuong.mo(
              context,
              (_) => KhieuNaiScreen(dv: dv, datCoc: d, phanDoi: true),
            ),
            child: const Text('Phản đối: tôi đã đến / đã nhận phòng'),
          ),
        );
      }
      if (d.coDaNhanPhong(now)) {
        them(
          FilledButton(
            onPressed: () async {
              if (await xacNhan(
                    context,
                    tieuDe: 'Xác nhận đã nhận phòng?',
                    noiDung: 'Tiền cọc sẽ được chuyển cho chủ trọ. Bạn sẽ được viết đánh giá.',
                  ) &&
                  context.mounted) {
                await _lam(context, {
                  'loai': 'SV_DA_NHAN',
                }, ok: 'Đã xác nhận nhận phòng');
              }
            },
            child: const Text('✅ Đã nhận phòng'),
          ),
        );
      }
      if (d.coKhieuNai(now, cfg)) {
        them(
          OutlinedButton(
            style: nguyHiem,
            onPressed: () => TroDieuHuong.mo(
              context,
              (_) => KhieuNaiScreen(dv: dv, datCoc: d),
            ),
            child: const Text('⚠️ Chủ trọ không thực hiện đúng cam kết'),
          ),
        );
      }
      if (d.coHuyMienPhi(now)) {
        them(
          OutlinedButton(
            style: nguyHiem,
            onPressed: () async {
              if (await xacNhan(
                    context,
                    tieuDe: 'Hủy cọc?',
                    noiDung: 'Hủy trong 30 phút đầu: bạn được hoàn 100% và dùng 1 lượt hủy miễn phí.',
                    dongY: 'Hủy cọc',
                    nguyHiem: true,
                  ) &&
                  context.mounted) {
                await _lam(context, {
                  'loai': 'SV_HUY',
                }, ok: 'Đã hủy, tiền cọc được hoàn 100%');
              }
            },
            child: Text(
              'Hủy (hoàn 100%, tới ${formatNgayGio(d.hanHuyMienPhi!)})',
            ),
          ),
        );
      }
      if (d.coYeuCauDoi(now, cfg)) {
        them(
          OutlinedButton(
            onPressed: () => _yeuCauDoi(context),
            child: const Text('Yêu cầu thay đổi thời điểm nhận phòng'),
          ),
        );
      }
      if (d.coKhongThue(now)) {
        them(
          OutlinedButton(
            style: nguyHiem,
            onPressed: () async {
              if (await xacNhan(
                    context,
                    tieuDe: 'Không thuê nữa?',
                    noiDung:
                        'Bạn sẽ MẤT CỌC: ${formatPrice(d.soTien)} được chuyển cho chủ trọ để bù việc giữ phòng. Phòng sẽ mở lại cho người khác.',
                    dongY: 'Tôi không thuê nữa',
                    nguyHiem: true,
                  ) &&
                  context.mounted) {
                await _lam(context, {
                  'loai': 'SV_KHONG_THUE',
                }, ok: 'Đã báo không thuê nữa');
              }
            },
            child: const Text('Không thuê nữa'),
          ),
        );
      }
      if (d.coDanhGia) {
        them(
          FilledButton.icon(
            onPressed: () => TroDieuHuong.mo(
              context,
              (_) => DanhGiaTroScreen(
                dv: dv,
                loaiNguon: 'dat_coc',
                idNguon: d.id,
                tenPhong: d.tenPhong,
              ),
            ),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Viết / cập nhật đánh giá'),
          ),
        );
      }
      if (d.status == 'released') {
        them(
          TextButton(
            onPressed: () => moBaoCao(
              context,
              dv,
              loai: 'phong',
              id: d.phongId,
              datCocId: d.id,
              lyDoMacDinh: 'noi_quy_sai',
            ),
            child: const Text(
              'Báo cáo: nội quy không đúng với thông tin lúc giao dịch',
            ),
          ),
        );
      }
    }

    if (_laChu) {
      if (d.coTraLoiDoi) {
        them(
          FilledButton(
            onPressed: () => _lam(context, {
              'loai': 'CT_DONG_Y_DOI',
            }, ok: 'Đã đồng ý thời điểm mới'),
            child: Text('Đồng ý đổi sang ${formatNgayGio(d.doi!.thoiDiemMoi)}'),
          ),
        );
        them(
          OutlinedButton(
            onPressed: () => _lam(context, {
              'loai': 'CT_TU_CHOI_DOI',
            }, ok: 'Đã từ chối, giữ thời điểm cũ'),
            child: const Text('Từ chối, giữ thời điểm cũ'),
          ),
        );
      }
      if (d.coTraLoiKhieuNai) {
        them(
          FilledButton(
            onPressed: () => _traLoiKhieuNai(context),
            child: const Text('Trả lời khiếu nại (kèm bằng chứng)'),
          ),
        );
      }
      if (d.coBaoKhongDen(now, cfg)) {
        them(
          OutlinedButton(
            style: nguyHiem,
            onPressed: () async {
              if (await xacNhan(
                    context,
                    tieuDe: 'Báo sinh viên không đến nhận phòng?',
                    noiDung: 'Sinh viên sẽ được báo ngay và có 12 giờ để phản đối. Không phản đối thì tiền cọc chuyển cho bạn.',
                    nguyHiem: true,
                  ) &&
                  context.mounted) {
                await _lam(context, {
                  'loai': 'CT_BAO_KHONG_DEN',
                }, ok: 'Đã báo, chờ 12 giờ phản đối');
              }
            },
            child: const Text('⚠️ Sinh viên không đến nhận phòng'),
          ),
        );
      } else if (d.dangGiu && d.khongDen == null && !now.isBefore(d.t)) {
        them(
          Text(
            'Nút "Sinh viên không đến nhận phòng" mở từ ${formatNgayGio(d.t.add(TroConfig.phut(cfg.anHanKhongDenPhut)))} (3 giờ ân hạn cho sinh viên đến trễ).',
            style: TroText.bodySmall,
          ),
        );
      }
      if (d.coHuyCoc(now)) {
        them(
          OutlinedButton(
            style: nguyHiem,
            onPressed: () => _huyCoc(context),
            child: const Text(
              'Hủy cọc (hoàn 100% cho sinh viên, bị ghi vi phạm)',
            ),
          ),
        );
      }
    }
    return ds;
  }

  Future<void> _yeuCauDoi(BuildContext context) async {
    DateTime? moi;
    String? loi;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Yêu cầu thay đổi thời điểm nhận phòng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chỉ gửi được 1 lần. Chủ trọ có 24 giờ để trả lời; không trả lời thì bạn được hoàn 100%.',
                style: TroText.bodySmall,
              ),
              const SizedBox(height: TroSpacing.md),
              ChonThoiDiemNhanPhong(
                nhan: 'Thời điểm mới',
                giaTri: moi,
                loi: loi,
                onChanged: (t) => setS(() {
                  moi = t;
                  loi = null;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                final l = kiemTraThoiDiem(
                  moi,
                  now: now,
                  itNhat: TroConfig.phut(cfg.doiCachLucGuiItNhatPhut),
                  toiDa: (d.tBanDau ?? d.t)
                      .add(TroConfig.phut(cfg.doiToiDaSauTBanDauPhut))
                      .difference(now),
                  ngayVaoO: d.ngayVaoO,
                  moc: 'lúc gửi',
                );
                if (l != null) {
                  setS(() => loi = l);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && moi != null && context.mounted) {
      await _lam(context, {
        'loai': 'SV_YEU_CAU_DOI',
        'thoiDiemMoi': moi!.millisecondsSinceEpoch,
      }, ok: 'Đã gửi yêu cầu, chờ chủ trọ trả lời trong 24 giờ');
    }
  }

  Future<void> _huyCoc(BuildContext context) async {
    var an = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Hủy cọc?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sinh viên được hoàn 100%. Bạn bị ghi 1 vi phạm (3 vi phạm / 90 ngày bị khóa đăng tin / nhận cọc 30 ngày).',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: an,
                onChanged: (v) => setS(() => an = v ?? false),
                title: const Text('Ẩn phòng sau khi hủy'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: TroColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hủy cọc'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await _lam(context, {
        'loai': 'CT_HUY_COC',
        'anPhong': an,
      }, ok: 'Đã hủy cọc, đã hoàn 100% cho sinh viên');
    }
  }

  Future<void> _traLoiKhieuNai(BuildContext context) async {
    final c = TextEditingController();
    var bangChung = <String>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Trả lời khiếu nại'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung (ít nhất 10 ký tự)',
                  ),
                ),
                const SizedBox(height: TroSpacing.md),
                TroMediaField(
                  storage: dv.storage,
                  folder: 'tro_anh',
                  nhan: 'Bằng chứng',
                  toiDa: 5,
                  giaTri: bangChung,
                  onChanged: (v) => setS(() => bangChung = v),
                  pickImages: dv.pickImages,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await _lam(context, {
        'loai': 'CT_TRA_LOI_KHIEU_NAI',
        'noiDung': c.text.trim(),
        'bangChung': bangChung,
      }, ok: 'Đã gửi trả lời');
    }
  }

  void _xemBanChup(BuildContext context) {
    final bc = d.chupThongTin!;
    final p = (bc['phong'] as Map?) ?? const {};
    final n = (bc['nhaTro'] as Map?) ?? const {};
    final nq = (n['noiQuy'] as Map?) ?? const {};
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(TroSpacing.screen),
        children: [
          const Text(
            'Thông tin lúc cọc (không đổi khi chủ sửa tin)',
            style: TroText.h2,
          ),
          const SizedBox(height: TroSpacing.md),
          Text(
            'Phòng ${p['ten'] ?? ''} · ${n['ten'] ?? ''}',
            style: TroText.h3,
          ),
          Text(
            'Giá thuê: ${formatPrice((p['giaThue'] as num?) ?? 0)} · Cọc: ${formatPrice((p['tienCoc'] as num?) ?? 0)}',
          ),
          Text(
            'Diện tích: ${p['dienTich'] ?? ''} m² · Tối đa ${p['soNguoiToiDa'] ?? ''} người',
          ),
          Text(
            'Tiện ích: ${[for (final t in (p['tienIch'] as List? ?? const [])) tienIchPhongLabels[t] ?? t].join(', ')}',
          ),
          const SizedBox(height: TroSpacing.sm),
          const Text('Nội quy lúc cọc', style: TroText.label),
          Text(
            'Giờ giấc: ${nq['gioGiac'] == 'tu_do' ? 'Tự do 24/24' : 'Đóng cửa ${nq['gioDongCua'] ?? ''}'}',
          ),
          Text(
            'Thú cưng: ${nq['thuCung'] == true ? 'Cho phép' : 'Không cho phép'}',
          ),
          Text(
            'Ở qua đêm: ${nq['oQuaDem'] == true ? 'Cho phép' : 'Không cho phép'}',
          ),
          Text('Báo trước khi trả phòng: ${nq['baoTruocTuan'] ?? ''} tuần'),
          const SizedBox(height: TroSpacing.sm),
          Text('Mô tả: ${p['moTa'] ?? ''}'),
        ],
      ),
    );
  }
}

class _KhoiDoi extends StatelessWidget {
  const _KhoiDoi({required this.d});

  final DatCoc d;

  @override
  Widget build(BuildContext context) {
    final y = d.doi!;
    final kq = {
      'cho': 'đang chờ chủ trọ trả lời',
      'dong_y': 'chủ trọ đã đồng ý',
      'tu_choi': 'chủ trọ đã từ chối',
      'qua_han': 'quá hạn, đã hoàn 100%',
      'dong': 'đã đóng',
    }[y.ketQua];
    return Padding(
      padding: const EdgeInsets.only(top: TroSpacing.md),
      child: Text(
        'Yêu cầu đổi thời điểm sang ${formatNgayGio(y.thoiDiemMoi)}: $kq.',
        style: TroText.body,
      ),
    );
  }
}

class _KhoiKhongDen extends StatelessWidget {
  const _KhoiKhongDen({required this.d});

  final DatCoc d;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: TroSpacing.md),
    child: TroWarningBox(
      message: d.khongDen!.phanDoi
          ? 'Chủ trọ báo sinh viên không đến lúc ${formatNgayGio(d.khongDen!.luc)}; sinh viên đã phản đối, admin đang xem xét.'
          : 'Chủ trọ báo sinh viên không đến nhận phòng lúc ${formatNgayGio(d.khongDen!.luc)}. Hạn phản đối: ${formatNgayGio(d.khongDen!.hanPhanDoi)}.',
    ),
  );
}

class _KhoiKhieuNai extends StatelessWidget {
  const _KhoiKhieuNai({required this.k});

  final KhieuNai k;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: TroSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(TroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k.loai == 'phan_doi'
                ? 'Phản đối "không đến"'
                : 'Khiếu nại: ${lyDoKhieuNaiLabels[k.lyDo] ?? k.lyDo}',
            style: TroText.h3,
          ),
          const SizedBox(height: TroSpacing.xs),
          Text(k.moTa, style: TroText.body),
          if (k.chuTraLoi != null) ...[
            const SizedBox(height: TroSpacing.sm),
            Text('Chủ trọ trả lời: ${k.chuTraLoi}', style: TroText.body),
          ] else if (k.hanChuTraLoi != null)
            Text(
              'Chủ trọ trả lời trước ${formatNgayGio(k.hanChuTraLoi!)}',
              style: TroText.bodySmall,
            ),
          if (k.ketLuan != null) ...[
            const SizedBox(height: TroSpacing.sm),
            Text(
              'Kết luận của admin: ${KhieuNai.ketLuanLabels[k.ketLuan] ?? k.ketLuan}',
              style: TroText.label,
            ),
            if ((k.lyDoQuyet ?? '').isNotEmpty)
              Text('Lý do: ${k.lyDoQuyet}', style: TroText.bodySmall),
          ] else
            const Text(
              'Tiền cọc tiếp tục được giữ tới khi admin quyết định.',
              style: TroText.bodySmall,
            ),
        ],
      ),
    ),
  );
}
