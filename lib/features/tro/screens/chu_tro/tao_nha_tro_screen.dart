import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/nha_tro.dart';
import '../../models/tro_config.dart';
import '../../models/tro_filter.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../sinh_vien/chon_diem_goc_screen.dart';
import '../tro_routes.dart';

/// Khung form nhiều bước: thanh tiến trình "Bước 2/5", quay lại không mất dữ liệu.
class TroFormNhieuBuoc extends StatelessWidget {
  const TroFormNhieuBuoc({
    required this.tieuDe,
    required this.buoc,
    required this.tenBuoc,
    required this.noiDung,
    required this.onQuayLai,
    required this.onTiep,
    this.nutCuoi,
    this.dangLuu = false,
    super.key,
  });

  final String tieuDe;
  final int buoc;
  final List<String> tenBuoc;
  final Widget noiDung;
  final VoidCallback? onQuayLai;
  final VoidCallback? onTiep;
  final Widget? nutCuoi;
  final bool dangLuu;

  @override
  Widget build(BuildContext context) {
    final cuoi = buoc == tenBuoc.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(tieuDe)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TroSpacing.screen,
              TroSpacing.sm,
              TroSpacing.screen,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bước ${buoc + 1}/${tenBuoc.length} · ${tenBuoc[buoc]}',
                  style: TroText.label,
                ),
                const SizedBox(height: TroSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TroRadius.pill),
                  child: LinearProgressIndicator(
                    value: (buoc + 1) / tenBuoc.length,
                    minHeight: 6,
                    backgroundColor: TroColors.primarySoft,
                    color: TroColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TroSpacing.screen),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: noiDung,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(TroSpacing.screen),
              decoration: BoxDecoration(
                color: TroColors.white,
                boxShadow: TroTheme.softShadow,
              ),
              child: Row(
                children: [
                  if (onQuayLai != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: dangLuu ? null : onQuayLai,
                        child: const Text('Quay lại'),
                      ),
                    ),
                  if (onQuayLai != null) const SizedBox(width: TroSpacing.md),
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
        ],
      ),
    );
  }
}

/// Dòng lỗi của một bước (báo lỗi bằng chữ, không chỉ đổi màu viền).
class LoiBuoc extends StatelessWidget {
  const LoiBuoc(this.loi, {super.key});

  final List<String> loi;

  @override
  Widget build(BuildContext context) => loi.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: TroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in loi)
                Text('• $l', style: const TextStyle(color: TroColors.danger)),
            ],
          ),
        );
}

/// TRO-CT-01 Tạo nhà trọ (5 phần), tự lưu nháp. Nhà trọ đang hiển thị thì là form SỬA:
/// nội dung / tiện ích / nội quy hiện ngay; ảnh, video, địa chỉ, vị trí ghim tạo bản chỉnh sửa chờ duyệt.
class TaoNhaTroScreen extends StatefulWidget {
  const TaoNhaTroScreen({required this.dv, this.nhaTro, super.key});

  final TroDichVu dv;
  final NhaTro? nhaTro;

  @override
  State<TaoNhaTroScreen> createState() => _TaoNhaTroScreenState();
}

class _TaoNhaTroScreenState extends State<TaoNhaTroScreen> {
  static const _ten = [
    'Thông tin chung',
    'Vị trí',
    'Ảnh khu trọ',
    'Video khu trọ',
    'Giấy tờ và gửi',
  ];
  int _buoc = 0;
  String? _id;
  bool _dangLuu = false;
  List<String> _loi = const [];

  final _tenNha = TextEditingController();
  final _tongPhong = TextEditingController();
  final _soTang = TextEditingController();
  final _moTa = TextEditingController();
  final _diaChi = TextEditingController();
  final _phuong = TextEditingController();
  String _loaiHinh = 'phong';
  final _tienIch = <String>{};
  String? _gioGiac;
  String? _gioDongCua;
  bool? _thuCung;
  bool? _oQuaDem;
  int? _baoTruoc;
  GeoPoint? _viTri;
  List<String> _anh = [];
  List<String> _video = [];
  String _anhBia = '';
  List<String> _giayTo = [];
  bool _camKet = false;

  bool get _laSua =>
      widget.nhaTro != null &&
      !['draft', 'rejected'].contains(widget.nhaTro!.trangThai);

  @override
  void initState() {
    super.initState();
    final n = widget.nhaTro;
    if (n != null) {
      _id = n.id;
      _tenNha.text = n.ten;
      _tongPhong.text = n.tongSoPhong?.toString() ?? '';
      _soTang.text = n.soTang?.toString() ?? '';
      _moTa.text = n.moTa;
      _diaChi.text = n.diaChi;
      _phuong.text = n.phuong;
      _loaiHinh = n.loaiHinh;
      _tienIch.addAll(n.tienIchChung);
      _gioGiac = n.noiQuy?.gioGiac;
      _gioDongCua = n.noiQuy?.gioDongCua;
      _thuCung = n.noiQuy?.thuCung;
      _oQuaDem = n.noiQuy?.oQuaDem;
      _baoTruoc = n.noiQuy?.baoTruocTuan;
      _viTri = n.viTri;
      _anh = [...n.anh];
      _video = [...n.video];
      _anhBia = n.anhBia;
      _camKet = n.camKet;
      widget.dv.nhaTro
          .docGiayTo(n.id)
          .then((g) => mounted ? setState(() => _giayTo = g) : null)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_tenNha, _tongPhong, _soTang, _moTa, _diaChi, _phuong]) {
      c.dispose();
    }
    super.dispose();
  }

  NoiQuy? get _noiQuy =>
      _gioGiac == null ||
          _thuCung == null ||
          _oQuaDem == null ||
          _baoTruoc == null
      ? null
      : NoiQuy(
          gioGiac: _gioGiac!,
          gioDongCua: _gioDongCua,
          thuCung: _thuCung!,
          oQuaDem: _oQuaDem!,
          baoTruocTuan: _baoTruoc!,
        );

  Map<String, dynamic> get _duLieu => {
    'chuTroId': widget.dv.uid,
    'ten': _tenNha.text.trim(),
    'loaiHinh': _loaiHinh,
    'tongSoPhong': int.tryParse(_tongPhong.text.trim()),
    'soTang': int.tryParse(_soTang.text.trim()),
    'tienIchChung': _tienIch.toList(),
    'noiQuy': _noiQuy?.toMap(),
    'moTa': _moTa.text.trim(),
    'diaChi': _diaChi.text.trim(),
    'phuong': _phuong.text.trim(),
    'searchText': boDau('${_tenNha.text} ${_diaChi.text} ${_phuong.text}'),
    'viTri': _viTri,
    'anh': _anh,
    'video': _video,
    'anhBia': _anhBia,
    'camKet': _camKet,
  };

  List<String> _kiemTra(int b) {
    final l = <String>[];
    final cfg = const TroConfig();
    if (b == 0) {
      final t = _tenNha.text.trim().length;
      if (t < 5 || t > 80) l.add('Tên nhà trọ 5–80 ký tự.');
      if ((int.tryParse(_tongPhong.text.trim()) ?? 0) < 1) {
        l.add('Nhập tổng số phòng.');
      }
      if ((int.tryParse(_soTang.text.trim()) ?? 0) < 1) l.add('Nhập số tầng.');
      if (_noiQuy == null) l.add('Chọn đủ 4 tiêu chí nội quy.');
      if (_gioGiac == 'gioi_han' &&
          (_gioDongCua == null || _gioDongCua!.isEmpty)) {
        l.add('Nhập giờ đóng cửa.');
      }
      if (_moTa.text.trim().length < 30) l.add('Mô tả ít nhất 30 ký tự.');
    } else if (b == 1) {
      if (_diaChi.text.trim().length < 5) l.add('Nhập địa chỉ đầy đủ.');
      if (_viTri == null) l.add('Ghim vị trí nhà trọ (đúng cổng) trên bản đồ.');
    } else if (b == 2) {
      if (_anh.length < cfg.anhToiThieu || _anh.length > cfg.anhToiDa) {
        l.add('Cần ${cfg.anhToiThieu}–${cfg.anhToiDa} ảnh khu trọ.');
      }
      if (_anhBia.isEmpty) l.add('Chọn ảnh bìa.');
    } else if (b == 3) {
      if (_video.length < cfg.videoToiThieu || _video.length > cfg.videoToiDa) {
        l.add('Cần ${cfg.videoToiThieu}–${cfg.videoToiDa} video khu trọ.');
      }
    } else if (b == 4 && !_laSua) {
      if (_giayTo.isEmpty) {
        l.add('Tải lên giấy tờ nhà (hoặc hợp đồng thuê nếu cho thuê lại).');
      }
      if (!_camKet) l.add('Tick cam kết thông tin đúng sự thật.');
    }
    return l;
  }

  /// Tự lưu nháp (bản đang hiển thị thì không ghi thẳng, chỉ lưu khi bấm "Lưu thay đổi").
  Future<void> _luuNhap() async {
    if (_laSua) return;
    _id = await widget.dv.nhaTro.luuNhapNhaTro(_id, _duLieu);
    if (_giayTo.isNotEmpty) await widget.dv.nhaTro.luuGiayTo(_id!, _giayTo);
  }

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
    final ok = await chayThaoTac(
      context,
      () async {
        if (_laSua) {
          final d = Map<String, dynamic>.from(_duLieu)
            ..remove('chuTroId')
            ..remove('camKet')
            ..remove('searchText');
          d['viTri'] = _viTri == null
              ? null
              : {'lat': _viTri!.latitude, 'lng': _viTri!.longitude};
          await widget.dv.nhaTro.thaoTac('suaNhaTro', {
            'nhaTroId': _id,
            'thayDoi': d,
          });
        } else {
          await _luuNhap();
          await widget.dv.nhaTro.thaoTac('guiDuyetNhaTro', {'nhaTroId': _id});
        }
      },
      thanhCong: _laSua
          ? 'Đã lưu. Ảnh / video / vị trí mới (nếu có) chờ admin duyệt.'
          : 'Đã gửi duyệt nhà trọ',
    );
    if (!mounted) return;
    setState(() => _dangLuu = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (daPop, _) {
        if (daPop && _buoc > 0) _luuNhap().catchError((_) {});
      },
      child: TroFormNhieuBuoc(
        tieuDe: _laSua ? 'Sửa nhà trọ' : 'Tạo nhà trọ',
        buoc: _buoc,
        tenBuoc: _ten,
        dangLuu: _dangLuu,
        onQuayLai: _buoc == 0
            ? null
            : () => setState(() {
                _buoc--;
                _loi = const [];
              }),
        onTiep: _tiep,
        nutCuoi: StreamBuilder<XacThuc>(
          stream: widget.dv.xacThuc.cuaToi(widget.dv.uid),
          builder: (context, s) {
            final xt = s.data ?? const XacThuc();
            final duocGui = _laSua || (xt.daOtp && xt.daXacThucDanhTinh);
            return FilledButton(
              onPressed: _dangLuu || !duocGui ? null : _guiDuyet,
              child: Text(_laSua ? 'Lưu thay đổi' : 'Gửi duyệt'),
            );
          },
        ),
        noiDung: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.nhaTro?.lyDoTuChoi != null &&
                widget.nhaTro!.trangThai == 'rejected')
              Padding(
                padding: const EdgeInsets.only(bottom: TroSpacing.md),
                child: TroWarningBox(
                  message:
                      'Bị từ chối: ${widget.nhaTro!.lyDoTuChoi}. Sửa rồi gửi lại.',
                ),
              ),
            ...switch (_buoc) {
              0 => _buoc0(),
              1 => _buoc1(),
              2 => [
                TroMediaField(
                  storage: widget.dv.storage,
                  folder: 'tro_anh',
                  nhan: 'Ảnh khu trọ',
                  goiY: 'Ảnh cổng, lối đi, chỗ để xe... Ảnh được chọn từ thư viện, chỉ hiện ở trang chi tiết.',
                  toiThieu: 3,
                  toiDa: 10,
                  giaTri: _anh,
                  anhBia: _anhBia,
                  onChanged: (v) => setState(() {
                    _anh = v;
                    if (!v.contains(_anhBia)) {
                      _anhBia = v.isEmpty ? '' : v.first;
                    }
                  }),
                  onChonAnhBia: (u) => setState(() => _anhBia = u),
                  pickImages: widget.dv.pickImages,
                ),
              ],
              3 => [
                TroMediaField(
                  storage: widget.dv.storage,
                  folder: 'tro_video',
                  laVideo: true,
                  nhan: 'Video khu trọ',
                  goiY: _loaiHinh == 'nguyen_can'
                      ? 'Quay bên ngoài: cổng, lối vào, xung quanh (15–60 giây).'
                      : 'Gợi ý quay: cổng → lối đi → chỗ để xe → khu chung (15–60 giây).',
                  toiThieu: 1,
                  toiDa: 2,
                  giaTri: _video,
                  onChanged: (v) => setState(() => _video = v),
                  pickVideo: widget.dv.pickVideo,
                ),
              ],
              _ => _buoc4(),
            },
            LoiBuoc(_loi),
          ],
        ),
      ),
    );
  }

  List<Widget> _buoc0() => [
    TextField(
      controller: _tenNha,
      decoration: const InputDecoration(labelText: 'Tên nhà trọ (5–80 ký tự)'),
    ),
    const SizedBox(height: TroSpacing.md),
    const Text('Loại hình', style: TroText.label),
    RadioGroup<String>(
      groupValue: _loaiHinh,
      onChanged: _laSua
          ? (_) {}
          : (v) => setState(() => _loaiHinh = v ?? 'phong'),
      child: Row(
        children: [
          for (final e in loaiHinhLabels.entries)
            Expanded(
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: e.key,
                title: Text(e.value),
              ),
            ),
        ],
      ),
    ),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _tongPhong,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tổng số phòng'),
          ),
        ),
        const SizedBox(width: TroSpacing.md),
        Expanded(
          child: TextField(
            controller: _soTang,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Số tầng'),
          ),
        ),
      ],
    ),
    const SizedBox(height: TroSpacing.md),
    const Text('Tiện ích chung', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        for (final e in tienIchChungLabels.entries)
          FilterChip(
            label: Text(e.value),
            selected: _tienIch.contains(e.key),
            onSelected: (on) => setState(
              () => on ? _tienIch.add(e.key) : _tienIch.remove(e.key),
            ),
          ),
      ],
    ),
    const SizedBox(height: TroSpacing.lg),
    const Text('Nội quy (bắt buộc đủ 4 tiêu chí)', style: TroText.h3),
    const SizedBox(height: TroSpacing.sm),
    const Text('🕐 Giờ giấc ra vào', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Tự do 24/24'),
          selected: _gioGiac == 'tu_do',
          onSelected: (_) => setState(() => _gioGiac = 'tu_do'),
        ),
        ChoiceChip(
          label: const Text('Có giới hạn'),
          selected: _gioGiac == 'gioi_han',
          onSelected: (_) => setState(() => _gioGiac = 'gioi_han'),
        ),
      ],
    ),
    if (_gioGiac == 'gioi_han')
      OutlinedButton.icon(
        onPressed: () async {
          final g = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 22, minute: 0),
            helpText: 'Giờ đóng cửa',
          );
          if (g != null) {
            setState(
              () => _gioDongCua =
                  '${g.hour.toString().padLeft(2, '0')}:${g.minute.toString().padLeft(2, '0')}',
            );
          }
        },
        icon: const Icon(Icons.schedule),
        label: Text(
          _gioDongCua == null ? 'Chọn giờ đóng cửa' : 'Đóng cửa $_gioDongCua',
        ),
      ),
    const SizedBox(height: TroSpacing.sm),
    const Text('🐶 Nuôi thú cưng', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Cho phép'),
          selected: _thuCung == true,
          onSelected: (_) => setState(() => _thuCung = true),
        ),
        ChoiceChip(
          label: const Text('Không cho phép'),
          selected: _thuCung == false,
          onSelected: (_) => setState(() => _thuCung = false),
        ),
      ],
    ),
    const SizedBox(height: TroSpacing.sm),
    const Text('🛏️ Bạn bè / người thân ở qua đêm', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Cho phép'),
          selected: _oQuaDem == true,
          onSelected: (_) => setState(() => _oQuaDem = true),
        ),
        ChoiceChip(
          label: const Text('Không cho phép'),
          selected: _oQuaDem == false,
          onSelected: (_) => setState(() => _oQuaDem = false),
        ),
      ],
    ),
    const SizedBox(height: TroSpacing.sm),
    const Text('📅 Thời gian báo trước khi trả phòng', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        for (final t in [1, 2, 3])
          ChoiceChip(
            label: Text('$t tuần'),
            selected: _baoTruoc == t,
            onSelected: (_) => setState(() => _baoTruoc = t),
          ),
      ],
    ),
    const SizedBox(height: TroSpacing.lg),
    TextField(
      controller: _moTa,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Mô tả (ít nhất 30 ký tự)',
        helperText: 'Ở chung với chủ hay không thì ghi trong mô tả.',
      ),
    ),
  ];

  List<Widget> _buoc1() => [
    TextField(
      controller: _diaChi,
      decoration: const InputDecoration(
        labelText: 'Địa chỉ đầy đủ (số nhà, đường, phường)',
      ),
    ),
    const SizedBox(height: TroSpacing.md),
    TextField(
      controller: _phuong,
      decoration: const InputDecoration(labelText: 'Phường / xã'),
    ),
    const SizedBox(height: TroSpacing.md),
    OutlinedButton.icon(
      onPressed: () async {
        final g = await TroDieuHuong.mo<DiemGoc>(
          context,
          (_) => ChonDiemGocScreen(
            tieuDe: 'Ghim đúng cổng nhà trọ',
            banDau: _viTri == null
                ? null
                : DiemGoc(lat: _viTri!.latitude, lng: _viTri!.longitude),
          ),
        );
        if (g != null) setState(() => _viTri = GeoPoint(g.lat, g.lng));
      },
      icon: const Icon(Icons.place_outlined),
      label: Text(
        _viTri == null
            ? 'Ghim vị trí trên bản đồ'
            : 'Đã ghim (${_viTri!.latitude.toStringAsFixed(5)}, ${_viTri!.longitude.toStringAsFixed(5)}) — đổi',
      ),
    ),
  ];

  List<Widget> _buoc4() => [
    if (!_laSua) ...[
      TroMediaField(
        storage: widget.dv.storage,
        folder: 'tro_rieng',
        nhan: 'Giấy tờ nhà (hoặc hợp đồng thuê nếu cho thuê lại)',
        goiY: 'Chỉ chủ trọ và admin xem được. (Đặc tả yêu cầu chụp trong app — sẽ bổ sung khi có máy Android thật.)',
        toiThieu: 1,
        toiDa: 4,
        giaTri: _giayTo,
        onChanged: (v) => setState(() => _giayTo = v),
        pickImages: widget.dv.pickImages,
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _camKet,
        onChanged: (v) => setState(() => _camKet = v ?? false),
        title: const Text('Tôi cam kết thông tin nhà trọ là đúng sự thật.'),
      ),
    ],
    const Text('Xem trước', style: TroText.h3),
    Card(
      child: ListTile(
        title: Text(_tenNha.text),
        subtitle: Text(
          '${loaiHinhLabels[_loaiHinh]} · ${_diaChi.text}\n${_noiQuy?.gioGiacLabel ?? ''} · ${_anh.length} ảnh · ${_video.length} video',
        ),
      ),
    ),
    if (!_laSua)
      StreamBuilder<XacThuc>(
        stream: widget.dv.xacThuc.cuaToi(widget.dv.uid),
        builder: (context, s) {
          final xt = s.data ?? const XacThuc();
          if (!xt.daOtp) {
            return ListTile(
              leading: const Icon(
                Icons.warning_amber,
                color: TroColors.warning,
              ),
              title: const Text(
                'Cần xác thực số điện thoại trước khi gửi duyệt',
              ),
              trailing: TextButton(
                onPressed: () => TroDieuHuong.mo(
                  context,
                  (_) => XacThucSdtScreen(service: widget.dv.xacThuc),
                ),
                child: const Text('Xác thực'),
              ),
            );
          }
          if (!xt.daXacThucDanhTinh) {
            return ListTile(
              leading: const Icon(
                Icons.warning_amber,
                color: TroColors.warning,
              ),
              title: Text(
                'Chưa xác nhận người thật: ${XacThuc.danhTinhLabels[xt.danhTinh]}. Bạn vẫn lưu nháp được.',
              ),
              trailing: xt.danhTinh == 'cho_duyet'
                  ? null
                  : TextButton(
                      onPressed: () => TroDieuHuong.mo(
                        context,
                        (_) =>
                            XacNhanDanhTinhScreen(service: widget.dv.xacThuc),
                      ),
                      child: const Text('Xác nhận'),
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
  ];
}
