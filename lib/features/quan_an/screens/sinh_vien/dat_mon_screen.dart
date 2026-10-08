import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/quan_an_filter.dart' show khoangCachMet;
import '../../services/don_mon_service.dart';
import '../../services/quan_an_api.dart' show ApiException;
import '../../services/quan_an_bo_nho.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../tuong_tac/thanh_toan_screen.dart';
import 'dat_ban_screen.dart' show ChonNgayGioQuanAn;
import 'theo_doi_don_screen.dart';

/// Lời giải thích tiếng Việt cho mã lỗi báo giá / đặt món khi hệ thống không kèm thông điệp.
String moTaLoiDatMon(String? ma, String? thongDiep) {
  if (thongDiep != null && thongDiep.trim().isNotEmpty) return thongDiep.trim();
  return switch (ma) {
    'mon_het' => 'Có món vừa hết. Hãy quay lại giỏ để bỏ món đó.',
    'quan_dong' => 'Quán đang đóng cửa nên chưa nhận đơn.',
    'quan_khong_nhan_don' => 'Quán đang tạm ngưng nhận đơn.',
    'ngoai_ban_kinh' => 'Địa chỉ nằm ngoài bán kính giao của quán.',
    'chua_du_don_toi_thieu' => 'Đơn chưa đạt mức tối thiểu của quán.',
    'gio_hen_sai' => 'Giờ hẹn không hợp lệ, hãy chọn lại.',
    _ => 'Chưa đặt được món lúc này, vui lòng thử lại.',
  };
}

/// Kiểm tra giờ hẹn lấy / giao món (mục 3.4 Bước 5b): sau bây giờ 30 phút – 2 giờ và trước giờ đóng
/// cửa của ca đang mở. Trả về lỗi tiếng Việt hoặc null. Hệ thống kiểm tra thật khi báo giá.
String? kiemTraGioHen(
  DateTime? t, {
  required DateTime now,
  required QuanAnConfig cfg,
  required QuanAn quan,
}) {
  if (t == null) return 'Chọn giờ hẹn.';
  final itNhat = QuanAnConfig.phut(cfg.henGioToiThieuPhut);
  final toiDa = QuanAnConfig.phut(cfg.henGioToiDaPhut);
  String dai(Duration d) => d.inHours >= 1 && d.inMinutes % 60 == 0
      ? '${d.inHours} giờ'
      : '${d.inMinutes} phút';
  if (t.isBefore(now.add(itNhat))) {
    return 'Giờ hẹn phải sau bây giờ ít nhất ${dai(itNhat)}.';
  }
  if (t.isAfter(now.add(toiDa))) {
    return 'Giờ hẹn không quá ${dai(toiDa)} kể từ bây giờ.';
  }
  if (quan.dangTamNgung(now)) {
    return 'Quán đang tạm ngưng nhận đơn nên chưa hẹn giờ được.';
  }
  final nghi = quan.tamNghiDen;
  if (nghi != null && now.isBefore(nghi)) {
    return 'Quán đang tạm nghỉ nên chưa hẹn giờ được.';
  }
  final ca = caDangMo(quan.gioMoCua, now);
  if (ca == null) return 'Quán đang đóng cửa nên chưa hẹn giờ được.';
  if (!t.isBefore(ca.den)) {
    return 'Giờ hẹn phải trước giờ đóng cửa của quán (${formatNgayGio(ca.den)}).';
  }
  return null;
}

/// QA-SV-07 Đặt món: cách nhận, địa chỉ giao, giờ, người nhận, cách trả. Tổng tiền DO HỆ THỐNG TÍNH
/// (`baoGia`) mỗi khi đổi lựa chọn; app chỉ gửi món / tùy chọn / số lượng, không gửi số tiền.
class DatMonScreen extends StatefulWidget {
  const DatMonScreen({required this.dv, required this.quan, super.key});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<DatMonScreen> createState() => _DatMonScreenState();
}

class _DatMonScreenState extends State<DatMonScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();
  ThongTinSinhVien _tt = const ThongTinSinhVien();
  XacThuc _xt = const XacThuc();
  bool _dangNap = true;
  bool _loiNap = false;

  String _cachNhan = 'den_lay';
  DiaChiDat? _diaChi;
  List<Map<String, dynamic>> _daLuu = const [];
  String _gio = 'asap';
  DateTime? _gioHen;
  String? _loiGioHen;
  String _cachTra = 'app';
  final _sdt = TextEditingController();
  final _ghiChu = TextEditingController();

  BaoGia? _baoGia;
  bool _dangTinh = false;
  String? _loiTinh;
  int _lanTinh = 0;

  bool _dangDat = false;
  bool _daDat = false;
  ({String ma, String thongDiep})? _loiDat;
  ({num cu, num moi})? _giaDoi;

  CaiDatDatMon get _dm => widget.quan.datMon;

  @override
  void initState() {
    super.initState();
    _cachNhan = _dm.denLay ? 'den_lay' : 'giao';
    _nap();
  }

  @override
  void dispose() {
    _sdt.dispose();
    _ghiChu.dispose();
    super.dispose();
  }

  Future<void> _nap() async {
    setState(() {
      _dangNap = true;
      _loiNap = false;
    });
    try {
      final cfg = await widget.dv.donMon.cauHinh();
      XacThuc xt;
      try {
        xt = await widget.dv.xacThuc.cuaToi(widget.dv.uid).first;
      } catch (_) {
        xt = const XacThuc();
      }
      ThongTinSinhVien tt;
      try {
        tt = await widget.dv.donMon.thongTinSinhVien();
      } catch (_) {
        tt = const ThongTinSinhVien();
      }
      final daLuu = await QuanAnBoNho.docDiaChi();
      if (!mounted) return;
      setState(() {
        _cfg = cfg;
        _xt = xt;
        _tt = tt;
        _daLuu = daLuu;
        if (_sdt.text.isEmpty) _sdt.text = xt.sdt ?? '';
        if (tt.datMonAppBiKhoa(DateTime.now())) _cachTra = 'tien_mat';
        _dangNap = false;
      });
      _tinhGia();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dangNap = false;
        _loiNap = true;
      });
    }
  }

  // ---------------------------------------------------------------- Báo giá

  /// Hệ thống tính lại toàn bộ giá theo lựa chọn hiện tại.
  Future<void> _tinhGia({bool giuLoiDat = false}) async {
    final gio = widget.dv.gioHang.gio;
    final lan = ++_lanTinh;
    if (gio.laRong) return;
    String? loiGioHen;
    if (_gio == 'hen') {
      loiGioHen = kiemTraGioHen(
        _gioHen,
        now: DateTime.now(),
        cfg: _cfg,
        quan: widget.quan,
      );
    }
    if ((_cachNhan == 'giao' && _diaChi == null) || loiGioHen != null) {
      setState(() {
        _baoGia = null;
        _dangTinh = false;
        _loiTinh = null;
        _loiGioHen = _gioHen == null ? null : loiGioHen;
      });
      return;
    }
    setState(() {
      _dangTinh = true;
      _loiTinh = null;
      _loiGioHen = null;
    });
    try {
      final bg = await widget.dv.donMon.baoGia(
        quanId: widget.quan.id,
        items: gio.toApiItems(),
        cachNhan: _cachNhan,
        diaChi: _cachNhan == 'giao' ? _diaChi : null,
        gio: _gio,
        gioHen: _gio == 'hen' ? _gioHen : null,
      );
      if (!mounted || lan != _lanTinh) return;
      setState(() {
        _baoGia = bg;
        _dangTinh = false;
        if (!giuLoiDat) _loiDat = null;
        // Tiền mặt không còn hợp lệ với đơn này: quay về trả trên app.
        if (_cachTra == 'tien_mat' &&
            !_tienMatDuoc(bg) &&
            !_tt.datMonAppBiKhoa(DateTime.now())) {
          _cachTra = 'app';
        }
      });
    } on ApiException catch (e) {
      if (!mounted || lan != _lanTinh) return;
      setState(() {
        _dangTinh = false;
        _baoGia = null;
        _loiTinh = e.message;
      });
    } catch (_) {
      if (!mounted || lan != _lanTinh) return;
      setState(() {
        _dangTinh = false;
        _baoGia = null;
        _loiTinh = 'Không tính được tổng tiền, vui lòng thử lại.';
      });
    }
  }

  bool _tienMatDuoc(BaoGia? bg) =>
      bg != null &&
      bg.ok &&
      bg.tienMatDuocKhong &&
      _dm.tienMat &&
      _tt.coTienMat &&
      _xt.daOtp;

  String? _lyDoKhongTienMat(BaoGia? bg) {
    if (!_dm.tienMat) return 'Quán này không nhận tiền mặt.';
    if (!_tt.coTienMat) {
      return 'Bạn tạm thời không chọn được tiền mặt (do đơn không nhận món trước đây).';
    }
    if (_tt.khoaTienMatDen?.isAfter(DateTime.now()) ?? false) {
      return 'Bạn đang bị khóa tiền mặt tới ${formatNgayGio(_tt.khoaTienMatDen!)}.';
    }
    if (bg == null || !bg.ok) return 'Cần tính xong tổng tiền trước.';
    if (!bg.tienMatDuocKhong) {
      return 'Tiền mặt chỉ áp dụng cho đơn dưới ${formatPrice(_cfg.tienMatDuoi)}.';
    }
    return null;
  }

  // ---------------------------------------------------------------- Địa chỉ

  void _datDiaChi(DiaChiDat d) {
    setState(() => _diaChi = d);
    _tinhGia();
  }

  Future<void> _luuDiaChi(DiaChiDat d) async {
    final ds = [
      {'ten': _tenNgan(d.dong), 'dong': d.dong, 'lat': d.lat, 'lng': d.lng},
      for (final x in _daLuu)
        if (!_cungToaDo(x, d.lat, d.lng)) x,
    ].take(5).toList();
    setState(() => _daLuu = ds);
    await QuanAnBoNho.luuDiaChi(ds);
  }

  bool _cungToaDo(Map<String, dynamic> x, double lat, double lng) =>
      (((x['lat'] as num?)?.toDouble() ?? 0) - lat).abs() < 0.00005 &&
      (((x['lng'] as num?)?.toDouble() ?? 0) - lng).abs() < 0.00005;

  String _tenNgan(String dong) {
    final d = dong.trim();
    if (d.isEmpty) return 'Địa chỉ đã lưu';
    final phan = d.split(',').first.trim();
    return phan.length > 40 ? '${phan.substring(0, 40)}…' : phan;
  }

  Future<void> _xoaDiaChiLuu(Map<String, dynamic> x) async {
    final ds = [
      for (final y in _daLuu)
        if (!identical(y, x)) y,
    ];
    setState(() => _daLuu = ds);
    await QuanAnBoNho.luuDiaChi(ds);
  }

  Future<void> _dungViTriHienTai() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = await _viTriHienTai();
    if (!mounted) return;
    if (p == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Không lấy được vị trí (chưa cho phép định vị). Hãy chọn địa chỉ trên bản đồ.',
          ),
        ),
      );
      return;
    }
    final dong = await _diaChiTuToaDo(p.lat, p.lng) ?? 'Vị trí hiện tại';
    if (!mounted) return;
    _datDiaChi(DiaChiDat(lat: p.lat, lng: p.lng, dong: dong));
  }

  Future<void> _chonTrenBanDo() async {
    final kq = await QuanAnDieuHuong.mo<_KetQuaChonDiaChi>(
      context,
      (_) => _ChonDiaChiScreen(
        banDau: _diaChi == null ? null : LatLng(_diaChi!.lat, _diaChi!.lng),
        viTriQuan: widget.quan.viTri == null
            ? null
            : LatLng(widget.quan.viTri!.latitude, widget.quan.viTri!.longitude),
      ),
    );
    if (kq == null || !mounted) return;
    _datDiaChi(kq.diaChi);
    if (kq.luu) await _luuDiaChi(kq.diaChi);
  }

  double? _khoangCachKm() {
    final q = widget.quan.viTri;
    final d = _diaChi;
    if (q == null || d == null) return null;
    return khoangCachMet(q.latitude, q.longitude, d.lat, d.lng) / 1000;
  }

  // ---------------------------------------------------------------- Đặt món

  String? get _loiSdt {
    final s = _sdt.text.replaceAll(RegExp(r'[\s.\-]'), '');
    if (s.isEmpty) return null;
    return RegExp(r'^(\+84|0)\d{9}$').hasMatch(s)
        ? null
        : 'Số điện thoại chưa đúng (ví dụ 0912345678).';
  }

  bool get _sdtHopLe => _sdt.text.trim().isNotEmpty && _loiSdt == null;

  /// Lý do nút đặt món đang mờ (null = bấm được).
  String? _lyDoChua() {
    if (_dangTinh) return 'Đang tính tổng tiền...';
    if (_cachNhan == 'giao' && _diaChi == null) {
      return 'Chọn địa chỉ giao để xem tổng tiền.';
    }
    if (_gio == 'hen' && (_gioHen == null || _loiGioHen != null)) {
      return _loiGioHen ?? 'Chọn giờ hẹn.';
    }
    final bg = _baoGia;
    if (_loiTinh != null) return _loiTinh;
    if (bg == null) return 'Chưa có tổng tiền.';
    if (!bg.ok) return moTaLoiDatMon(bg.ma, bg.thongDiep);
    if (!_sdtHopLe) return 'Nhập số điện thoại người nhận hợp lệ.';
    if (_cachTra == 'tien_mat' && !_tienMatDuoc(bg)) {
      return _lyDoKhongTienMat(bg) ?? 'Không chọn được tiền mặt.';
    }
    if (_cachTra == 'app' && _tt.datMonAppBiKhoa(DateTime.now())) {
      return 'Bạn đang bị khóa đặt món trả trên app.';
    }
    return null;
  }

  Future<void> _dat() async {
    final bg = _baoGia;
    if (_dangDat || bg == null || !bg.ok || _lyDoChua() != null) return;
    setState(() {
      _dangDat = true;
      _loiDat = null;
    });
    final gio = widget.dv.gioHang.gio;
    KetQuaDatMon? kq;
    final xong = await chayThaoTac(context, () async {
      kq = await widget.dv.donMon.datMon(
        quanId: widget.quan.id,
        items: gio.toApiItems(),
        cachNhan: _cachNhan,
        diaChi: _cachNhan == 'giao' ? _diaChi : null,
        gio: _gio,
        gioHen: _gio == 'hen' ? _gioHen : null,
        cachTra: _cachTra,
        sdtNhan: _sdt.text.replaceAll(RegExp(r'[\s.\-]'), ''),
        ghiChuQuan: _ghiChu.text.trim(),
        tongDaThay: bg.tong,
      );
    });
    if (!mounted) return;
    final r = kq;
    if (!xong || r == null) {
      setState(() => _dangDat = false);
      return;
    }
    if (r.ok && r.donId != null) {
      final donId = r.donId!;
      final traApp = _cachTra == 'app';
      setState(() => _daDat = true);
      final nav = Navigator.of(context);
      nav.pushReplacement(
        quanAnRoute(
          (_) => traApp
              ? ThanhToanScreen(dv: widget.dv, donId: donId)
              : TheoDoiDonScreen(dv: widget.dv, donId: donId),
        ),
      );
      widget.dv.gioHang.xoaHet();
      return;
    }
    if (r.giaDoi) {
      // Không tạo gì: cho khách xem tổng mới rồi bấm đặt lại.
      setState(() {
        _dangDat = false;
        _giaDoi = (cu: bg.tong, moi: r.tong ?? bg.tong);
        if (r.baoGia != null && r.baoGia!.ok) _baoGia = r.baoGia;
      });
      await _tinhGia();
      if (mounted && r.tong != null && _baoGia != null && _baoGia!.ok) {
        setState(() => _giaDoi = (cu: bg.tong, moi: _baoGia!.tong));
      }
      return;
    }
    setState(() {
      _dangDat = false;
      _loiDat = (ma: r.ma ?? '', thongDiep: moTaLoiDatMon(r.ma, r.thongDiep));
    });
    _tinhGia();
  }

  // ---------------------------------------------------------------- Giao diện

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt món')),
    body: _daDat
        ? const Center(child: CircularProgressIndicator())
        : ListenableBuilder(
            listenable: widget.dv.gioHang,
            builder: (context, _) => _thanBody(),
          ),
  );

  Widget _thanBody() {
    final gio = widget.dv.gioHang.gio;
    if (gio.laRong || gio.quanId != widget.quan.id) {
      return QuanAnEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Giỏ hàng đang trống',
        message: 'Hãy chọn món ở trang quán rồi đặt lại.',
        actionLabel: 'Quay lại',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }
    if (!widget.quan.nhanDatMon) {
      return QuanAnEmptyState(
        icon: Icons.storefront_outlined,
        title: 'Quán chưa nhận đặt món qua app',
        message: 'Bạn có thể nhắn tin hoặc gọi điện cho quán.',
        actionLabel: 'Quay lại giỏ',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }
    if (_dangNap) return const QuanAnSkeletonList(count: 1);
    if (_loiNap) return QuanAnErrorState(onRetry: _nap);
    if (!_xt.daOtp) {
      return QuanAnEmptyState(
        icon: Icons.phone_iphone,
        title: 'Cần xác thực số điện thoại',
        message: 'Đặt món trên app cần số điện thoại đã xác thực (OTP).',
        actionLabel: 'Xác thực ngay',
        onAction: () async {
          await QuanAnDieuHuong.mo(
            context,
            (_) => XacThucSdtScreen(service: widget.dv.xacThuc),
          );
          _nap();
        },
      );
    }
    final now = DateTime.now();
    if (_tt.datMonBiKhoa(now)) {
      return QuanAnEmptyState(
        icon: Icons.lock_clock,
        title: 'Bạn đang bị khóa đặt món',
        message:
            'Tới ${formatNgayGio(_tt.khoaDatMonDen!)}. Bạn có thể kháng nghị trong mục "Của tôi".',
      );
    }
    return Column(
      children: [
        if (_dangTinh || _dangDat) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(QuanAnSpacing.screen),
                children: [
                  Text(widget.quan.ten, style: QuanAnText.h2),
                  const SizedBox(height: QuanAnSpacing.lg),
                  _cachNhanCard(),
                  if (_cachNhan == 'giao') ...[
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    _diaChiCard(),
                  ],
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  _gioCard(),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  _nguoiNhanCard(),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  _tongCard(),
                  const SizedBox(height: QuanAnSpacing.cardGap),
                  _traCard(),
                  const SizedBox(height: QuanAnSpacing.lg),
                ],
              ),
            ),
          ),
        ),
        _thanhDuoi(),
      ],
    );
  }

  Widget _khung(String tieuDe, List<Widget> con) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe, style: QuanAnText.h3),
          const SizedBox(height: QuanAnSpacing.sm),
          ...con,
        ],
      ),
    ),
  );

  Widget _cachNhanCard() {
    final cacCach = <String>[
      if (_dm.denLay) 'den_lay',
      if (_dm.giaoTanNoi) 'giao',
    ];
    return _khung('Cách nhận món', [
      RadioGroup<String>(
        groupValue: _cachNhan,
        onChanged: (v) {
          if (v == null || v == _cachNhan) return;
          setState(() {
            _cachNhan = v;
            _giaDoi = null;
          });
          _tinhGia();
        },
        child: Column(
          children: [
            for (final c in cacCach)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: c,
                title: Text(cachNhanLabels[c] ?? c),
                subtitle: Text(
                  c == 'giao'
                      ? '${_dm.phiGiaoMoTa} · trong bán kính ${_dm.banKinhKm} km'
                      : 'Bạn tới quán nhận món và đọc mã nhận món 4 số.',
                  style: QuanAnText.bodySmall,
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _diaChiCard() {
    final d = _diaChi;
    final daLuuTrung = d == null
        ? null
        : _daLuu.cast<Map<String, dynamic>?>().firstWhere(
            (x) => _cungToaDo(x!, d.lat, d.lng),
            orElse: () => null,
          );
    final km = _khoangCachKm();
    final ngoai =
        km != null && km > _dm.banKinhKm && _baoGia?.ma != 'ngoai_ban_kinh';
    return _khung('Địa chỉ giao', [
      if (d != null && daLuuTrung == null)
        _DiaChiTile(
          chon: true,
          ten: d.dong.isEmpty ? 'Địa chỉ đã chọn' : d.dong,
          phu: null,
          onTap: () {},
        ),
      for (final x in _daLuu)
        _DiaChiTile(
          chon: d != null && _cungToaDo(x, d.lat, d.lng),
          ten: x['ten'] as String? ?? 'Địa chỉ đã lưu',
          phu: x['dong'] as String?,
          onTap: () => _datDiaChi(
            DiaChiDat(
              lat: (x['lat'] as num).toDouble(),
              lng: (x['lng'] as num).toDouble(),
              dong: x['dong'] as String? ?? '',
            ),
          ),
          onXoa: () => _xoaDiaChiLuu(x),
        ),
      if (d == null && _daLuu.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: QuanAnSpacing.sm),
          child: Text(
            'Chưa có địa chỉ nào. Dùng vị trí hiện tại hoặc chọn trên bản đồ.',
            style: QuanAnText.bodySmall,
          ),
        ),
      if (ngoai)
        Padding(
          padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
          child: Text(
            'Địa chỉ này cách quán khoảng ${km.toStringAsFixed(1).replaceAll('.', ',')} km, ngoài bán kính giao ${_dm.banKinhKm} km của quán.',
            style: QuanAnText.body.copyWith(color: QuanAnColors.danger),
          ),
        ),
      Wrap(
        spacing: QuanAnSpacing.sm,
        runSpacing: QuanAnSpacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: _dungViTriHienTai,
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text('Vị trí hiện tại'),
          ),
          OutlinedButton.icon(
            onPressed: _chonTrenBanDo,
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Tìm / ghim trên bản đồ'),
          ),
        ],
      ),
    ]);
  }

  Widget _gioCard() => _khung('Thời gian', [
    RadioGroup<String>(
      groupValue: _gio,
      onChanged: (v) {
        if (v == null || v == _gio) return;
        setState(() {
          _gio = v;
          _giaDoi = null;
          _loiGioHen = null;
        });
        _tinhGia();
      },
      child: Column(
        children: [
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: 'asap',
            title: Text(gioDatLabels['asap']!),
            subtitle: Text(
              _gio == 'asap' && _baoGia?.gioDuKienSanSang != null
                  ? 'Dự kiến sẵn sàng lúc ${formatNgayGio(_baoGia!.gioDuKienSanSang!)}'
                  : 'Quán nhận trong ${_cfg.quanXacNhanPhut} phút, giờ dự kiến hiện khi có tổng tiền.',
              style: QuanAnText.bodySmall,
            ),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: 'hen',
            title: Text(gioDatLabels['hen']!),
            subtitle: Text(
              'Từ ${_cfg.henGioToiThieuPhut} phút đến ${_cfg.henGioToiDaPhut ~/ 60} giờ nữa, trước giờ đóng cửa của quán.',
              style: QuanAnText.bodySmall,
            ),
          ),
        ],
      ),
    ),
    if (_gio == 'hen') ...[
      const SizedBox(height: QuanAnSpacing.sm),
      ChonNgayGioQuanAn(
        nhan: 'Giờ hẹn',
        giaTri: _gioHen,
        loi: _loiGioHen,
        ngayCuoi: DateTime.now().add(QuanAnConfig.phut(_cfg.henGioToiDaPhut)),
        onChanged: (t) {
          setState(() {
            _gioHen = t;
            _giaDoi = null;
          });
          _tinhGia();
        },
      ),
    ],
  ]);

  Widget _nguoiNhanCard() => _khung('Người nhận', [
    TextField(
      controller: _sdt,
      keyboardType: TextInputType.phone,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Số điện thoại người nhận',
        errorText: _loiSdt,
      ),
    ),
    const SizedBox(height: QuanAnSpacing.md),
    TextField(
      controller: _ghiChu,
      maxLines: 2,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: 'Ghi chú cho quán (không bắt buộc)',
        hintText: 'Ví dụ: gọi trước khi tới, ít đá',
      ),
    ),
  ]);

  Widget _tongCard() {
    final bg = _baoGia;
    final gio = widget.dv.gioHang.gio;
    return _khung('Đơn của bạn', [
      if (bg != null && bg.ok)
        for (final m in bg.monAn)
          _DongTien(
            '${m.ten} × ${m.soLuong}'
            '${m.tuyChonMoTa.isEmpty ? '' : '\n${m.tuyChonMoTa}'}',
            formatPrice(m.thanhTien),
            nho: true,
          )
      else
        for (final d in gio.dong)
          _DongTien(
            '${d.ten} × ${d.soLuong}'
            '${d.tuyChon.isEmpty ? '' : '\n${d.tuyChon.map((t) => '${t.nhom}: ${t.ten}').join(' · ')}'}',
            null,
            nho: true,
          ),
      const Divider(height: QuanAnSpacing.xxl),
      if (_loiTinh != null) ...[
        Text(
          _loiTinh!,
          style: QuanAnText.body.copyWith(color: QuanAnColors.danger),
        ),
        const SizedBox(height: QuanAnSpacing.sm),
        OutlinedButton(onPressed: _tinhGia, child: const Text('Thử lại')),
      ] else if (bg == null)
        Text(
          _dangTinh
              ? 'Đang tính tổng tiền...'
              : _cachNhan == 'giao' && _diaChi == null
              ? 'Chọn địa chỉ giao để hệ thống tính phí giao và tổng tiền.'
              : _gio == 'hen' && _gioHen == null
              ? 'Chọn giờ hẹn để hệ thống tính tổng tiền.'
              : 'Chưa có tổng tiền.',
          style: QuanAnText.bodySmall,
        )
      else if (!bg.ok) ...[
        QuanAnWarningBox(message: moTaLoiDatMon(bg.ma, bg.thongDiep)),
        const SizedBox(height: QuanAnSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Quay lại giỏ'),
        ),
      ] else ...[
        _DongTien('Tiền món', formatPrice(bg.tienMon)),
        if (bg.giamCombo > 0)
          _DongTien('Giảm combo', '-${formatPrice(bg.giamCombo)}', xanh: true),
        if (bg.giamGia > 0 || bg.khuyenMaiApDung.isNotEmpty)
          _DongTien(
            bg.khuyenMaiApDung.isEmpty
                ? 'Giảm giá'
                : 'Giảm giá (${bg.khuyenMaiApDung.map((k) => k.tieuDe).join(', ')})',
            '-${formatPrice(bg.giamGia)}',
            xanh: true,
          ),
        if (_cachNhan == 'giao')
          _DongTien(
            'Phí giao',
            bg.phiGiao <= 0 ? 'Miễn phí' : formatPrice(bg.phiGiao),
          ),
        const Divider(height: QuanAnSpacing.xxl),
        _DongTien('Tổng', formatPrice(bg.tong), dam: true),
        const SizedBox(height: QuanAnSpacing.xs),
        const Text(
          'Tổng tiền do hệ thống tính theo menu và khuyến mãi hiện tại.',
          style: QuanAnText.bodySmall,
        ),
      ],
      if (_giaDoi != null) ...[
        const SizedBox(height: QuanAnSpacing.md),
        QuanAnWarningBox(
          message:
              'Giá vừa thay đổi: tổng mới ${formatPrice(_giaDoi!.moi)} (trước đó ${formatPrice(_giaDoi!.cu)}). Chưa có đơn nào được tạo. Hãy xem lại rồi bấm đặt món một lần nữa để xác nhận.',
        ),
      ],
      if (_loiDat != null) ...[
        const SizedBox(height: QuanAnSpacing.md),
        QuanAnWarningBox(message: _loiDat!.thongDiep),
        const SizedBox(height: QuanAnSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Quay lại giỏ'),
        ),
      ],
    ]);
  }

  Widget _traCard() {
    final bg = _baoGia;
    final khoaApp = _tt.datMonAppBiKhoa(DateTime.now());
    final tienMatOk = _tienMatDuoc(bg);
    final lyDoTm = tienMatOk ? null : _lyDoKhongTienMat(bg);
    return _khung('Cách trả tiền', [
      RadioGroup<String>(
        groupValue: _cachTra,
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _cachTra = v;
            _giaDoi = null;
          });
        },
        child: Column(
          children: [
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'app',
              enabled: !khoaApp,
              title: Text(cachTraLabels['app']!),
              subtitle: Text(
                khoaApp
                    ? 'Bạn đang bị khóa đặt món trả trên app tới ${formatNgayGio(_tt.khoaDatMonAppDen!)}.'
                    : 'Mặc định. App giữ tiền tới khi bạn nhận món.',
                style: QuanAnText.bodySmall,
              ),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'tien_mat',
              enabled: tienMatOk,
              title: Text(cachTraLabels['tien_mat']!),
              subtitle: Text(
                lyDoTm ??
                    'Trả trực tiếp khi nhận món. App không giữ hay hoàn tiền.',
                style: QuanAnText.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _thanhDuoi() {
    final bg = _baoGia;
    final ly = _lyDoChua();
    final label = bg != null && bg.ok
        ? 'Đặt món · ${formatPrice(bg.tong)}'
        : 'Đặt món';
    return Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ly != null && !_dangTinh)
                    Padding(
                      padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
                      child: Text(
                        ly,
                        style: QuanAnText.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: ly == null && !_dangDat ? _dat : null,
                      child: _dangDat
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: QuanAnColors.white,
                              ),
                            )
                          : Text(label),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaChiTile extends StatelessWidget {
  const _DiaChiTile({
    required this.chon,
    required this.ten,
    required this.phu,
    required this.onTap,
    this.onXoa,
  });

  final bool chon;
  final String ten;
  final String? phu;
  final VoidCallback onTap;
  final VoidCallback? onXoa;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: QuanAnSpacing.sm,
    onTap: onTap,
    leading: Icon(
      chon ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      color: chon ? QuanAnColors.primary : QuanAnColors.textSecondary,
    ),
    title: Text(ten, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: phu == null || phu!.isEmpty || phu == ten
        ? null
        : Text(phu!, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: onXoa == null
        ? null
        : IconButton(
            tooltip: 'Xóa địa chỉ đã lưu',
            onPressed: onXoa,
            icon: const Icon(Icons.close),
          ),
  );
}

class _DongTien extends StatelessWidget {
  const _DongTien(
    this.nhan,
    this.giaTri, {
    this.dam = false,
    this.xanh = false,
    this.nho = false,
  });

  final String nhan;
  final String? giaTri;
  final bool dam;
  final bool xanh;
  final bool nho;

  @override
  Widget build(BuildContext context) {
    final kieu = dam
        ? QuanAnText.price.copyWith(fontSize: 18)
        : (nho ? QuanAnText.body : QuanAnText.body).copyWith(
            color: xanh ? QuanAnColors.success : null,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(nhan, style: kieu)),
          if (giaTri != null) ...[
            const SizedBox(width: QuanAnSpacing.sm),
            Text(giaTri!, style: kieu),
          ],
        ],
      ),
    );
  }
}

// ==================================================================== Chọn địa chỉ

/// Kết quả chọn địa chỉ trên bản đồ.
class _KetQuaChonDiaChi {
  const _KetQuaChonDiaChi(this.diaChi, this.luu);

  final DiaChiDat diaChi;
  final bool luu;
}

/// Lấy vị trí hiện tại; không được phép định vị thì null (app gợi ý chọn trên bản đồ).
Future<({double lat, double lng})?> _viTriHienTai() async {
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

/// Tìm địa chỉ trên OpenStreetMap (Nominatim), không cần khóa API.
Future<List<({double lat, double lng, String ten})>> _timDiaChi(
  String q,
) async {
  if (q.trim().length < 3) return const [];
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': q,
    'format': 'json',
    'limit': '5',
    'countrycodes': 'vn',
    'accept-language': 'vi',
  });
  try {
    final r = await http.get(uri);
    if (r.statusCode != 200) return const [];
    return [
      for (final x in jsonDecode(r.body) as List)
        (
          lat: double.parse(x['lat'] as String),
          lng: double.parse(x['lon'] as String),
          ten: x['display_name'] as String? ?? '',
        ),
    ];
  } catch (_) {
    return const [];
  }
}

/// Tên địa chỉ từ tọa độ (Nominatim); lỗi thì null.
Future<String?> _diaChiTuToaDo(double lat, double lng) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'lat': '$lat',
    'lon': '$lng',
    'format': 'json',
    'accept-language': 'vi',
  });
  try {
    final r = await http.get(uri);
    if (r.statusCode != 200) return null;
    final m = jsonDecode(r.body);
    final ten = m is Map ? m['display_name'] as String? : null;
    return ten == null || ten.isEmpty ? null : ten;
  } catch (_) {
    return null;
  }
}

/// Chọn địa chỉ giao: gõ để tìm hoặc kéo bản đồ đặt ghim vào giữa; ghi thêm chi tiết (số nhà, phòng...).
class _ChonDiaChiScreen extends StatefulWidget {
  const _ChonDiaChiScreen({this.banDau, this.viTriQuan});

  final LatLng? banDau;
  final LatLng? viTriQuan;

  @override
  State<_ChonDiaChiScreen> createState() => _ChonDiaChiScreenState();
}

class _ChonDiaChiScreenState extends State<_ChonDiaChiScreen> {
  static const _macDinh = LatLng(10.4599, 105.6377); // Cao Lãnh, Đồng Tháp
  final _map = MapController();
  final _tim = TextEditingController();
  final _chiTiet = TextEditingController();
  late LatLng _tam = widget.banDau ?? widget.viTriQuan ?? _macDinh;
  List<({double lat, double lng, String ten})> _goiY = const [];
  String? _tenChon;
  bool _dangTim = false;
  bool _dangChon = false;
  bool _luu = true;
  String? _thongBao;

  @override
  void dispose() {
    _tim.dispose();
    _chiTiet.dispose();
    super.dispose();
  }

  Future<void> _timKiem() async {
    setState(() => _dangTim = true);
    final ds = await _timDiaChi(_tim.text);
    if (!mounted) return;
    setState(() {
      _dangTim = false;
      _goiY = ds;
      _thongBao = ds.isEmpty
          ? 'Không tìm thấy địa chỉ, thử gõ cụ thể hơn hoặc kéo bản đồ.'
          : null;
    });
  }

  void _chonGoiY(({double lat, double lng, String ten}) g) {
    setState(() {
      _goiY = const [];
      _tenChon = g.ten;
      _tam = LatLng(g.lat, g.lng);
    });
    _map.move(_tam, 16);
  }

  Future<void> _viTriHienTai2() async {
    setState(() => _thongBao = null);
    final p = await _viTriHienTai();
    if (!mounted) return;
    if (p == null) {
      setState(
        () => _thongBao = 'Không lấy được vị trí (chưa cho phép định vị). Hãy gõ địa chỉ hoặc kéo bản đồ.',
      );
      return;
    }
    setState(() {
      _tenChon = null;
      _tam = LatLng(p.lat, p.lng);
    });
    _map.move(_tam, 17);
  }

  Future<void> _xong() async {
    if (_dangChon) return;
    setState(() => _dangChon = true);
    var dong = _tenChon;
    dong ??= await _diaChiTuToaDo(_tam.latitude, _tam.longitude);
    dong ??= _tim.text.trim().isEmpty
        ? 'Điểm đã ghim trên bản đồ'
        : _tim.text.trim();
    final chiTiet = _chiTiet.text.trim();
    if (!mounted) return;
    Navigator.pop(
      context,
      _KetQuaChonDiaChi(
        DiaChiDat(
          lat: _tam.latitude,
          lng: _tam.longitude,
          dong: chiTiet.isEmpty ? dong : '$chiTiet, $dong',
        ),
        _luu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn địa chỉ giao')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tim,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _timKiem(),
                      decoration: const InputDecoration(
                        hintText: 'Gõ địa chỉ, tên đường, phường...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  OutlinedButton(
                    onPressed: _dangTim ? null : _timKiem,
                    child: Text(_dangTim ? '...' : 'Tìm'),
                  ),
                ],
              ),
              for (final g in _goiY)
                ListTile(
                  dense: true,
                  minVerticalPadding: QuanAnSpacing.sm,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: QuanAnColors.primary,
                  ),
                  title: Text(
                    g.ten,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _chonGoiY(g),
                ),
              const SizedBox(height: QuanAnSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viTriHienTai2,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Dùng vị trí hiện tại'),
                ),
              ),
              if (_thongBao != null)
                Padding(
                  padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: Text(
                    _thongBao!,
                    style: const TextStyle(color: QuanAnColors.warning),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _tam,
                  initialZoom: 16,
                  onPositionChanged: (cam, coTay) {
                    _tam = cam.center;
                    // Kéo ghim đi chỗ khác thì bỏ tên địa chỉ đã chọn từ gợi ý.
                    if (coTay) _tenChon = null;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_sinh_vien',
                  ),
                  if (widget.viTriQuan != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.viTriQuan!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.storefront,
                            color: QuanAnColors.markerGrey,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  const SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
              const IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(
                    Icons.location_pin,
                    size: 44,
                    color: QuanAnColors.primary,
                  ),
                ),
              ),
              const Positioned(
                top: QuanAnSpacing.sm,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(QuanAnSpacing.sm),
                    child: Text('Kéo bản đồ để đặt ghim vào giữa'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _chiTiet,
                  decoration: const InputDecoration(
                    labelText:
                        'Chi tiết (số nhà, tầng, phòng...) - không bắt buộc',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _luu,
                  onChanged: (v) => setState(() => _luu = v),
                  title: const Text('Lưu địa chỉ cho lần sau'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _dangChon ? null : _xong,
                    child: Text(
                      _dangChon ? 'Đang xử lý...' : 'Dùng địa chỉ này',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
