import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/image_gallery.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/lich_gio_mo_cua_editor.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'chon_vi_tri_quan_screen.dart';

/// Khung form nhiều bước của chủ quán: thanh tiến trình "Bước 2/5", quay lại không mất
/// dữ liệu, khung lỗi đỏ CỐ ĐỊNH ngay trên nút Tiếp (không phải cuộn mới thấy).
class QuanAnFormNhieuBuoc extends StatelessWidget {
  const QuanAnFormNhieuBuoc({
    required this.tieuDe,
    required this.buoc,
    required this.tenBuoc,
    required this.noiDung,
    required this.onQuayLai,
    required this.onTiep,
    this.nutCuoi,
    this.dangLuu = false,
    this.loi = const [],
    super.key,
  });

  final String tieuDe;
  final int buoc;
  final List<String> tenBuoc;
  final Widget noiDung;
  final VoidCallback? onQuayLai;
  final VoidCallback? onTiep;

  /// Nút ở bước cuối (thay cho "Tiếp"), ví dụ "Gửi duyệt".
  final Widget? nutCuoi;
  final bool dangLuu;

  /// Lỗi của bước hiện tại, hiện ngay trên nút Tiếp.
  final List<String> loi;

  @override
  Widget build(BuildContext context) {
    final cuoi = buoc == tenBuoc.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(tieuDe)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuanAnSpacing.screen,
              QuanAnSpacing.sm,
              QuanAnSpacing.screen,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bước ${buoc + 1}/${tenBuoc.length} · ${tenBuoc[buoc]}',
                  style: QuanAnText.label,
                ),
                const SizedBox(height: QuanAnSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(QuanAnRadius.pill),
                  child: LinearProgressIndicator(
                    value: (buoc + 1) / tenBuoc.length,
                    minHeight: 6,
                    backgroundColor: QuanAnColors.primarySoft,
                    color: QuanAnColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(QuanAnSpacing.screen),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: noiDung,
                ),
              ),
            ),
          ),
          KhungLoiDo(loi),
          Container(
            decoration: BoxDecoration(
              color: QuanAnColors.white,
              boxShadow: QuanAnTheme.softShadow,
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.all(QuanAnSpacing.screen),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (onQuayLai != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: dangLuu ? null : onQuayLai,
                              child: const Text('Quay lại'),
                            ),
                          ),
                        if (onQuayLai != null)
                          const SizedBox(width: QuanAnSpacing.md),
                        Expanded(
                          child: cuoi && nutCuoi != null
                              ? nutCuoi!
                              : FilledButton(
                                  onPressed: dangLuu ? null : onTiep,
                                  child: Text(dangLuu ? 'Đang lưu...' : 'Tiếp'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// QA-CQ-01 Đăng quán (5 phần), tự lưu nháp. Mở cả để sửa bản nháp / quán bị từ chối.
///
/// Ảnh mặt tiền dùng chung form này qua [QuanAnMediaField] (đồ án: dán link hoặc tải lên;
/// chụp trong app có GPS sẽ bổ sung khi có máy Android thật), nên không có màn
/// `chup_mat_tien_screen.dart` riêng (QA-CQ-02).
class DangQuanScreen extends StatefulWidget {
  const DangQuanScreen({required this.dv, this.quan, super.key});

  final QuanAnDichVu dv;

  /// Bản nháp / quán bị từ chối cần sửa; null = đăng quán mới.
  final QuanAn? quan;

  @override
  State<DangQuanScreen> createState() => _DangQuanScreenState();
}

class _DangQuanScreenState extends State<DangQuanScreen> {
  static const _ten = [
    'Thông tin chung',
    'Vị trí và giờ mở cửa',
    'Tiện ích và phục vụ',
    'Ảnh',
    'Giấy tờ và gửi',
  ];

  int _buoc = 0;
  String? _id;
  bool _dangLuu = false;
  List<String> _loi = const [];
  QuanAnConfig _cfg = const QuanAnConfig();
  XacThuc _xt = const XacThuc();
  StreamSubscription<XacThuc>? _xtSub;
  Future<void> _luuTruoc = Future.value();

  final _tenQuan = TextEditingController();
  final _moTa = TextEditingController();
  final _sdt = TextEditingController();
  final _diaChi = TextEditingController();
  final _phuong = TextEditingController();
  final _ghiChuViTri = TextEditingController();
  final _mst = TextEditingController();

  String? _loaiQuan;
  final _loaiMon = <String>{};
  GeoPoint? _viTri;
  bool _luuDong = false;
  LichMoCua _lich = {};
  bool _anTaiQuan = true;
  bool _mangDi = false;
  final _tienIch = <String>{};
  bool _nhanDatBan = false;
  bool _nhanDatMon = false;
  bool _quanTuGiao = false;
  CaiDatDatMon _datMonGoc = const CaiDatDatMon();
  List<String> _anhMatTien = [];
  List<String> _anhKhac = [];
  List<String> _anhGiayChungNhan = [];
  List<String> _anhAttp = [];
  bool _camKet = false;

  bool get _laHoKinhDoanh => _loaiQuan == 'ho_kinh_doanh';

  /// Chỉ bản nháp / bị từ chối mới ghi thẳng được (quán đang hoạt động sửa ở màn "Sửa thông tin").
  bool get _ghiDuoc => widget.quan == null || widget.quan!.suaNhapDuoc;

  @override
  void initState() {
    super.initState();
    final q = widget.quan;
    if (q != null) {
      _id = q.id;
      _tenQuan.text = q.ten;
      _moTa.text = q.moTa;
      _sdt.text = q.sdt;
      _diaChi.text = q.diaChi;
      _phuong.text = q.phuong;
      _ghiChuViTri.text = q.ghiChuViTri;
      _loaiQuan = q.loaiQuan;
      _loaiMon.addAll(q.loaiMon);
      _viTri = q.viTri;
      _luuDong = q.luuDong;
      _lich = {
        for (final e in q.gioMoCua.entries) e.key: List<CaMoCua>.of(e.value),
      };
      _anTaiQuan = q.phucVu.anTaiQuan;
      _mangDi = q.phucVu.mangDi;
      _tienIch.addAll(q.tienIch);
      _nhanDatBan = q.nhanDatBan;
      _datMonGoc = q.datMon;
      _nhanDatMon = q.datMon.bat;
      _quanTuGiao = q.datMon.giaoTanNoi;
      _anhMatTien = [...q.anhMatTien];
      _anhKhac = [...q.anhKhac];
      _camKet = q.camKet;
      if (q.laHoKinhDoanh) {
        widget.dv.quan
            .layGiayTo(q.id)
            .then((g) {
              if (!mounted) return;
              setState(() {
                _mst.text = g.maSoThue;
                _anhGiayChungNhan = [...g.anhGiayChungNhan];
                _anhAttp = [...g.anhAttp];
              });
            })
            .catchError((_) {});
      }
    }
    _xtSub = widget.dv.xacThuc.cuaToi(widget.dv.uid).listen((x) {
      if (mounted) setState(() => _xt = x);
    }, onError: (_) {});
    widget.dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _xtSub?.cancel();
    for (final c in [
      _tenQuan,
      _moTa,
      _sdt,
      _diaChi,
      _phuong,
      _ghiChuViTri,
      _mst,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Dữ liệu ----

  CaiDatDatMon get _datMon {
    if (!_laHoKinhDoanh) return const CaiDatDatMon();
    var d = _datMonGoc.copyWith(bat: _nhanDatMon, giaoTanNoi: _quanTuGiao);
    // Bật đặt món mà chưa chọn cách nhận nào thì mặc định "Đến lấy" (chỉnh tiếp ở Cài đặt đặt món).
    if (d.bat && !d.coCachNhan) d = d.copyWith(denLay: true);
    return d;
  }

  Map<String, dynamic> _duLieu() => {
    'ten': _tenQuan.text.trim(),
    'loaiQuan': ?_loaiQuan,
    'loaiMon': _loaiMon.toList(),
    'moTa': _moTa.text.trim(),
    'sdt': _sdt.text.replaceAll(RegExp(r'\s'), ''),
    'diaChi': _diaChi.text.trim(),
    'phuong': _phuong.text.trim(),
    'viTri': ?_viTri,
    'luuDong': _luuDong,
    'ghiChuViTri': _luuDong ? _ghiChuViTri.text.trim() : '',
    'gioMoCua': lichToMap(_lich),
    'phucVu': PhucVu(anTaiQuan: _anTaiQuan, mangDi: _mangDi).toMap(),
    'tienIch': _tienIch.toList(),
    'nhanDatBan': _laHoKinhDoanh && _nhanDatBan,
    'datMon': _datMon.toMap(),
    'anhMatTien': _anhMatTien,
    'anhBia': _anhMatTien.isEmpty ? '' : _anhMatTien.first,
    'anhKhac': _anhKhac,
    'camKet': _camKet,
  };

  GiayToQuan get _giayTo => GiayToQuan(
    maSoThue: _mst.text.trim(),
    anhGiayChungNhan: _anhGiayChungNhan,
    anhAttp: _anhAttp,
  );

  bool get _coGiayTo =>
      _laHoKinhDoanh &&
      (_mst.text.trim().isNotEmpty ||
          _anhGiayChungNhan.isNotEmpty ||
          _anhAttp.isNotEmpty);

  /// Ghi bản nháp (và giấy tờ). Các lần lưu nối đuôi nhau để không tạo trùng quán.
  Future<void> _luuNhap() {
    if (!_ghiDuoc) return Future.value();
    final du = _duLieu();
    final giay = _coGiayTo ? _giayTo : null;
    final truoc = _luuTruoc;
    final f = () async {
      try {
        await truoc;
      } catch (_) {}
      _id = await widget.dv.quan.luuNhapQuan(_id, du);
      if (giay != null) await widget.dv.quan.luuGiayTo(_id!, giay);
    }();
    _luuTruoc = f;
    return f;
  }

  // ---- Kiểm tra ----

  static final _reSdt = RegExp(r'^0\d{9}$');
  static final _reMst = RegExp(r'^\d{10,13}$');

  List<String> _kiemTra(int b) {
    final l = <String>[];
    final c = _cfg;
    if (b == 0) {
      final t = _tenQuan.text.trim().length;
      if (t < c.tenQuanToiThieu || t > c.tenQuanToiDa) {
        l.add('Tên quán ${c.tenQuanToiThieu}–${c.tenQuanToiDa} ký tự.');
      }
      if (_loaiQuan == null) l.add('Chọn loại quán.');
      if (_loaiMon.isEmpty || _loaiMon.length > 3) {
        l.add('Chọn 1–3 loại món chính.');
      }
      if (!_reSdt.hasMatch(_sdt.text.replaceAll(RegExp(r'\s'), ''))) {
        l.add('Số điện thoại quán gồm 10 chữ số, bắt đầu bằng 0.');
      }
    } else if (b == 1) {
      if (_diaChi.text.trim().length < 5) l.add('Nhập địa chỉ đầy đủ.');
      if (_viTri == null) l.add('Ghim vị trí quán trên bản đồ.');
      if (_luuDong && _ghiChuViTri.text.trim().isEmpty) {
        l.add('Ghi chú chỗ bán thường xuyên (ví dụ: Đầu hẻm 51).');
      }
      l.addAll(LichGioMoCuaEditor.kiemTra(_lich, toiDaCa: c.caMoCuaToiDa));
    } else if (b == 2) {
      if (!_anTaiQuan && !_mangDi) {
        l.add('Chọn ít nhất một hình thức phục vụ (ăn tại quán hoặc mang đi).');
      }
    } else if (b == 3) {
      if (_anhMatTien.length < c.anhMatTienToiThieu ||
          _anhMatTien.length > c.anhMatTienToiDa) {
        l.add('Cần ${c.anhMatTienToiThieu}–${c.anhMatTienToiDa} ảnh mặt tiền.');
      }
      if (_anhKhac.length > c.anhKhacToiDa) {
        l.add('Ảnh khác tối đa ${c.anhKhacToiDa} ảnh.');
      }
    } else if (b == 4) {
      if (_laHoKinhDoanh) {
        if (!_reMst.hasMatch(_mst.text.trim())) {
          l.add('Mã số thuế gồm 10–13 chữ số.');
        }
        if (_anhGiayChungNhan.isEmpty) {
          l.add('Thêm ảnh giấy chứng nhận đăng ký hộ kinh doanh.');
        }
      }
      if (!_camKet) l.add('Tick cam kết thông tin đúng sự thật.');
    }
    return l;
  }

  // ---- Hành động ----

  Future<void> _tiep() async {
    final l = _kiemTra(_buoc);
    setState(() => _loi = l);
    if (l.isNotEmpty) return;
    setState(() => _dangLuu = true);
    final ok = await chayThaoTac(context, _luuNhap);
    if (!mounted) return;
    setState(() {
      _dangLuu = false;
      if (ok) _buoc++;
    });
  }

  Future<void> _guiDuyet() async {
    final l = [for (var b = 0; b < _ten.length; b++) ..._kiemTra(b)];
    setState(() => _loi = l);
    if (l.isNotEmpty) return;
    setState(() => _dangLuu = true);
    final ok = await chayThaoTac(context, () async {
      await _luuNhap();
      await widget.dv.quan.thaoTac('guiDuyetQuan', {'quanId': _id});
    }, thanhCong: 'Đã gửi duyệt quán');
    if (!mounted) return;
    setState(() => _dangLuu = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _ghim() async {
    final g = await QuanAnDieuHuong.mo<GeoPoint>(
      context,
      (_) => ChonViTriQuanScreen(
        banDau: _viTri,
        tieuDe: 'Ghim vị trí quán',
        goiY: _luuDong ? 'Ghim chỗ bán thường xuyên' : 'Ghim đúng cửa quán',
      ),
    );
    if (g != null && mounted) setState(() => _viTri = g);
  }

  void _datAnhBia(String url) => setState(() {
    _anhMatTien = [url, ..._anhMatTien.where((x) => x != url)];
  });

  // ---- Giao diện ----

  @override
  Widget build(BuildContext context) {
    final q = widget.quan;
    return PopScope(
      onPopInvokedWithResult: (daPop, _) {
        // Thoát giữa chừng vẫn giữ dữ liệu đã nhập dưới dạng bản nháp.
        if (daPop && (_buoc > 0 || _tenQuan.text.trim().isNotEmpty)) {
          _luuNhap().catchError((_) {});
        }
      },
      child: QuanAnFormNhieuBuoc(
        tieuDe: q == null
            ? 'Đăng quán'
            : (q.trangThai == 'rejected'
                  ? 'Sửa quán bị từ chối'
                  : 'Sửa bản nháp'),
        buoc: _buoc,
        tenBuoc: _ten,
        dangLuu: _dangLuu,
        loi: _loi,
        onQuayLai: _buoc == 0
            ? null
            : () => setState(() {
                _buoc--;
                _loi = const [];
              }),
        onTiep: _tiep,
        nutCuoi: _nutGui(),
        noiDung: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (q?.trangThai == 'rejected' && q?.lyDoTuChoi != null)
              Padding(
                padding: const EdgeInsets.only(bottom: QuanAnSpacing.md),
                child: QuanAnWarningBox(
                  message: 'Bị từ chối: ${q!.lyDoTuChoi}. Sửa rồi gửi lại.',
                ),
              ),
            if (!_ghiDuoc)
              const Padding(
                padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                child: HopThongBao.canhBao(
                  noiDung: 'Quán này không còn là bản nháp. Hãy sửa ở mục "Sửa thông tin" trong trang quản lý quán.',
                ),
              ),
            ...switch (_buoc) {
              0 => _buoc0(),
              1 => _buoc1(),
              2 => _buoc2(),
              3 => _buoc3(),
              _ => _buoc4(),
            },
            const SizedBox(height: QuanAnSpacing.md),
            Text(
              'Bản nháp tự lưu khi bấm Tiếp hoặc khi thoát; quay lại không mất dữ liệu.',
              style: QuanAnText.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  bool get _duocGui => _xt.daOtp && _xt.daXacThucDanhTinh;

  String? get _lyDoChuaGui {
    if (!_xt.daOtp) {
      return 'Cần xác thực số điện thoại (OTP) trước khi gửi duyệt.';
    }
    if (!_xt.daXacThucDanhTinh) {
      return 'Cần xác nhận người thật trước khi gửi duyệt '
          '(${XacThuc.danhTinhLabels[_xt.danhTinh]}). Bạn vẫn lưu nháp được.';
    }
    return null;
  }

  Widget _nutGui() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_lyDoChuaGui != null)
        Padding(
          padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
          child: Text(
            _lyDoChuaGui!,
            style: QuanAnText.bodySmall.copyWith(color: QuanAnColors.warning),
          ),
        ),
      FilledButton(
        onPressed: _dangLuu || !_duocGui || !_ghiDuoc ? null : _guiDuyet,
        child: Text(_dangLuu ? 'Đang gửi...' : 'Gửi duyệt'),
      ),
    ],
  );

  Widget _khoang([double h = QuanAnSpacing.md]) => SizedBox(height: h);

  List<Widget> _buoc0() => [
    TextField(
      controller: _tenQuan,
      maxLength: _cfg.tenQuanToiDa,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText:
            'Tên quán (${_cfg.tenQuanToiThieu}–${_cfg.tenQuanToiDa} ký tự)',
      ),
    ),
    _khoang(),
    const Text('Loại quán', style: QuanAnText.label),
    const SizedBox(height: QuanAnSpacing.xs),
    const Text(
      'Chọn đúng thực tế. Khai sai loại quán sẽ bị admin yêu cầu chuyển loại hoặc ẩn quán.',
      style: QuanAnText.bodySmall,
    ),
    const SizedBox(height: QuanAnSpacing.sm),
    _TheChonLoai(
      chon: _loaiQuan == 'ho_kinh_doanh',
      tieuDe: 'Hộ kinh doanh',
      ghiChu:
          'Quán có mặt bằng, có đăng ký kinh doanh (quán cơm, quán phở...). '
          'Cần mã số thuế và ảnh giấy chứng nhận.',
      quyenLoi: const [
        'Nhận đặt món và thanh toán qua app, nhận đặt bàn',
        'Tối đa 5 khuyến mãi, tự trừ vào đơn',
        'Huy hiệu "Đã xác thực kinh doanh"',
      ],
      onTap: () => setState(() => _loaiQuan = 'ho_kinh_doanh'),
    ),
    const SizedBox(height: QuanAnSpacing.sm),
    _TheChonLoai(
      chon: _loaiQuan == 'ban_le',
      tieuDe: 'Bán lẻ / vỉa hè',
      ghiChu: 'Xe đẩy, gánh hàng, quán vỉa hè, bán tại nhà. Không cần giấy tờ.',
      quyenLoi: const [
        'Hiện trên danh sách, bản đồ; có menu, đánh giá, check-in',
        'Không nhận đặt món / đặt bàn qua app',
        'Tối đa 1 khuyến mãi, chỉ hiển thị (không tự trừ)',
        'Huy hiệu "Đã xác thực chủ quán"; sau này có giấy tờ thì nâng cấp được',
      ],
      onTap: () => setState(() => _loaiQuan = 'ban_le'),
    ),
    _khoang(QuanAnSpacing.lg),
    Text(
      'Loại món chính (chọn 1–3) · đã chọn ${_loaiMon.length}',
      style: QuanAnText.label,
    ),
    const SizedBox(height: QuanAnSpacing.sm),
    Wrap(
      spacing: QuanAnSpacing.sm,
      runSpacing: QuanAnSpacing.xs,
      children: [
        for (final e in loaiMonLabels.entries)
          FilterChip(
            label: Text(e.value),
            selected: _loaiMon.contains(e.key),
            onSelected: (on) => setState(() {
              if (on) {
                if (_loaiMon.length < 3) _loaiMon.add(e.key);
              } else {
                _loaiMon.remove(e.key);
              }
            }),
          ),
      ],
    ),
    _khoang(QuanAnSpacing.lg),
    TextField(
      controller: _moTa,
      maxLines: 4,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Mô tả quán',
        helperText:
            'Món đặc trưng, không khí, giờ đông khách... (không bắt buộc)',
      ),
    ),
    _khoang(),
    TextField(
      controller: _sdt,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
      decoration: const InputDecoration(
        labelText: 'Số điện thoại quán',
        helperText: 'Khách đã đăng nhập mới thấy số này',
      ),
    ),
  ];

  List<Widget> _buoc1() => [
    TextField(
      controller: _diaChi,
      decoration: const InputDecoration(
        labelText: 'Địa chỉ đầy đủ (số nhà, đường)',
      ),
    ),
    _khoang(),
    TextField(
      controller: _phuong,
      decoration: const InputDecoration(labelText: 'Phường / xã'),
    ),
    _khoang(),
    OutlinedButton.icon(
      onPressed: _ghim,
      icon: const Icon(Icons.place_outlined),
      label: Text(
        _viTri == null
            ? 'Ghim vị trí trên bản đồ'
            : 'Đã ghim (${_viTri!.latitude.toStringAsFixed(5)}, ${_viTri!.longitude.toStringAsFixed(5)}), bấm để đổi',
      ),
    ),
    _khoang(QuanAnSpacing.sm),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _luuDong,
      onChanged: (v) => setState(() => _luuDong = v),
      title: const Text('Bán lưu động'),
      subtitle: const Text('Xe đẩy không đứng cố định một chỗ'),
    ),
    if (_luuDong) ...[
      TextField(
        controller: _ghiChuViTri,
        decoration: const InputDecoration(
          labelText: 'Ghi chú chỗ bán thường xuyên',
          helperText: 'Ví dụ: Đầu hẻm 51. Ghim ở trên là chỗ bán thường xuyên.',
        ),
      ),
      const SizedBox(height: QuanAnSpacing.sm),
      const Text(
        'Đổi chỗ bán thường xuyên thì phải chụp lại ảnh mặt tiền và chờ duyệt lại.',
        style: QuanAnText.bodySmall,
      ),
    ],
    _khoang(QuanAnSpacing.lg),
    const Text('Giờ mở cửa từng ngày', style: QuanAnText.h3),
    const SizedBox(height: QuanAnSpacing.xs),
    Text(
      'Mỗi ngày tối đa ${_cfg.caMoCuaToiDa} ca hoặc nghỉ.',
      style: QuanAnText.bodySmall,
    ),
    _khoang(QuanAnSpacing.sm),
    LichGioMoCuaEditor(
      lich: _lich,
      toiDaCa: _cfg.caMoCuaToiDa,
      onChanged: (v) => setState(() => _lich = v),
    ),
  ];

  List<Widget> _buoc2() => [
    const Text('Hình thức phục vụ (chọn ít nhất 1)', style: QuanAnText.h3),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _anTaiQuan,
      onChanged: (v) => setState(() => _anTaiQuan = v ?? false),
      title: const Text('Ăn tại quán'),
    ),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _mangDi,
      onChanged: (v) => setState(() => _mangDi = v ?? false),
      title: const Text('Mang đi'),
    ),
    _khoang(),
    const Text('Tiện ích', style: QuanAnText.h3),
    const SizedBox(height: QuanAnSpacing.sm),
    Wrap(
      spacing: QuanAnSpacing.sm,
      runSpacing: QuanAnSpacing.xs,
      children: [
        for (final e in tienIchLabels.entries)
          FilterChip(
            label: Text(e.value),
            selected: _tienIch.contains(e.key),
            onSelected: (on) => setState(
              () => on ? _tienIch.add(e.key) : _tienIch.remove(e.key),
            ),
          ),
      ],
    ),
    if (_laHoKinhDoanh) ...[
      _khoang(QuanAnSpacing.lg),
      const Text('Dịch vụ qua app (hộ kinh doanh)', style: QuanAnText.h3),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _nhanDatBan,
        onChanged: (v) => setState(() => _nhanDatBan = v),
        title: const Text('Nhận đặt bàn'),
        subtitle: const Text('Khách đặt bàn trước, không thu tiền'),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _nhanDatMon,
        onChanged: (v) => setState(() => _nhanDatMon = v),
        title: const Text('Nhận đặt món qua app'),
        subtitle: const Text('Thanh toán qua app hoặc tiền mặt khi nhận'),
      ),
      if (_nhanDatMon)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _quanTuGiao,
          onChanged: (v) => setState(() => _quanTuGiao = v),
          title: const Text('Quán tự giao'),
          subtitle: const Text(
            'Bán kính, phí giao, đơn tối thiểu cài sau trong "Cài đặt đặt món"',
          ),
        ),
    ] else if (_loaiQuan == null)
      const Padding(
        padding: EdgeInsets.only(top: QuanAnSpacing.lg),
        child: Text(
          'Chọn loại quán ở phần 1 để xem các dịch vụ có thể bật.',
          style: QuanAnText.bodySmall,
        ),
      ),
  ];

  List<Widget> _buoc3() => [
    QuanAnMediaField(
      storage: widget.dv.storage,
      folder: 'quan_an_mat_tien',
      nhan: 'Ảnh mặt tiền',
      goiY:
          'Ảnh đầu tiên là ảnh bìa. Đồ án: dán link hoặc tải ảnh lên; chụp '
          'trong app có GPS sẽ bổ sung khi có máy Android thật.',
      toiThieu: _cfg.anhMatTienToiThieu,
      toiDa: _cfg.anhMatTienToiDa,
      giaTri: _anhMatTien,
      anhBia: _anhMatTien.isEmpty ? '' : _anhMatTien.first,
      onChanged: (v) => setState(() => _anhMatTien = v),
      onChonAnhBia: _datAnhBia,
      pickImages: widget.dv.pickImages,
    ),
    _khoang(QuanAnSpacing.xl),
    QuanAnMediaField(
      storage: widget.dv.storage,
      folder: 'quan_an_anh',
      nhan: 'Ảnh khác (không gian, món ăn)',
      goiY: 'Không bắt buộc. Chỉ hiện ở trang chi tiết quán.',
      toiDa: _cfg.anhKhacToiDa,
      giaTri: _anhKhac,
      onChanged: (v) => setState(() => _anhKhac = v),
      pickImages: widget.dv.pickImages,
    ),
  ];

  List<Widget> _buoc4() => [
    if (_laHoKinhDoanh) ...[
      TextField(
        controller: _mst,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 13,
        decoration: const InputDecoration(
          labelText: 'Mã số thuế',
          helperText: 'Admin tra cứu mã số thuế để đối chiếu',
        ),
      ),
      _khoang(),
      QuanAnMediaField(
        storage: widget.dv.storage,
        folder: 'quan_an_rieng',
        nhan: 'Ảnh giấy chứng nhận đăng ký hộ kinh doanh',
        goiY: 'Chỉ chủ quán và admin xem được.',
        toiThieu: 1,
        toiDa: 4,
        giaTri: _anhGiayChungNhan,
        onChanged: (v) => setState(() => _anhGiayChungNhan = v),
        pickImages: widget.dv.pickImages,
      ),
      _khoang(QuanAnSpacing.lg),
      QuanAnMediaField(
        storage: widget.dv.storage,
        folder: 'quan_an_rieng',
        nhan: 'Giấy an toàn thực phẩm (không bắt buộc)',
        toiDa: 4,
        giaTri: _anhAttp,
        onChanged: (v) => setState(() => _anhAttp = v),
        pickImages: widget.dv.pickImages,
      ),
    ] else
      const HopThongBao(
        noiDung:
            'Quán bán lẻ / vỉa hè không cần giấy tờ. Sau này có giấy tờ thì '
            'nâng cấp lên hộ kinh doanh trong trang quản lý.',
      ),
    _khoang(QuanAnSpacing.md),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _camKet,
      onChanged: (v) => setState(() => _camKet = v ?? false),
      title: const Text(
        'Tôi cam kết thông tin về quán và loại quán là đúng sự thật.',
      ),
    ),
    _khoang(),
    const Text('Xem trước', style: QuanAnText.h3),
    const SizedBox(height: QuanAnSpacing.sm),
    _XemTruoc(
      anhBia: _anhMatTien.isEmpty ? null : _anhMatTien.first,
      ten: _tenQuan.text.trim(),
      loaiQuan: _loaiQuan,
      loaiMon: _loaiMon.map((m) => loaiMonLabels[m] ?? m).join(' · '),
      diaChi: _diaChi.text.trim(),
      luuDong: _luuDong,
      lich: _lich,
      phucVu: [
        if (_anTaiQuan) 'Ăn tại quán',
        if (_mangDi) 'Mang đi',
      ].join(' · '),
      soAnhKhac: _anhKhac.length,
      dichVu: [
        if (_laHoKinhDoanh && _nhanDatBan) 'Đặt bàn',
        if (_laHoKinhDoanh && _nhanDatMon) 'Đặt món qua app',
        if (_laHoKinhDoanh && _nhanDatMon && _quanTuGiao) 'Quán tự giao',
      ].join(' · '),
    ),
    _khoang(),
    ..._canhBaoXacThuc(),
  ];

  /// Cảnh báo xác thực (như Tìm trọ): chưa OTP hoặc chưa xác nhận người thật thì chỉ lưu nháp được.
  List<Widget> _canhBaoXacThuc() {
    if (_duocGui) return const [];
    final chuaOtp = !_xt.daOtp;
    return [
      HopThongBao.canhBao(
        noiDung: chuaOtp
            ? 'Cần xác thực số điện thoại trước khi gửi duyệt.'
            : 'Chưa xác nhận người thật: ${XacThuc.danhTinhLabels[_xt.danhTinh]}. Bạn vẫn lưu nháp được.',
        child: chuaOtp || _xt.danhTinh != 'cho_duyet'
            ? Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => QuanAnDieuHuong.mo(
                    context,
                    (_) => chuaOtp
                        ? XacThucSdtScreen(service: widget.dv.xacThuc)
                        : XacNhanDanhTinhScreen(service: widget.dv.xacThuc),
                  ),
                  child: Text(
                    chuaOtp ? 'Xác thực số điện thoại' : 'Xác nhận người thật',
                  ),
                ),
              )
            : null,
      ),
    ];
  }
}

/// Thẻ chọn loại quán (chọn một trong hai), có giải thích quyền lợi.
class _TheChonLoai extends StatelessWidget {
  const _TheChonLoai({
    required this.chon,
    required this.tieuDe,
    required this.ghiChu,
    required this.quyenLoi,
    required this.onTap,
  });

  final bool chon;
  final String tieuDe;
  final String ghiChu;
  final List<String> quyenLoi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: chon,
    label: tieuDe,
    child: Material(
      color: chon ? QuanAnColors.primaryLight : QuanAnColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        side: BorderSide(
          color: chon ? QuanAnColors.primary : QuanAnColors.border,
          width: chon ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(QuanAnRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                chon
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: chon ? QuanAnColors.primary : QuanAnColors.textSecondary,
              ),
              const SizedBox(width: QuanAnSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tieuDe, style: QuanAnText.h3),
                    const SizedBox(height: QuanAnSpacing.xs),
                    Text(ghiChu, style: QuanAnText.bodySmall),
                    const SizedBox(height: QuanAnSpacing.xs),
                    for (final q in quyenLoi)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• $q', style: QuanAnText.bodySmall),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _XemTruoc extends StatelessWidget {
  const _XemTruoc({
    required this.anhBia,
    required this.ten,
    required this.loaiQuan,
    required this.loaiMon,
    required this.diaChi,
    required this.luuDong,
    required this.lich,
    required this.phucVu,
    required this.soAnhKhac,
    required this.dichVu,
  });

  final String? anhBia;
  final String ten;
  final String? loaiQuan;
  final String loaiMon;
  final String diaChi;
  final bool luuDong;
  final LichMoCua lich;
  final String phucVu;
  final int soAnhKhac;
  final String dichVu;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: anhBia == null
              ? const ColoredBox(
                  color: QuanAnColors.primaryLight,
                  child: Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: QuanAnColors.primary,
                    ),
                  ),
                )
              : NetworkPhoto(anhBia!),
        ),
        Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ten.isEmpty ? '(Chưa đặt tên)' : ten, style: QuanAnText.h2),
              const SizedBox(height: QuanAnSpacing.xs),
              if (loaiQuan != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.xacThuc,
                    label: loaiQuanLabels[loaiQuan] ?? loaiQuan!,
                  ),
                ),
              const SizedBox(height: QuanAnSpacing.sm),
              if (loaiMon.isNotEmpty)
                Text('Món chính: $loaiMon', style: QuanAnText.body),
              Text(
                '${luuDong ? 'Bán lưu động · ' : ''}$diaChi',
                style: QuanAnText.bodySmall,
              ),
              if (phucVu.isNotEmpty)
                Text('Phục vụ: $phucVu', style: QuanAnText.bodySmall),
              if (dichVu.isNotEmpty)
                Text('Dịch vụ: $dichVu', style: QuanAnText.bodySmall),
              Text('$soAnhKhac ảnh khác', style: QuanAnText.bodySmall),
              const SizedBox(height: QuanAnSpacing.sm),
              const Text('Giờ mở cửa', style: QuanAnText.label),
              for (var d = 1; d <= 7; d++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(tenThu(d), style: QuanAnText.bodySmall),
                    ),
                    Expanded(
                      child: Text(
                        tomTatNgay(lich[d]),
                        style: QuanAnText.bodySmall,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
