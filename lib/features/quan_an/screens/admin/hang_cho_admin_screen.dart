import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/quan_an_config.dart';
import '../../services/admin_quan_an_service.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'admin_chung.dart';
import 'bao_cao_khang_nghi_admin_screen.dart';
import 'duyet_quan_screen.dart';
import 'khieu_nai_don_screen.dart';

/// Nhóm lọc của hàng chờ (mục 3.12): mã nhóm → (nhãn, các loại việc thuộc nhóm).
const _nhomLoc = <(String, String, Set<String>)>[
  ('quan', 'Quán chờ duyệt', {'quan'}),
  ('sua', 'Chỉnh sửa / nâng cấp loại', {'chinh_sua', 'nang_cap'}),
  ('khai_sai_loai', 'Quán nghi khai sai loại', {'khai_sai_loai'}),
  ('bao_cao', 'Báo cáo', {'bao_cao'}),
  ('khieu_nai_don', 'Khiếu nại đơn', {'khieu_nai_don'}),
  ('phan_doi', 'Phản đối "khách không nhận"', {'phan_doi'}),
  ('qua_han_6h', 'Đơn quá 6 giờ chưa có bằng chứng', {'qua_han_6h'}),
  ('rua_soat_lua_dao', 'Đơn cần rà soát (quán lừa đảo)', {'rua_soat_lua_dao'}),
  ('khang_nghi', 'Kháng nghị', {'khang_nghi'}),
];

/// Nhãn loại việc, riêng nhóm "Chỉnh sửa / nâng cấp" tách rõ hai loại.
String _nhanLoai(ViecAdminQuan v) => ViecAdminQuan.loaiLabels[v.loai] ?? v.loai;

/// QA-AD-04 Hàng chờ admin Quán ăn: lọc theo loại, sắp theo cờ khẩn → khiếu nại tiền và báo cáo
/// ưu tiên cao → hồ sơ gắn cờ → còn lại theo thời gian (mục 3.12). Màn rộng dùng bảng nhiều cột.
class HangChoAdminScreen extends StatefulWidget {
  const HangChoAdminScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  State<HangChoAdminScreen> createState() => _HangChoAdminScreenState();
}

class _HangChoAdminScreenState extends State<HangChoAdminScreen> {
  String? _nhom;

  void _mo(ViecAdminQuan v) {
    final dv = widget.dv;
    switch (v.loai) {
      case 'bao_cao' || 'khang_nghi':
        QuanAnDieuHuong.mo(
          context,
          (_) => BaoCaoKhangNghiAdminScreen(dv: dv, viec: v),
        );
      case 'khieu_nai_don' || 'phan_doi' || 'qua_han_6h' || 'rua_soat_lua_dao':
        QuanAnDieuHuong.mo(
          context,
          (_) => KhieuNaiDonAdminScreen(dv: dv, donId: v.id),
        );
      default:
        QuanAnDieuHuong.mo(context, (_) => DuyetQuanScreen(dv: dv, viec: v));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Quán ăn'),
      actions: [
        IconButton(
          tooltip: 'Khóa chức năng người dùng',
          onPressed: () => moKhoaChucNang(context, widget.dv),
          icon: const Icon(Icons.person_off_outlined),
        ),
        IconButton(
          tooltip: 'Cấu hình thời hạn (test)',
          onPressed: () => QuanAnDieuHuong.mo(
            context,
            (_) => CauHinhAdminScreen(dv: widget.dv),
          ),
          icon: const Icon(Icons.timer_outlined),
        ),
      ],
    ),
    body: QuanAnStream<List<ViecAdminQuan>>(
      stream: () => widget.dv.admin.hangCho(),
      builder: (context, tatCa) {
        final sapXep = sapXepHangCho(tatCa);
        final nhom = _nhomLoc.where((n) => n.$1 == _nhom).firstOrNull;
        final ds = nhom == null
            ? sapXep
            : [
                for (final v in sapXep)
                  if (nhom.$3.contains(v.loai)) v,
              ];
        return Column(
          children: [
            _ChipLoc(
              chon: _nhom,
              tatCa: sapXep,
              onChon: (k) => setState(() => _nhom = k),
            ),
            Expanded(
              child: ds.isEmpty
                  ? QuanAnEmptyState(
                      icon: Icons.task_alt,
                      title: 'Không có việc chờ xử lý',
                      message: nhom == null
                          ? 'Mọi hồ sơ, khiếu nại và báo cáo đã được xử lý.'
                          : 'Không có việc nào thuộc loại "${nhom.$2}".',
                      actionLabel: nhom == null ? null : 'Xem tất cả',
                      onAction: () => setState(() => _nhom = null),
                    )
                  : LayoutBuilder(
                      builder: (context, c) => c.maxWidth >= 800
                          ? _Bang(ds: ds, onMo: _mo)
                          : _DanhSach(ds: ds, onMo: _mo),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _ChipLoc extends StatelessWidget {
  const _ChipLoc({
    required this.chon,
    required this.tatCa,
    required this.onChon,
  });

  final String? chon;
  final List<ViecAdminQuan> tatCa;
  final ValueChanged<String?> onChon;

  int _dem(Set<String> loai) => tatCa.where((v) => loai.contains(v.loai)).length;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: QuanAnSpacing.screen,
        vertical: QuanAnSpacing.sm,
      ),
      children: [
        Align(
          child: ChoiceChip(
            label: Text('Tất cả (${tatCa.length})'),
            selected: chon == null,
            onSelected: (_) => onChon(null),
          ),
        ),
        for (final n in _nhomLoc)
          Padding(
            padding: const EdgeInsets.only(left: QuanAnSpacing.sm),
            child: Align(
              child: ChoiceChip(
                label: Text('${n.$2} (${_dem(n.$3)})'),
                selected: chon == n.$1,
                onSelected: (_) => onChon(n.$1),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Huy hiệu mức ưu tiên (chữ + biểu tượng, không chỉ dùng màu).
Widget? _huyHieuUuTien(ViecAdminQuan v) => switch (v.uuTien) {
  0 => const QuanAnStatusBadge(kind: QuanAnBadgeKind.dongCua, label: 'Cờ khẩn'),
  1 => const QuanAnStatusBadge(
    kind: QuanAnBadgeKind.canhBao,
    label: 'Ưu tiên cao',
  ),
  2 => const QuanAnStatusBadge(kind: QuanAnBadgeKind.chung, label: 'Gắn cờ'),
  _ => null,
};

class _DanhSach extends StatelessWidget {
  const _DanhSach({required this.ds, required this.onMo});

  final List<ViecAdminQuan> ds;
  final ValueChanged<ViecAdminQuan> onMo;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(QuanAnSpacing.screen),
    itemCount: ds.length,
    separatorBuilder: (_, _) => const SizedBox(height: QuanAnSpacing.cardGap),
    itemBuilder: (context, i) {
      final v = ds[i];
      final huyHieu = _huyHieuUuTien(v);
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onMo(v),
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
                    if (huyHieu != null) huyHieu,
                    Text(_nhanLoai(v), style: QuanAnText.bodySmall),
                  ],
                ),
                const SizedBox(height: QuanAnSpacing.sm),
                Text(v.tieuDe, style: QuanAnText.h3),
                if (v.moTa.isNotEmpty)
                  Text(
                    v.moTa,
                    style: QuanAnText.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: QuanAnSpacing.xs),
                Text(formatNgayGio(v.luc), style: QuanAnText.bodySmall),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Bảng nhiều cột cho màn rộng: Ưu tiên · Loại · Việc · Thời gian.
class _Bang extends StatelessWidget {
  const _Bang({required this.ds, required this.onMo});

  final List<ViecAdminQuan> ds;
  final ValueChanged<ViecAdminQuan> onMo;

  static const _cot = [2, 3, 5, 2];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      QuanAnSpacing.screen,
      0,
      QuanAnSpacing.screen,
      QuanAnSpacing.screen,
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QuanAnSpacing.lg,
            vertical: QuanAnSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: QuanAnColors.primaryLight,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(QuanAnRadius.card),
            ),
          ),
          child: Row(
            children: [
              for (final (i, t) in const [
                'Ưu tiên',
                'Loại',
                'Việc',
                'Thời gian',
              ].indexed)
                Expanded(
                  flex: _cot[i],
                  child: Text(t, style: QuanAnText.label),
                ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: QuanAnColors.white,
              border: Border.all(color: QuanAnColors.border),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(QuanAnRadius.card),
              ),
            ),
            child: ListView.separated(
              itemCount: ds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = ds[i];
                final huyHieu = _huyHieuUuTien(v);
                return InkWell(
                  onTap: () => onMo(v),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.symmetric(
                      horizontal: QuanAnSpacing.lg,
                      vertical: QuanAnSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: _cot[0],
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: huyHieu ?? const Text('—'),
                          ),
                        ),
                        Expanded(
                          flex: _cot[1],
                          child: Text(
                            _nhanLoai(v),
                            style: QuanAnText.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: _cot[2],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.tieuDe,
                                style: QuanAnText.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (v.moTa.isNotEmpty)
                                Text(
                                  v.moTa,
                                  style: QuanAnText.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: _cot[3],
                          child: Text(
                            formatNgayGio(v.luc),
                            style: QuanAnText.bodySmall,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: QuanAnColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

/// Các con số có thể ghi đè khi test / demo: khóa → (nhãn, cách đọc giá trị hiện hành).
final _khoaCauHinh = <String, (String, int Function(QuanAnConfig))>{
  'quanXacNhanPhut': ('Quán xác nhận đơn (phút)', (c) => c.quanXacNhanPhut),
  'choThanhToanPhut': ('Chờ thanh toán (phút)', (c) => c.choThanhToanPhut),
  'quanChamPhut': (
    'Quán chậm, mở nút hủy sau giờ dự kiến (phút)',
    (c) => c.quanChamPhut,
  ),
  'giaoLauPhut': (
    'Giao lâu, mở "Chưa nhận được món" sau (phút)',
    (c) => c.giaoLauPhut,
  ),
  'khachKhongToiLayPhut': (
    'Khách không tới lấy sau "Sẵn sàng" (phút)',
    (c) => c.khachKhongToiLayPhut,
  ),
  'phanDoiPhut': ('Hạn phản đối "khách không nhận" (phút)', (c) => c.phanDoiPhut),
  'giuThemPhut': ('Giữ tiền thêm sau "khách không nhận" (phút)', (c) => c.giuThemPhut),
  'khieuNaiPhut': ('Hạn khiếu nại sau bằng chứng (phút)', (c) => c.khieuNaiPhut),
  'quanTraLoiPhut': ('Quán trả lời khiếu nại (phút)', (c) => c.quanTraLoiPhut),
  'tuHoanTatPhut': ('Tự hoàn tất đơn sau (phút)', (c) => c.tuHoanTatPhut),
  'nhacTuHoanTatSauPhut': (
    'Nhắc trước khi tự hoàn tất, sau (phút)',
    (c) => c.nhacTuHoanTatSauPhut,
  ),
  'quaHanPhut': ('Đơn quá hạn chưa có bằng chứng (phút)', (c) => c.quaHanPhut),
  'khieuNaiKhanPhut': ('Khiếu nại treo thành cờ khẩn (phút)', (c) => c.khieuNaiKhanPhut),
  'henGioToiThieuPhut': ('Hẹn giờ tối thiểu (phút)', (c) => c.henGioToiThieuPhut),
  'henGioToiDaPhut': ('Hẹn giờ tối đa (phút)', (c) => c.henGioToiDaPhut),
  'datBanQuanXacNhanPhut': (
    'Quán xác nhận đặt bàn (phút)',
    (c) => c.datBanQuanXacNhanPhut,
  ),
  'datBanTruocGioHenPhut': (
    'Hạn xác nhận trước giờ hẹn (phút)',
    (c) => c.datBanTruocGioHenPhut,
  ),
  'giuBanPhut': ('Giữ bàn sau giờ hẹn (phút)', (c) => c.giuBanPhut),
  'huySatGioPhut': ('Hủy bàn sát giờ (phút)', (c) => c.huySatGioPhut),
  'tuDongDongBanPhut': (
    'Tự đóng bàn sau giờ giữ bàn (phút)',
    (c) => c.tuDongDongBanPhut,
  ),
};

/// Admin xem và ghi đè các con số (mục 3.16): khi test được rút ngắn thời hạn.
class CauHinhAdminScreen extends StatefulWidget {
  const CauHinhAdminScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  State<CauHinhAdminScreen> createState() => _CauHinhAdminScreenState();
}

class _CauHinhAdminScreenState extends State<CauHinhAdminScreen> {
  late Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh();
  final _o = {for (final k in _khoaCauHinh.keys) k: TextEditingController()};
  final _loi = <String, String>{};
  bool _dangLuu = false;

  @override
  void dispose() {
    for (final c in _o.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _luu(QuanAnConfig hienTai) async {
    final ghiDe = <String, dynamic>{};
    final loi = <String, String>{};
    for (final e in _o.entries) {
      final t = e.value.text.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n == null || n < 1) {
        loi[e.key] = 'Nhập số nguyên từ 1 trở lên';
        continue;
      }
      if (n != _khoaCauHinh[e.key]!.$2(hienTai)) ghiDe[e.key] = n;
    }
    setState(() {
      _loi
        ..clear()
        ..addAll(loi);
    });
    if (loi.isNotEmpty) return;
    if (ghiDe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có con số nào thay đổi')),
      );
      return;
    }
    setState(() => _dangLuu = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.admin.capNhatCauHinh(ghiDe),
      thanhCong: 'Đã lưu cấu hình',
    );
    if (!mounted) return;
    setState(() {
      _dangLuu = false;
      if (ok) {
        for (final c in _o.values) {
          c.clear();
        }
        _cfg = widget.dv.donMon.cauHinh();
      }
    });
  }

  Future<void> _veMacDinh() async {
    final dongY = await xacNhan(
      context,
      tieuDe: 'Về cấu hình mặc định?',
      noiDung: 'Mọi con số đã ghi đè sẽ trở về giá trị của đặc tả (mục 3.16).',
      dongY: 'Về mặc định',
    );
    if (!dongY || !mounted) return;
    final ok = await chayThaoTac(
      context,
      () => widget.dv.admin.capNhatCauHinh(const <String, dynamic>{}),
      thanhCong: 'Đã về mặc định',
    );
    if (ok && mounted) {
      setState(() {
        for (final c in _o.values) {
          c.clear();
        }
        _cfg = widget.dv.donMon.cauHinh();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cấu hình thời hạn (test)')),
    body: FutureBuilder<QuanAnConfig>(
      future: _cfg,
      builder: (context, s) {
        if (s.hasError) {
          return QuanAnErrorState(
            message: 'Không tải được cấu hình',
            onRetry: () => setState(() {
              _cfg = widget.dv.donMon.cauHinh();
            }),
          );
        }
        if (!s.hasData) return const QuanAnSkeletonList(count: 2);
        final cfg = s.data!;
        return AdminTrang(
          children: [
            const Text(
              'Để trống ô nào thì giữ nguyên con số hiện hành. Chỉ dùng khi '
              'test / demo để rút ngắn thời hạn.',
              style: QuanAnText.bodySmall,
            ),
            LayoutBuilder(
              builder: (context, c) {
                final cot = c.maxWidth >= 640 ? 2 : 1;
                final rong = (c.maxWidth - (cot - 1) * QuanAnSpacing.md) / cot;
                return Wrap(
                  spacing: QuanAnSpacing.md,
                  runSpacing: QuanAnSpacing.md,
                  children: [
                    for (final e in _khoaCauHinh.entries)
                      SizedBox(
                        width: rong,
                        child: TextField(
                          controller: _o[e.key],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: e.value.$1,
                            hintText: 'Hiện tại: ${e.value.$2(cfg)}',
                            errorText: _loi[e.key],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            FilledButton(
              onPressed: _dangLuu ? null : () => _luu(cfg),
              child: const Text('Lưu cấu hình'),
            ),
            OutlinedButton(
              onPressed: _dangLuu ? null : _veMacDinh,
              child: const Text('Về mặc định'),
            ),
          ],
        );
      },
    ),
  );
}
