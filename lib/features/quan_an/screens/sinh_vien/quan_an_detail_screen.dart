import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../../../shared/widgets/location_map.dart';
import '../../models/danh_gia.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/khuyen_mai.dart';
import '../../models/mon_an.dart';
import '../../models/nhom_mon.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart' show QuanAnConfig, tienIchLabels;
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/diem_danh_gia_box.dart';
import '../../widgets/gio_hang_bar.dart';
import '../../widgets/khuyen_mai_banner.dart';
import '../../widgets/mon_an_tile.dart';
import '../../widgets/nhom_mon_tab_bar.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_card.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../../widgets/trang_thai_mo_cua_badge.dart';
import '../quan_an_routes.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import 'check_in_screen.dart';
import 'dat_ban_screen.dart';
import 'danh_gia_quan_screen.dart';
import 'mon_an_detail_sheet.dart';

/// Số đánh giá hiện sẵn; còn lại bấm "Xem thêm".
const _soDanhGiaRutGon = 5;

String _d1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

void _thongBao(BuildContext context, String chu) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chu)));

/// Dòng "Đang đóng cửa — mở lúc 6:00 sáng mai" từ câu trạng thái của [tinhMoCua].
String _dongDongCua(TinhTrangMoCua tt) {
  final s = tt.thongDiep;
  if (s.startsWith('Mở lúc')) {
    return 'Đang đóng cửa — m${s.substring(1)}';
  }
  return 'Đang đóng cửa';
}

/// QA-SV-04 Chi tiết quán (mục 3.4 Bước 2): thông tin, khuyến mãi, menu, đánh giá và thanh nút
/// dưới cùng đổi theo tình trạng của quán. Khách chưa đăng nhập xem được hết, trừ số điện thoại.
class QuanAnDetailScreen extends StatefulWidget {
  const QuanAnDetailScreen({required this.dv, required this.quanId, super.key});

  final QuanAnDichVu dv;
  final String quanId;

  @override
  State<QuanAnDetailScreen> createState() => _QuanAnDetailScreenState();
}

class _QuanAnDetailScreenState extends State<QuanAnDetailScreen> {
  late Stream<QuanAn?> _stream = widget.dv.quan.quan(widget.quanId);

  @override
  Widget build(BuildContext context) => StreamBuilder<QuanAn?>(
    stream: _stream,
    builder: (context, snap) {
      if (snap.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: QuanAnErrorState(
            message: 'Không tải được thông tin quán',
            onRetry: () =>
                setState(() => _stream = widget.dv.quan.quan(widget.quanId)),
          ),
        );
      }
      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
        return Scaffold(
          appBar: AppBar(),
          body: const SingleChildScrollView(
            child: QuanAnSkeletonList(count: 2),
          ),
        );
      }
      final q = snap.data;
      final laChu =
          q != null && widget.dv.uid.isNotEmpty && q.chuQuanId == widget.dv.uid;
      if (q == null || (!q.dangHien && !laChu)) {
        return Scaffold(
          appBar: AppBar(),
          body: const QuanAnEmptyState(
            title: 'Quán không tồn tại hoặc đang tạm ngưng hoạt động',
            icon: Icons.storefront_outlined,
          ),
        );
      }
      return _ChiTietQuan(dv: widget.dv, quan: q, laChu: laChu);
    },
  );
}

class _ChiTietQuan extends StatefulWidget {
  const _ChiTietQuan({
    required this.dv,
    required this.quan,
    required this.laChu,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final bool laChu;

  @override
  State<_ChiTietQuan> createState() => _ChiTietQuanState();
}

class _ChiTietQuanState extends State<_ChiTietQuan> {
  final _cuon = ScrollController();
  final _khoaMuc = <String, GlobalKey>{};
  QuanAnConfig _cfg = const QuanAnConfig();
  Timer? _dongHo;
  String? _nhomDangChon;

  QuanAnDichVu get _dv => widget.dv;
  QuanAn get _q => widget.quan;

  @override
  void initState() {
    super.initState();
    _napCauHinh();
    // Trạng thái mở cửa đổi theo thời gian: làm mới mỗi phút.
    _dongHo = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dongHo?.cancel();
    _cuon.dispose();
    super.dispose();
  }

  Future<void> _napCauHinh() async {
    try {
      final c = await _dv.donMon.cauHinh();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
  }

  GlobalKey _khoa(String id) => _khoaMuc.putIfAbsent(id, GlobalKey.new);

  void _cuonToiNhom(String id) {
    setState(() => _nhomDangChon = id);
    final ctx = _khoa(id).currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  bool _canDangNhap(String viec) {
    if (_dv.uid.isNotEmpty) return true;
    _thongBao(context, 'Vui lòng đăng nhập để $viec.');
    return false;
  }

  Uri get _duongDi {
    final v = _q.viTri;
    if (v != null) return directionsUri(v.latitude, v.longitude);
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': _q.diaChi,
    });
  }

  void _chiDuong() => launchUrl(_duongDi, mode: LaunchMode.externalApplication);

  void _nhanTin() {
    if (!_canDangNhap('nhắn tin cho quán')) return;
    QuanAnDieuHuong.chat(context, _dv, _q.chuQuanId, quanId: _q.id);
  }

  void _datBan() {
    if (!_canDangNhap('đặt bàn')) return;
    QuanAnDieuHuong.mo(context, (_) => DatBanScreen(dv: _dv, quan: _q));
  }

  void _checkIn() {
    if (!_canDangNhap('check-in')) return;
    QuanAnDieuHuong.mo(context, (_) => CheckInScreen(dv: _dv, quan: _q));
  }

  void _baoCao() {
    if (!_canDangNhap('báo cáo')) return;
    moBaoCao(context, _dv, loai: 'quan', id: _q.id);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final now = DateTime.now();
    final tt = q.moCua(now, cfg: _cfg);
    final datMonDuoc = q.datMonDuocLuc(now, cfg: _cfg);
    return Scaffold(
      appBar: AppBar(
        title: Text(q.ten, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!widget.laChu) ...[
            NutLuuQuan(dv: _dv, quanId: q.id, chuQuanId: q.chuQuanId),
            IconButton(
              tooltip: 'Báo cáo quán',
              onPressed: _baoCao,
              icon: const Icon(Icons.flag_outlined),
            ),
          ],
          const SizedBox(width: QuanAnSpacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        controller: _cuon,
        padding: const EdgeInsets.all(QuanAnSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.laChu) ...[
                  _GhiChuChuQuan(quan: q),
                  const SizedBox(height: QuanAnSpacing.lg),
                ],
                _Anh(quan: q),
                const SizedBox(height: QuanAnSpacing.lg),
                _ThongTinChung(
                  quan: q,
                  tinhTrang: tt,
                  tamNgung: q.nhanDatMon && (q.dangTamNgung(now) || q.khoaBan),
                  onCheckIn: widget.laChu ? null : _checkIn,
                ),
                const SizedBox(height: QuanAnSpacing.xl),
                _PhucVuVaTienIch(quan: q),
                if (q.moTa.trim().isNotEmpty) ...[
                  const SizedBox(height: QuanAnSpacing.xl),
                  const Text('Mô tả', style: QuanAnText.h2),
                  const SizedBox(height: QuanAnSpacing.sm),
                  Text(q.moTa, style: QuanAnText.body),
                ],
                const SizedBox(height: QuanAnSpacing.xl),
                _DiaChi(quan: q, onChiDuong: _chiDuong),
                const SizedBox(height: QuanAnSpacing.xl),
                _ChuQuan(
                  dv: _dv,
                  quan: q,
                  laChu: widget.laChu,
                  onNhanTin: _nhanTin,
                ),
                _KhuyenMaiKhoi(dv: _dv, quanId: q.id),
                const SizedBox(height: QuanAnSpacing.xl),
                _MenuKhoi(
                  dv: _dv,
                  quan: q,
                  cfg: _cfg,
                  laChu: widget.laChu,
                  choThem: datMonDuoc,
                  dangChon: _nhomDangChon,
                  khoaMuc: _khoa,
                  onChonNhom: _cuonToiNhom,
                ),
                const SizedBox(height: QuanAnSpacing.xl),
                _DanhGiaKhoi(dv: _dv, quan: q, laChu: widget.laChu),
                const SizedBox(height: QuanAnSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.laChu
          ? null
          : _ThanhDuoi(
              dv: _dv,
              quan: q,
              tinhTrang: tt,
              datMonDuoc: datMonDuoc,
              now: now,
              onChiDuong: _chiDuong,
              onNhanTin: _nhanTin,
              onDatBan: _datBan,
            ),
    );
  }
}

/// Nhắc chủ quán rằng đang xem như khách, kèm trạng thái quán nếu chưa hoạt động.
class _GhiChuChuQuan extends StatelessWidget {
  const _GhiChuChuQuan({required this.quan});

  final QuanAn quan;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(QuanAnSpacing.md),
    decoration: BoxDecoration(
      color: QuanAnColors.primaryLight,
      borderRadius: BorderRadius.circular(QuanAnRadius.button),
    ),
    child: Text(
      quan.dangHien
          ? 'Đây là quán của bạn — bạn đang xem như khách. Quản lý quán ở Của tôi → Quản lý quán của tôi.'
          : 'Quán của bạn đang ở trạng thái "${quan.trangThaiLabel}", khách chưa thấy quán này.',
      style: QuanAnText.body,
    ),
  );
}

class _Anh extends StatelessWidget {
  const _Anh({required this.quan});

  final QuanAn quan;

  @override
  Widget build(BuildContext context) {
    final anh = <String>{
      ...quan.anhMatTien,
      if (quan.anhBia.isNotEmpty) quan.anhBia,
      ...quan.anhKhac,
    }.toList();
    if (anh.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: QuanAnColors.primaryLight,
          borderRadius: BorderRadius.circular(QuanAnRadius.card),
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          size: 56,
          color: QuanAnColors.primary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(QuanAnRadius.card),
      child: ImageGallery(urls: anh, aspectRatio: 16 / 9),
    );
  }
}

class _ThongTinChung extends StatefulWidget {
  const _ThongTinChung({
    required this.quan,
    required this.tinhTrang,
    required this.tamNgung,
    required this.onCheckIn,
  });

  final QuanAn quan;
  final TinhTrangMoCua tinhTrang;
  final bool tamNgung;

  /// Null = không hiện nút (chủ quán xem quán của mình).
  final VoidCallback? onCheckIn;

  @override
  State<_ThongTinChung> createState() => _ThongTinChungState();
}

class _ThongTinChungState extends State<_ThongTinChung> {
  bool _xemGio = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quan;
    final sl = q.soLieu;
    final homNay = gioVietNam(DateTime.now()).weekday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.ten, style: QuanAnText.h1),
        const SizedBox(height: QuanAnSpacing.sm),
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          children: [
            QuanAnStatusBadge(
              kind: QuanAnBadgeKind.xacThuc,
              label: q.daXacThucLabel,
            ),
            for (final n in q.nhanHuyHieu)
              Chip(label: Text(n), visualDensity: VisualDensity.compact),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.sm),
        Text(
          sl.coDiemXacMinh
              ? '★ ${_d1(sl.diemTong!)} · ${sl.soDanhGia} đánh giá xác minh'
              : 'Chưa có đánh giá xác minh',
          style: sl.coDiemXacMinh
              ? QuanAnText.label.copyWith(color: QuanAnColors.primary)
              : QuanAnText.bodySmall,
        ),
        const SizedBox(height: QuanAnSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              if (q.loaiMon.isNotEmpty) TextSpan(text: '${q.loaiMonLabel}  '),
              if (q.giaHienThi != '—')
                TextSpan(text: q.giaHienThi, style: QuanAnText.price),
            ],
          ),
          style: QuanAnText.body,
        ),
        const SizedBox(height: QuanAnSpacing.md),
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TrangThaiMoCuaBadge(tinhTrang: widget.tinhTrang),
            if (widget.tamNgung && widget.tinhTrang.trangThai.dangMo)
              const QuanAnStatusBadge(
                kind: QuanAnBadgeKind.sapDong,
                label: 'Tạm ngưng nhận đơn',
              ),
            TextButton.icon(
              onPressed: () => setState(() => _xemGio = !_xemGio),
              icon: Icon(_xemGio ? Icons.expand_less : Icons.expand_more),
              label: Text(_xemGio ? 'Ẩn giờ mở cửa' : 'Xem giờ cả tuần'),
            ),
          ],
        ),
        if (_xemGio)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            decoration: BoxDecoration(
              color: QuanAnColors.white,
              borderRadius: BorderRadius.circular(QuanAnRadius.button),
              border: Border.all(color: QuanAnColors.border),
            ),
            child: Column(
              children: [
                for (var d = 1; d <= 7; d++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            tenThu(d),
                            style: d == homNay
                                ? QuanAnText.label
                                : QuanAnText.body,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tomTatNgay(q.gioMoCua[d]),
                            textAlign: TextAlign.end,
                            style: d == homNay
                                ? QuanAnText.label
                                : QuanAnText.body,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (widget.onCheckIn != null) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          OutlinedButton.icon(
            onPressed: widget.onCheckIn,
            icon: const Icon(Icons.place_outlined),
            label: const Text('Check-in tại quán'),
          ),
        ],
      ],
    );
  }
}

class _PhucVuVaTienIch extends StatelessWidget {
  const _PhucVuVaTienIch({required this.quan});

  final QuanAn quan;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final d = q.datMon;
    final nhan = <String>[
      if (q.phucVu.anTaiQuan) '🍽 Ăn tại quán',
      if (q.phucVu.mangDi) '🥡 Mang đi',
      if (q.nhanDatMon) '🛵 Đặt món qua app',
      if (q.nhanDatBanQuaApp) '📅 Nhận đặt bàn',
      if (q.luuDong) '🛺 Bán lưu động',
    ];
    final chiTietDatMon = [
      if (q.nhanDatMon && d.denLay) 'Đến lấy',
      if (q.nhanDatMon && d.giaoTanNoi)
        'Giao tận nơi trong ${d.banKinhKm} km · ${d.phiGiaoMoTa}',
      if (q.nhanDatMon && d.donToiThieu > 0)
        'Đơn tối thiểu ${formatPrice(d.donToiThieu)}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình thức phục vụ', style: QuanAnText.h2),
        const SizedBox(height: QuanAnSpacing.sm),
        if (nhan.isEmpty)
          const Text(
            'Quán chưa khai hình thức phục vụ.',
            style: QuanAnText.bodySmall,
          )
        else
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [for (final n in nhan) Chip(label: Text(n))],
          ),
        if (chiTietDatMon.isNotEmpty) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          Text(chiTietDatMon.join(' · '), style: QuanAnText.bodySmall),
        ],
        if (q.luuDong && q.ghiChuViTri.isNotEmpty) ...[
          const SizedBox(height: QuanAnSpacing.xs),
          Text('Vị trí: ${q.ghiChuViTri}', style: QuanAnText.bodySmall),
        ],
        if (q.tienIch.isNotEmpty) ...[
          const SizedBox(height: QuanAnSpacing.xl),
          const Text('Tiện ích', style: QuanAnText.h2),
          const SizedBox(height: QuanAnSpacing.sm),
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [
              for (final t in q.tienIch)
                Chip(label: Text(tienIchLabels[t] ?? t)),
            ],
          ),
        ],
      ],
    );
  }
}

class _DiaChi extends StatelessWidget {
  const _DiaChi({required this.quan, required this.onChiDuong});

  final QuanAn quan;
  final VoidCallback onChiDuong;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Địa chỉ', style: QuanAnText.h2),
        const SizedBox(height: QuanAnSpacing.sm),
        Text(
          [q.diaChi, q.phuong].where((s) => s.isNotEmpty).join(', '),
          style: QuanAnText.body,
        ),
        const SizedBox(height: QuanAnSpacing.md),
        if (q.viTri != null)
          LocationMap(
            latitude: q.viTri!.latitude,
            longitude: q.viTri!.longitude,
          )
        else
          OutlinedButton.icon(
            onPressed: onChiDuong,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Chỉ đường'),
          ),
      ],
    );
  }
}

/// Khối chủ quán: tỷ lệ phản hồi / nhận đơn / giữ bàn, Gọi (cần đăng nhập), Nhắn tin.
class _ChuQuan extends StatefulWidget {
  const _ChuQuan({
    required this.dv,
    required this.quan,
    required this.laChu,
    required this.onNhanTin,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final bool laChu;
  final VoidCallback onNhanTin;

  @override
  State<_ChuQuan> createState() => _ChuQuanState();
}

class _ChuQuanState extends State<_ChuQuan> {
  Future<String?>? _sdt;

  @override
  void initState() {
    super.initState();
    final q = widget.quan;
    if (widget.dv.uid.isNotEmpty && !widget.laChu) {
      _sdt = q.sdt.isNotEmpty
          ? Future.value(q.sdt)
          : widget.dv.quan.laySdtQuan(q.id).catchError((_) => null);
    }
  }

  String _ty(int? v) => v == null ? 'chưa có' : '$v%';

  @override
  Widget build(BuildContext context) {
    final q = widget.quan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(QuanAnSpacing.lg),
        child: StreamBuilder<ChiSoChuQuan>(
          stream: widget.dv.quan.chiSoChu(q.chuQuanId),
          builder: (context, s) {
            final cs = s.data ?? const ChiSoChuQuan();
            final chiSo = [
              'Tỷ lệ phản hồi: ${_ty(cs.tyLePhanHoi)}',
              if (q.nhanDatMon) 'Nhận đơn: ${_ty(cs.tyLeNhanDon)}',
              if (q.nhanDatBanQuaApp) 'Giữ bàn: ${_ty(cs.tyLeGiuBan)}',
            ].join(' · ');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: QuanAnColors.primaryLight,
                      child: Icon(Icons.person, color: QuanAnColors.primary),
                    ),
                    const SizedBox(width: QuanAnSpacing.md),
                    Expanded(
                      child: Text(
                        cs.hoTen ?? 'Chủ quán',
                        style: QuanAnText.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (cs.daXacThucDanhTinh) ...[
                  const SizedBox(height: QuanAnSpacing.sm),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: QuanAnStatusBadge(
                      kind: QuanAnBadgeKind.xacThuc,
                      label: 'Đã xác thực danh tính',
                    ),
                  ),
                ],
                const SizedBox(height: QuanAnSpacing.sm),
                Text(chiSo, style: QuanAnText.bodySmall),
                if (!widget.laChu) ...[
                  const SizedBox(height: QuanAnSpacing.md),
                  if (_sdt == null)
                    const Text(
                      'Đăng nhập để xem số điện thoại và nhắn tin cho chủ quán.',
                      style: QuanAnText.bodySmall,
                    )
                  else
                    FutureBuilder<String?>(
                      future: _sdt,
                      builder: (context, sdt) => Wrap(
                        spacing: QuanAnSpacing.sm,
                        runSpacing: QuanAnSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onNhanTin,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Nhắn tin'),
                          ),
                          if (sdt.data != null && sdt.data!.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri(scheme: 'tel', path: sdt.data)),
                              icon: const Icon(Icons.call_outlined),
                              label: Text('Gọi ${sdt.data}'),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Khối "Khuyến mãi" (ẩn khi quán không có khuyến mãi nào đang chạy).
class _KhuyenMaiKhoi extends StatelessWidget {
  const _KhuyenMaiKhoi({required this.dv, required this.quanId});

  final QuanAnDichVu dv;
  final String quanId;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<KhuyenMai>>(
    stream: dv.khuyenMai.dangChay(quanId),
    builder: (context, s) {
      if (s.hasError) {
        return const Padding(
          padding: EdgeInsets.only(top: QuanAnSpacing.xl),
          child: Text(
            'Không tải được khuyến mãi của quán.',
            style: TextStyle(color: QuanAnColors.danger),
          ),
        );
      }
      final ds = s.data ?? const <KhuyenMai>[];
      if (ds.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: QuanAnSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Khuyến mãi', style: QuanAnText.h2),
            const SizedBox(height: QuanAnSpacing.sm),
            for (final km in ds)
              Padding(
                padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
                child: KhuyenMaiBanner(khuyenMai: km),
              ),
          ],
        ),
      );
    },
  );
}

/// Khối menu: thanh nhóm món, món nổi bật trên cùng, rồi từng nhóm.
class _MenuKhoi extends StatelessWidget {
  const _MenuKhoi({
    required this.dv,
    required this.quan,
    required this.cfg,
    required this.laChu,
    required this.choThem,
    required this.dangChon,
    required this.khoaMuc,
    required this.onChonNhom,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final QuanAnConfig cfg;
  final bool laChu;

  /// Quán đang nhận đặt món được ngay lúc này (nút ＋ bấm được).
  final bool choThem;
  final String? dangChon;
  final GlobalKey Function(String id) khoaMuc;
  final ValueChanged<String> onChonNhom;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Menu', style: QuanAnText.h2),
      const SizedBox(height: QuanAnSpacing.sm),
      QuanAnStream<List<NhomMon>>(
        stream: () => dv.menu.nhomMon(quan.id),
        thongBaoLoi: 'Không tải được menu',
        dangTai: const QuanAnSkeletonBox(height: 96),
        builder: (context, nhom) => QuanAnStream<List<MonAn>>(
          stream: () => dv.menu.mon(quan.id),
          thongBaoLoi: 'Không tải được menu',
          dangTai: const QuanAnSkeletonBox(height: 96),
          builder: (context, mon) => ListenableBuilder(
            listenable: dv.gioHang,
            builder: (context, _) => _noiDung(context, nhom, mon),
          ),
        ),
      ),
    ],
  );

  Widget _tile(BuildContext context, MonAn m) => Padding(
    padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
    child: MonAnTile(
      mon: m,
      soTrongGio: dv.gioHang.gio.quanId == quan.id
          ? dv.gioHang.gio.soLuongMon(m.id)
          : 0,
      choThem: choThem,
      onTap: () => moChiTietMon(context, dv, quan, m),
      onThem: quan.nhanDatMon && !laChu
          ? () => moChiTietMon(context, dv, quan, m)
          : null,
    ),
  );

  Widget _noiDung(BuildContext context, List<NhomMon> nhom, List<MonAn> mon) {
    if (mon.isEmpty) {
      return const Text('Quán chưa có món nào.', style: QuanAnText.bodySmall);
    }
    final theoNhom = <String, List<MonAn>>{};
    final idNhom = {for (final n in nhom) n.id};
    for (final m in mon) {
      theoNhom
          .putIfAbsent(
            idNhom.contains(m.nhomId) ? m.nhomId : '__khac__',
            () => [],
          )
          .add(m);
    }
    final cacNhom = [
      for (final n in nhom)
        if (theoNhom[n.id]?.isNotEmpty ?? false) n,
      if (theoNhom['__khac__']?.isNotEmpty ?? false)
        const NhomMon(id: '__khac__', quanId: '', ten: 'Khác'),
    ];
    final noiBat = mon.where((m) => m.noiBat).toList();
    final chon =
        dangChon ??
        (noiBat.isNotEmpty ? nhomNoiBatId : cacNhom.firstOrNull?.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NhomMonTabBar(
          nhom: cacNhom,
          coNoiBat: noiBat.isNotEmpty,
          dangChon: chon,
          onChon: onChonNhom,
        ),
        if (noiBat.isNotEmpty) ...[
          KeyedSubtree(
            key: khoaMuc(nhomNoiBatId),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: QuanAnSpacing.sm),
              child: Text('⭐ Nổi bật', style: QuanAnText.h3),
            ),
          ),
          for (final m in noiBat) _tile(context, m),
        ],
        for (final n in cacNhom) ...[
          KeyedSubtree(
            key: khoaMuc(n.id),
            child: Padding(
              padding: const EdgeInsets.only(
                top: QuanAnSpacing.md,
                bottom: QuanAnSpacing.sm,
              ),
              child: Text(n.ten, style: QuanAnText.h3),
            ),
          ),
          for (final m in theoNhom[n.id]!) _tile(context, m),
        ],
      ],
    );
  }
}

/// Khối đánh giá: điểm tổng thể + 4 tiêu chí, nút viết / sửa đánh giá, danh sách đánh giá.
class _DanhGiaKhoi extends StatefulWidget {
  const _DanhGiaKhoi({
    required this.dv,
    required this.quan,
    required this.laChu,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final bool laChu;

  @override
  State<_DanhGiaKhoi> createState() => _DanhGiaKhoiState();
}

class _DanhGiaKhoiState extends State<_DanhGiaKhoi> {
  bool _het = false;

  void _viet() {
    if (widget.dv.uid.isEmpty) {
      _thongBao(context, 'Vui lòng đăng nhập để đánh giá.');
      return;
    }
    QuanAnDieuHuong.mo(
      context,
      (_) => DanhGiaQuanScreen(
        dv: widget.dv,
        quanId: widget.quan.id,
        tenQuan: widget.quan.ten,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dv = widget.dv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đánh giá', style: QuanAnText.h2),
        const SizedBox(height: QuanAnSpacing.sm),
        DiemDanhGiaBox(soLieu: widget.quan.soLieu),
        if (!widget.laChu) ...[
          const SizedBox(height: QuanAnSpacing.md),
          if (dv.uid.isEmpty)
            OutlinedButton.icon(
              onPressed: _viet,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Viết đánh giá'),
            )
          else
            StreamBuilder<DanhGia?>(
              stream: dv.danhGia.cuaToi(widget.quan.id),
              builder: (context, s) => OutlinedButton.icon(
                onPressed: _viet,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(
                  s.data == null ? 'Viết đánh giá' : 'Sửa đánh giá của tôi',
                ),
              ),
            ),
        ],
        const SizedBox(height: QuanAnSpacing.md),
        QuanAnStream<List<DanhGia>>(
          stream: () => dv.danhGia.cuaQuan(widget.quan.id),
          thongBaoLoi: 'Không tải được đánh giá',
          dangTai: const QuanAnSkeletonBox(height: 96),
          builder: (context, ds) {
            final sx = sapXepDanhGia(ds);
            if (sx.isEmpty) {
              return const Text(
                'Chưa có đánh giá.',
                style: QuanAnText.bodySmall,
              );
            }
            final hien = _het ? sx : sx.take(_soDanhGiaRutGon).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in hien)
                  _DanhGiaTile(dv: dv, d: d, laChu: widget.laChu),
                if (!_het && sx.length > _soDanhGiaRutGon)
                  TextButton(
                    onPressed: () => setState(() => _het = true),
                    child: Text(
                      'Xem thêm ${sx.length - _soDanhGiaRutGon} đánh giá',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Một đánh giá: nhãn xác minh, điểm 4 tiêu chí, thẻ, nhận xét, ảnh, chủ quán trả lời (1 lần).
/// Đánh giá chưa xác minh hiện nhạt hơn.
class _DanhGiaTile extends StatelessWidget {
  const _DanhGiaTile({required this.dv, required this.d, required this.laChu});

  final QuanAnDichVu dv;
  final DanhGia d;
  final bool laChu;

  static const _icon = {
    'dat_mon': Icons.delivery_dining_rounded,
    'dat_ban': Icons.restaurant_rounded,
    'check_in': Icons.place_rounded,
  };

  Future<void> _traLoi(BuildContext context) async {
    final c = TextEditingController();
    final nd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trả lời công khai (1 lần)'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Nội dung trả lời'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    c.dispose();
    if (nd == null || nd.isEmpty || !context.mounted) return;
    await chayThaoTac(
      context,
      () => dv.danhGia.traLoi(d.id, nd),
      thanhCong: 'Đã trả lời đánh giá',
    );
  }

  @override
  Widget build(BuildContext context) {
    final daXm = d.tinhDiem && d.nhan != null;
    final chiTiet = [
      for (final (ma, nhan) in tieuChiDanhGia)
        if (d.diem[ma] != null) '$nhan ${d.diem[ma]}',
    ].join(' · ');
    return Opacity(
      opacity: daXm ? 1 : 0.7,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
        padding: const EdgeInsets.all(QuanAnSpacing.md),
        decoration: BoxDecoration(
          color: QuanAnColors.white,
          borderRadius: BorderRadius.circular(QuanAnRadius.card),
          border: Border.all(color: QuanAnColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '★ ${_d1(d.diemTong)}',
                  style: QuanAnText.label.copyWith(color: QuanAnColors.primary),
                ),
                Text(
                  d.tenNguoiViet.isEmpty ? 'Sinh viên' : d.tenNguoiViet,
                  style: QuanAnText.label,
                ),
                QuanAnStatusBadge(
                  kind: daXm ? QuanAnBadgeKind.nhan : QuanAnBadgeKind.chung,
                  icon: _icon[d.nhan],
                  label: switch (d.nhan) {
                    'dat_mon' => 'Đã đặt món',
                    'dat_ban' => 'Đã đến theo đặt bàn',
                    'check_in' => 'Check-in tại quán',
                    _ => 'Chưa xác minh',
                  },
                ),
              ],
            ),
            if (chiTiet.isNotEmpty) ...[
              const SizedBox(height: QuanAnSpacing.xs),
              Text(
                '$chiTiet${d.daCapNhat ? ' · Đã cập nhật' : ''}',
                style: QuanAnText.bodySmall,
              ),
            ],
            if (d.the.isNotEmpty) ...[
              const SizedBox(height: QuanAnSpacing.xs),
              Wrap(
                spacing: QuanAnSpacing.xs,
                children: [
                  for (final t in d.the)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(theNhanhDanhGiaLabels[t] ?? t),
                    ),
                ],
              ),
            ],
            if (d.nhanXet.isNotEmpty) ...[
              const SizedBox(height: QuanAnSpacing.xs),
              Text(d.nhanXet, style: QuanAnText.body),
            ],
            if (d.anh.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                child: Wrap(
                  spacing: QuanAnSpacing.xs,
                  runSpacing: QuanAnSpacing.xs,
                  children: [
                    for (final a in d.anh)
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NetworkPhoto(a),
                        ),
                      ),
                  ],
                ),
              ),
            if (d.chuTraLoi != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: QuanAnSpacing.sm),
                padding: const EdgeInsets.all(QuanAnSpacing.sm),
                decoration: BoxDecoration(
                  color: QuanAnColors.primaryLight,
                  borderRadius: BorderRadius.circular(QuanAnRadius.input),
                ),
                child: Text(
                  'Chủ quán trả lời: ${d.chuTraLoi}',
                  style: QuanAnText.bodySmall.copyWith(
                    color: QuanAnColors.textPrimary,
                  ),
                ),
              ),
            Row(
              children: [
                if (laChu && d.chuTraLoi == null)
                  TextButton(
                    onPressed: () => _traLoi(context),
                    child: const Text('Trả lời'),
                  ),
                const Spacer(),
                if (d.nguoiViet != dv.uid)
                  TextButton(
                    onPressed: () {
                      if (dv.uid.isEmpty) {
                        _thongBao(context, 'Vui lòng đăng nhập để báo cáo.');
                        return;
                      }
                      moBaoCao(context, dv, loai: 'danh_gia', id: d.id);
                    },
                    child: const Text('Báo cáo'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh nút dưới cùng, đúng bảng mục 3.4 Bước 2 (tối đa 1 nút chính):
/// nhận đặt món & đang mở → Xem giỏ + Đặt bàn · đóng / tạm ngưng → Đặt bàn + Nhắn tin + dòng báo ·
/// chỉ đặt bàn → Đặt bàn + Nhắn tin · tạm nghỉ → Chỉ đường + Nhắn tin · còn lại → Chỉ đường + Nhắn tin.
class _ThanhDuoi extends StatelessWidget {
  const _ThanhDuoi({
    required this.dv,
    required this.quan,
    required this.tinhTrang,
    required this.datMonDuoc,
    required this.now,
    required this.onChiDuong,
    required this.onNhanTin,
    required this.onDatBan,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final TinhTrangMoCua tinhTrang;
  final bool datMonDuoc;
  final DateTime now;
  final VoidCallback onChiDuong;
  final VoidCallback onNhanTin;
  final VoidCallback onDatBan;

  Widget get _nutChiDuong => FilledButton.icon(
    onPressed: onChiDuong,
    icon: const Icon(Icons.directions_outlined),
    label: const Text('Chỉ đường'),
  );

  Widget get _nutDatBanChinh => FilledButton.icon(
    onPressed: onDatBan,
    icon: const Icon(Icons.event_seat_outlined),
    label: const Text('Đặt bàn'),
  );

  Widget get _nutDatBanPhu => OutlinedButton.icon(
    onPressed: onDatBan,
    icon: const Icon(Icons.event_seat_outlined),
    label: const Text('Đặt bàn'),
  );

  Widget get _nutNhanTin => OutlinedButton.icon(
    onPressed: onNhanTin,
    icon: const Icon(Icons.chat_bubble_outline),
    label: const Text('Nhắn tin'),
  );

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final tt = tinhTrang.trangThai;
    final tamNghi = tt == TrangThaiMoCua.tamNghi;
    final dong = tt == TrangThaiMoCua.dong;
    String? dongBao;
    Widget? chinh;
    Widget? phu;
    var gioHang = false;
    if (tamNghi) {
      chinh = _nutChiDuong;
      phu = _nutNhanTin;
      dongBao = tinhTrang.thongDiep;
    } else if (q.nhanDatMon && datMonDuoc) {
      gioHang = true;
      if (q.nhanDatBanQuaApp) phu = _nutDatBanPhu;
    } else if (q.nhanDatMon) {
      chinh = q.nhanDatBanQuaApp ? _nutDatBanChinh : _nutChiDuong;
      phu = _nutNhanTin;
      dongBao = dong ? _dongDongCua(tinhTrang) : 'Tạm ngưng nhận đơn';
    } else if (q.nhanDatBanQuaApp) {
      chinh = _nutDatBanChinh;
      phu = _nutNhanTin;
      if (dong) dongBao = _dongDongCua(tinhTrang);
    } else {
      chinh = _nutChiDuong;
      phu = _nutNhanTin;
      if (dong) dongBao = _dongDongCua(tinhTrang);
    }
    return ListenableBuilder(
      listenable: dv.gioHang,
      builder: (context, _) {
        final g = dv.gioHang.gio;
        final coGio = gioHang && !g.laRong && g.quanId == q.id;
        if (!coGio && chinh == null && phu == null && dongBao == null) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: QuanAnColors.white,
            boxShadow: [
              BoxShadow(
                color: QuanAnColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(QuanAnSpacing.screen),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dongBao != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: QuanAnSpacing.sm,
                          ),
                          child: Text(
                            dongBao,
                            style: QuanAnText.label.copyWith(
                              color: QuanAnColors.warning,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (coGio) GioHangBar(dv: dv, quan: q),
                      if (coGio && phu != null)
                        const SizedBox(height: QuanAnSpacing.sm),
                      if (!coGio && gioHang && phu != null)
                        phu
                      else if (coGio && phu != null)
                        phu
                      else if (chinh != null || phu != null)
                        Row(
                          children: [
                            if (chinh != null) Expanded(flex: 3, child: chinh),
                            if (chinh != null && phu != null)
                              const SizedBox(width: QuanAnSpacing.sm),
                            if (phu != null) Expanded(flex: 2, child: phu),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
