import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/formatters.dart';
import '../models/don_mon.dart';
import '../models/quan_an_config.dart';
import 'chu_quan_chung.dart';
import '../services/quan_an_api.dart' show ApiException;
import '../services/quan_an_dich_vu.dart';
import 'quan_an_async.dart';
import 'quan_an_media_field.dart';
import 'quan_an_status_badge.dart';
import 'quan_an_theme.dart';

/// Vị trí GPS lấy được lúc bấm (null = không lấy được).
typedef ViTriGps = ({double lat, double lng});
typedef LayViTriGps = Future<ViTriGps?> Function();

/// Lấy vị trí hiện tại bằng geolocator (điện thoại và trình duyệt có định vị).
/// Không được phép / tắt định vị → null để màn hình báo bằng chữ.
Future<ViTriGps?> layViTriGeolocator() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var quyen = await Geolocator.checkPermission();
    if (quyen == LocationPermission.denied) {
      quyen = await Geolocator.requestPermission();
    }
    if (quyen == LocationPermission.denied ||
        quyen == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (lat: p.latitude, lng: p.longitude);
  } catch (_) {
    return null;
  }
}

/// Huy hiệu trạng thái đơn theo màu trạng thái của module (mục 3.19).
QuanAnStatusBadge huyHieuTrangThaiDon(DonMon d) {
  final kind = switch (d.status) {
    'placed' ||
    'delivered' ||
    'not_received' ||
    'disputed' => QuanAnBadgeKind.canhBao,
    'completed' => QuanAnBadgeKind.moCua,
    'ready' || 'delivering' => QuanAnBadgeKind.nhan,
    'rejected' ||
    'cancelled_student' ||
    'cancelled_restaurant' ||
    'expired' ||
    'expired_accept' => QuanAnBadgeKind.dongCua,
    _ => QuanAnBadgeKind.chung,
  };
  return QuanAnStatusBadge(kind: kind, label: d.trangThaiLabel);
}

/// Các nút xử lý đơn của chủ quán, hiện theo trạng thái / điều kiện của [DonMon] (bảng 3.5i).
/// Hệ thống vẫn kiểm tra lại mọi điều kiện khi bấm; mọi thao tác gửi kèm `version` đang thấy.
class DonChuQuanActions extends StatelessWidget {
  const DonChuQuanActions({
    required this.dv,
    required this.don,
    required this.cfg,
    required this.now,
    this.layViTri,
    super.key,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final QuanAnConfig cfg;
  final DateTime now;

  /// Thay cách lấy GPS (dùng khi thử); mặc định geolocator.
  final LayViTriGps? layViTri;

  Future<void> _gui(
    BuildContext context,
    Map<String, dynamic> su, {
    String? thanhCong,
  }) => chayThaoTac(
    context,
    () => dv.donMon.thaoTac(don.id, don.version, su),
    thanhCong: thanhCong,
  );

  Future<void> _tuChoi(BuildContext context) async {
    final dongY = await xacNhan(
      context,
      tieuDe: 'Từ chối đơn này?',
      noiDung: don.traApp
          ? 'Đơn bị hủy và hoàn 100% tiền cho khách.'
          : 'Đơn bị hủy. Đơn tiền mặt không có tiền nào qua app.',
      dongY: 'Từ chối đơn',
      nguyHiem: true,
    );
    if (dongY && context.mounted) {
      await _gui(context, {
        'loai': 'QUAN_TU_CHOI',
      }, thanhCong: 'Đã từ chối đơn');
    }
  }

  Future<void> _huy(BuildContext context) async {
    final dongY = await xacNhan(
      context,
      tieuDe: 'Hủy đơn đã nhận?',
      noiDung:
          'Khách được hoàn 100% (nếu đã trả trên app) và tỷ lệ nhận đơn của '
          'quán bị giảm. Chỉ hủy khi thật sự không làm được.',
      dongY: 'Hủy đơn',
      nguyHiem: true,
    );
    if (dongY && context.mounted) {
      await _gui(context, {'loai': 'QUAN_HUY'}, thanhCong: 'Đã hủy đơn');
    }
  }

  Future<void> _nhapMa(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) =>
          _NhapMaDialog(dv: dv, don: don, soChu: cfg.maNhanMonSoChu),
    );
    if (ok ?? false) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận khách nhận món')),
      );
    }
  }

  Future<void> _bangChung(
    BuildContext context, {
    required String loai,
    required String tieuDe,
    required String huongDan,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => _BangChungSheet(
        dv: dv,
        don: don,
        loai: loai,
        tieuDe: tieuDe,
        huongDan: huongDan,
        layViTri: layViTri ?? layViTriGeolocator,
      ),
    );
    if (ok ?? false) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi ảnh và vị trí')),
      );
    }
  }

  Future<void> _traLoi(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => _TraLoiKhieuNaiDialog(dv: dv, don: don),
    );
    if (ok ?? false) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi câu trả lời khiếu nại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nut = <Widget>[];
    final ghiChu = <String>[];

    if (don.status == 'placed') {
      if (don.coQuanNhan(now)) {
        nut.add(
          FilledButton.icon(
            onPressed: () =>
                _gui(context, {'loai': 'QUAN_NHAN'}, thanhCong: 'Đã nhận đơn'),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Nhận đơn'),
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
        ghiChu.add(
          'Đã quá hạn xác nhận. Hệ thống đang tự hủy đơn'
          '${don.traApp ? ' và hoàn tiền cho khách' : ''}.',
        );
      }
    }

    if (don.coQuanSanSang) {
      nut.add(
        FilledButton.icon(
          onPressed: () => _gui(context, {
            'loai': 'QUAN_SAN_SANG',
          }, thanhCong: 'Đã báo món sẵn sàng cho khách đến lấy'),
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Sẵn sàng (đến lấy)'),
        ),
      );
    }
    if (don.coQuanDangGiao) {
      nut.add(
        FilledButton.icon(
          onPressed: () => _gui(context, {
            'loai': 'QUAN_DANG_GIAO',
          }, thanhCong: 'Đã báo đang giao'),
          icon: const Icon(Icons.delivery_dining_rounded),
          label: const Text('Đang giao'),
        ),
      );
    }
    if (don.coQuanHuy) {
      nut.add(
        OutlinedButton(
          style: kieuNutNguyHiem(),
          onPressed: () => _huy(context),
          child: const Text('Hủy đơn'),
        ),
      );
    }

    if (don.coNhapMa) {
      nut.add(
        FilledButton.icon(
          onPressed: () => _nhapMa(context),
          icon: const Icon(Icons.pin_outlined),
          label: Text('Nhập mã nhận món (${cfg.maNhanMonSoChu} số)'),
        ),
      );
    }
    if (don.coQuanDaGiao) {
      nut.add(
        FilledButton.icon(
          onPressed: () => _bangChung(
            context,
            loai: 'QUAN_DA_GIAO',
            tieuDe: 'Đã giao: ảnh và vị trí',
            huongDan:
                'Chụp ảnh món đã giao tại điểm giao và lấy vị trí GPS. '
                'Hệ thống so vị trí với địa chỉ giao của khách.',
          ),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Đã giao + ảnh GPS'),
        ),
      );
    }

    final khongNhan = don.quanKhongNhan(now, cfg);
    if (khongNhan.hien) {
      nut.add(
        OutlinedButton(
          style: kieuNutNguyHiem(),
          onPressed: khongNhan.bam
              ? () => _bangChung(
                  context,
                  loai: 'QUAN_KHONG_NHAN',
                  tieuDe: 'Khách không nhận: ảnh và vị trí',
                  huongDan: don.laGiao
                      ? 'Chụp ảnh tại điểm giao và lấy vị trí GPS. Khách được '
                            'báo ngay và có ${cfg.phanDoiPhut ~/ 60} giờ để phản đối.'
                      : 'Chụp ảnh tại quán và lấy vị trí GPS. Khách được báo '
                            'ngay và có ${cfg.phanDoiPhut ~/ 60} giờ để phản đối.',
                )
              : null,
          child: const Text('Khách không nhận'),
        ),
      );
      if (!khongNhan.bam && khongNhan.giaiThich != null) {
        ghiChu.add(khongNhan.giaiThich!);
      }
    }

    if (don.coQuanTraLoiKhieuNai(now)) {
      nut.add(
        FilledButton.icon(
          onPressed: () => _traLoi(context),
          icon: const Icon(Icons.reply_rounded),
          label: const Text('Trả lời khiếu nại'),
        ),
      );
    }

    if (nut.isEmpty && ghiChu.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nut.isNotEmpty)
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: nut,
          ),
        for (final g in ghiChu)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
            child: Text(g, style: QuanAnText.bodySmall),
          ),
      ],
    );
  }
}

/// Hộp nhập mã nhận món. Chủ quán không xem được mã, chỉ nhập mã khách đọc cho.
class _NhapMaDialog extends StatefulWidget {
  const _NhapMaDialog({
    required this.dv,
    required this.don,
    required this.soChu,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final int soChu;

  @override
  State<_NhapMaDialog> createState() => _NhapMaDialogState();
}

class _NhapMaDialogState extends State<_NhapMaDialog> {
  final _ma = TextEditingController();
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _ma.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final ma = _ma.text.trim();
    if (ma.length != widget.soChu) {
      setState(() => _loi = 'Nhập đủ ${widget.soChu} số.');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await widget.dv.donMon.thaoTac(widget.don.id, widget.don.version, {
        'loai': 'QUAN_NHAP_MA',
        'ma': ma,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nhập mã nhận món'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hỏi khách mã ${widget.soChu} số hiện trên app của khách. '
            'Chủ quán không xem được mã này.',
            style: QuanAnText.bodySmall,
          ),
          const SizedBox(height: QuanAnSpacing.md),
          TextField(
            controller: _ma,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: widget.soChu,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _gui(),
            onChanged: (_) {
              if (_loi != null) setState(() => _loi = null);
            },
            decoration: InputDecoration(
              labelText: 'Mã nhận món',
              errorText: _loi,
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _dangGui ? null : () => Navigator.pop(context, false),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: _dangGui ? null : _gui,
        child: Text(_dangGui ? 'Đang gửi...' : 'Xác nhận'),
      ),
    ],
  );
}

/// Bảng gửi bằng chứng: ảnh (link hoặc tải lên) + vị trí GPS, cho "Đã giao" và "Khách không nhận".
/// Việc chụp trực tiếp trong app có GPS sẽ bổ sung khi có máy Android thật.
class _BangChungSheet extends StatefulWidget {
  const _BangChungSheet({
    required this.dv,
    required this.don,
    required this.loai,
    required this.tieuDe,
    required this.huongDan,
    required this.layViTri,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final String loai;
  final String tieuDe;
  final String huongDan;
  final LayViTriGps layViTri;

  @override
  State<_BangChungSheet> createState() => _BangChungSheetState();
}

class _BangChungSheetState extends State<_BangChungSheet> {
  List<String> _anh = [];
  ViTriGps? _viTri;
  bool _dangGps = false;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _layGps();
  }

  Future<void> _layGps() async {
    setState(() {
      _dangGps = true;
      _loi = null;
    });
    final v = await widget.layViTri();
    if (!mounted) return;
    setState(() {
      _viTri = v;
      _dangGps = false;
    });
  }

  Future<void> _gui() async {
    final l = <String>[
      if (_anh.isEmpty) 'Thêm ảnh chụp tại chỗ (link hoặc tải lên).',
      if (_viTri == null) 'Cần lấy được vị trí GPS. Bấm "Lấy lại vị trí".',
    ];
    if (l.isNotEmpty) {
      setState(() => _loi = l.join(' '));
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await widget.dv.donMon.thaoTac(widget.don.id, widget.don.version, {
        'loai': widget.loai,
        'anh': _anh.first,
        'lat': _viTri!.lat,
        'lng': _viTri!.lng,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(QuanAnSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.tieuDe, style: QuanAnText.h2),
          const SizedBox(height: QuanAnSpacing.xs),
          Text(widget.huongDan, style: QuanAnText.bodySmall),
          const SizedBox(height: QuanAnSpacing.lg),
          QuanAnMediaField(
            storage: widget.dv.storage,
            folder: 'quan_an_bang_chung',
            nhan: 'Ảnh',
            toiThieu: 1,
            toiDa: 1,
            giaTri: _anh,
            onChanged: (v) => setState(() => _anh = v),
            pickImages: widget.dv.pickImages,
            goiY:
                'Đồ án: dán link hoặc tải ảnh lên. Chụp trực tiếp trong app '
                'sẽ bổ sung khi có máy Android thật.',
          ),
          const SizedBox(height: QuanAnSpacing.lg),
          Row(
            children: [
              Icon(
                _viTri == null
                    ? Icons.location_off_outlined
                    : Icons.my_location_rounded,
                color: _viTri == null
                    ? QuanAnColors.warning
                    : QuanAnColors.success,
              ),
              const SizedBox(width: QuanAnSpacing.sm),
              Expanded(
                child: Text(
                  _dangGps
                      ? 'Đang lấy vị trí...'
                      : (_viTri == null
                            ? 'Chưa có vị trí GPS. Hãy bật định vị và cho phép '
                                  'ứng dụng / trình duyệt dùng vị trí.'
                            : 'Vị trí: ${_viTri!.lat.toStringAsFixed(5)}, '
                                  '${_viTri!.lng.toStringAsFixed(5)}'),
                  style: QuanAnText.body,
                ),
              ),
              TextButton(
                onPressed: _dangGps ? null : _layGps,
                child: const Text('Lấy lại vị trí'),
              ),
            ],
          ),
          if (_loi != null) ...[
            const SizedBox(height: QuanAnSpacing.md),
            HopThongBao.loi(noiDung: _loi!),
          ],
          const SizedBox(height: QuanAnSpacing.lg),
          FilledButton(
            onPressed: _dangGui ? null : _gui,
            child: Text(_dangGui ? 'Đang gửi...' : 'Gửi'),
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          OutlinedButton(
            onPressed: _dangGui ? null : () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}

/// Trả lời khiếu nại: nội dung + (tùy chọn) đề nghị hoàn toàn phần / một phần.
class _TraLoiKhieuNaiDialog extends StatefulWidget {
  const _TraLoiKhieuNaiDialog({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  @override
  State<_TraLoiKhieuNaiDialog> createState() => _TraLoiKhieuNaiDialogState();
}

class _TraLoiKhieuNaiDialogState extends State<_TraLoiKhieuNaiDialog> {
  final _noiDung = TextEditingController();
  String? _hoan;
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _noiDung.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final nd = _noiDung.text.trim();
    if (nd.length < 5) {
      setState(() => _loi = 'Nhập nội dung trả lời (ít nhất 5 ký tự).');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await widget.dv.donMon.thaoTac(widget.don.id, widget.don.version, {
        'loai': 'QUAN_TRA_LOI_KHIEU_NAI',
        'noiDung': nd,
        'deNghiHoan': ?_hoan,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.don.khieuNai;
    return AlertDialog(
      title: const Text('Trả lời khiếu nại'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (k != null) ...[
              Text(
                '${k.loaiLabel}${k.lyDo.isEmpty ? '' : ': ${k.lyDoLabel}'}',
                style: QuanAnText.label,
              ),
              if (k.moTa.isNotEmpty) Text(k.moTa, style: QuanAnText.body),
              if (k.hanChuTraLoi != null)
                Text(
                  'Trả lời trước ${formatNgayGio(k.hanChuTraLoi!)}. '
                  'Không trả lời kịp thì admin quyết dựa trên bằng chứng của khách.',
                  style: QuanAnText.bodySmall,
                ),
              const SizedBox(height: QuanAnSpacing.md),
            ],
            TextField(
              controller: _noiDung,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Nội dung trả lời'),
            ),
            const SizedBox(height: QuanAnSpacing.sm),
            const Text('Đề nghị hoàn tiền (tùy chọn)', style: QuanAnText.label),
            const SizedBox(height: QuanAnSpacing.xs),
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.xs,
              children: [
                ChoiceChip(
                  label: const Text('Không đề nghị'),
                  selected: _hoan == null,
                  onSelected: (_) => setState(() => _hoan = null),
                ),
                ChoiceChip(
                  label: const Text('Hoàn toàn phần'),
                  selected: _hoan == 'hoan_toan',
                  onSelected: (_) => setState(() => _hoan = 'hoan_toan'),
                ),
                ChoiceChip(
                  label: const Text('Hoàn một phần'),
                  selected: _hoan == 'hoan_mot_phan',
                  onSelected: (_) => setState(() => _hoan = 'hoan_mot_phan'),
                ),
              ],
            ),
            if (_loi != null) ...[
              const SizedBox(height: QuanAnSpacing.md),
              HopThongBao.loi(noiDung: _loi!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: Text(_dangGui ? 'Đang gửi...' : 'Gửi trả lời'),
        ),
      ],
    );
  }
}

/// Dòng "2 × Cơm gà (Cỡ: Lớn)".
String dongMonTrongDon(MonTrongDon m) =>
    '${m.soLuong} × ${m.ten}${m.tuyChon.isEmpty ? '' : ' (${m.tuyChonMoTa})'}';

/// Thẻ đơn trong danh sách của chủ quán: món, tổng, cách nhận, giờ dự kiến, cách trả,
/// đếm ngược và nút xử lý. Bấm vào phần thông tin để mở chi tiết ([onMo]).
class DonChuQuanThe extends StatelessWidget {
  const DonChuQuanThe({
    required this.dv,
    required this.don,
    required this.cfg,
    this.onMo,
    this.layViTri,
    super.key,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final QuanAnConfig cfg;
  final VoidCallback? onMo;
  final LayViTriGps? layViTri;

  @override
  Widget build(BuildContext context) => QuanAnDongHo(
    builder: (context, now) {
      final d = don;
      final gioDuKien = d.laHenGio
          ? (d.gioHen == null
                ? 'Hẹn giờ'
                : 'Hẹn giờ: ${formatNgayGio(d.gioHen!)}')
          : (d.gioDuKienSanSang == null
                ? 'Càng sớm càng tốt'
                : 'Dự kiến sẵn sàng: ${formatNgayGio(d.gioDuKienSanSang!)}');
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(QuanAnRadius.card),
              ),
              onTap: onMo,
              child: Padding(
                padding: const EdgeInsets.all(QuanAnSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đơn ${maNgan(d.id)}',
                            style: QuanAnText.h3,
                          ),
                        ),
                        const SizedBox(width: QuanAnSpacing.sm),
                        Flexible(child: huyHieuTrangThaiDon(d)),
                      ],
                    ),
                    const SizedBox(height: QuanAnSpacing.sm),
                    Wrap(
                      spacing: QuanAnSpacing.sm,
                      runSpacing: QuanAnSpacing.xs,
                      children: [
                        QuanAnStatusBadge(
                          kind: QuanAnBadgeKind.chung,
                          label: d.cachNhanLabel,
                          icon: d.laGiao
                              ? Icons.delivery_dining_rounded
                              : Icons.storefront_rounded,
                        ),
                        if (d.laTienMat)
                          QuanAnStatusBadge(
                            kind: QuanAnBadgeKind.canhBao,
                            label:
                                'Tiền mặt: thu ${formatPrice(d.tong)} khi nhận',
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
                    const SizedBox(height: QuanAnSpacing.md),
                    for (final m in d.monAn.take(3))
                      Text(dongMonTrongDon(m), style: QuanAnText.body),
                    if (d.monAn.length > 3)
                      Text(
                        '+ ${d.monAn.length - 3} món khác',
                        style: QuanAnText.bodySmall,
                      ),
                    const SizedBox(height: QuanAnSpacing.sm),
                    Row(
                      children: [
                        const Text('Tổng', style: QuanAnText.bodySmall),
                        const Spacer(),
                        Text(formatPrice(d.tong), style: QuanAnText.price),
                      ],
                    ),
                    const SizedBox(height: QuanAnSpacing.xs),
                    Text(gioDuKien, style: QuanAnText.bodySmall),
                    if (d.laGiao && d.diaChiGiao != null)
                      Text(
                        'Giao đến: ${d.diaChiGiao!.dong}',
                        style: QuanAnText.bodySmall,
                      ),
                    if (d.ghiChuQuan.isNotEmpty)
                      Text(
                        'Ghi chú: ${d.ghiChuQuan}',
                        style: QuanAnText.bodySmall,
                      ),
                    _DemNguocDon(don: d, cfg: cfg, now: now),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                QuanAnSpacing.lg,
                0,
                QuanAnSpacing.lg,
                QuanAnSpacing.lg,
              ),
              child: DonChuQuanActions(
                dv: dv,
                don: d,
                cfg: cfg,
                now: now,
                layViTri: layViTri,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Đếm ngược của đơn: đơn mới có thanh tiến độ mm:ss (5 phút để nhận), đơn khác theo mốc chính.
class _DemNguocDon extends StatelessWidget {
  const _DemNguocDon({required this.don, required this.cfg, required this.now});

  final DonMon don;
  final QuanAnConfig cfg;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (don.status == 'placed' && don.hanQuanNhan != null) {
      final con = don.hanQuanNhan!.difference(now);
      final tong = QuanAnConfig.phut(cfg.quanXacNhanPhut);
      final tiLe = tong.inSeconds == 0
          ? 0.0
          : (con.inSeconds / tong.inSeconds).clamp(0.0, 1.0);
      final gap = con.inSeconds <= 60;
      final mau = gap ? QuanAnColors.danger : QuanAnColors.warning;
      return Padding(
        padding: const EdgeInsets.only(top: QuanAnSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: mau),
                const SizedBox(width: QuanAnSpacing.xs),
                Expanded(
                  child: Text(
                    con.inSeconds <= 0
                        ? 'Đã quá hạn xác nhận'
                        : 'Còn ${phutGiay(con)} để nhận hoặc từ chối',
                    style: TextStyle(color: mau, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QuanAnSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(QuanAnRadius.pill),
              child: LinearProgressIndicator(
                value: tiLe,
                minHeight: 6,
                backgroundColor: QuanAnColors.skeleton,
                color: mau,
              ),
            ),
          ],
        ),
      );
    }
    final moc = don.mocDemNguoc(now, cfg);
    if (moc == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: QuanAnColors.textSecondary,
          ),
          const SizedBox(width: QuanAnSpacing.xs),
          Expanded(
            child: Text(
              '${moc.$1}: ${formatNgayGio(moc.$2)} '
              '(${formatConLai(moc.$2.difference(now))})',
              style: QuanAnText.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
