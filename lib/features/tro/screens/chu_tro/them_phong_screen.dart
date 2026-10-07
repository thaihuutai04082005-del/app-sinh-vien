import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/nha_tro.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import 'tao_nha_tro_screen.dart';

/// TRO-CT-02 Thêm phòng (4 phần) + Nhân bản. Phòng đang hiển thị thì là form SỬA:
/// giá, phí, mô tả, tiện ích, số người, ngày vào ở hiện ngay; ảnh / video tạo bản chỉnh sửa chờ duyệt;
/// tiền cọc không đổi được khi phòng đang có người cọc.
class ThemPhongScreen extends StatefulWidget {
  const ThemPhongScreen({
    required this.dv,
    required this.nhaTro,
    this.phong,
    this.nhanBanTu,
    super.key,
  });

  final TroDichVu dv;
  final NhaTro nhaTro;
  final PhongTro? phong;

  /// "Nhân bản phòng": copy hết, trừ tên phòng, ảnh và video.
  final PhongTro? nhanBanTu;

  @override
  State<ThemPhongScreen> createState() => _ThemPhongScreenState();
}

class _ThemPhongScreenState extends State<ThemPhongScreen> {
  static const _tenBuoc = [
    'Thông tin phòng',
    'Ảnh phòng',
    'Video phòng',
    'Xem trước và gửi duyệt',
  ];
  int _buoc = 0;
  String? _id;
  bool _dangLuu = false;
  List<String> _loi = const [];

  final _ten = TextEditingController();
  final _khu = TextEditingController();
  final _tang = TextEditingController();
  final _dienTich = TextEditingController();
  final _dienTichGac = TextEditingController();
  final _soNguoi = TextEditingController(text: '1');
  final _soPhongNgu = TextEditingController();
  final _soWc = TextEditingController();
  final _gia = TextEditingController();
  final _coc = TextEditingController();
  final _giaDien = TextEditingController();
  final _giaNuoc = TextEditingController();
  final _hopDong = TextEditingController();
  final _moTa = TextEditingController();
  bool? _coGac;
  bool? _coBep;
  String _cachDien = 'theo_so';
  String _cachNuoc = 'theo_nguoi';
  final _tienIch = <String>{};
  final _phiKhac = <(TextEditingController, TextEditingController)>[];
  DateTime? _ngayVaoO;
  List<String> _anh = [];
  List<String> _video = [];
  String _anhBia = '';

  bool get _nguyenCan => widget.nhaTro.laNguyenCan;
  bool get _laSua =>
      widget.phong != null &&
      !['draft', 'rejected'].contains(widget.phong!.trangThai);

  @override
  void initState() {
    super.initState();
    final p = widget.phong ?? widget.nhanBanTu;
    if (p != null) {
      if (widget.phong != null) {
        _id = p.id;
        _ten.text = p.ten;
        _anh = [...p.anh];
        _video = [...p.video];
        _anhBia = p.anhBia;
      }
      _khu.text = p.khu;
      _tang.text = p.tang?.toString() ?? '';
      _dienTich.text = _so(p.dienTich);
      _dienTichGac.text = p.dienTichGac == null ? '' : _so(p.dienTichGac!);
      _soNguoi.text = '${p.soNguoiToiDa}';
      _soPhongNgu.text = p.soPhongNgu?.toString() ?? '';
      _soWc.text = p.soWc?.toString() ?? '';
      _gia.text = _so(p.giaThue);
      _coc.text = _so(p.tienCoc);
      _giaDien.text = p.tienDien == null ? '' : _so(p.tienDien!.gia);
      _giaNuoc.text = p.tienNuoc == null ? '' : _so(p.tienNuoc!.gia);
      _hopDong.text = p.hopDongToiThieu?.toString() ?? '';
      _moTa.text = p.moTa;
      _coGac = p.coGac;
      _coBep = p.coBep;
      _cachDien = p.tienDien?.cach ?? 'theo_so';
      _cachNuoc = p.tienNuoc?.cach ?? 'theo_nguoi';
      _tienIch.addAll(p.tienIch);
      for (final f in p.phiKhac) {
        _phiKhac.add((
          TextEditingController(text: f.ten),
          TextEditingController(text: _so(f.gia)),
        ));
      }
      _ngayVaoO = p.ngayVaoO;
    }
  }

  static String _so(num x) =>
      x == x.roundToDouble() ? x.toStringAsFixed(0) : x.toString();

  num? _n(TextEditingController c) =>
      num.tryParse(c.text.trim().replaceAll('.', '').replaceAll(',', '.'));
  int? _i(TextEditingController c) => int.tryParse(c.text.trim());

  PhongTro get _phong => PhongTro(
    id: _id ?? '',
    nhaTroId: widget.nhaTro.id,
    chuTroId: widget.dv.uid,
    ten: _ten.text.trim(),
    khu: _khu.text.trim(),
    tang: _i(_tang),
    coGac: _nguyenCan ? null : _coGac,
    dienTich: _n(_dienTich) ?? 0,
    dienTichGac: (_coGac ?? false) ? _n(_dienTichGac) : null,
    soNguoiToiDa: _i(_soNguoi) ?? 0,
    soPhongNgu: _nguyenCan ? _i(_soPhongNgu) : null,
    soWc: _nguyenCan ? _i(_soWc) : null,
    coBep: _nguyenCan ? _coBep : null,
    tienIch: _tienIch.toList(),
    giaThue: _n(_gia) ?? 0,
    tienCoc: _n(_coc) ?? 0,
    tienDien: ChiPhi(cach: _cachDien, gia: _n(_giaDien) ?? -1),
    tienNuoc: ChiPhi(cach: _cachNuoc, gia: _n(_giaNuoc) ?? -1),
    phiKhac: [
      for (final (t, g) in _phiKhac)
        if (t.text.trim().isNotEmpty)
          PhiKhac(ten: t.text.trim(), gia: _n(g) ?? 0),
    ],
    hopDongToiThieu: _i(_hopDong),
    ngayVaoO: _ngayVaoO,
    moTa: _moTa.text.trim(),
    anh: _anh,
    video: _video,
    anhBia: _anhBia,
  );

  List<String> _kiemTra(int b) {
    final l = <String>[];
    const cfg = TroConfig();
    final p = _phong;
    if (b == 0) {
      if (p.ten.isEmpty) l.add('Nhập tên / số phòng.');
      if (!_nguyenCan && _coGac == null) l.add('Chọn có gác hay không.');
      if (p.dienTich <= 0) l.add('Diện tích sàn phải lớn hơn 0.');
      if ((_coGac ?? false) && (p.dienTichGac ?? 0) <= 0) {
        l.add('Nhập diện tích gác.');
      }
      if (p.soNguoiToiDa < 1) l.add('Số người ở tối đa ít nhất 1.');
      if (_nguyenCan &&
          ((p.soPhongNgu ?? 0) < 1 || (p.soWc ?? 0) < 1 || _coBep == null)) {
        l.add('Nhập số phòng ngủ, số WC, có bếp không.');
      }
      if (p.giaThue <= 0) l.add('Giá thuê phải lớn hơn 0.');
      if (p.tienCoc <= 0) l.add('Nhập số tiền cọc.');
      if (p.tienCoc > p.giaThue) l.add('Tiền cọc tối đa 1 tháng tiền thuê.');
      if ((p.tienDien?.gia ?? -1) < 0) l.add('Nhập tiền điện.');
      if ((p.tienNuoc?.gia ?? -1) < 0) l.add('Nhập tiền nước.');
      if (_laSua &&
          widget.phong!.trangThai == 'reserved' &&
          p.tienCoc != widget.phong!.tienCoc) {
        l.add('Không đổi được tiền cọc khi phòng đang có người cọc.');
      }
    } else if (b == 1) {
      if (_anh.length < cfg.anhToiThieu || _anh.length > cfg.anhToiDa) {
        l.add('Cần ${cfg.anhToiThieu}–${cfg.anhToiDa} ảnh phòng.');
      }
      if (_anhBia.isEmpty) l.add('Chọn ảnh bìa phòng.');
    } else if (b == 2) {
      if (_video.length < cfg.videoToiThieu || _video.length > cfg.videoToiDa) {
        l.add('Cần ${cfg.videoToiThieu}–${cfg.videoToiDa} video phòng.');
      }
    }
    return l;
  }

  Future<void> _luuNhap() async {
    if (_laSua) return;
    _id = await widget.dv.nhaTro.luuNhapPhong(_id, _phong.toDraftMap());
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

  Future<void> _gui() async {
    final l = [for (var b = 0; b < 3; b++) ..._kiemTra(b)];
    setState(() => _loi = l);
    if (l.isNotEmpty) return;
    setState(() => _dangLuu = true);
    final ok = await chayThaoTac(
      context,
      () async {
        if (_laSua) {
          final m = _phong.toDraftMap()
            ..removeWhere(
              (k, _) => [
                'nhaTroId',
                'chuTroId',
                'ten',
                'coGac',
                'dienTich',
                'dienTichGac',
                'soPhongNgu',
                'soWc',
                'coBep',
              ].contains(k),
            );
          m['ngayVaoO'] = _ngayVaoO?.millisecondsSinceEpoch;
          await widget.dv.nhaTro.thaoTac('suaPhong', {
            'phongId': _id,
            'thayDoi': m,
          });
        } else {
          await _luuNhap();
          await widget.dv.nhaTro.thaoTac('guiDuyetPhong', {'phongId': _id});
        }
      },
      thanhCong: _laSua
          ? 'Đã lưu. Ảnh / video mới (nếu có) chờ admin duyệt.'
          : 'Đã gửi duyệt phòng',
    );
    if (!mounted) return;
    setState(() => _dangLuu = false);
    if (ok) Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in [
      _ten,
      _khu,
      _tang,
      _dienTich,
      _dienTichGac,
      _soNguoi,
      _soPhongNgu,
      _soWc,
      _gia,
      _coc,
      _giaDien,
      _giaNuoc,
      _hopDong,
      _moTa,
    ]) {
      c.dispose();
    }
    for (final (a, b) in _phiKhac) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  Widget _o(
    TextEditingController c,
    String nhan, {
    bool so = false,
    String? goiY,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: TroSpacing.md),
    child: TextField(
      controller: c,
      keyboardType: so ? TextInputType.number : null,
      decoration: InputDecoration(labelText: nhan, helperText: goiY),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (daPop, _) {
      if (daPop && _buoc > 0) _luuNhap().catchError((_) {});
    },
    child: TroFormNhieuBuoc(
      tieuDe: _laSua
          ? 'Sửa phòng ${widget.phong!.ten}'
          : (_nguyenCan ? 'Thông tin căn nhà' : 'Thêm phòng'),
      buoc: _buoc,
      tenBuoc: _tenBuoc,
      dangLuu: _dangLuu,
      onQuayLai: _buoc == 0
          ? null
          : () => setState(() {
              _buoc--;
              _loi = const [];
            }),
      onTiep: _tiep,
      nutCuoi: FilledButton(
        onPressed: _dangLuu ? null : _gui,
        child: Text(_laSua ? 'Lưu thay đổi' : 'Gửi duyệt'),
      ),
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.phong?.trangThai == 'rejected' &&
              widget.phong?.lyDoTuChoi != null)
            Padding(
              padding: const EdgeInsets.only(bottom: TroSpacing.md),
              child: TroWarningBox(
                message: 'Bị từ chối: ${widget.phong!.lyDoTuChoi}',
              ),
            ),
          if (widget.nhanBanTu != null && _buoc == 0)
            const Padding(
              padding: EdgeInsets.only(bottom: TroSpacing.md),
              child: Text(
                'Đã copy thông tin từ phòng gốc. Tên phòng, ảnh và video phải làm lại cho đúng phòng mới.',
                style: TroText.bodySmall,
              ),
            ),
          ...switch (_buoc) {
            0 => _buoc0(),
            1 => [
              TroMediaField(
                storage: widget.dv.storage,
                folder: 'tro_anh',
                nhan: 'Ảnh phòng',
                toiThieu: 3,
                toiDa: 10,
                giaTri: _anh,
                anhBia: _anhBia,
                onChanged: (v) => setState(() {
                  _anh = v;
                  if (!v.contains(_anhBia)) _anhBia = v.isEmpty ? '' : v.first;
                }),
                onChonAnhBia: (u) => setState(() => _anhBia = u),
                pickImages: widget.dv.pickImages,
              ),
            ],
            2 => [
              TroMediaField(
                storage: widget.dv.storage,
                folder: 'tro_video',
                laVideo: true,
                nhan: 'Video phòng',
                goiY: _nguyenCan ? 'Quay bên trong căn nhà (15–60 giây).' : 'Gợi ý quay: toàn cảnh → nhà vệ sinh → cửa sổ, gác (15–60 giây).',
                toiThieu: 1,
                toiDa: 2,
                giaTri: _video,
                onChanged: (v) => setState(() => _video = v),
                pickVideo: widget.dv.pickVideo,
              ),
            ],
            _ => [
              Card(
                child: ListTile(
                  title: Text('Phòng ${_ten.text}'),
                  subtitle: Text(
                    '${_phong.moTaDienTich}\n${formatPrice(_phong.giaThue)}/tháng · Cọc ${formatPrice(_phong.tienCoc)} · ${_anh.length} ảnh · ${_video.length} video',
                  ),
                ),
              ),
              const Text(
                'Phòng được duyệt sẽ nhận cọc qua app (mọi phòng đều vậy).',
                style: TroText.bodySmall,
              ),
            ],
          },
          LoiBuoc(_loi),
        ],
      ),
    ),
  );

  List<Widget> _buoc0() => [
    _o(_ten, 'Tên / số phòng (không trùng trong nhà trọ)'),
    Row(
      children: [
        Expanded(child: _o(_khu, 'Khu / Dãy (tùy chọn)')),
        const SizedBox(width: TroSpacing.md),
        Expanded(child: _o(_tang, 'Tầng', so: true)),
      ],
    ),
    if (!_nguyenCan) ...[
      const Text('Loại phòng', style: TroText.label),
      Wrap(
        spacing: TroSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Có gác'),
            selected: _coGac == true,
            onSelected: (_) => setState(() => _coGac = true),
          ),
          ChoiceChip(
            label: const Text('Không gác'),
            selected: _coGac == false,
            onSelected: (_) => setState(() => _coGac = false),
          ),
        ],
      ),
      const SizedBox(height: TroSpacing.md),
    ],
    Row(
      children: [
        Expanded(
          child: _o(_dienTich, 'Diện tích sàn (m², không tính gác)', so: true),
        ),
        if (_coGac ?? false) ...[
          const SizedBox(width: TroSpacing.md),
          Expanded(child: _o(_dienTichGac, 'Diện tích gác (m²)', so: true)),
        ],
      ],
    ),
    _o(_soNguoi, 'Số người ở tối đa', so: true),
    if (_nguyenCan) ...[
      Row(
        children: [
          Expanded(child: _o(_soPhongNgu, 'Số phòng ngủ', so: true)),
          const SizedBox(width: TroSpacing.md),
          Expanded(child: _o(_soWc, 'Số WC', so: true)),
        ],
      ),
      Wrap(
        spacing: TroSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Có bếp'),
            selected: _coBep == true,
            onSelected: (_) => setState(() => _coBep = true),
          ),
          ChoiceChip(
            label: const Text('Không có bếp'),
            selected: _coBep == false,
            onSelected: (_) => setState(() => _coBep = false),
          ),
        ],
      ),
      const SizedBox(height: TroSpacing.md),
    ],
    const Text('Tiện ích trong phòng', style: TroText.label),
    Wrap(
      spacing: TroSpacing.sm,
      children: [
        for (final e in tienIchPhongLabels.entries)
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
    const Text('Chi phí', style: TroText.h3),
    const SizedBox(height: TroSpacing.sm),
    _o(_gia, 'Giá thuê / tháng (đ)', so: true),
    _o(_coc, 'Tiền cọc (đ) — tối đa 1 tháng tiền thuê', so: true),
    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _cachDien,
            decoration: const InputDecoration(labelText: 'Tiền điện'),
            items: [
              for (final e in cachTinhDienLabels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _cachDien = v ?? 'theo_so'),
          ),
        ),
        const SizedBox(width: TroSpacing.md),
        Expanded(
          child: TextField(
            controller: _giaDien,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá (đ)'),
          ),
        ),
      ],
    ),
    const SizedBox(height: TroSpacing.md),
    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _cachNuoc,
            decoration: const InputDecoration(labelText: 'Tiền nước'),
            items: [
              for (final e in cachTinhNuocLabels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _cachNuoc = v ?? 'theo_nguoi'),
          ),
        ),
        const SizedBox(width: TroSpacing.md),
        Expanded(
          child: TextField(
            controller: _giaNuoc,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá (đ)'),
          ),
        ),
      ],
    ),
    const SizedBox(height: TroSpacing.md),
    const Text('Phí khác (wifi, rác, gửi xe...)', style: TroText.label),
    for (final (t, g) in _phiKhac)
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: t,
              decoration: const InputDecoration(labelText: 'Tên phí'),
            ),
          ),
          const SizedBox(width: TroSpacing.sm),
          Expanded(
            child: TextField(
              controller: g,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'đ / tháng'),
            ),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: () =>
                setState(() => _phiKhac.removeWhere((x) => x.$1 == t)),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    TextButton.icon(
      onPressed: () => setState(
        () => _phiKhac.add((TextEditingController(), TextEditingController())),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Thêm phí'),
    ),
    _o(_hopDong, 'Hợp đồng tối thiểu (tháng, tùy chọn)', so: true),
    OutlinedButton.icon(
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: _ngayVaoO ?? DateTime.now(),
          helpText: 'Ngày có thể vào ở',
        );
        if (d != null) setState(() => _ngayVaoO = d);
      },
      icon: const Icon(Icons.event_available),
      label: Text(
        _ngayVaoO == null
            ? 'Ngày có thể vào ở'
            : 'Vào ở từ ${formatNgay(_ngayVaoO!)}',
      ),
    ),
    const SizedBox(height: TroSpacing.md),
    _o(_moTa, 'Mô tả phòng'),
  ];
}
