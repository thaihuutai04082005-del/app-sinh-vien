import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/mon_an.dart';
import '../../models/nhom_mon.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_map_marker.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// Phân vị [p] (0–1) của danh sách giá, nội suy tuyến tính.
num phanViGia(List<num> gia, double p) {
  final s = [...gia]..sort();
  if (s.length == 1) return s.first;
  final vt = p * (s.length - 1);
  final duoi = vt.floor();
  final tren = vt.ceil();
  return s[duoi] + (s[tren] - s[duoi]) * (vt - duoi);
}

/// Mức giá tự tính của quán (mục 3.3 Bước 3): lấy giá món thuộc nhóm "món chính"; quán không
/// có món chính thì lấy toàn bộ món. Trả (P25, P75), null khi chưa có món.
(num, num)? mucGiaQuan(List<NhomMon> nhom, List<MonAn> mon) {
  if (mon.isEmpty) return null;
  final doUong = {
    for (final n in nhom)
      if (n.laDoUong) n.id,
  };
  final chinh = [
    for (final m in mon)
      if (!doUong.contains(m.nhomId)) m.gia,
  ];
  final gia = chinh.isEmpty ? [for (final m in mon) m.gia] : chinh;
  return (phanViGia(gia, 0.25), phanViGia(gia, 0.75));
}

/// QA-CQ-05 Quản lý menu: nhóm món, món (ảnh, mô tả, ⭐ nổi bật, còn / hết), tùy chọn.
/// Sửa menu hiện ngay, không cần duyệt; đơn đã đặt vẫn giữ giá lúc đặt.
class QuanLyMenuScreen extends StatefulWidget {
  const QuanLyMenuScreen({required this.dv, required this.quanId, super.key});

  final QuanAnDichVu dv;
  final String quanId;

  @override
  State<QuanLyMenuScreen> createState() => _QuanLyMenuScreenState();
}

class _QuanLyMenuScreenState extends State<QuanLyMenuScreen> {
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
    appBar: AppBar(title: const Text('Menu')),
    body: QuanAnStream<List<NhomMon>>(
      stream: () => widget.dv.menu.nhomMonCuaChu(widget.quanId),
      thongBaoLoi: 'Không tải được nhóm món',
      builder: (context, nhom) => QuanAnStream<List<MonAn>>(
        stream: () => widget.dv.menu.monCuaChu(widget.quanId),
        thongBaoLoi: 'Không tải được món',
        builder: (context, mon) => _NoiDung(
          dv: widget.dv,
          quanId: widget.quanId,
          cfg: _cfg,
          nhom: nhom,
          mon: mon,
        ),
      ),
    ),
  );
}

class _NoiDung extends StatelessWidget {
  const _NoiDung({
    required this.dv,
    required this.quanId,
    required this.cfg,
    required this.nhom,
    required this.mon,
  });

  final QuanAnDichVu dv;
  final String quanId;
  final QuanAnConfig cfg;
  final List<NhomMon> nhom;
  final List<MonAn> mon;

  int get _thuTuNhomMoi =>
      nhom.fold<int>(0, (s, n) => n.thuTu > s ? n.thuTu : s) + 1;
  int get _thuTuMonMoi =>
      mon.fold<int>(0, (s, m) => m.thuTu > s ? m.thuTu : s) + 1;

  Future<void> _suaNhom(BuildContext context, [NhomMon? n]) async {
    final kq = await showDialog<({String ten, bool doUong})>(
      context: context,
      builder: (c) => _NhomDialog(nhom: n),
    );
    if (kq == null || !context.mounted) return;
    await chayThaoTac(
      context,
      () => dv.menu.luuNhomMon(
        NhomMon(
          id: n?.id ?? '',
          quanId: quanId,
          chuQuanId: dv.uid,
          ten: kq.ten,
          laDoUong: kq.doUong,
          thuTu: n?.thuTu ?? _thuTuNhomMoi,
        ),
      ),
      thanhCong: n == null ? 'Đã thêm nhóm' : 'Đã lưu nhóm',
    );
  }

  Future<void> _xoaNhom(BuildContext context, NhomMon n) async {
    final soMon = mon.where((m) => m.nhomId == n.id).length;
    if (soMon > 0) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Chưa xóa được nhóm'),
          content: Text(
            'Nhóm "${n.ten}" còn $soMon món. Hãy xóa hoặc chuyển các món sang nhóm khác trước.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await xacNhan(
      context,
      tieuDe: 'Xóa nhóm "${n.ten}"?',
      noiDung: 'Nhóm trống sẽ bị xóa.',
      dongY: 'Xóa nhóm',
      nguyHiem: true,
    );
    if (ok && context.mounted) {
      await chayThaoTac(
        context,
        () => dv.menu.xoaNhomMon(n.id),
        thanhCong: 'Đã xóa nhóm',
      );
    }
  }

  Future<void> _suaMon(BuildContext context, [MonAn? m]) async {
    await QuanAnDieuHuong.mo<bool>(
      context,
      (_) => _MonEditorScreen(
        dv: dv,
        quanId: quanId,
        cfg: cfg,
        mon: m,
        nhom: nhom,
        soNoiBatKhac: mon.where((x) => x.noiBat && x.id != m?.id).length,
        thuTuMoi: _thuTuMonMoi,
      ),
    );
  }

  Future<void> _xoaMon(BuildContext context, MonAn m) async {
    final ok = await xacNhan(
      context,
      tieuDe: 'Xóa món "${m.ten}"?',
      noiDung: 'Món biến mất khỏi menu. Đơn đã đặt vẫn giữ nguyên món và giá lúc đặt.',
      dongY: 'Xóa món',
      nguyHiem: true,
    );
    if (ok && context.mounted) {
      await chayThaoTac(
        context,
        () => dv.menu.xoaMon(m.id),
        thanhCong: 'Đã xóa món',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gia = mucGiaQuan(nhom, mon);
    final idNhom = {for (final n in nhom) n.id};
    final moCoi = [
      for (final m in mon)
        if (!idNhom.contains(m.nhomId)) m,
    ];
    final du = mon.length >= cfg.monToiThieuHienThi;
    final duMon = mon.length >= cfg.monToiDa;
    final duNhom = nhom.length >= cfg.nhomMonToiDa;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QuanAnSpacing.screen),
      child: TrangRong(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KhoiThongTin(
              tieuDe: '${mon.length} món · ${nhom.length} nhóm',
              phu:
                  'Sửa menu hiện ngay, không cần duyệt. Tối đa ${cfg.nhomMonToiDa} nhóm, ${cfg.monToiDa} món.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (du)
                    const HopThongBao.thanhCong(
                      noiDung: 'Menu đủ món để quán hiện ở danh sách.',
                    )
                  else
                    HopThongBao.canhBao(
                      noiDung:
                          'Quán cần ít nhất ${cfg.monToiThieuHienThi} món mới hiện ở danh sách. '
                          'Hiện có ${mon.length} món.',
                    ),
                  const SizedBox(height: QuanAnSpacing.md),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mức giá của quán (tự tính)',
                          style: QuanAnText.bodySmall,
                        ),
                      ),
                      Text(
                        gia == null
                            ? '—'
                            : (nhanKhoangGia(gia.$1, gia.$2) ?? '—'),
                        style: QuanAnText.price,
                      ),
                    ],
                  ),
                  const Text(
                    'Tính từ món chính (không tính nhóm đồ uống / món thêm); quán chỉ bán đồ uống thì tính mọi món. Cập nhật khi menu đổi.',
                    style: QuanAnText.bodySmall,
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  Wrap(
                    spacing: QuanAnSpacing.sm,
                    runSpacing: QuanAnSpacing.sm,
                    children: [
                      FilledButton.icon(
                        onPressed: nhom.isEmpty || duMon
                            ? null
                            : () => _suaMon(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm món'),
                      ),
                      OutlinedButton.icon(
                        onPressed: duNhom ? null : () => _suaNhom(context),
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('Thêm nhóm'),
                      ),
                    ],
                  ),
                  if (nhom.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: QuanAnSpacing.sm),
                      child: Text(
                        'Hãy tạo nhóm món trước (ví dụ: Món chính, Đồ uống), rồi thêm món vào nhóm.',
                        style: QuanAnText.bodySmall,
                      ),
                    ),
                  if (duMon || duNhom)
                    Padding(
                      padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                      child: Text(
                        duMon
                            ? 'Đã đủ ${cfg.monToiDa} món, xóa bớt mới thêm được.'
                            : 'Đã đủ ${cfg.nhomMonToiDa} nhóm, xóa bớt mới thêm được.',
                        style: QuanAnText.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: QuanAnSpacing.cardGap),
            if (nhom.isEmpty && mon.isEmpty)
              const QuanAnEmptyState(
                icon: Icons.restaurant_menu_rounded,
                title: 'Menu còn trống',
                message: 'Thêm nhóm món đầu tiên, rồi thêm món.',
              ),
            for (final n in nhom) ...[
              _Nhom(
                nhom: n,
                mon: [
                  for (final m in mon)
                    if (m.nhomId == n.id) m,
                ],
                onSuaNhom: () => _suaNhom(context, n),
                onXoaNhom: () => _xoaNhom(context, n),
                onSuaMon: (m) => _suaMon(context, m),
                onXoaMon: (m) => _xoaMon(context, m),
                onBatTat: (m, v) => chayThaoTac(
                  context,
                  () => dv.menu.batTatMon(m.id, conHang: v),
                ),
              ),
              const SizedBox(height: QuanAnSpacing.cardGap),
            ],
            if (moCoi.isNotEmpty)
              _Nhom(
                nhom: null,
                mon: moCoi,
                onSuaNhom: null,
                onXoaNhom: null,
                onSuaMon: (m) => _suaMon(context, m),
                onXoaMon: (m) => _xoaMon(context, m),
                onBatTat: (m, v) => chayThaoTac(
                  context,
                  () => dv.menu.batTatMon(m.id, conHang: v),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Nhom extends StatelessWidget {
  const _Nhom({
    required this.nhom,
    required this.mon,
    required this.onSuaNhom,
    required this.onXoaNhom,
    required this.onSuaMon,
    required this.onXoaMon,
    required this.onBatTat,
  });

  final NhomMon? nhom;
  final List<MonAn> mon;
  final VoidCallback? onSuaNhom;
  final VoidCallback? onXoaNhom;
  final void Function(MonAn) onSuaMon;
  final void Function(MonAn) onXoaMon;
  final void Function(MonAn, bool) onBatTat;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nhom?.ten ?? 'Chưa phân nhóm',
                  style: QuanAnText.h3,
                ),
              ),
              if (nhom?.laDoUong ?? false)
                const Flexible(
                  child: QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.chung,
                    label: 'Đồ uống / món thêm',
                  ),
                ),
              if (onSuaNhom != null)
                IconButton(
                  tooltip: 'Sửa nhóm',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onSuaNhom,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (onXoaNhom != null)
                IconButton(
                  tooltip: 'Xóa nhóm',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onXoaNhom,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: QuanAnColors.danger,
                  ),
                ),
            ],
          ),
          if (mon.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: QuanAnSpacing.sm),
              child: Text('Nhóm chưa có món.', style: QuanAnText.bodySmall),
            ),
          for (final m in mon) ...[
            const Divider(),
            _DongMon(
              mon: m,
              onSua: () => onSuaMon(m),
              onXoa: () => onXoaMon(m),
              onBatTat: (v) => onBatTat(m, v),
            ),
          ],
        ],
      ),
    ),
  );
}

class _DongMon extends StatelessWidget {
  const _DongMon({
    required this.mon,
    required this.onSua,
    required this.onXoa,
    required this.onBatTat,
  });

  final MonAn mon;
  final VoidCallback onSua;
  final VoidCallback onXoa;
  final ValueChanged<bool> onBatTat;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QuanAnRadius.input),
                child: mon.anh.isEmpty
                    ? const ColoredBox(
                        color: QuanAnColors.primaryLight,
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: QuanAnColors.primary,
                        ),
                      )
                    : NetworkPhoto(mon.anh),
              ),
            ),
            const SizedBox(width: QuanAnSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mon.noiBat ? '⭐ ' : ''}${mon.ten}',
                    style: QuanAnText.label,
                  ),
                  Text(formatPrice(mon.gia), style: QuanAnText.price),
                  if (mon.coTuyChon)
                    Text(
                      'Tùy chọn: ${mon.tuyChon.map((t) => t.ten).join(', ')}${mon.coTuyChonBatBuoc ? ' (có mục bắt buộc)' : ''}',
                      style: QuanAnText.bodySmall,
                    ),
                  if (mon.moTa.isNotEmpty)
                    Text(
                      mon.moTa,
                      style: QuanAnText.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.xs),
        Wrap(
          spacing: QuanAnSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: mon.conHang, onChanged: onBatTat),
                Text(
                  mon.conHang ? 'Còn hàng' : 'Hết món',
                  style: QuanAnText.label.copyWith(
                    color: mon.conHang
                        ? QuanAnColors.success
                        : QuanAnColors.danger,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onSua,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Sửa'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: QuanAnColors.danger),
              onPressed: onXoa,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Xóa'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NhomDialog extends StatefulWidget {
  const _NhomDialog({this.nhom});

  final NhomMon? nhom;

  @override
  State<_NhomDialog> createState() => _NhomDialogState();
}

class _NhomDialogState extends State<_NhomDialog> {
  late final _ten = TextEditingController(text: widget.nhom?.ten ?? '');
  late bool _doUong = widget.nhom?.laDoUong ?? false;
  String? _loi;

  @override
  void dispose() {
    _ten.dispose();
    super.dispose();
  }

  void _luu() {
    final t = _ten.text.trim();
    if (t.isEmpty || t.length > 40) {
      setState(() => _loi = 'Tên nhóm 1–40 ký tự.');
      return;
    }
    Navigator.pop(context, (ten: t, doUong: _doUong));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.nhom == null ? 'Thêm nhóm món' : 'Sửa nhóm món'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ten,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _luu(),
            decoration: InputDecoration(
              labelText: 'Tên nhóm (Món chính, Đồ uống...)',
              errorText: _loi,
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _doUong,
            onChanged: (v) => setState(() => _doUong = v ?? false),
            title: const Text('Nhóm đồ uống / món thêm'),
            subtitle: const Text('Không tính vào mức giá của quán'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton(onPressed: _luu, child: const Text('Lưu')),
    ],
  );
}

// ---------------------------------------------------------------------------
// Màn sửa một món
// ---------------------------------------------------------------------------

class _LuaChonForm {
  _LuaChonForm({String ten = '', num giaThem = 0})
    : ten = TextEditingController(text: ten),
      gia = TextEditingController(
        text: giaThem == 0 ? '' : '${giaThem.round()}',
      );

  final TextEditingController ten;
  final TextEditingController gia;

  void dispose() {
    ten.dispose();
    gia.dispose();
  }
}

class _NhomTuyChonForm {
  _NhomTuyChonForm({
    String ten = '',
    this.batBuoc = false,
    this.chonNhieu = false,
    int toiDa = 2,
    List<_LuaChonForm>? lua,
  }) : ten = TextEditingController(text: ten),
       toiDa = TextEditingController(text: '$toiDa'),
       lua = lua ?? [_LuaChonForm()];

  factory _NhomTuyChonForm.tu(NhomTuyChon n) => _NhomTuyChonForm(
    ten: n.ten,
    batBuoc: n.batBuoc,
    chonNhieu: n.chonNhieu,
    toiDa: n.chonNhieu ? n.toiDa : 2,
    lua: [for (final l in n.lua) _LuaChonForm(ten: l.ten, giaThem: l.giaThem)],
  );

  final TextEditingController ten;
  bool batBuoc;
  bool chonNhieu;
  final TextEditingController toiDa;
  final List<_LuaChonForm> lua;

  void dispose() {
    ten.dispose();
    toiDa.dispose();
    for (final l in lua) {
      l.dispose();
    }
  }
}

class _MonEditorScreen extends StatefulWidget {
  const _MonEditorScreen({
    required this.dv,
    required this.quanId,
    required this.cfg,
    required this.mon,
    required this.nhom,
    required this.soNoiBatKhac,
    required this.thuTuMoi,
  });

  final QuanAnDichVu dv;
  final String quanId;
  final QuanAnConfig cfg;
  final MonAn? mon;
  final List<NhomMon> nhom;
  final int soNoiBatKhac;
  final int thuTuMoi;

  @override
  State<_MonEditorScreen> createState() => _MonEditorScreenState();
}

class _MonEditorScreenState extends State<_MonEditorScreen> {
  late final _ten = TextEditingController(text: widget.mon?.ten ?? '');
  late final _gia = TextEditingController(
    text: widget.mon == null ? '' : '${widget.mon!.gia.round()}',
  );
  late final _moTa = TextEditingController(text: widget.mon?.moTa ?? '');
  late String? _nhomId = () {
    final id = widget.mon?.nhomId;
    if (id != null && widget.nhom.any((n) => n.id == id)) return id;
    return widget.nhom.isEmpty ? null : widget.nhom.first.id;
  }();
  late List<String> _anh = [
    if (widget.mon != null && widget.mon!.anh.isNotEmpty) widget.mon!.anh,
  ];
  late bool _noiBat = widget.mon?.noiBat ?? false;
  late bool _conHang = widget.mon?.conHang ?? true;
  late final List<_NhomTuyChonForm> _tuyChon = [
    for (final t in widget.mon?.tuyChon ?? const <NhomTuyChon>[])
      _NhomTuyChonForm.tu(t),
  ];
  List<String> _loi = const [];
  bool _dangLuu = false;

  @override
  void dispose() {
    _ten.dispose();
    _gia.dispose();
    _moTa.dispose();
    for (final t in _tuyChon) {
      t.dispose();
    }
    super.dispose();
  }

  List<String> _kiemTra() {
    final l = <String>[];
    final c = widget.cfg;
    final t = _ten.text.trim().length;
    if (t < c.tenMonToiThieu || t > c.tenMonToiDa) {
      l.add('Tên món ${c.tenMonToiThieu}–${c.tenMonToiDa} ký tự.');
    }
    if ((int.tryParse(_gia.text.trim()) ?? 0) <= 0) {
      l.add('Giá món phải lớn hơn 0.');
    }
    if (_nhomId == null) l.add('Chọn nhóm món.');
    if (_noiBat && widget.soNoiBatKhac >= c.monNoiBatToiDa) {
      l.add(
        'Chỉ được tối đa ${c.monNoiBatToiDa} món nổi bật. Bỏ ⭐ ở món khác trước.',
      );
    }
    for (var i = 0; i < _tuyChon.length; i++) {
      final n = _tuyChon[i];
      final ten = n.ten.text.trim();
      final nhan = 'Tùy chọn ${i + 1}${ten.isEmpty ? '' : ' ("$ten")'}';
      if (ten.isEmpty) l.add('$nhan: nhập tên nhóm (Cỡ, Topping...).');
      final lua = [
        for (final x in n.lua)
          if (x.ten.text.trim().isNotEmpty || x.gia.text.trim().isNotEmpty) x,
      ];
      if (lua.isEmpty) l.add('$nhan: thêm ít nhất một lựa chọn.');
      for (final x in lua) {
        if (x.ten.text.trim().isEmpty) {
          l.add('$nhan: có lựa chọn chưa đặt tên.');
          break;
        }
      }
      final tenLua = lua.map((x) => x.ten.text.trim()).toList();
      if (tenLua.toSet().length != tenLua.length) {
        l.add('$nhan: có hai lựa chọn trùng tên.');
      }
      if (n.chonNhieu) {
        final td = int.tryParse(n.toiDa.text.trim()) ?? 0;
        if (td < 2 || (lua.isNotEmpty && td > lua.length)) {
          l.add(
            '$nhan: số lựa chọn tối đa từ 2 đến ${lua.length < 2 ? 2 : lua.length}.',
          );
        }
      }
    }
    return l;
  }

  MonAn _dung() => MonAn(
    id: widget.mon?.id ?? '',
    quanId: widget.quanId,
    nhomId: _nhomId!,
    chuQuanId: widget.dv.uid,
    ten: _ten.text.trim(),
    moTa: _moTa.text.trim(),
    gia: int.parse(_gia.text.trim()),
    anh: _anh.isEmpty ? '' : _anh.first,
    noiBat: _noiBat,
    conHang: _conHang,
    thuTu: widget.mon?.thuTu ?? widget.thuTuMoi,
    tuyChon: [
      for (final n in _tuyChon)
        NhomTuyChon(
          ten: n.ten.text.trim(),
          batBuoc: n.batBuoc,
          toiDa: n.chonNhieu ? int.parse(n.toiDa.text.trim()) : 1,
          lua: [
            for (final x in n.lua)
              if (x.ten.text.trim().isNotEmpty)
                LuaChon(
                  ten: x.ten.text.trim(),
                  giaThem: int.tryParse(x.gia.text.trim()) ?? 0,
                ),
          ],
        ),
    ],
  );

  Future<void> _luu() async {
    final l = _kiemTra();
    setState(() => _loi = l);
    if (l.isNotEmpty) return;
    setState(() => _dangLuu = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.menu.luuMon(_dung()),
      thanhCong: widget.mon == null ? 'Đã thêm món' : 'Đã lưu món',
    );
    if (!mounted) return;
    setState(() => _dangLuu = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.mon == null ? 'Thêm món' : 'Sửa món')),
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
                  TextField(
                    controller: _ten,
                    maxLength: widget.cfg.tenMonToiDa,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText:
                          'Tên món (${widget.cfg.tenMonToiThieu}–${widget.cfg.tenMonToiDa} ký tự)',
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _nhomId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Nhóm món'),
                    items: [
                      for (final n in widget.nhom)
                        DropdownMenuItem(
                          value: n.id,
                          child: Text(n.ten, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _nhomId = v),
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                  TextField(
                    controller: _gia,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Giá (đồng)',
                      suffixText: 'đ',
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                  TextField(
                    controller: _moTa,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (không bắt buộc)',
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.sm),
                  QuanAnMediaField(
                    storage: widget.dv.storage,
                    folder: 'quan_an_mon',
                    nhan: 'Ảnh món',
                    goiY: 'Nên có ảnh để khách dễ chọn món. Đồ án: dán link hoặc tải lên.',
                    toiDa: 1,
                    giaTri: _anh,
                    onChanged: (v) => setState(() => _anh = v),
                    pickImages: widget.dv.pickImages,
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _noiBat,
                    onChanged: (v) => setState(() => _noiBat = v),
                    title: const Text('⭐ Món nổi bật'),
                    subtitle: Text(
                      'Hiện đầu menu. Tối đa ${widget.cfg.monNoiBatToiDa} món (đang có ${widget.soNoiBatKhac} món khác).',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _conHang,
                    onChanged: (v) => setState(() => _conHang = v),
                    title: Text(_conHang ? 'Còn hàng' : 'Hết món'),
                    subtitle: const Text('Hết món thì khách không đặt được'),
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  const Text('Tùy chọn', style: QuanAnText.h3),
                  const SizedBox(height: QuanAnSpacing.xs),
                  const Text(
                    'Ví dụ: Cỡ (Nhỏ / Lớn +5.000đ), Topping (thêm trứng +5.000đ).',
                    style: QuanAnText.bodySmall,
                  ),
                  const SizedBox(height: QuanAnSpacing.sm),
                  for (var i = 0; i < _tuyChon.length; i++) ...[
                    _KhoiTuyChon(
                      form: _tuyChon[i],
                      onDoi: () => setState(() {}),
                      onXoa: () =>
                          setState(() => _tuyChon.removeAt(i).dispose()),
                    ),
                    const SizedBox(height: QuanAnSpacing.sm),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _tuyChon.add(_NhomTuyChonForm())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm nhóm tùy chọn'),
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
            onPressed: _dangLuu ? null : _luu,
            child: Text(_dangLuu ? 'Đang lưu...' : 'Lưu món'),
          ),
        ),
      ],
    ),
  );
}

class _KhoiTuyChon extends StatelessWidget {
  const _KhoiTuyChon({
    required this.form,
    required this.onDoi,
    required this.onXoa,
  });

  final _NhomTuyChonForm form;
  final VoidCallback onDoi;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) => Card(
    color: QuanAnColors.background,
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: form.ten,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm tùy chọn (Cỡ, Topping...)',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Xóa nhóm tùy chọn',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onXoa,
                icon: const Icon(
                  Icons.delete_outline,
                  color: QuanAnColors.danger,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: form.batBuoc,
            onChanged: (v) {
              form.batBuoc = v;
              onDoi();
            },
            title: const Text('Bắt buộc chọn'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: form.chonNhieu,
            onChanged: (v) {
              form.chonNhieu = v;
              onDoi();
            },
            title: Text(form.chonNhieu ? 'Chọn nhiều' : 'Chọn một'),
          ),
          if (form.chonNhieu)
            TextField(
              controller: form.toiDa,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Chọn tối đa mấy lựa chọn',
              ),
            ),
          const SizedBox(height: QuanAnSpacing.sm),
          const Text('Các lựa chọn', style: QuanAnText.label),
          for (var i = 0; i < form.lua.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: form.lua[i].ten,
                      decoration: const InputDecoration(labelText: 'Lựa chọn'),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: form.lua[i].gia,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Cộng thêm',
                        suffixText: 'đ',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xóa lựa chọn',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: form.lua.length <= 1
                        ? null
                        : () {
                            form.lua.removeAt(i).dispose();
                            onDoi();
                          },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                form.lua.add(_LuaChonForm());
                onDoi();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm lựa chọn'),
            ),
          ),
        ],
      ),
    ),
  );
}
