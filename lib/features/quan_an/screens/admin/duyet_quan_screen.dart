import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../../../shared/widgets/location_map.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/admin_quan_an_service.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'admin_chung.dart';
import 'dinh_chi_quan_screen.dart';

/// Nhãn các trường có thể nằm trong bản chỉnh sửa.
const _nhanTruong = {
  'ten': 'Tên quán',
  'loaiQuan': 'Loại quán',
  'loaiMon': 'Món chính',
  'moTa': 'Mô tả',
  'sdt': 'Số điện thoại',
  'diaChi': 'Địa chỉ',
  'phuong': 'Phường / xã',
  'viTri': 'Ghim bản đồ',
  'luuDong': 'Bán lưu động',
  'ghiChuViTri': 'Ghi chú vị trí',
  'gioMoCua': 'Giờ mở cửa',
  'phucVu': 'Hình thức phục vụ',
  'tienIch': 'Tiện ích',
  'nhanDatBan': 'Nhận đặt bàn',
  'datMon': 'Cài đặt đặt món',
  'anhMatTien': 'Ảnh mặt tiền',
  'anhBia': 'Ảnh bìa',
  'anhKhac': 'Ảnh khác',
  'viTriAnh': 'Vị trí chụp ảnh mặt tiền',
  'maSoThue': 'Mã số thuế',
  'anhGiayChungNhan': 'Ảnh giấy chứng nhận hộ kinh doanh',
  'anhAttp': 'Ảnh giấy an toàn thực phẩm',
};

/// Trường hệ thống trong `banChinhSua`, không phải nội dung cần so sánh.
const _truongHeThong = {'guiLuc', 'loai'};

const _nhanKhaiSai = {
  'may_lanh': 'Chọn máy lạnh / chỗ ngồi trong nhà',
  'bien_hieu': 'Ảnh có biển hiệu cố định',
  'menu_nhieu': 'Menu nhiều món bất thường',
  'gio_mo_dai': 'Mở cửa nhiều giờ mỗi ngày',
  'bao_cao': 'Người dùng báo cáo khai sai loại hình',
};

/// Việc cần kiểm tra theo loại hồ sơ (mục 3.12).
List<String> _canKiemTra(String loai) => switch (loai) {
  'quan' => const [
    'Chủ quán đã xác thực danh tính',
    'Ảnh mặt tiền chụp trong app, GPS ổn, không giả lập',
    'Địa chỉ khớp vị trí ghim',
    'Hộ kinh doanh: mã số thuế còn hoạt động, tên khớp CCCD, địa chỉ khớp',
    'Bán lẻ: không có dấu hiệu khai sai loại',
    'Mô tả không quảng cáo',
  ],
  'chinh_sua' => const [
    'Kiểm tra như duyệt quán, với phần thay đổi',
    'So bản hiện tại với bản chỉnh sửa ở bảng bên dưới',
  ],
  'nang_cap' => const [
    'Kiểm tra như duyệt quán, với phần thay đổi',
    'Mã số thuế còn hoạt động, tên khớp CCCD, địa chỉ khớp',
  ],
  _ => const [
    'Xem lại ảnh, menu, giờ mở cửa và tiện ích của quán',
    'Đúng là khai sai loại thì yêu cầu chuyển loại; sai báo động thì bỏ cờ',
  ],
};

double _khoangCachMet(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h.toDouble()));
}

/// QA-AD-01 Duyệt quán / bản chỉnh sửa / nâng cấp loại · xử lý cờ nghi khai sai loại (mục 3.12, 3.5f, 3.5g).
class DuyetQuanScreen extends StatefulWidget {
  const DuyetQuanScreen({required this.dv, required this.viec, super.key});

  final QuanAnDichVu dv;
  final ViecAdminQuan viec;

  @override
  State<DuyetQuanScreen> createState() => _DuyetQuanScreenState();
}

class _DuyetQuanScreenState extends State<DuyetQuanScreen> {
  bool _daDoiChieuMst = false;
  late Future<GiayToQuan> _giayTo = widget.dv.quan.layGiayTo(widget.viec.id);
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh().catchError(
    (_) => const QuanAnConfig(),
  );

  ViecAdminQuan get _viec => widget.viec;
  bool get _laCoKhaiSai => _viec.loai == 'khai_sai_loai';
  bool get _laSua => _viec.loai == 'chinh_sua' || _viec.loai == 'nang_cap';

  Map<String, dynamic> get _ban => {
    for (final e
        in ((_viec.duLieu['banChinhSua'] as Map?) ?? const {}).entries)
      if (!_truongHeThong.contains(e.key)) e.key as String: e.value,
  };

  /// Quán như sẽ hiển thị sau khi duyệt (bản chỉnh sửa đè lên bản hiện tại).
  QuanAn get _quanMoi => QuanAn.fromMap(_viec.id, {..._viec.duLieu, ..._ban});

  bool get _hoKinhDoanh =>
      _viec.loai == 'nang_cap' || _quanMoi.laHoKinhDoanh;

  Future<void> _xong(Future<void> Function() viec, String ok) async {
    if (await chayThaoTac(context, viec, thanhCong: ok) && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _duyet() => _xong(
    () => widget.dv.admin.duyet(
      loai: _viec.loai,
      id: _viec.id,
      dongY: true,
      daDoiChieuMst: _hoKinhDoanh ? _daDoiChieuMst : null,
    ),
    'Đã duyệt',
  );

  Future<void> _tuChoi() async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: 'Lý do từ chối',
      noiDung: 'Chọn lý do có sẵn hoặc tự ghi. Chủ quán sẽ thấy lý do này.',
      goiY: lyDoTuChoiQuanLabels,
      nutXacNhan: 'Từ chối',
      nguyHiem: true,
    );
    if (lyDo == null || !mounted) return;
    await _xong(
      () => widget.dv.admin.duyet(
        loai: _viec.loai,
        id: _viec.id,
        dongY: false,
        lyDo: lyDo,
      ),
      'Đã từ chối',
    );
  }

  Future<void> _yeuCauChuyenLoai(int ngay) async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: 'Yêu cầu chuyển loại trong $ngay ngày',
      noiDung:
          'Quán phải chuyển sang hộ kinh doanh trong $ngay ngày. Quá hạn mà '
          'chưa chuyển thì quán bị ẩn.',
      goiY: const [
        'Menu và giờ mở cửa cho thấy quán hoạt động như hộ kinh doanh',
        'Ảnh có biển hiệu cố định, chỗ ngồi trong nhà',
      ],
      nutXacNhan: 'Yêu cầu chuyển loại',
    );
    if (lyDo == null || !mounted) return;
    await _xong(
      () => widget.dv.admin.yeuCauChuyenLoai(_viec.id, lyDo),
      'Đã yêu cầu chuyển loại',
    );
  }

  Future<void> _boCo() async {
    final lyDo = await hoiLyDo(
      context,
      tieuDe: 'Bỏ cờ nghi khai sai loại',
      noiDung: 'Quán được giữ nguyên loại bán lẻ và rời khỏi hàng chờ.',
      goiY: const ['Đã xem lại, quán đúng là bán lẻ / vỉa hè'],
      nutXacNhan: 'Bỏ cờ',
    );
    if (lyDo == null || !mounted) return;
    await _xong(
      () => widget.dv.admin.goi('adminBoCoKhaiSaiLoai', {
        'quanId': _viec.id,
        'lyDo': lyDo,
      }),
      'Đã bỏ cờ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _quanMoi;
    return Scaffold(
      appBar: AppBar(
        title: Text(ViecAdminQuan.loaiLabels[_viec.loai] ?? 'Duyệt quán'),
        actions: [
          IconButton(
            tooltip: 'Đình chỉ, ẩn, khóa bán quán',
            onPressed: () => QuanAnDieuHuong.mo(
              context,
              (_) => DinhChiQuanScreen(dv: widget.dv, quanId: _viec.id),
            ),
            icon: const Icon(Icons.gavel_outlined),
          ),
        ],
      ),
      bottomNavigationBar: FutureBuilder<QuanAnConfig>(
        future: _cfg,
        initialData: const QuanAnConfig(),
        builder: (context, s) => _ThanhDuoi(
          laCoKhaiSai: _laCoKhaiSai,
          ngayChuyenLoai: (s.data ?? const QuanAnConfig()).hanChuyenLoaiNgay,
          choDuyet: _hoKinhDoanh && !_daDoiChieuMst,
          onDuyet: _duyet,
          onTuChoi: _tuChoi,
          onChuyenLoai: _yeuCauChuyenLoai,
          onBoCo: _boCo,
        ),
      ),
      body: AdminTrang(
        children: [
          if (_viec.uuTien <= 2 && q.khaiSaiLoai != null)
            QuanAnWarningBox(
              message:
                  'Nghi khai sai loại'
                  '${q.khaiSaiLoai!.lyDo.isEmpty ? '' : ': ${q.khaiSaiLoai!.lyDo.map((l) => _nhanKhaiSai[l] ?? l).join('; ')}'}',
            ),
          _ThongTin(quan: q, viec: _viec),
          _AnhVaViTri(quan: q, cfg: _cfg),
          if (_hoKinhDoanh) _GiayTo(future: _giayTo, onThuLai: _thuLaiGiayTo),
          if (_laSua) _SoSanh(viec: _viec, ban: _ban),
          AdminMuc(
            tieuDe: 'Admin kiểm tra',
            bieuTuong: Icons.fact_check_outlined,
            children: [
              for (final t in _canKiemTra(_viec.loai))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: QuanAnSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_box_outline_blank,
                        size: 18,
                        color: QuanAnColors.textSecondary,
                      ),
                      const SizedBox(width: QuanAnSpacing.sm),
                      Expanded(child: Text(t, style: QuanAnText.body)),
                    ],
                  ),
                ),
            ],
          ),
          if (_hoKinhDoanh && !_laCoKhaiSai)
            Card(
              child: CheckboxListTile(
                value: _daDoiChieuMst,
                onChanged: (v) => setState(() => _daDoiChieuMst = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Đã đối chiếu mã số thuế trên trang tra cứu công khai',
                  style: QuanAnText.label,
                ),
                subtitle: const Text(
                  'Còn hoạt động · tên chủ hộ khớp CCCD · địa chỉ khớp ghim. '
                  'Bắt buộc tick trước khi duyệt hộ kinh doanh.',
                  style: QuanAnText.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _thuLaiGiayTo() => setState(() {
    _giayTo = widget.dv.quan.layGiayTo(widget.viec.id);
  });
}

class _ThanhDuoi extends StatelessWidget {
  const _ThanhDuoi({
    required this.laCoKhaiSai,
    required this.ngayChuyenLoai,
    required this.choDuyet,
    required this.onDuyet,
    required this.onTuChoi,
    required this.onChuyenLoai,
    required this.onBoCo,
  });

  final bool laCoKhaiSai;
  final int ngayChuyenLoai;

  /// Hộ kinh doanh chưa tick đối chiếu mã số thuế: khóa nút Duyệt.
  final bool choDuyet;
  final VoidCallback onDuyet;
  final VoidCallback onTuChoi;
  final ValueChanged<int> onChuyenLoai;
  final VoidCallback onBoCo;

  @override
  Widget build(BuildContext context) {
    final phu = OutlinedButton(
      onPressed: laCoKhaiSai ? onBoCo : onTuChoi,
      child: Text(laCoKhaiSai ? 'Bỏ cờ' : 'Từ chối'),
    );
    final chinh = FilledButton(
      onPressed: laCoKhaiSai
          ? () => onChuyenLoai(ngayChuyenLoai)
          : (choDuyet ? null : onDuyet),
      child: Text(
        laCoKhaiSai
            ? 'Yêu cầu chuyển loại trong $ngayChuyenLoai ngày'
            : 'Duyệt',
        textAlign: TextAlign.center,
      ),
    );
    return Material(
      color: QuanAnColors.white,
      elevation: 8,
      child: SafeArea(
        child: AdminNoiDung(
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: LayoutBuilder(
              builder: (context, c) => c.maxWidth < 520
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        chinh,
                        const SizedBox(height: QuanAnSpacing.sm),
                        phu,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: phu),
                        const SizedBox(width: QuanAnSpacing.md),
                        Expanded(flex: 2, child: chinh),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThongTin extends StatelessWidget {
  const _ThongTin({required this.quan, required this.viec});

  final QuanAn quan;
  final ViecAdminQuan viec;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    return AdminMuc(
      tieuDe: q.ten.isEmpty ? 'Quán chưa đặt tên' : q.ten,
      bieuTuong: Icons.storefront_outlined,
      children: [
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          children: [
            QuanAnStatusBadge(
              kind: q.laHoKinhDoanh
                  ? QuanAnBadgeKind.xacThuc
                  : QuanAnBadgeKind.chung,
              label: q.loaiQuanLabel,
            ),
            QuanAnStatusBadge(
              kind: QuanAnBadgeKind.chung,
              label: q.trangThaiLabel,
            ),
            if (q.khoaBan)
              const QuanAnStatusBadge(
                kind: QuanAnBadgeKind.dongCua,
                label: 'Đã khóa bán',
              ),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.md),
        AdminDong('Món chính', q.loaiMonLabel),
        AdminDong('Số điện thoại', q.sdt),
        AdminDong('Hình thức', [
          if (q.phucVu.anTaiQuan) 'Ăn tại quán',
          if (q.phucVu.mangDi) 'Mang đi',
          if (q.nhanDatBan) 'Nhận đặt bàn',
          if (q.datMon.bat) 'Đặt món qua app',
        ].join(' · ')),
        AdminDong('Gửi lúc', formatNgayGio(viec.luc)),
        if (q.moTa.isNotEmpty) AdminDong('Mô tả', q.moTa),
      ],
    );
  }
}

class _AnhVaViTri extends StatelessWidget {
  const _AnhVaViTri({required this.quan, required this.cfg});

  final QuanAn quan;
  final Future<QuanAnConfig> cfg;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final anh = q.anhMatTien.isNotEmpty
        ? q.anhMatTien
        : [if (q.anhBia.isNotEmpty) q.anhBia];
    return AdminMuc(
      tieuDe: 'Ảnh mặt tiền và địa chỉ',
      bieuTuong: Icons.place_outlined,
      children: [
        if (anh.isEmpty)
          const Text('Chưa có ảnh mặt tiền', style: QuanAnText.bodySmall)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ImageGallery(urls: anh, aspectRatio: 16 / 9),
            ),
          ),
        const SizedBox(height: QuanAnSpacing.md),
        AdminDong(
          'Địa chỉ',
          [q.diaChi, q.phuong].where((s) => s.isNotEmpty).join(', '),
        ),
        if (q.luuDong) AdminDong('Bán lưu động', q.ghiChuViTri),
        if (q.viTri != null) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: LocationMap(
                latitude: q.viTri!.latitude,
                longitude: q.viTri!.longitude,
                height: 200,
              ),
            ),
          ),
        ] else
          const AdminDong('Ghim bản đồ', 'Chưa ghim vị trí'),
        FutureBuilder<QuanAnConfig>(
          future: cfg,
          initialData: const QuanAnConfig(),
          builder: (context, s) {
            final lech = (s.data ?? const QuanAnConfig()).gpsLechMet;
            if (q.viTriAnh == null) {
              return const AdminDong(
                'GPS ảnh',
                'Ảnh mặt tiền không có GPS',
                mau: QuanAnColors.danger,
              );
            }
            if (q.viTri == null) return const SizedBox.shrink();
            final m = _khoangCachMet(q.viTri!, q.viTriAnh!);
            final xa = m > lech;
            return AdminDong(
              'GPS ảnh',
              'Nơi chụp ảnh cách ghim ${formatKhoangCach(m)}'
                  '${xa ? ' (lệch quá $lech m, cần xem kỹ)' : ' (khớp)'}',
              mau: xa ? QuanAnColors.danger : QuanAnColors.success,
            );
          },
        ),
      ],
    );
  }
}

class _GiayTo extends StatelessWidget {
  const _GiayTo({required this.future, required this.onThuLai});

  final Future<GiayToQuan> future;
  final VoidCallback onThuLai;

  @override
  Widget build(BuildContext context) => AdminMuc(
    tieuDe: 'Giấy tờ riêng của quán',
    bieuTuong: Icons.lock_outline,
    children: [
      FutureBuilder<GiayToQuan>(
        future: future,
        builder: (context, s) {
          if (s.hasError) {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'Không tải được giấy tờ',
                    style: TextStyle(color: QuanAnColors.danger),
                  ),
                ),
                TextButton(onPressed: onThuLai, child: const Text('Thử lại')),
              ],
            );
          }
          if (!s.hasData) return const LinearProgressIndicator();
          final g = s.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminDong('Mã số thuế', g.maSoThue),
              const SizedBox(height: QuanAnSpacing.sm),
              const Text('Giấy chứng nhận hộ kinh doanh', style: QuanAnText.label),
              const SizedBox(height: QuanAnSpacing.xs),
              AdminAnh(g.anhGiayChungNhan, khiRong: 'Chưa có ảnh'),
              if (g.anhAttp.isNotEmpty) ...[
                const SizedBox(height: QuanAnSpacing.md),
                const Text('Giấy an toàn thực phẩm', style: QuanAnText.label),
                const SizedBox(height: QuanAnSpacing.xs),
                AdminAnh(g.anhAttp),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class _SoSanh extends StatelessWidget {
  const _SoSanh({required this.viec, required this.ban});

  final ViecAdminQuan viec;
  final Map<String, dynamic> ban;

  @override
  Widget build(BuildContext context) => AdminMuc(
    tieuDe: 'So sánh bản hiện tại với bản chỉnh sửa',
    bieuTuong: Icons.compare_arrows,
    children: [
      if (ban.isEmpty)
        const Text('Không có trường nào thay đổi', style: QuanAnText.bodySmall)
      else ...[
        const Row(
          children: [
            Expanded(child: Text('Hiện tại', style: QuanAnText.label)),
            SizedBox(width: QuanAnSpacing.md),
            Expanded(child: Text('Bản chỉnh sửa', style: QuanAnText.label)),
          ],
        ),
        for (final e in ban.entries) ...[
          const Divider(height: QuanAnSpacing.xl),
          Text(_nhanTruong[e.key] ?? e.key, style: QuanAnText.bodySmall),
          const SizedBox(height: QuanAnSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _GiaTri(khoa: e.key, v: viec.duLieu[e.key])),
              const SizedBox(width: QuanAnSpacing.md),
              Expanded(child: _GiaTri(khoa: e.key, v: e.value, moi: true)),
            ],
          ),
        ],
      ],
    ],
  );
}

class _GiaTri extends StatelessWidget {
  const _GiaTri({required this.khoa, required this.v, this.moi = false});

  final String khoa;
  final Object? v;
  final bool moi;

  static const _truongAnh = {
    'anhMatTien',
    'anhKhac',
    'anhGiayChungNhan',
    'anhAttp',
    'anhBia',
  };

  String _chu() {
    final x = v;
    if (x == null || (x is String && x.isEmpty) || (x is List && x.isEmpty)) {
      return '—';
    }
    if (x is GeoPoint) {
      return '${x.latitude.toStringAsFixed(5)}, ${x.longitude.toStringAsFixed(5)}';
    }
    if (x is bool) return x ? 'Có' : 'Không';
    if (khoa == 'loaiQuan') return loaiQuanLabels[x] ?? '$x';
    if (khoa == 'loaiMon' && x is List) {
      return x.map((m) => loaiMonLabels[m] ?? '$m').join(' · ');
    }
    if (khoa == 'tienIch' && x is List) {
      return x.map((m) => tienIchLabels[m] ?? '$m').join(' · ');
    }
    if (khoa == 'gioMoCua') {
      final lich = lichTuMap(x);
      return [
        for (var d = 1; d <= 7; d++) '${tenThu(d)}: ${tomTatNgay(lich[d])}',
      ].join('\n');
    }
    if (khoa == 'phucVu') {
      final p = PhucVu.fromMap(x);
      return [
        if (p.anTaiQuan) 'Ăn tại quán',
        if (p.mangDi) 'Mang đi',
      ].join(' · ');
    }
    if (khoa == 'datMon') {
      final d = CaiDatDatMon.fromMap(x);
      return [
        d.bat ? 'Bật đặt món' : 'Tắt đặt món',
        if (d.denLay) 'đến lấy',
        if (d.giaoTanNoi) 'giao tận nơi (${d.banKinhKm} km)',
        if (d.tienMat) 'tiền mặt',
      ].join(' · ');
    }
    if (x is List) return x.join(', ');
    if (x is Map) return x.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    return '$x';
  }

  @override
  Widget build(BuildContext context) {
    if (_truongAnh.contains(khoa)) {
      final urls = v is String ? [if ((v as String).isNotEmpty) v as String] : danhSachChuoi(v);
      return urls.isEmpty
          ? const Text('—')
          : AdminAnh(urls, kichThuoc: 64);
    }
    return Text(
      _chu(),
      style: QuanAnText.body.copyWith(
        color: moi ? QuanAnColors.primaryDark : QuanAnColors.textSecondary,
        fontWeight: moi ? FontWeight.w600 : null,
      ),
    );
  }
}
