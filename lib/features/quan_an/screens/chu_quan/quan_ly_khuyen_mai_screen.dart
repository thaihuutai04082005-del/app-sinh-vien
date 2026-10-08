import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/services/xac_thuc_service.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/khuyen_mai.dart';
import '../../models/mon_an.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// Trạng thái hiển thị của khuyến mãi: đang chạy · đã dừng · hết hạn (quá ngày kết thúc).
String _trangThaiHienThi(KhuyenMai k, DateTime now) {
  if (k.trangThai == 'dung') return 'dung';
  if (k.trangThai == 'het_han') return 'het_han';
  if (k.ketThuc != null && now.isAfter(k.ketThuc!)) return 'het_han';
  return 'chay';
}

String _loiChu(Object e) =>
    e is ApiException ? e.message : 'Có lỗi xảy ra, vui lòng thử lại.';

/// QA-CQ-06 Khuyến mãi: danh sách, tạo / sửa 5 loại, dừng. Không cần duyệt.
class QuanLyKhuyenMaiScreen extends StatefulWidget {
  const QuanLyKhuyenMaiScreen({
    required this.dv,
    required this.quanId,
    super.key,
  });

  final QuanAnDichVu dv;
  final String quanId;

  @override
  State<QuanLyKhuyenMaiScreen> createState() => _QuanLyKhuyenMaiScreenState();
}

class _QuanLyKhuyenMaiScreenState extends State<QuanLyKhuyenMaiScreen> {
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
    appBar: AppBar(title: const Text('Khuyến mãi')),
    body: QuanAnStream<QuanAn?>(
      stream: () => widget.dv.quan.quan(widget.quanId),
      thongBaoLoi: 'Không tải được thông tin quán',
      builder: (context, q) => q == null
          ? const QuanAnEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Không tìm thấy quán',
            )
          : QuanAnStream<List<KhuyenMai>>(
              stream: () => widget.dv.khuyenMai.cuaChu(widget.quanId),
              thongBaoLoi: 'Không tải được khuyến mãi',
              builder: (context, ds) =>
                  _DanhSach(dv: widget.dv, quan: q, cfg: _cfg, ds: ds),
            ),
    ),
  );
}

class _DanhSach extends StatelessWidget {
  const _DanhSach({
    required this.dv,
    required this.quan,
    required this.cfg,
    required this.ds,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final QuanAnConfig cfg;
  final List<KhuyenMai> ds;

  Future<void> _mo(BuildContext context, [KhuyenMai? km]) =>
      QuanAnDieuHuong.mo<bool>(
        context,
        (_) => _KhuyenMaiEditor(dv: dv, quan: quan, cfg: cfg, km: km),
      );

  Future<void> _dung(BuildContext context, KhuyenMai km) async {
    final ok = await xacNhan(
      context,
      tieuDe: 'Dừng khuyến mãi?',
      noiDung:
          '"${km.tieuDe}" sẽ ngừng áp dụng ngay. Đơn đã đặt trước đó không bị ảnh hưởng. Dừng rồi không bật lại được, bạn tạo khuyến mãi mới nếu cần.',
      dongY: 'Dừng khuyến mãi',
      nguyHiem: true,
    );
    if (ok && context.mounted) {
      await chayThaoTac(
        context,
        () => dv.khuyenMai.dung(km.id),
        thanhCong: 'Đã dừng khuyến mãi',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final toiDa = cfg.khuyenMaiToiDa(quan.loaiQuan);
    final dangChay = ds.where((k) => _trangThaiHienThi(k, now) == 'chay');
    final soChay = dangChay.length;
    final du = soChay >= toiDa;
    final sapXep = [...ds]
      ..sort((a, b) {
        final ta = _trangThaiHienThi(a, now) == 'chay' ? 0 : 1;
        final tb = _trangThaiHienThi(b, now) == 'chay' ? 0 : 1;
        if (ta != tb) return ta.compareTo(tb);
        return (b.batDau ?? DateTime(2000)).compareTo(
          a.batDau ?? DateTime(2000),
        );
      });
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QuanAnSpacing.screen),
      child: TrangRong(
        rongToiDa: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KhoiThongTin(
              tieuDe: 'Đang chạy $soChay/$toiDa khuyến mãi',
              phu: quan.laHoKinhDoanh
                  ? 'Tối đa $toiDa khuyến mãi cùng lúc. Hệ thống tự tính giảm giá khi khách đặt món qua app. Không cần duyệt, nhưng khuyến mãi sai thực tế có thể bị báo cáo.'
                  : 'Quán bán lẻ tối đa $toiDa khuyến mãi. Khuyến mãi chỉ hiển thị cho khách xem, không tự trừ vào tiền.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!quan.laHoKinhDoanh)
                    const Padding(
                      padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                      child: HopThongBao(
                        noiDung: 'Chỉ hiển thị, không tự trừ. Bạn tự giảm giá khi bán tại quán.',
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: du ? null : () => _mo(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tạo khuyến mãi'),
                  ),
                  if (du)
                    Padding(
                      padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                      child: Text(
                        'Đã đủ $toiDa khuyến mãi đang chạy. Dừng bớt một khuyến mãi mới tạo thêm được.',
                        style: QuanAnText.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: QuanAnSpacing.cardGap),
            if (sapXep.isEmpty)
              const QuanAnEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'Chưa có khuyến mãi',
                message: 'Tạo khuyến mãi để quán nổi bật hơn trong danh sách.',
              ),
            for (final km in sapXep) ...[
              _TheKhuyenMai(
                km: km,
                now: now,
                onSua: () => _mo(context, km),
                onDung: () => _dung(context, km),
              ),
              const SizedBox(height: QuanAnSpacing.cardGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _TheKhuyenMai extends StatelessWidget {
  const _TheKhuyenMai({
    required this.km,
    required this.now,
    required this.onSua,
    required this.onDung,
  });

  final KhuyenMai km;
  final DateTime now;
  final VoidCallback onSua;
  final VoidCallback onDung;

  @override
  Widget build(BuildContext context) {
    final tt = _trangThaiHienThi(km, now);
    final chay = tt == 'chay';
    final chuaBatDau = chay && km.batDau != null && now.isBefore(km.batDau!);
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
                QuanAnStatusBadge(
                  kind: chay ? QuanAnBadgeKind.moCua : QuanAnBadgeKind.chung,
                  label: chuaBatDau
                      ? 'Sắp chạy'
                      : (trangThaiKhuyenMaiLabels[tt] ?? tt),
                ),
                QuanAnStatusBadge(
                  kind: QuanAnBadgeKind.nhan,
                  label: km.loaiLabel,
                  icon: Icons.local_offer_outlined,
                ),
              ],
            ),
            const SizedBox(height: QuanAnSpacing.sm),
            Text(km.tieuDe, style: QuanAnText.h3),
            const SizedBox(height: QuanAnSpacing.xs),
            Text(km.moTaNgan, style: QuanAnText.body),
            if (km.batDau != null && km.ketThuc != null)
              Text(
                'Từ ${formatNgay(km.batDau!)} đến ${formatNgay(km.ketThuc!)}',
                style: QuanAnText.bodySmall,
              ),
            if (chay) ...[
              const SizedBox(height: QuanAnSpacing.sm),
              Wrap(
                spacing: QuanAnSpacing.sm,
                runSpacing: QuanAnSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: onSua,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                  ),
                  OutlinedButton.icon(
                    style: kieuNutNguyHiem(),
                    onPressed: onDung,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Dừng khuyến mãi'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tạo / sửa khuyến mãi
// ---------------------------------------------------------------------------

class _KhuyenMaiEditor extends StatefulWidget {
  const _KhuyenMaiEditor({
    required this.dv,
    required this.quan,
    required this.cfg,
    this.km,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final QuanAnConfig cfg;
  final KhuyenMai? km;

  @override
  State<_KhuyenMaiEditor> createState() => _KhuyenMaiEditorState();
}

class _KhuyenMaiEditorState extends State<_KhuyenMaiEditor> {
  final _tieuDe = TextEditingController();
  final _phanTram = TextEditingController();
  final _giamToiDa = TextEditingController();
  final _giamTien = TextEditingController();
  final _donToiThieu = TextEditingController();
  final _giaCombo = TextEditingController();

  String _loai = 'giam_phan_tram';
  // Ưu đãi sinh viên: giảm theo % hay theo tiền.
  bool _svTheoTien = false;
  // monId -> số lượng
  final Map<String, int> _combo = {};
  int _tu = 14 * 60;
  int _den = 16 * 60;
  final Set<int> _ngay = {1, 2, 3, 4, 5};
  late DateTime _batDau;
  late DateTime _ketThuc;
  List<String> _loi = const [];
  bool _dangLuu = false;

  static DateTime _chiNgay(DateTime t) {
    final v = gioVietNam(t);
    return DateTime(v.year, v.month, v.day);
  }

  @override
  void initState() {
    super.initState();
    final homNay = _chiNgay(DateTime.now());
    _batDau = homNay;
    _ketThuc = homNay.add(const Duration(days: 29));
    final k = widget.km;
    if (k == null) return;
    _loai = k.loai;
    _tieuDe.text = k.tieuDe;
    _phanTram.text = k.phanTram == null ? '' : _s(k.phanTram!);
    _giamToiDa.text = k.giamToiDa == null ? '' : _s(k.giamToiDa!);
    _giamTien.text = k.giamTien == null ? '' : _s(k.giamTien!);
    _donToiThieu.text = k.donToiThieu == null ? '' : _s(k.donToiThieu!);
    _svTheoTien = k.loai == 'sinh_vien' && (k.giamTien ?? 0) > 0;
    if (k.combo != null) {
      for (final m in k.combo!.mon) {
        _combo[m.monId] = m.soLuong;
      }
      _giaCombo.text = _s(k.combo!.gia);
    }
    final g = k.gioVang;
    if (g != null) {
      _tu = g.tu;
      _den = g.den;
      _ngay
        ..clear()
        ..addAll(g.ngay);
      if (g.giamToiDa != null) _giamToiDa.text = _s(g.giamToiDa!);
      _phanTram.text = _s(g.phanTram);
    }
    if (k.batDau != null) _batDau = _chiNgay(k.batDau!);
    if (k.ketThuc != null) _ketThuc = _chiNgay(k.ketThuc!);
  }

  @override
  void dispose() {
    for (final c in [
      _tieuDe,
      _phanTram,
      _giamToiDa,
      _giamTien,
      _donToiThieu,
      _giaCombo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _s(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  num? _so(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : num.tryParse(t);
  }

  String _ngayChu(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _chonNgay(bool batDau) async {
    final homNay = _chiNgay(DateTime.now());
    final g = await showDatePicker(
      context: context,
      helpText: batDau ? 'Ngày bắt đầu' : 'Ngày kết thúc',
      initialDate: batDau ? _batDau : _ketThuc,
      firstDate: widget.km == null ? homNay : DateTime(2024),
      lastDate: homNay.add(const Duration(days: 365)),
    );
    if (g == null) return;
    setState(() {
      if (batDau) {
        _batDau = g;
        if (_ketThuc.isBefore(g)) _ketThuc = g;
      } else {
        _ketThuc = g;
      }
    });
  }

  Future<void> _chonGio(bool tu) async {
    final phut = tu ? _tu : _den;
    final g = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: phut ~/ 60, minute: phut % 60),
      helpText: tu ? 'Giờ bắt đầu' : 'Giờ kết thúc',
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (g == null) return;
    setState(() {
      if (tu) {
        _tu = g.hour * 60 + g.minute;
      } else {
        _den = g.hour * 60 + g.minute;
      }
    });
  }

  List<String> _kiemTra(List<MonAn> menu) {
    final l = <String>[];
    final tieu = _tieuDe.text.trim();
    if (tieu.length < 3 || tieu.length > 80) {
      l.add('Tiêu đề khuyến mãi 3–80 ký tự.');
    }
    num? pt() => _so(_phanTram);
    final donTT = _so(_donToiThieu);
    if (donTT != null && donTT < 0) l.add('Đơn tối thiểu không được âm.');
    switch (_loai) {
      case 'giam_phan_tram':
        final p = pt();
        if (p == null || p <= 0 || p > 100) {
          l.add('Phần trăm giảm từ 1 đến 100.');
        }
      case 'giam_tien':
        final t = _so(_giamTien);
        if (t == null || t <= 0) l.add('Nhập số tiền giảm lớn hơn 0.');
      case 'combo':
        final co = _comboHopLe(menu);
        if (co.length < 2) l.add('Combo cần chọn ít nhất 2 món từ menu.');
        final gia = _so(_giaCombo);
        final tong = _tongGiaThuong(menu);
        if (gia == null || gia <= 0) {
          l.add('Nhập giá combo lớn hơn 0.');
        } else if (co.length >= 2 && gia >= tong) {
          l.add(
            'Giá combo phải thấp hơn tổng giá thường (${formatPrice(tong)}).',
          );
        }
      case 'gio_vang':
        if (_tu == _den) {
          l.add('Giờ bắt đầu và kết thúc không được trùng nhau.');
        }
        if (_ngay.isEmpty) l.add('Chọn ít nhất một ngày áp dụng.');
        final p = pt();
        if (p == null || p <= 0 || p > 100) {
          l.add('Phần trăm giảm từ 1 đến 100.');
        }
      case 'sinh_vien':
        if (_svTheoTien) {
          final t = _so(_giamTien);
          if (t == null || t <= 0) l.add('Nhập số tiền giảm lớn hơn 0.');
        } else {
          final p = pt();
          if (p == null || p <= 0 || p > 100) {
            l.add('Phần trăm giảm từ 1 đến 100.');
          }
        }
    }
    if (_ketThuc.isBefore(_batDau)) {
      l.add('Ngày kết thúc phải sau hoặc cùng ngày bắt đầu.');
    } else if (_ketThuc.difference(_batDau).inDays + 1 >
        widget.cfg.khuyenMaiToiDaNgay) {
      l.add('Khuyến mãi kéo dài tối đa ${widget.cfg.khuyenMaiToiDaNgay} ngày.');
    }
    return l;
  }

  List<MonCombo> _comboHopLe(List<MonAn> menu) {
    final co = {for (final m in menu) m.id};
    return [
      for (final e in _combo.entries)
        if (co.contains(e.key) && e.value > 0)
          MonCombo(monId: e.key, soLuong: e.value),
    ];
  }

  num _tongGiaThuong(List<MonAn> menu) {
    final gia = {for (final m in menu) m.id: m.gia};
    return _comboHopLe(menu)
        .fold<num>(0, (s, m) => s + (gia[m.monId] ?? 0) * m.soLuong);
  }

  KhuyenMai _dung(List<MonAn> menu) {
    final dtt = _so(_donToiThieu);
    final batDau = dauNgayVn(_batDau);
    final ketThuc = cuoiNgayVn(_ketThuc);
    final goc = KhuyenMai(
      id: widget.km?.id ?? '',
      quanId: widget.quan.id,
      chuQuanId: widget.dv.uid,
      loai: _loai,
      tieuDe: _tieuDe.text.trim(),
      batDau: batDau,
      ketThuc: ketThuc,
    );
    KhuyenMai tao({
      num? phanTram,
      num? giamToiDa,
      num? giamTien,
      num? donToiThieu,
      ComboKm? combo,
      GioVangKm? gioVang,
    }) => KhuyenMai(
      id: goc.id,
      quanId: goc.quanId,
      chuQuanId: goc.chuQuanId,
      loai: goc.loai,
      tieuDe: goc.tieuDe,
      batDau: batDau,
      ketThuc: ketThuc,
      phanTram: phanTram,
      giamToiDa: giamToiDa,
      giamTien: giamTien,
      donToiThieu: donToiThieu,
      combo: combo,
      gioVang: gioVang,
    );
    final toiDa = _so(_giamToiDa);
    switch (_loai) {
      case 'giam_phan_tram':
        return tao(
          phanTram: _so(_phanTram),
          giamToiDa: toiDa,
          donToiThieu: dtt,
        );
      case 'giam_tien':
        return tao(giamTien: _so(_giamTien), donToiThieu: dtt);
      case 'combo':
        return tao(
          combo: ComboKm(mon: _comboHopLe(menu), gia: _so(_giaCombo) ?? 0),
        );
      case 'gio_vang':
        return tao(
          gioVang: GioVangKm(
            tu: _tu,
            den: _den,
            ngay: ([..._ngay]..sort()),
            phanTram: _so(_phanTram) ?? 0,
            giamToiDa: toiDa,
          ),
        );
      default:
        return tao(
          phanTram: _svTheoTien ? null : _so(_phanTram),
          giamTien: _svTheoTien ? _so(_giamTien) : null,
          donToiThieu: dtt,
        );
    }
  }

  Future<void> _luu(List<MonAn> menu) async {
    final loi = _kiemTra(menu);
    setState(() => _loi = loi);
    if (loi.isNotEmpty) return;
    setState(() => _dangLuu = true);
    try {
      await widget.dv.khuyenMai.luu(_dung(menu));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.km == null ? 'Đã tạo khuyến mãi' : 'Đã lưu khuyến mãi',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _loi = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Widget _oSo(
    TextEditingController c,
    String nhan, {
    String? hau,
    String? goiY,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: QuanAnSpacing.md),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: nhan,
        suffixText: hau,
        helperText: goiY,
        helperMaxLines: 3,
      ),
    ),
  );

  List<Widget> _truongTheoLoai(List<MonAn> menu) {
    switch (_loai) {
      case 'giam_phan_tram':
        return [
          _oSo(_phanTram, 'Giảm bao nhiêu phần trăm', hau: '%'),
          _oSo(_giamToiDa, 'Mức giảm tối đa (không bắt buộc)', hau: 'đ'),
          _oSo(_donToiThieu, 'Đơn tối thiểu (không bắt buộc)', hau: 'đ'),
        ];
      case 'giam_tien':
        return [
          _oSo(_giamTien, 'Số tiền giảm', hau: 'đ'),
          _oSo(_donToiThieu, 'Đơn tối thiểu (không bắt buộc)', hau: 'đ'),
        ];
      case 'combo':
        return _truongCombo(menu);
      case 'gio_vang':
        return [
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _chonGio(true),
                icon: const Icon(Icons.schedule_rounded),
                label: Text('Từ ${phutHienThi(_tu)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _chonGio(false),
                icon: const Icon(Icons.schedule_rounded),
                label: Text('Đến ${phutHienThi(_den)}'),
              ),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.md),
          const Text('Các ngày áp dụng', style: QuanAnText.label),
          const SizedBox(height: QuanAnSpacing.xs),
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.xs,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(d == 7 ? 'CN' : 'T${d + 1}'),
                  selected: _ngay.contains(d),
                  onSelected: (on) =>
                      setState(() => on ? _ngay.add(d) : _ngay.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.md),
          _oSo(_phanTram, 'Giảm bao nhiêu phần trăm', hau: '%'),
          _oSo(_giamToiDa, 'Mức giảm tối đa (không bắt buộc)', hau: 'đ'),
        ];
      default:
        return [
          const Text(
            'Dành cho tài khoản có huy hiệu "Email trường".',
            style: QuanAnText.bodySmall,
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Giảm %')),
              ButtonSegment(value: true, label: Text('Giảm tiền')),
            ],
            selected: {_svTheoTien},
            onSelectionChanged: (s) => setState(() => _svTheoTien = s.first),
          ),
          const SizedBox(height: QuanAnSpacing.md),
          if (_svTheoTien)
            _oSo(_giamTien, 'Số tiền giảm', hau: 'đ')
          else
            _oSo(_phanTram, 'Giảm bao nhiêu phần trăm', hau: '%'),
          _oSo(_donToiThieu, 'Đơn tối thiểu (không bắt buộc)', hau: 'đ'),
        ];
    }
  }

  List<Widget> _truongCombo(List<MonAn> menu) {
    if (menu.length < 2) {
      return const [
        HopThongBao.canhBao(
          noiDung: 'Menu cần có ít nhất 2 món mới tạo được combo. Hãy thêm món ở mục Menu trước.',
        ),
      ];
    }
    final tong = _tongGiaThuong(menu);
    return [
      const Text(
        'Chọn các món trong combo (ít nhất 2 món)',
        style: QuanAnText.label,
      ),
      const SizedBox(height: QuanAnSpacing.xs),
      for (final m in menu)
        _DongMonCombo(
          mon: m,
          soLuong: _combo[m.id] ?? 0,
          onDoi: (n) => setState(() {
            if (n <= 0) {
              _combo.remove(m.id);
            } else {
              _combo[m.id] = n;
            }
          }),
        ),
      const SizedBox(height: QuanAnSpacing.sm),
      Text(
        'Tổng giá thường của bộ món: ${formatPrice(tong)}',
        style: QuanAnText.bodySmall,
      ),
      const SizedBox(height: QuanAnSpacing.md),
      _oSo(
        _giaCombo,
        'Giá combo',
        hau: 'đ',
        goiY: 'Phải thấp hơn tổng giá thường để khách thấy được ưu đãi.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final laSua = widget.km != null;
    return Scaffold(
      appBar: AppBar(title: Text(laSua ? 'Sửa khuyến mãi' : 'Tạo khuyến mãi')),
      body: QuanAnStream<List<MonAn>>(
        stream: () => widget.dv.menu.monCuaChu(widget.quan.id),
        thongBaoLoi: 'Không tải được menu',
        builder: (context, menu) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(QuanAnSpacing.screen),
                child: TrangRong(
                  rongToiDa: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.quan.laHoKinhDoanh)
                        const Padding(
                          padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                          child: HopThongBao(
                            noiDung: 'Quán bán lẻ: khuyến mãi chỉ hiển thị, không tự trừ vào tiền.',
                          ),
                        ),
                      KhoiThongTin(
                        tieuDe: 'Loại khuyến mãi',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: QuanAnSpacing.sm,
                              runSpacing: QuanAnSpacing.xs,
                              children: [
                                for (final e in loaiKhuyenMaiLabels.entries)
                                  ChoiceChip(
                                    label: Text(e.value),
                                    selected: _loai == e.key,
                                    // Sửa khuyến mãi thì giữ nguyên loại.
                                    onSelected: laSua
                                        ? null
                                        : (_) => setState(() {
                                            _loai = e.key;
                                            _loi = const [];
                                          }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: QuanAnSpacing.md),
                            TextField(
                              controller: _tieuDe,
                              maxLength: 80,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề',
                                helperText: 'Ví dụ: Giảm 10% bữa trưa, Combo cơm + nước',
                              ),
                            ),
                            const SizedBox(height: QuanAnSpacing.sm),
                            ..._truongTheoLoai(menu),
                          ],
                        ),
                      ),
                      const SizedBox(height: QuanAnSpacing.cardGap),
                      KhoiThongTin(
                        tieuDe: 'Thời gian áp dụng',
                        phu:
                            'Tối đa ${cfg.khuyenMaiToiDaNgay} ngày. Hết ngày kết thúc thì tự ẩn.',
                        child: Wrap(
                          spacing: QuanAnSpacing.sm,
                          runSpacing: QuanAnSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _chonNgay(true),
                              icon: const Icon(Icons.event_rounded),
                              label: Text('Bắt đầu ${_ngayChu(_batDau)}'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _chonNgay(false),
                              icon: const Icon(Icons.event_available_rounded),
                              label: Text('Kết thúc ${_ngayChu(_ketThuc)}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ThanhDuoiForm(
              loi: _loi,
              child: FilledButton(
                onPressed: _dangLuu ? null : () => _luu(menu),
                child: Text(
                  _dangLuu
                      ? 'Đang lưu...'
                      : (laSua ? 'Lưu khuyến mãi' : 'Tạo khuyến mãi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DongMonCombo extends StatelessWidget {
  const _DongMonCombo({
    required this.mon,
    required this.soLuong,
    required this.onDoi,
  });

  final MonAn mon;
  final int soLuong;
  final ValueChanged<int> onDoi;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mon.ten,
                style: QuanAnText.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(formatPrice(mon.gia), style: QuanAnText.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Bớt một ${mon.ten}',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: soLuong > 0 ? () => onDoi(soLuong - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$soLuong',
            textAlign: TextAlign.center,
            style: QuanAnText.label,
          ),
        ),
        IconButton(
          tooltip: 'Thêm một ${mon.ten}',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: soLuong < 20 ? () => onDoi(soLuong + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );
}
