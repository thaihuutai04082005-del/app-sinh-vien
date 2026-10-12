import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/don_mon.dart';
import '../../models/quan_an_config.dart';
import '../../models/thanh_toan.dart';
import '../../models/tin_nhan.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'admin_chung.dart';

/// Loại việc admin đang xử lý trên một đơn.
enum _Viec { khieuNai, phanDoi, quaHan, luaDao, daXong }

_Viec _viecCua(DonMon d) {
  if (d.status == 'disputed') {
    final phanDoi =
        d.khieuNai?.loai == 'phan_doi_khong_nhan' ||
        (d.khongNhan?.phanDoi ?? false);
    return phanDoi ? _Viec.phanDoi : _Viec.khieuNai;
  }
  if (d.ruaSoatLuaDao && DonMon.dangChay.contains(d.status)) {
    return _Viec.luaDao;
  }
  if (d.coQuaHan && (d.status == 'ready' || d.status == 'delivering')) {
    return _Viec.quaHan;
  }
  return _Viec.daXong;
}

String _thoiHan(int phut) =>
    phut % 60 == 0 ? '${phut ~/ 60} giờ' : '$phut phút';

/// QA-AD-02 Khiếu nại đơn · phản đối "khách không nhận" · đơn quá hạn chưa có bằng chứng ·
/// đơn cần rà soát do quán bị kết luận lừa đảo (mục 3.5b, 3.5d, 3.12, 3.14).
/// Xem bằng chứng hai bên rồi chọn một quyết định hợp lệ cho loại việc; bắt buộc ghi lý do.
class KhieuNaiDonAdminScreen extends StatelessWidget {
  const KhieuNaiDonAdminScreen({
    required this.dv,
    required this.donId,
    super.key,
  });

  final QuanAnDichVu dv;
  final String donId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xử lý đơn')),
    body: QuanAnStream<DonMon?>(
      stream: () => dv.donMon.donMon(donId),
      builder: (context, d) => d == null
          ? const QuanAnEmptyState(title: 'Không tìm thấy đơn')
          : _NoiDung(dv: dv, don: d),
    ),
  );
}

class _NoiDung extends StatefulWidget {
  const _NoiDung({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  String? _chon;
  bool _tinhBomHang = true;
  final _lyDo = TextEditingController();
  final _soTien = TextEditingController();
  bool _dangGui = false;
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh().catchError(
    (_) => const QuanAnConfig(),
  );

  DonMon get _d => widget.don;
  _Viec get _viec => _viecCua(_d);

  @override
  void dispose() {
    _lyDo.dispose();
    _soTien.dispose();
    super.dispose();
  }

  // ---- Các quyết định hợp lệ theo từng loại việc ----
  List<AdminLuaChon<String>> get _luaChon {
    final app = _d.traApp;
    final k = _d.khieuNai;
    switch (_viec) {
      case _Viec.khieuNai:
        if (!app) {
          // Đơn tiền mặt: không có tiền để hoàn hay chuyển, chỉ xác minh giao nhận.
          return const [
            AdminLuaChon(
              'da_giao',
              'Đã giao / nhận thành công',
              moTa: 'Đơn hoàn tất, được đánh dấu đã xác minh.',
            ),
            AdminLuaChon(
              'khong_giao',
              'Không giao được',
              moTa: 'Đơn chuyển thành "Quán hủy".',
            ),
          ];
        }
        final xacMinh =
            k?.loai == 'chua_nhan_mon' ||
            k?.loai == 'xac_minh' ||
            k?.lyDo == 'khong_nhan_duoc';
        return [
          const AdminLuaChon(
            'hoan_toan',
            'Hoàn toàn phần',
            moTa: 'Hoàn 100% tổng đơn cho sinh viên.',
          ),
          const AdminLuaChon(
            'hoan_mot_phan',
            'Hoàn một phần',
            moTa: 'Hoàn số tiền nhập bên dưới, phần còn lại chuyển cho quán.',
          ),
          const AdminLuaChon(
            'chuyen_cho_quan',
            'Chuyển tiền cho quán',
            moTa: 'Bác khiếu nại, quán nhận đủ tiền.',
          ),
          if (xacMinh)
            const AdminLuaChon(
              'da_giao',
              'Đã giao / nhận thành công',
              moTa: 'Chuyển tiền cho quán, đơn được đánh dấu đã xác minh.',
            ),
        ];
      case _Viec.phanDoi:
        return app
            ? const [
                AdminLuaChon(
                  'hoan_toan',
                  'Chấp nhận phản đối',
                  moTa: 'Hoàn tiền cho sinh viên, KHÔNG tính bom hàng.',
                ),
                AdminLuaChon(
                  'chuyen_cho_quan',
                  'Bác phản đối',
                  moTa: 'Chuyển tiền cho quán; có thể tính 1 lần bom hàng cho sinh viên.',
                ),
              ]
            : const [
                AdminLuaChon(
                  'khong_giao',
                  'Chấp nhận phản đối',
                  moTa: 'Đơn chuyển thành "Quán hủy", không tính bom hàng (không có tiền hoàn).',
                ),
                AdminLuaChon(
                  'da_giao',
                  'Bác phản đối',
                  moTa:
                      'Đơn hoàn tất; có thể tính 1 lần bom hàng cho sinh viên.',
                ),
              ];
      case _Viec.quaHan:
        return app
            ? const [
                AdminLuaChon(
                  'hoan_toan',
                  'Không giao được: hoàn 100%',
                  moTa: 'Hoàn toàn bộ tiền cho sinh viên.',
                ),
                AdminLuaChon(
                  'chuyen_cho_quan',
                  'Đã giao thật: chuyển tiền cho quán',
                  moTa: 'Quán nhận tiền, đơn được đánh dấu đã xác minh.',
                ),
              ]
            : const [
                AdminLuaChon(
                  'da_giao',
                  'Đã giao: hoàn tất',
                  moTa: 'Đơn chuyển thành "Hoàn tất", đã xác minh.',
                ),
                AdminLuaChon(
                  'khong_giao',
                  'Không giao được: quán hủy',
                  moTa: 'Đơn chuyển thành "Quán hủy".',
                ),
              ];
      case _Viec.luaDao:
        return [
          const AdminLuaChon(
            'da_giao',
            'Đã giao thật: hoàn tất theo luật',
            moTa: 'Đơn hoàn tất, được đánh dấu đã xác minh.',
          ),
          AdminLuaChon(
            'khong_giao',
            'Bằng chứng giả / không giao',
            moTa: app
                ? 'Hoàn 100% cho sinh viên.'
                : 'Đơn chuyển thành "Quán hủy".',
          ),
          const AdminLuaChon(
            'giu_tien',
            'Chưa đủ căn cứ: giữ tiền như tranh chấp',
            moTa: 'Đơn chuyển sang "Đang khiếu nại", tiền tiếp tục được giữ.',
          ),
        ];
      case _Viec.daXong:
        return const [];
    }
  }

  /// Phản đối bị bác (quán nhận tiền / đơn hoàn tất) thì được chọn có tính bom hàng.
  bool get _hienBomHang =>
      _viec == _Viec.phanDoi &&
      (_chon == 'chuyen_cho_quan' || _chon == 'da_giao');

  int? get _soTienHoan {
    final n = int.tryParse(_soTien.text.trim());
    return n;
  }

  String? get _loiSoTien {
    if (_chon != 'hoan_mot_phan' || _soTien.text.trim().isEmpty) return null;
    final n = _soTienHoan;
    if (n == null || n <= 0 || n >= _d.tong) {
      return 'Nhập số tiền lớn hơn 0 và nhỏ hơn tổng đơn (${formatPrice(_d.tong)})';
    }
    return null;
  }

  bool get _duDieuKien {
    if (_chon == null || _lyDo.text.trim().isEmpty || _dangGui) return false;
    if (_chon == 'hoan_mot_phan') {
      final n = _soTienHoan;
      return n != null && n > 0 && n < _d.tong;
    }
    return true;
  }

  Map<String, dynamic> _su() {
    final lyDo = _lyDo.text.trim();
    switch (_viec) {
      case _Viec.khieuNai:
        return {
          'loai': 'ADMIN_QUYET',
          'quyetDinh': _chon,
          if (_chon == 'hoan_mot_phan') 'soTienHoan': _soTienHoan,
          'lyDo': lyDo,
        };
      case _Viec.phanDoi:
        return {
          'loai': 'ADMIN_QUYET',
          'quyetDinh': _chon,
          'tinhBomHang': _hienBomHang && _tinhBomHang,
          'lyDo': lyDo,
        };
      case _Viec.quaHan:
        return {'loai': 'ADMIN_QUA_HAN', 'quyetDinh': _chon, 'lyDo': lyDo};
      case _Viec.luaDao:
        return {'loai': 'ADMIN_LUA_DAO', 'quyetDinh': _chon, 'lyDo': lyDo};
      case _Viec.daXong:
        return const {};
    }
  }

  String? get _nhanLuaChon =>
      _luaChon.where((l) => l.gia == _chon).firstOrNull?.nhan;

  Future<void> _gui() async {
    final dongY = await xacNhan(
      context,
      tieuDe: 'Gửi quyết định?',
      noiDung:
          'Quyết định: ${_nhanLuaChon ?? ''}.'
          '${_chon == 'hoan_mot_phan' ? ' Hoàn ${formatPrice(_soTienHoan ?? 0)}.' : ''}'
          '${_hienBomHang && _tinhBomHang ? ' Tính 1 lần bom hàng cho sinh viên.' : ''}'
          '\nQuyết định được ghi nhật ký và không hoàn tác được.',
      dongY: 'Gửi quyết định',
    );
    if (!dongY || !mounted) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.admin.thaoTacDon(_d.id, _d.version, _su()),
      thanhCong: 'Đã quyết định',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final k = d.khieuNai;
    return AdminTrang(
      children: [
        _TieuDe(don: d, viec: _viec, cfg: _cfg),
        LayoutBuilder(
          builder: (context, c) {
            final sv = _BangChungSinhVien(don: d);
            final quan = _BangChungQuan(don: d);
            return c.maxWidth >= 700
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: sv),
                      const SizedBox(width: QuanAnSpacing.cardGap),
                      Expanded(child: quan),
                    ],
                  )
                : Column(
                    children: [
                      sv,
                      const SizedBox(height: QuanAnSpacing.cardGap),
                      quan,
                    ],
                  );
          },
        ),
        _BangChungGiao(don: d),
        _DonHang(dv: widget.dv, don: d),
        _DongThoiGian(don: d),
        _XemChat(dv: widget.dv, don: d),
        if (_viec == _Viec.daXong)
          const QuanAnEmptyState(
            icon: Icons.task_alt,
            title: 'Đơn không còn việc chờ xử lý',
            message: 'Đơn này đã được xử lý hoặc không còn cờ nào cần admin.',
          )
        else
          AdminMuc(
            tieuDe: 'Quyết định của admin',
            bieuTuong: Icons.gavel_outlined,
            children: [
              if (!_d.traApp)
                const Padding(
                  padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                  child: Text(
                    'Đơn tiền mặt: không có khoản tiền qua app nên không có lựa '
                    'chọn hoàn tiền hay chuyển tiền.',
                    style: QuanAnText.bodySmall,
                  ),
                ),
              if (_viec == _Viec.luaDao)
                const Padding(
                  padding: EdgeInsets.only(bottom: QuanAnSpacing.md),
                  child: QuanAnWarningBox(
                    message:
                        'Xét riêng đơn này theo bằng chứng của chính nó (mã / ảnh '
                        'GPS, chat, thời gian, vị trí, phản hồi sinh viên, dấu hiệu '
                        'gian lận). Không mặc định coi bằng chứng cũ là thật, cũng '
                        'không mặc định là giả.',
                  ),
                ),
              AdminLuaChonNhom<String>(
                cacLuaChon: _luaChon,
                giaTri: _chon,
                onChanged: (v) => setState(() => _chon = v),
              ),
              if (_chon == 'hoan_mot_phan') ...[
                const SizedBox(height: QuanAnSpacing.xs),
                TextField(
                  controller: _soTien,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Số tiền hoàn (đồng)',
                    helperText: 'Nhỏ hơn tổng đơn ${formatPrice(d.tong)}',
                    errorText: _loiSoTien,
                  ),
                ),
              ],
              if (_hienBomHang)
                CheckboxListTile(
                  value: _tinhBomHang,
                  onChanged: (v) => setState(() => _tinhBomHang = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tính 1 lần bom hàng cho sinh viên',
                    style: QuanAnText.body,
                  ),
                  subtitle: const Text(
                    'Hai lần: mất quyền tiền mặt. Ba lần: khóa đặt món. '
                    'Sinh viên được kháng nghị.',
                    style: QuanAnText.bodySmall,
                  ),
                ),
              const SizedBox(height: QuanAnSpacing.md),
              AdminLyDoField(
                controller: _lyDo,
                onChanged: () => setState(() {}),
              ),
              if (k?.coKhan ?? false) ...[
                const SizedBox(height: QuanAnSpacing.sm),
                const Text(
                  'Khiếu nại này đang treo quá hạn: ưu tiên xử lý. Hệ thống '
                  'không tự chuyển tiền khi đang khiếu nại.',
                  style: QuanAnText.bodySmall,
                ),
              ],
              const SizedBox(height: QuanAnSpacing.lg),
              FilledButton(
                onPressed: _duDieuKien ? _gui : null,
                child: const Text('Gửi quyết định'),
              ),
            ],
          ),
      ],
    );
  }
}

class _TieuDe extends StatelessWidget {
  const _TieuDe({required this.don, required this.viec, required this.cfg});

  final DonMon don;
  final _Viec viec;
  final Future<QuanAnConfig> cfg;

  String _gioiThieu(QuanAnConfig c) => switch (viec) {
    _Viec.khieuNai => 'Sinh viên khiếu nại / báo chưa nhận được món. Xem bằng chứng hai bên rồi quyết định.',
    _Viec.phanDoi =>
      'Quán báo "khách không nhận" (chỉ là báo cáo của quán, chưa phải kết luận). '
          'Sinh viên đã phản đối trong hạn ${_thoiHan(c.phanDoiPhut)}.',
    _Viec.quaHan =>
      'Quá ${_thoiHan(c.quaHanPhut)} chưa có bằng chứng giao / nhận và hai bên không xử lý.',
    _Viec.luaDao => 'Quán bị kết luận lừa đảo. Đơn được giữ tiền và gắn cờ để xét riêng từng đơn.',
    _Viec.daXong => '',
  };

  @override
  Widget build(BuildContext context) {
    final d = don;
    final k = d.khieuNai;
    return AdminMuc(
      tieuDe: d.tenQuan.isEmpty ? 'Đơn món' : d.tenQuan,
      bieuTuong: Icons.receipt_long_outlined,
      children: [
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          children: [
            QuanAnStatusBadge(
              kind: QuanAnBadgeKind.canhBao,
              label: d.trangThaiLabel,
            ),
            QuanAnStatusBadge(
              kind: d.traApp ? QuanAnBadgeKind.chung : QuanAnBadgeKind.nhan,
              label: d.traApp ? 'Trả trên app' : 'Tiền mặt',
            ),
            if (k?.coKhan ?? false)
              const QuanAnStatusBadge(
                kind: QuanAnBadgeKind.dongCua,
                label: 'Cờ khẩn',
              ),
            if (d.ruaSoatLuaDao)
              const QuanAnStatusBadge(
                kind: QuanAnBadgeKind.dongCua,
                label: 'Rà soát lừa đảo',
              ),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.md),
        AdminDong('Tổng đơn', formatPrice(d.tong)),
        AdminDong('Cách nhận', d.cachNhanLabel),
        AdminDong('Số điện thoại', d.svSdt),
        if (viec != _Viec.daXong)
          FutureBuilder<QuanAnConfig>(
            future: cfg,
            initialData: const QuanAnConfig(),
            builder: (context, s) => Padding(
              padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
              child: Text(
                _gioiThieu(s.data ?? const QuanAnConfig()),
                style: QuanAnText.body,
              ),
            ),
          ),
      ],
    );
  }
}

class _BangChungSinhVien extends StatelessWidget {
  const _BangChungSinhVien({required this.don});

  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final k = don.khieuNai;
    final kn = don.khongNhan;
    return AdminMuc(
      tieuDe: 'Phía sinh viên',
      bieuTuong: Icons.person_outline,
      children: [
        if (k == null && kn == null)
          const Text('Sinh viên chưa gửi gì.', style: QuanAnText.bodySmall),
        if (k != null) ...[
          AdminDong('Loại', k.loaiLabel),
          if (k.lyDo.isNotEmpty) AdminDong('Lý do', k.lyDoLabel),
          AdminDong('Mô tả', k.moTa),
          if (k.luc != null) AdminDong('Gửi lúc', formatNgayGio(k.luc!)),
          const SizedBox(height: QuanAnSpacing.xs),
          AdminAnh(k.anh, khiRong: 'Không đính kèm ảnh'),
        ],
        if (kn != null && kn.phanDoi) ...[
          const Divider(height: QuanAnSpacing.xl),
          const Text('Phản đối "khách không nhận"', style: QuanAnText.label),
          AdminDong('Mô tả', kn.moTaPhanDoi ?? ''),
          if (kn.phanDoiLuc != null)
            AdminDong('Phản đối lúc', formatNgayGio(kn.phanDoiLuc!)),
        ],
      ],
    );
  }
}

class _BangChungQuan extends StatelessWidget {
  const _BangChungQuan({required this.don});

  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final k = don.khieuNai;
    final kn = don.khongNhan;
    return AdminMuc(
      tieuDe: 'Phía quán',
      bieuTuong: Icons.storefront_outlined,
      children: [
        if (k != null) ...[
          AdminDong(
            'Trả lời',
            k.chuTraLoi ?? 'Chưa trả lời (quá hạn thì quyết theo bằng chứng của sinh viên)',
          ),
          if (k.deNghiHoan != null)
            AdminDong(
              'Quán đề nghị',
              quyetDinhKhieuNaiLabels[k.deNghiHoan] ?? k.deNghiHoan!,
            ),
          if (k.chuTraLoiLuc != null)
            AdminDong('Trả lời lúc', formatNgayGio(k.chuTraLoiLuc!)),
        ],
        if (kn != null) ...[
          if (k != null) const Divider(height: QuanAnSpacing.xl),
          const Text('Quán báo "khách không nhận"', style: QuanAnText.label),
          AdminDong('Báo lúc', formatNgayGio(kn.luc)),
          const SizedBox(height: QuanAnSpacing.xs),
          AdminAnh([if (kn.anh.isNotEmpty) kn.anh], khiRong: 'Không có ảnh'),
          if (kn.viTri != null)
            AdminDong(
              'GPS',
              '${kn.viTri!.latitude.toStringAsFixed(5)}, ${kn.viTri!.longitude.toStringAsFixed(5)}',
            ),
        ],
        if (k == null && kn == null)
          const Text('Quán chưa gửi gì.', style: QuanAnText.bodySmall),
      ],
    );
  }
}

class _BangChungGiao extends StatelessWidget {
  const _BangChungGiao({required this.don});

  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final d = don;
    final a = d.anhGiao;
    return AdminMuc(
      tieuDe: 'Bằng chứng giao / nhận',
      bieuTuong: Icons.verified_outlined,
      children: [
        if (!d.coBangChung && a == null)
          const Text(
            'Chưa có bằng chứng giao / nhận (mã nhận món hoặc ảnh giao GPS).',
            style: TextStyle(color: QuanAnColors.danger),
          ),
        if (d.coBangChung)
          AdminDong(
            'Bằng chứng',
            '${d.bangChungLoai == 'ma' ? 'Quán nhập đúng mã nhận món' : 'Quán chụp ảnh giao có GPS'} '
                'lúc ${formatNgayGio(d.bangChungLuc!)}',
          ),
        if (a != null) ...[
          const SizedBox(height: QuanAnSpacing.xs),
          AdminAnh([if (a.url.isNotEmpty) a.url]),
          if (a.viTri != null)
            AdminDong(
              'GPS ảnh giao',
              '${a.viTri!.latitude.toStringAsFixed(5)}, ${a.viTri!.longitude.toStringAsFixed(5)}',
            ),
          if (a.khoangCachM != null)
            AdminDong(
              'Cách điểm giao',
              formatKhoangCach(a.khoangCachM!.toDouble()),
            ),
        ],
        if (d.diaChiGiao != null && d.diaChiGiao!.dong.isNotEmpty)
          AdminDong('Địa chỉ giao', d.diaChiGiao!.dong),
      ],
    );
  }
}

class _DonHang extends StatelessWidget {
  const _DonHang({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final d = don;
    return AdminMuc(
      tieuDe: 'Đơn hàng',
      bieuTuong: Icons.restaurant_menu,
      children: [
        for (final m in d.monAn)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${m.soLuong} × ${m.ten}'
                    '${m.tuyChonMoTa.isEmpty ? '' : '\n${m.tuyChonMoTa}'}',
                    style: QuanAnText.body,
                  ),
                ),
                const SizedBox(width: QuanAnSpacing.sm),
                Text(formatPrice(m.thanhTien), style: QuanAnText.body),
              ],
            ),
          ),
        const Divider(height: QuanAnSpacing.xl),
        AdminDong('Tiền món', formatPrice(d.tienMon)),
        if (d.giamCombo + d.giamGia > 0)
          AdminDong('Giảm', '-${formatPrice(d.giamCombo + d.giamGia)}'),
        if (d.phiGiao > 0) AdminDong('Phí giao', formatPrice(d.phiGiao)),
        AdminDong('Tổng', formatPrice(d.tong)),
        AdminDong('Thanh toán', cachTraLabels[d.cachTra] ?? d.cachTra),
        if (d.traApp)
          StreamBuilder<KhoanTien?>(
            stream: dv.donMon.khoanTien(d.id),
            builder: (context, s) {
              if (s.hasError) {
                return const AdminDong(
                  'Khoản tiền',
                  'Không tải được khoản tiền',
                  mau: QuanAnColors.danger,
                );
              }
              if (s.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: LinearProgressIndicator(),
                );
              }
              final t = s.data;
              return AdminDong(
                'Khoản tiền',
                t == null
                    ? 'Chưa có khoản tiền'
                    : '${KhoanTien.labels[t.trangThai] ?? t.trangThai} · ${formatPrice(t.soTien)}',
              );
            },
          ),
      ],
    );
  }
}

class _DongThoiGian extends StatelessWidget {
  const _DongThoiGian({required this.don});

  final DonMon don;

  @override
  Widget build(BuildContext context) {
    final ls = don.lichSu;
    return AdminMuc(
      tieuDe: 'Dòng thời gian',
      bieuTuong: Icons.timeline,
      children: [
        if (ls.isEmpty)
          const Text('Chưa có mốc nào được ghi.', style: QuanAnText.bodySmall),
        for (final m in ls)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: QuanAnSpacing.sm),
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: QuanAnColors.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trangThaiDonLabels[m.trangThai] ?? m.trangThai,
                        style: QuanAnText.label,
                      ),
                      if (m.luc != null)
                        Text(
                          formatNgayGio(m.luc!),
                          style: QuanAnText.bodySmall,
                        ),
                      if (m.ghiChu.isNotEmpty)
                        Text(m.ghiChu, style: QuanAnText.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Xem (chỉ đọc) cuộc chat giữa sinh viên và quán của đơn; hoặc nhắn riêng từng bên.
class _XemChat extends StatefulWidget {
  const _XemChat({required this.dv, required this.don});

  final QuanAnDichVu dv;
  final DonMon don;

  @override
  State<_XemChat> createState() => _XemChatState();
}

class _XemChatState extends State<_XemChat> {
  bool _mo = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.don;
    final chatId = CuocChat.maCuoc(d.svId, d.chuQuanId);
    return AdminMuc(
      tieuDe: 'Chat sinh viên – quán',
      bieuTuong: Icons.chat_bubble_outline,
      children: [
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _mo = !_mo),
              icon: Icon(_mo ? Icons.expand_less : Icons.expand_more),
              label: Text(_mo ? 'Ẩn chat' : 'Xem chat'),
            ),
            TextButton(
              onPressed: () => QuanAnDieuHuong.chat(
                context,
                widget.dv,
                d.svId,
                quanId: d.quanId,
                donId: d.id,
              ),
              child: const Text('Nhắn sinh viên'),
            ),
            TextButton(
              onPressed: () => QuanAnDieuHuong.chat(
                context,
                widget.dv,
                d.chuQuanId,
                quanId: d.quanId,
                donId: d.id,
              ),
              child: const Text('Nhắn quán'),
            ),
          ],
        ),
        if (_mo)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.md),
            child: QuanAnStream<List<TinNhan>>(
              stream: () => widget.dv.chat.tinNhan(chatId),
              thongBaoLoi: 'Không tải được chat',
              dangTai: const LinearProgressIndicator(),
              builder: (context, ds) {
                if (ds.isEmpty) {
                  return const Text(
                    'Hai bên chưa nhắn gì.',
                    style: QuanAnText.bodySmall,
                  );
                }
                final gan = ds.length > 30 ? ds.sublist(ds.length - 30) : ds;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in gan)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: QuanAnSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.nguoiGui == d.svId ? 'Sinh viên' : 'Quán'}'
                              '${t.guiLuc == null ? '' : ' · ${formatNgayGio(t.guiLuc!)}'}',
                              style: QuanAnText.bodySmall,
                            ),
                            if (t.loai == 'anh')
                              AdminAnh([t.noiDung], kichThuoc: 72)
                            else if (t.loai == 'the_tin')
                              Text(
                                '[Thẻ] ${t.theTin?.tieuDe ?? ''}',
                                style: QuanAnText.body,
                              )
                            else
                              Text(
                                t.noiDung,
                                style: QuanAnText.body.copyWith(
                                  color: t.coCanhBao
                                      ? QuanAnColors.danger
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
