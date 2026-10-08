import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/services/xac_thuc_service.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'chon_vi_tri_quan_screen.dart';

/// QA-CQ-09 Sửa thông tin quán (mục 3.3 Bước 6).
/// - Hiện ngay: mô tả, số điện thoại, loại món, tiện ích, hình thức phục vụ, ảnh khác, nhận đặt bàn.
/// - Tạo bản chỉnh sửa chờ duyệt (bản cũ vẫn hiện): tên, địa chỉ, vị trí ghim, ảnh mặt tiền,
///   bán lưu động, ghi chú chỗ bán.
/// - Quán bán lẻ có thể nâng cấp lên hộ kinh doanh (mã số thuế + ảnh giấy chứng nhận).
class SuaThongTinQuanScreen extends StatefulWidget {
  const SuaThongTinQuanScreen({
    required this.dv,
    required this.quan,
    super.key,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<SuaThongTinQuanScreen> createState() => _SuaThongTinQuanScreenState();
}

class _SuaThongTinQuanScreenState extends State<SuaThongTinQuanScreen> {
  static final _reSdt = RegExp(r'^0\d{9}$');
  static final _reMst = RegExp(r'^\d{10,13}$');

  QuanAnConfig _cfg = const QuanAnConfig();
  late final _moTa = TextEditingController(text: widget.quan.moTa);
  late final _sdt = TextEditingController(text: widget.quan.sdt);
  late final _ten = TextEditingController(text: widget.quan.ten);
  late final _diaChi = TextEditingController(text: widget.quan.diaChi);
  late final _phuong = TextEditingController(text: widget.quan.phuong);
  late final _ghiChuViTri = TextEditingController(
    text: widget.quan.ghiChuViTri,
  );
  final _mst = TextEditingController();

  late final Set<String> _loaiMon = {...widget.quan.loaiMon};
  late final Set<String> _tienIch = {...widget.quan.tienIch};
  late bool _anTaiQuan = widget.quan.phucVu.anTaiQuan;
  late bool _mangDi = widget.quan.phucVu.mangDi;
  late bool _nhanDatBan = widget.quan.nhanDatBan;
  late List<String> _anhKhac = [...widget.quan.anhKhac];
  late List<String> _anhMatTien = [...widget.quan.anhMatTien];
  late GeoPoint? _viTri = widget.quan.viTri;
  late bool _luuDong = widget.quan.luuDong;
  List<String> _anhGiayChungNhan = [];

  List<String> _loi = const [];
  List<String> _loiNangCap = const [];
  bool _dangLuu = false;
  bool _dangNangCap = false;

  QuanAn get _q => widget.quan;

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
  void dispose() {
    for (final c in [_moTa, _sdt, _ten, _diaChi, _phuong, _ghiChuViTri, _mst]) {
      c.dispose();
    }
    super.dispose();
  }

  String _loiChu(Object e) =>
      e is ApiException ? e.message : 'Có lỗi xảy ra, vui lòng thử lại.';

  String get _sdtSach => _sdt.text.replaceAll(RegExp(r'\s'), '');

  bool _khacDs(Iterable<String> a, Iterable<String> b) {
    final x = {...a};
    final y = {...b};
    return x.length != y.length || !x.containsAll(y);
  }

  bool get _doiViTri =>
      (_viTri?.latitude != _q.viTri?.latitude) ||
      (_viTri?.longitude != _q.viTri?.longitude);

  /// Các trường chờ duyệt đã thay đổi so với bản đang hiện.
  Map<String, dynamic> get _truongChoDuyet => {
    if (_ten.text.trim() != _q.ten) 'ten': _ten.text.trim(),
    if (_diaChi.text.trim() != _q.diaChi) 'diaChi': _diaChi.text.trim(),
    if (_phuong.text.trim() != _q.phuong) 'phuong': _phuong.text.trim(),
    if (_doiViTri && _viTri != null)
      'viTri': {'lat': _viTri!.latitude, 'lng': _viTri!.longitude},
    if (_anhMatTien.join('|') != _q.anhMatTien.join('|'))
      'anhMatTien': _anhMatTien,
    if (_luuDong != _q.luuDong) 'luuDong': _luuDong,
    if ((_luuDong ? _ghiChuViTri.text.trim() : '') != _q.ghiChuViTri)
      'ghiChuViTri': _luuDong ? _ghiChuViTri.text.trim() : '',
  };

  /// Các trường hiện ngay đã thay đổi.
  Map<String, dynamic> get _truongHienNgay => {
    if (_moTa.text.trim() != _q.moTa) 'moTa': _moTa.text.trim(),
    if (_sdtSach != _q.sdt) 'sdt': _sdtSach,
    if (_khacDs(_loaiMon, _q.loaiMon)) 'loaiMon': _loaiMon.toList(),
    if (_khacDs(_tienIch, _q.tienIch)) 'tienIch': _tienIch.toList(),
    if (_anTaiQuan != _q.phucVu.anTaiQuan || _mangDi != _q.phucVu.mangDi)
      'phucVu': PhucVu(anTaiQuan: _anTaiQuan, mangDi: _mangDi).toMap(),
    if (_anhKhac.join('|') != _q.anhKhac.join('|')) 'anhKhac': _anhKhac,
    if (_q.laHoKinhDoanh && _nhanDatBan != _q.nhanDatBan)
      'nhanDatBan': _nhanDatBan,
  };

  List<String> _kiemTra() {
    final l = <String>[];
    final c = _cfg;
    final t = _ten.text.trim().length;
    if (t < c.tenQuanToiThieu || t > c.tenQuanToiDa) {
      l.add('Tên quán ${c.tenQuanToiThieu}–${c.tenQuanToiDa} ký tự.');
    }
    if (_loaiMon.isEmpty || _loaiMon.length > 3) {
      l.add('Chọn 1–3 loại món chính.');
    }
    if (!_reSdt.hasMatch(_sdtSach)) {
      l.add('Số điện thoại gồm 10 số, bắt đầu bằng 0.');
    }
    if (_diaChi.text.trim().isEmpty) l.add('Nhập địa chỉ quán.');
    if (_viTri == null) l.add('Ghim vị trí quán trên bản đồ.');
    if (!_anTaiQuan && !_mangDi) {
      l.add('Chọn ít nhất một hình thức phục vụ.');
    }
    if (_luuDong && _ghiChuViTri.text.trim().isEmpty) {
      l.add('Quán bán lưu động cần ghi chú chỗ bán thường xuyên.');
    }
    if (_anhMatTien.length < c.anhMatTienToiThieu ||
        _anhMatTien.length > c.anhMatTienToiDa) {
      l.add(
        'Ảnh mặt tiền từ ${c.anhMatTienToiThieu} đến ${c.anhMatTienToiDa} ảnh.',
      );
    }
    // Bán lưu động đổi chỗ bán thì phải chụp / đổi lại ảnh mặt tiền.
    final doiChoBan =
        _luuDong &&
        (_doiViTri ||
            (_q.luuDong && _ghiChuViTri.text.trim() != _q.ghiChuViTri));
    if (doiChoBan && _anhMatTien.join('|') == _q.anhMatTien.join('|')) {
      l.add('Đổi chỗ bán thì phải đổi ảnh mặt tiền ở chỗ mới.');
    }
    if (l.isEmpty && _truongHienNgay.isEmpty && _truongChoDuyet.isEmpty) {
      l.add('Chưa có thay đổi nào để lưu.');
    }
    return l;
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

  Future<void> _luu() async {
    final loi = _kiemTra();
    setState(() => _loi = loi);
    if (loi.isNotEmpty) return;
    final hienNgay = _truongHienNgay;
    final choDuyet = _truongChoDuyet;
    setState(() => _dangLuu = true);
    try {
      await widget.dv.quan.thaoTac('suaQuan', {
        'quanId': _q.id,
        ...hienNgay,
        ...choDuyet,
      });
      if (!mounted) return;
      final s = [
        if (hienNgay.isNotEmpty) 'Đã lưu, phần thông tin sửa hiện ngay.',
        if (choDuyet.isNotEmpty) 'Phần tên, địa chỉ, vị trí, ảnh mặt tiền đã gửi chờ duyệt, bản cũ vẫn hiện.',
      ].join(' ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _loi = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Future<void> _nangCap() async {
    final loi = <String>[
      if (!_reMst.hasMatch(_mst.text.trim())) 'Mã số thuế gồm 10–13 chữ số.',
      if (_anhGiayChungNhan.isEmpty) 'Thêm ít nhất 1 ảnh giấy chứng nhận.',
    ];
    setState(() => _loiNangCap = loi);
    if (loi.isNotEmpty) return;
    setState(() => _dangNangCap = true);
    try {
      await widget.dv.quan.thaoTac('nangCapLoaiQuan', {
        'quanId': _q.id,
        'maSoThue': _mst.text.trim(),
        'anhGiayChungNhan': _anhGiayChungNhan,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu nâng cấp, chờ admin duyệt. Quán vẫn hoạt động như cũ.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _loiNangCap = [_loiChu(e)]);
    } finally {
      if (mounted) setState(() => _dangNangCap = false);
    }
  }

  void _datAnhBia(String url) => setState(() {
    _anhMatTien = [url, ..._anhMatTien.where((x) => x != url)];
  });

  Widget _nhanKhoi(String nhan, IconData icon, Color nen, Color chu) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QuanAnSpacing.md,
          vertical: QuanAnSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: nen,
          borderRadius: BorderRadius.circular(QuanAnRadius.button),
        ),
        child: Row(
          children: [
            Icon(icon, color: chu, size: 20),
            const SizedBox(width: QuanAnSpacing.sm),
            Expanded(
              child: Text(
                nhan,
                style: QuanAnText.bodySmall.copyWith(
                  color: chu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final cfg = _cfg;
    final choNangCap = q.coBanChinhSua && q.banChinhSua!['loai'] == 'nang_cap';
    final choSua = q.coBanChinhSua && !choNangCap;
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa thông tin quán')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(QuanAnSpacing.screen),
              child: TrangRong(
                rongToiDa: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (choSua)
                      const Padding(
                        padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                        child: HopThongBao.canhBao(
                          noiDung: 'Đang có một bản chỉnh sửa chờ duyệt. Gửi bản chỉnh sửa mới sẽ thay bản đó; bản cũ vẫn hiện cho khách.',
                        ),
                      ),
                    KhoiThongTin(
                      tieuDe: 'Sửa là hiện ngay',
                      phu: 'Không cần duyệt. Khách thấy thay đổi ngay sau khi lưu.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _nhanKhoi(
                            'Hiện ngay',
                            Icons.bolt_rounded,
                            QuanAnColors.successSoft,
                            QuanAnColors.success,
                          ),
                          const SizedBox(height: QuanAnSpacing.md),
                          TextField(
                            controller: _moTa,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText: 'Mô tả quán',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.sm),
                          TextField(
                            controller: _sdt,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9 ]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại quán',
                              helperText: 'Khách đã đăng nhập mới thấy số này',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.lg),
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
                                      if (_loaiMon.length < 3) {
                                        _loaiMon.add(e.key);
                                      }
                                    } else {
                                      _loaiMon.remove(e.key);
                                    }
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: QuanAnSpacing.lg),
                          const Text(
                            'Hình thức phục vụ',
                            style: QuanAnText.label,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _anTaiQuan,
                            onChanged: (v) =>
                                setState(() => _anTaiQuan = v ?? false),
                            title: const Text('Ăn tại quán'),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _mangDi,
                            onChanged: (v) =>
                                setState(() => _mangDi = v ?? false),
                            title: const Text('Mang đi'),
                          ),
                          const SizedBox(height: QuanAnSpacing.md),
                          const Text('Tiện ích', style: QuanAnText.label),
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
                                    () => on
                                        ? _tienIch.add(e.key)
                                        : _tienIch.remove(e.key),
                                  ),
                                ),
                            ],
                          ),
                          if (q.laHoKinhDoanh)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _nhanDatBan,
                              onChanged: (v) => setState(() => _nhanDatBan = v),
                              title: const Text('Nhận đặt bàn'),
                              subtitle: const Text(
                                'Khách đặt bàn trước, không thu tiền',
                              ),
                            ),
                          const SizedBox(height: QuanAnSpacing.lg),
                          QuanAnMediaField(
                            storage: widget.dv.storage,
                            folder: 'quan_an_anh',
                            nhan: 'Ảnh khác (không gian, món ăn)',
                            goiY: 'Không bắt buộc. Chỉ hiện ở trang chi tiết quán.',
                            toiDa: cfg.anhKhacToiDa,
                            giaTri: _anhKhac,
                            onChanged: (v) => setState(() => _anhKhac = v),
                            pickImages: widget.dv.pickImages,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    KhoiThongTin(
                      tieuDe: 'Sửa cần admin duyệt',
                      phu: 'Tên, địa chỉ, vị trí ghim, ảnh mặt tiền: bản cũ vẫn hiện cho khách cho tới khi duyệt xong. Bị từ chối thì giữ bản cũ và bạn thấy lý do.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _nhanKhoi(
                            'Tạo bản chỉnh sửa chờ duyệt, bản cũ vẫn hiện',
                            Icons.hourglass_top_rounded,
                            QuanAnColors.warningSoft,
                            QuanAnColors.warning,
                          ),
                          const SizedBox(height: QuanAnSpacing.md),
                          TextField(
                            controller: _ten,
                            maxLength: cfg.tenQuanToiDa,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText:
                                  'Tên quán (${cfg.tenQuanToiThieu}–${cfg.tenQuanToiDa} ký tự)',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.sm),
                          TextField(
                            controller: _diaChi,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ đầy đủ (số nhà, đường)',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.md),
                          TextField(
                            controller: _phuong,
                            decoration: const InputDecoration(
                              labelText: 'Phường / xã',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _ghim,
                            icon: const Icon(Icons.place_outlined),
                            label: Text(
                              _viTri == null
                                  ? 'Ghim vị trí trên bản đồ'
                                  : 'Đã ghim (${_viTri!.latitude.toStringAsFixed(5)}, ${_viTri!.longitude.toStringAsFixed(5)}), bấm để đổi',
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _luuDong,
                            onChanged: (v) => setState(() => _luuDong = v),
                            title: const Text('Bán lưu động'),
                            subtitle: const Text(
                              'Xe đẩy không đứng cố định một chỗ',
                            ),
                          ),
                          if (_luuDong) ...[
                            TextField(
                              controller: _ghiChuViTri,
                              decoration: const InputDecoration(
                                labelText: 'Ghi chú chỗ bán thường xuyên',
                                helperText: 'Ví dụ: Đầu hẻm 51',
                              ),
                            ),
                            const SizedBox(height: QuanAnSpacing.sm),
                            const Text(
                              'Đổi chỗ bán thường xuyên thì phải đổi ảnh mặt tiền ở chỗ mới.',
                              style: QuanAnText.bodySmall,
                            ),
                          ],
                          const SizedBox(height: QuanAnSpacing.lg),
                          QuanAnMediaField(
                            storage: widget.dv.storage,
                            folder: 'quan_an_anh',
                            nhan: 'Ảnh mặt tiền',
                            goiY: 'Ảnh đầu tiên là ảnh bìa.',
                            toiThieu: cfg.anhMatTienToiThieu,
                            toiDa: cfg.anhMatTienToiDa,
                            giaTri: _anhMatTien,
                            anhBia: _anhMatTien.isEmpty
                                ? ''
                                : _anhMatTien.first,
                            onChanged: (v) => setState(() => _anhMatTien = v),
                            onChonAnhBia: _datAnhBia,
                            pickImages: widget.dv.pickImages,
                          ),
                        ],
                      ),
                    ),
                    if (!q.laHoKinhDoanh) ...[
                      const SizedBox(height: QuanAnSpacing.cardGap),
                      _khoiNangCap(choNangCap),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ThanhDuoiForm(
            loi: _loi,
            child: FilledButton(
              onPressed: _dangLuu ? null : _luu,
              child: Text(_dangLuu ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _khoiNangCap(bool dangCho) => KhoiThongTin(
    tieuDe: 'Nâng cấp lên hộ kinh doanh',
    phu:
        'Có giấy đăng ký hộ kinh doanh thì nâng cấp để nhận đặt món, đặt bàn qua app và tối đa ${_cfg.khuyenMaiToiDaHoKinhDoanh} khuyến mãi tự trừ vào đơn.',
    child: dangCho
        ? const HopThongBao.canhBao(
            noiDung: 'Yêu cầu nâng cấp đang chờ admin duyệt. Trong lúc chờ quán vẫn hoạt động như quán bán lẻ.',
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _mst,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'Mã số thuế (10–13 số)',
                  helperText: 'Admin tra cứu mã số thuế để đối chiếu',
                ),
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              QuanAnMediaField(
                storage: widget.dv.storage,
                folder: 'quan_an_anh',
                nhan: 'Ảnh giấy chứng nhận đăng ký hộ kinh doanh',
                goiY: 'Chỉ chủ quán và admin xem được.',
                toiThieu: 1,
                toiDa: 4,
                giaTri: _anhGiayChungNhan,
                onChanged: (v) => setState(() => _anhGiayChungNhan = v),
                pickImages: widget.dv.pickImages,
              ),
              const SizedBox(height: QuanAnSpacing.md),
              KhungLoiDo(_loiNangCap, tieuDe: 'Chưa gửi được, cần sửa:'),
              if (_loiNangCap.isNotEmpty)
                const SizedBox(height: QuanAnSpacing.md),
              OutlinedButton(
                onPressed: _dangNangCap ? null : _nangCap,
                child: Text(
                  _dangNangCap ? 'Đang gửi...' : 'Gửi yêu cầu nâng cấp',
                ),
              ),
              const SizedBox(height: QuanAnSpacing.xs),
              const Text(
                'Cần admin duyệt. Quán vẫn bán bình thường trong lúc chờ.',
                style: QuanAnText.bodySmall,
              ),
            ],
          ),
  );
}
