import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/services/xac_thuc_service.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/lich_gio_mo_cua_editor.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';

/// QA-CQ-07 Giờ mở cửa / tạm nghỉ: lịch tuần, tạm nghỉ hôm nay, nghỉ dài ngày, mở lại,
/// tạm ngưng nhận đơn. Tạm nghỉ khi đang có đơn / bàn thì hỏi lại (mục 3.14).
class QuanLyGioMoCuaScreen extends StatefulWidget {
  const QuanLyGioMoCuaScreen({
    required this.dv,
    required this.quanId,
    super.key,
  });

  final QuanAnDichVu dv;
  final String quanId;

  @override
  State<QuanLyGioMoCuaScreen> createState() => _QuanLyGioMoCuaScreenState();
}

class _QuanLyGioMoCuaScreenState extends State<QuanLyGioMoCuaScreen> {
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
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Giờ mở cửa')),
    body: QuanAnStream<QuanAn?>(
      stream: () => widget.dv.quan.quan(widget.quanId),
      thongBaoLoi: 'Không tải được thông tin quán',
      builder: (context, q) => q == null
          ? const QuanAnEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Không tìm thấy quán',
            )
          : _NoiDung(key: ValueKey(q.id), dv: widget.dv, quan: q, cfg: _cfg),
    ),
  );
}

class _NoiDung extends StatefulWidget {
  const _NoiDung({
    required this.dv,
    required this.quan,
    required this.cfg,
    super.key,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final QuanAnConfig cfg;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  late LichMoCua _lich = _sao(widget.quan.gioMoCua);
  bool _daSua = false;
  bool _dangChay = false;
  List<String> _loiLich = const [];
  List<String> _loiThaoTac = const [];

  static LichMoCua _sao(LichMoCua l) => {
    for (final e in l.entries) e.key: List<CaMoCua>.of(e.value),
  };

  @override
  void didUpdateWidget(covariant _NoiDung old) {
    super.didUpdateWidget(old);
    // Chưa sửa gì thì theo dữ liệu mới nhất từ hệ thống.
    if (!_daSua) _lich = _sao(widget.quan.gioMoCua);
  }

  QuanAn get _q => widget.quan;

  String _loiChu(Object e) =>
      e is ApiException ? e.message : 'Có lỗi xảy ra, vui lòng thử lại.';

  void _bao(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _luuLich() async {
    final loi = LichGioMoCuaEditor.kiemTra(
      _lich,
      toiDaCa: widget.cfg.caMoCuaToiDa,
    );
    setState(() => _loiLich = loi);
    if (loi.isNotEmpty) return;
    setState(() => _dangChay = true);
    try {
      await widget.dv.quan.thaoTac('suaQuan', {
        'quanId': _q.id,
        'gioMoCua': lichToMap(_lich),
      });
      if (!mounted) return;
      setState(() => _daSua = false);
      _bao('Đã lưu giờ mở cửa, hiện ngay cho khách.');
    } catch (e) {
      if (mounted) setState(() => _loiLich = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangChay = false);
    }
  }

  /// Gọi `tamNghi`; nếu có đơn / bàn bị ảnh hưởng thì hỏi lại rồi gọi lần hai với `xacNhan`.
  Future<void> _tamNghi(String kieu, {DateTime? den}) async {
    setState(() {
      _dangChay = true;
      _loiThaoTac = const [];
    });
    try {
      final tham = <String, dynamic>{
        'quanId': _q.id,
        'kieu': kieu,
        if (den != null) 'den': den.millisecondsSinceEpoch,
      };
      var kq = await widget.dv.quan.thaoTac('tamNghi', tham);
      if (kq['canXacNhan'] == true) {
        if (!mounted) return;
        final ok = await _hoiXacNhan(
          demKetQua(kq['donAnhHuong']),
          demKetQua(kq['banAnhHuong']),
        );
        if (!ok) return;
        kq = await widget.dv.quan.thaoTac('tamNghi', {
          ...tham,
          'xacNhan': true,
        });
      }
      if (!mounted) return;
      _bao(
        kieu == 'mo_lai'
            ? 'Quán đã mở lại theo lịch tuần.'
            : 'Đã chuyển quán sang tạm nghỉ.',
      );
    } catch (e) {
      if (mounted) setState(() => _loiThaoTac = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangChay = false);
    }
  }

  Future<bool> _hoiXacNhan(int don, int ban) async {
    final kq = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Đang có đơn / bàn bị ảnh hưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn đang chờ quán xác nhận: $don đơn.'),
            Text('Bàn đã xác nhận chưa tới giờ: $ban bàn.'),
            const SizedBox(height: QuanAnSpacing.md),
            const Text(
              'Nếu tạm nghỉ: đơn chờ xác nhận sẽ bị hủy và hoàn tiền 100%; '
              'bàn đã xác nhận bị hủy và tính là lỗi của quán (giảm tỷ lệ giữ bàn). '
              'Đơn quán đã nhận vẫn phải làm xong.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Vẫn tạm nghỉ'),
          ),
        ],
      ),
    );
    return kq ?? false;
  }

  Future<void> _nghiDaiNgay() async {
    final bayGio = gioVietNam(DateTime.now());
    final homNay = DateTime(bayGio.year, bayGio.month, bayGio.day);
    final ngay = await showDatePicker(
      context: context,
      helpText: 'Chọn ngày quán mở lại',
      initialDate: homNay.add(const Duration(days: 2)),
      firstDate: homNay.add(const Duration(days: 1)),
      lastDate: homNay.add(const Duration(days: 365)),
    );
    if (ngay == null || !mounted) return;
    await _tamNghi('dai_ngay', den: dauNgayVn(ngay));
  }

  Future<void> _tamNgungDon(bool bat) async {
    setState(() {
      _dangChay = true;
      _loiThaoTac = const [];
    });
    try {
      await widget.dv.quan.thaoTac('tamNgungNhanDon', {
        'quanId': _q.id,
        'bat': bat,
      });
      if (!mounted) return;
      _bao(bat ? 'Đã tạm ngưng nhận đơn mới.' : 'Đã nhận đơn trở lại.');
    } catch (e) {
      if (mounted) setState(() => _loiThaoTac = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangChay = false);
    }
  }

  QuanAnBadgeKind _kind(TrangThaiMoCua t) => switch (t) {
    TrangThaiMoCua.mo => QuanAnBadgeKind.moCua,
    TrangThaiMoCua.sapDong => QuanAnBadgeKind.sapDong,
    TrangThaiMoCua.dong => QuanAnBadgeKind.dongCua,
    TrangThaiMoCua.tamNghi => QuanAnBadgeKind.tamNghi,
  };

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final loiLichKiemTra = _daSua
        ? LichGioMoCuaEditor.kiemTra(_lich, toiDaCa: widget.cfg.caMoCuaToiDa)
        : const <String>[];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: TrangRong(
              rongToiDa: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuanAnDongHo(
                    chuKy: const Duration(seconds: 30),
                    builder: (context, now) =>
                        _TrangThaiHienTai(quan: q, now: now, kind: _kind),
                  ),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  KhoiThongTin(
                    tieuDe: 'Tạm nghỉ',
                    phu: 'Quán vẫn hiện trên danh sách nhưng ghi "Tạm nghỉ", khách không đặt món / đặt bàn được.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: QuanAnSpacing.sm,
                          runSpacing: QuanAnSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _dangChay
                                  ? null
                                  : () => _tamNghi('hom_nay'),
                              icon: const Icon(Icons.pause_circle_outline),
                              label: const Text('Tạm nghỉ hôm nay'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _dangChay ? null : _nghiDaiNgay,
                              icon: const Icon(Icons.event_busy_outlined),
                              label: const Text('Nghỉ dài ngày đến ngày...'),
                            ),
                            if (q.tamNghiDen != null &&
                                q.tamNghiDen!.isAfter(DateTime.now()))
                              OutlinedButton.icon(
                                onPressed: _dangChay
                                    ? null
                                    : () => _tamNghi('mo_lai'),
                                icon: const Icon(Icons.play_circle_outline),
                                label: const Text('Mở lại'),
                              ),
                          ],
                        ),
                        const SizedBox(height: QuanAnSpacing.sm),
                        const Text(
                          '"Tạm nghỉ hôm nay" hết hiệu lực ở ca mở kế tiếp theo lịch tuần, tính từ ngày mai.',
                          style: QuanAnText.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  KhoiThongTin(
                    tieuDe: 'Tạm ngưng nhận đơn',
                    phu: 'Dùng khi quá đông: quán vẫn hiện là đang mở, chỉ chặn đơn mới. Đơn đã nhận vẫn làm bình thường.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: q.tamNgungNhanDon,
                          onChanged: _dangChay || !q.laHoKinhDoanh
                              ? null
                              : _tamNgungDon,
                          title: const Text('Tạm ngưng nhận đơn mới'),
                          subtitle: Text(
                            q.laHoKinhDoanh
                                ? (q.tamNgungNhanDon
                                      ? 'Đang tạm ngưng. Gạt tắt để nhận đơn lại.'
                                      : 'Đang nhận đơn bình thường.')
                                : 'Chỉ quán hộ kinh doanh có nhận đơn qua app.',
                          ),
                        ),
                        if (q.tamNgungDen != null &&
                            q.tamNgungDen!.isAfter(DateTime.now()))
                          HopThongBao.canhBao(
                            noiDung:
                                'Hệ thống đã tự tạm ngưng nhận đơn đến ${formatNgayGio(q.tamNgungDen!)} '
                                'vì quán bỏ lỡ nhiều đơn liên tiếp (${widget.cfg.tuTamNgungSoLan} đơn). '
                                'Hết giờ này sẽ tự nhận lại.',
                          ),
                      ],
                    ),
                  ),
                  KhungLoiDo(_loiThaoTac, tieuDe: 'Chưa thực hiện được:'),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  KhoiThongTin(
                    tieuDe: 'Lịch mở cửa theo tuần',
                    phu:
                        'Mỗi ngày tối đa ${widget.cfg.caMoCuaToiDa} ca hoặc nghỉ. Lưu xong hiện ngay, không cần duyệt.',
                    child: LichGioMoCuaEditor(
                      lich: _lich,
                      toiDaCa: widget.cfg.caMoCuaToiDa,
                      onChanged: (v) => setState(() {
                        _lich = v;
                        _daSua = true;
                        _loiLich = const [];
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ThanhDuoiForm(
          loi: _loiLich.isNotEmpty ? _loiLich : loiLichKiemTra,
          child: FilledButton(
            onPressed: _dangChay || !_daSua ? null : _luuLich,
            child: Text(
              _dangChay
                  ? 'Đang xử lý...'
                  : (_daSua ? 'Lưu giờ mở cửa' : 'Chưa có thay đổi'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrangThaiHienTai extends StatelessWidget {
  const _TrangThaiHienTai({
    required this.quan,
    required this.now,
    required this.kind,
  });

  final QuanAn quan;
  final DateTime now;
  final QuanAnBadgeKind Function(TrangThaiMoCua) kind;

  @override
  Widget build(BuildContext context) {
    final t = quan.moCua(now);
    final tamNgung = quan.dangTamNgung(now);
    return KhoiThongTin(
      tieuDe: 'Hiện tại',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.xs,
            children: [
              QuanAnStatusBadge(
                kind: kind(t.trangThai),
                label: t.trangThai.label,
              ),
              if (tamNgung)
                const QuanAnStatusBadge(
                  kind: QuanAnBadgeKind.sapDong,
                  label: 'Tạm ngưng nhận đơn',
                ),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          Text(t.thongDiep, style: QuanAnText.body),
          if (quan.trangThai != 'active')
            Padding(
              padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
              child: Text(
                'Quán đang ở trạng thái "${quan.trangThaiLabel}" nên chưa hiện cho khách.',
                style: QuanAnText.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
