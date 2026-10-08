import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/check_in.dart';
import '../../models/dat_ban.dart';
import '../../models/don_mon.dart';
import '../../models/khang_nghi.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/quan_an_filter.dart';
import '../../services/quan_an_bo_nho.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../quan_an_shell.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import '../tuong_tac/thong_bao_screen.dart';
import 'chon_diem_goc_screen.dart';

/// Số mục hiện sẵn trong mỗi danh sách; còn lại bấm "Xem thêm".
const _soMucRutGon = 5;

/// QA-SV-12 Của tôi — Quán ăn (mục 3.4 cuối): đơn đang làm và đã xong · đặt bàn · check-in ·
/// quán đã lưu · địa chỉ đã lưu · lần bom hàng / bỏ hẹn / khóa (kháng nghị được, mục 3.15);
/// lối vào quản lý quán của chủ quán và admin Quán ăn.
class CuaToiQuanAnScreen extends StatefulWidget {
  const CuaToiQuanAnScreen({required this.dv, this.onVeTrangChu, super.key});

  final QuanAnDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  State<CuaToiQuanAnScreen> createState() => _CuaToiQuanAnScreenState();
}

class _CuaToiQuanAnScreenState extends State<CuaToiQuanAnScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();
  ThongTinSinhVien? _thongTin;

  @override
  void initState() {
    super.initState();
    _nap();
  }

  Future<void> _nap() async {
    if (widget.dv.uid.isEmpty) return;
    try {
      final c = await widget.dv.donMon.cauHinh();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
    try {
      final t = await widget.dv.donMon.thongTinSinhVien();
      if (mounted) setState(() => _thongTin = t);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dv = widget.dv;
    return Scaffold(
      appBar: AppBar(
        leading: NutVeTrangChu(onPressed: widget.onVeTrangChu),
        title: const Text('Của tôi'),
      ),
      body: dv.uid.isEmpty
          ? const QuanAnEmptyState(
              icon: Icons.login_rounded,
              title: 'Vui lòng đăng nhập',
              message: 'Đăng nhập để xem đơn, đặt bàn và quán đã lưu của bạn.',
            )
          : StreamBuilder<XacThuc>(
              stream: dv.xacThuc.cuaToi(dv.uid),
              builder: (context, xtSnap) {
                final xt = xtSnap.data ?? const XacThuc();
                return LayoutBuilder(
                  builder: (context, c) {
                    final le = (c.maxWidth - 640) / 2;
                    return ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: le > QuanAnSpacing.screen
                            ? le
                            : QuanAnSpacing.screen,
                        vertical: QuanAnSpacing.screen,
                      ),
                      children: [
                        _TaiKhoan(dv: dv, xt: xt),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _DonCuaToi(dv: dv),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _BanCuaToi(dv: dv),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _CheckInCuaToi(dv: dv),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _DaLuu(dv: dv),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _DiaChiDaLuu(),
                        const SizedBox(height: QuanAnSpacing.xl),
                        _ViPhamVaKhoa(
                          dv: dv,
                          khoa: xt.sdt ?? dv.uid,
                          cfg: _cfg,
                          thongTin: _thongTin,
                        ),
                        const SizedBox(height: QuanAnSpacing.xl),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                minVerticalPadding: QuanAnSpacing.md,
                                leading: const Icon(
                                  Icons.storefront_outlined,
                                  color: QuanAnColors.primary,
                                ),
                                title: const Text('Quản lý quán của tôi'),
                                subtitle: const Text(
                                  'Đăng quán, menu, đơn hàng, đặt bàn, khuyến mãi, ví',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => QuanAnDieuHuong.quanLy(context, dv),
                              ),
                              const Divider(),
                              ListTile(
                                minVerticalPadding: QuanAnSpacing.md,
                                leading: const Icon(
                                  Icons.tune,
                                  color: QuanAnColors.primary,
                                ),
                                title: const Text('Cài đặt thông báo'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => QuanAnDieuHuong.mo(
                                  context,
                                  (_) => CaiDatThongBaoScreen(dv: dv),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<QuyenAdmin>(
                          stream: dv.xacThuc.quyenAdmin(dv.uid),
                          builder: (context, s) {
                            if (!(s.data?.quanAn ?? false)) {
                              return const SizedBox.shrink();
                            }
                            return Card(
                              margin: const EdgeInsets.only(
                                top: QuanAnSpacing.lg,
                              ),
                              child: ListTile(
                                minVerticalPadding: QuanAnSpacing.md,
                                leading: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: QuanAnColors.primary,
                                ),
                                title: const Text('Admin Quán ăn'),
                                subtitle: const Text('Hàng chờ, báo cáo, kháng nghị'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => QuanAnDieuHuong.admin(context, dv),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _TieuDeMuc extends StatelessWidget {
  const _TieuDeMuc(this.chu);

  final String chu;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
    child: Text(chu, style: QuanAnText.h2),
  );
}

/// Một mục trong danh sách (đơn, bàn, check-in, quán): thẻ bấm được, không dùng ListTile
/// để chữ dài và huy hiệu tự xuống dòng thay vì tràn ngang.
class _MucThe extends StatelessWidget {
  const _MucThe({
    required this.tieuDe,
    this.dongPhu,
    this.badge,
    this.onTap,
  });

  final String tieuDe;
  final String? dongPhu;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tieuDe, style: QuanAnText.h3),
                      if (dongPhu != null && dongPhu!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(dongPhu!, style: QuanAnText.bodySmall),
                        ),
                      if (badge != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: QuanAnSpacing.xs,
                          ),
                          child: badge,
                        ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Danh sách rút gọn: hiện [_soMucRutGon] mục đầu, còn lại bấm "Xem thêm".
class _DanhSachRutGon<T> extends StatefulWidget {
  const _DanhSachRutGon({required this.muc, required this.dung});

  final List<T> muc;
  final Widget Function(T) dung;

  @override
  State<_DanhSachRutGon<T>> createState() => _DanhSachRutGonState<T>();
}

class _DanhSachRutGonState<T> extends State<_DanhSachRutGon<T>> {
  bool _het = false;

  @override
  Widget build(BuildContext context) {
    final ds = _het ? widget.muc : widget.muc.take(_soMucRutGon).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in ds) widget.dung(m),
        if (!_het && widget.muc.length > _soMucRutGon)
          TextButton(
            onPressed: () => setState(() => _het = true),
            child: Text('Xem thêm ${widget.muc.length - _soMucRutGon} mục'),
          ),
      ],
    );
  }
}

class _TaiKhoan extends StatelessWidget {
  const _TaiKhoan({required this.dv, required this.xt});

  final QuanAnDichVu dv;
  final XacThuc xt;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          minVerticalPadding: QuanAnSpacing.md,
          leading: Icon(
            xt.daOtp ? Icons.verified_user : Icons.phone_iphone,
            color: xt.daOtp ? QuanAnColors.success : QuanAnColors.warning,
          ),
          title: Text(
            xt.daOtp
                ? 'Số điện thoại ${xt.sdt}'
                : 'Chưa xác thực số điện thoại',
          ),
          subtitle: Text(
            xt.daOtp
                ? 'Đã xác thực OTP'
                : 'Cần để đặt món, đặt bàn, đánh giá có nhãn và báo cáo được tính',
          ),
          trailing: TextButton(
            onPressed: () => QuanAnDieuHuong.mo(
              context,
              (_) => XacThucSdtScreen(service: dv.xacThuc),
            ),
            child: Text(xt.daOtp ? 'Đổi số' : 'Xác thực'),
          ),
        ),
        const Divider(),
        ListTile(
          minVerticalPadding: QuanAnSpacing.md,
          leading: Icon(
            Icons.badge_outlined,
            color: xt.daXacThucDanhTinh
                ? QuanAnColors.success
                : QuanAnColors.textSecondary,
          ),
          title: Text(XacThuc.danhTinhLabels[xt.danhTinh] ?? xt.danhTinh),
          subtitle: Text(
            xt.danhTinh == 'tu_choi'
                ? 'Lý do: ${xt.lyDoTuChoi ?? ''}'
                : 'Bắt buộc với chủ quán trước khi gửi duyệt quán',
          ),
          trailing: xt.daXacThucDanhTinh || xt.danhTinh == 'cho_duyet'
              ? null
              : TextButton(
                  onPressed: () => QuanAnDieuHuong.mo(
                    context,
                    (_) => XacNhanDanhTinhScreen(service: dv.xacThuc),
                  ),
                  child: const Text('Xác nhận'),
                ),
        ),
      ],
    ),
  );
}

QuanAnBadgeKind _kindDon(DonMon d) => switch (d.status) {
  'completed' => QuanAnBadgeKind.moCua,
  'delivered' || 'disputed' || 'not_received' => QuanAnBadgeKind.canhBao,
  'cancelled_student' ||
  'cancelled_restaurant' ||
  'rejected' ||
  'expired' ||
  'expired_accept' => QuanAnBadgeKind.dongCua,
  _ => QuanAnBadgeKind.chung,
};

class _DonCuaToi extends StatelessWidget {
  const _DonCuaToi({required this.dv});

  final QuanAnDichVu dv;

  Widget _the(BuildContext context, DonMon d) => _MucThe(
    tieuDe: d.tenQuan.isEmpty ? 'Đơn món' : d.tenQuan,
    dongPhu:
        '${d.taoLuc == null ? '' : '${formatNgayGio(d.taoLuc!)} · '}${formatPrice(d.tong)}',
    badge: QuanAnStatusBadge(kind: _kindDon(d), label: d.trangThaiLabel),
    onTap: () => QuanAnDieuHuong.don(context, dv, d.id),
  );

  @override
  Widget build(BuildContext context) => QuanAnStream<List<DonMon>>(
    stream: () => dv.donMon.cuaSinhVien(dv.uid),
    thongBaoLoi: 'Không tải được đơn của bạn',
    dangTai: const QuanAnSkeletonBox(height: 72),
    builder: (context, ds) {
      final sx = [...ds]
        ..sort(
          (a, b) => (b.taoLuc ?? DateTime(0)).compareTo(a.taoLuc ?? DateTime(0)),
        );
      final dangLam = sx.where((d) => d.dangDienRa).toList();
      final daXong = sx.where((d) => !d.dangDienRa).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TieuDeMuc('Đơn đang làm'),
          if (dangLam.isEmpty)
            const Text('Không có đơn nào đang làm.', style: QuanAnText.bodySmall)
          else
            for (final d in dangLam) _the(context, d),
          const SizedBox(height: QuanAnSpacing.lg),
          const _TieuDeMuc('Đơn đã xong'),
          if (daXong.isEmpty)
            const Text('Chưa có đơn nào đã xong.', style: QuanAnText.bodySmall)
          else
            _DanhSachRutGon<DonMon>(
              muc: daXong,
              dung: (d) => _the(context, d),
            ),
        ],
      );
    },
  );
}

class _BanCuaToi extends StatelessWidget {
  const _BanCuaToi({required this.dv});

  final QuanAnDichVu dv;

  @override
  Widget build(BuildContext context) => QuanAnStream<List<DatBan>>(
    stream: () => dv.datBan.cuaSinhVien(dv.uid),
    thongBaoLoi: 'Không tải được lượt đặt bàn',
    dangTai: const QuanAnSkeletonBox(height: 72),
    builder: (context, ds) {
      final sx = [...ds]..sort((a, b) => b.gio.compareTo(a.gio));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TieuDeMuc('Đặt bàn'),
          if (sx.isEmpty)
            const Text('Chưa có lượt đặt bàn nào.', style: QuanAnText.bodySmall)
          else
            _DanhSachRutGon<DatBan>(
              muc: sx,
              dung: (b) => _MucThe(
                tieuDe: b.tenQuan.isEmpty ? 'Đặt bàn' : b.tenQuan,
                dongPhu: '${formatNgayGio(b.gio)} · ${b.soNguoi} người',
                badge: QuanAnStatusBadge(
                  kind: switch (b.status) {
                    'confirmed' || 'arrived' => QuanAnBadgeKind.moCua,
                    'pending' => QuanAnBadgeKind.chung,
                    'no_show' => QuanAnBadgeKind.canhBao,
                    _ => QuanAnBadgeKind.dongCua,
                  },
                  label: b.trangThaiLabel,
                ),
                onTap: () => QuanAnDieuHuong.datBan(context, dv, b.id),
              ),
            ),
        ],
      );
    },
  );
}

class _CheckInCuaToi extends StatelessWidget {
  const _CheckInCuaToi({required this.dv});

  final QuanAnDichVu dv;

  @override
  Widget build(BuildContext context) => QuanAnStream<List<CheckIn>>(
    stream: () => dv.checkIn.cuaSinhVien(dv.uid),
    thongBaoLoi: 'Không tải được các lần check-in',
    dangTai: const QuanAnSkeletonBox(height: 72),
    builder: (context, ds) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TieuDeMuc('Check-in của tôi'),
        if (ds.isEmpty)
          const Text('Chưa check-in quán nào.', style: QuanAnText.bodySmall)
        else
          _DanhSachRutGon<CheckIn>(
            muc: ds,
            dung: (c) => StreamBuilder<QuanAn?>(
              stream: dv.quan.quan(c.quanId),
              builder: (context, q) => _MucThe(
                tieuDe: q.data?.ten ?? 'Quán đã check-in',
                dongPhu: c.luc == null ? null : formatNgayGio(c.luc!),
                badge: const QuanAnStatusBadge(
                  kind: QuanAnBadgeKind.nhan,
                  label: 'Check-in tại quán',
                  icon: Icons.place_rounded,
                ),
                onTap: () => QuanAnDieuHuong.quan(context, dv, c.quanId),
              ),
            ),
          ),
      ],
    ),
  );
}

class _DaLuu extends StatelessWidget {
  const _DaLuu({required this.dv});

  final QuanAnDichVu dv;

  @override
  Widget build(BuildContext context) => QuanAnStream<List<String>>(
    stream: () => dv.quan.quanDaLuu(dv.uid),
    thongBaoLoi: 'Không tải được quán đã lưu',
    dangTai: const QuanAnSkeletonBox(height: 72),
    builder: (context, ds) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TieuDeMuc('Quán đã lưu ❤️'),
        if (ds.isEmpty)
          const Text('Chưa lưu quán nào.', style: QuanAnText.bodySmall)
        else
          _DanhSachRutGon<String>(
            muc: ds,
            dung: (id) => StreamBuilder<QuanAn?>(
              stream: dv.quan.quan(id),
              builder: (context, n) {
                final q = n.data;
                if (q == null) return const SizedBox.shrink();
                final tt = q.moCua(DateTime.now());
                return _MucThe(
                  tieuDe: q.ten,
                  dongPhu: tt.thongDiep,
                  onTap: () => QuanAnDieuHuong.quan(context, dv, id),
                );
              },
            ),
          ),
      ],
    ),
  );
}

/// Địa chỉ giao hàng đã lưu trên máy ([QuanAnBoNho]): thêm bằng bản đồ, xóa từng địa chỉ.
class _DiaChiDaLuu extends StatefulWidget {
  @override
  State<_DiaChiDaLuu> createState() => _DiaChiDaLuuState();
}

class _DiaChiDaLuuState extends State<_DiaChiDaLuu> {
  List<Map<String, dynamic>>? _ds;

  @override
  void initState() {
    super.initState();
    _nap();
  }

  Future<void> _nap() async {
    final ds = await QuanAnBoNho.docDiaChi();
    if (mounted) setState(() => _ds = ds);
  }

  Future<void> _them() async {
    final g = await QuanAnDieuHuong.mo<DiemGoc>(
      context,
      (_) => const ChonDiemGocScreen(tieuDe: 'Chọn địa chỉ giao hàng'),
    );
    if (g == null || !mounted) return;
    final ten = TextEditingController(text: 'Nhà');
    final dongY = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Đặt tên địa chỉ'),
        content: TextField(
          controller: ten,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Tên gợi nhớ (Nhà, Ký túc xá...)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final tenDiaChi = ten.text.trim();
    ten.dispose();
    if (dongY != true || !mounted) return;
    final moi = [
      ...?_ds,
      {
        'ten': tenDiaChi.isEmpty ? 'Địa chỉ' : tenDiaChi,
        'dong': g.ten,
        'lat': g.lat,
        'lng': g.lng,
      },
    ];
    await QuanAnBoNho.luuDiaChi(moi);
    if (mounted) setState(() => _ds = moi);
  }

  Future<void> _xoa(int i) async {
    final moi = [...?_ds]..removeAt(i);
    await QuanAnBoNho.luuDiaChi(moi);
    if (mounted) setState(() => _ds = moi);
  }

  @override
  Widget build(BuildContext context) {
    final ds = _ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TieuDeMuc('Địa chỉ đã lưu'),
        if (ds == null)
          const QuanAnSkeletonBox(height: 56)
        else if (ds.isEmpty)
          const Text(
            'Chưa lưu địa chỉ giao hàng nào.',
            style: QuanAnText.bodySmall,
          ),
        if (ds != null)
          for (var i = 0; i < ds.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
              child: ListTile(
                minVerticalPadding: QuanAnSpacing.md,
                leading: const Icon(
                  Icons.home_outlined,
                  color: QuanAnColors.primary,
                ),
                title: Text('${ds[i]['ten'] ?? 'Địa chỉ'}'),
                subtitle: Text(
                  '${ds[i]['dong'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Xóa địa chỉ',
                  onPressed: () => _xoa(i),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _them,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Thêm địa chỉ'),
          ),
        ),
      ],
    );
  }
}

/// Lần bom hàng / bỏ hẹn / khóa chức năng và kháng nghị (mục 3.5, 3.15).
class _ViPhamVaKhoa extends StatelessWidget {
  const _ViPhamVaKhoa({
    required this.dv,
    required this.khoa,
    required this.cfg,
    required this.thongTin,
  });

  final QuanAnDichVu dv;

  /// Khóa của `qa_khoa`: số điện thoại đã xác thực, chưa có thì uid.
  final String khoa;
  final QuanAnConfig cfg;
  final ThongTinSinhVien? thongTin;

  static const _tenKhoa = {
    'khoaDatMonDen': ('Khóa đặt món', 'khoa_dat_mon'),
    'khoaDatBanDen': ('Khóa đặt bàn', 'khoa_dat_ban'),
    'khoaTienMatDen': ('Khóa trả tiền mặt khi nhận', 'khoa_tien_mat'),
    'khoaBaoCaoDen': ('Khóa báo cáo', 'khoa_bao_cao'),
    'khoaDatMonAppDen': ('Khóa đặt món trên app', 'khoa_dat_mon_app'),
  };

  static const _tenQuyetDinh = {
    'vi_pham': 'lần vi phạm',
    'khieu_nai_sai': 'khiếu nại bị tính sai',
    'khoa_dat_mon': 'khóa đặt món',
    'khoa_dat_ban': 'khóa đặt bàn',
    'khoa_tien_mat': 'khóa tiền mặt',
    'khoa_bao_cao': 'khóa báo cáo',
    'khoa_dat_mon_app': 'khóa đặt món trên app',
    'an_quan': 'ẩn quán',
    'khoa_ban': 'khóa bán',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _TieuDeMuc('Vi phạm và kháng nghị'),
      if (thongTin != null && thongTin!.soLanBomHang > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
          child: Text(
            'Số lần bom hàng: ${thongTin!.soLanBomHang}'
            '${thongTin!.coTienMat ? '' : ' · Bạn không còn được trả tiền mặt khi nhận'}',
            style: QuanAnText.body.copyWith(color: QuanAnColors.warning),
          ),
        ),
      StreamBuilder<Map<String, DateTime?>>(
        stream: dv.baoCao.khoaCuaToi(khoa),
        builder: (context, s) {
          final now = DateTime.now();
          final dangKhoa = {
            for (final e in (s.data ?? const <String, DateTime?>{}).entries)
              if (e.value != null &&
                  e.value!.isAfter(now) &&
                  _tenKhoa.containsKey(e.key))
                e.key: e.value!,
          };
          return Column(
            children: [
              for (final e in dangKhoa.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
                  child: ListTile(
                    minVerticalPadding: QuanAnSpacing.md,
                    leading: const Icon(
                      Icons.lock_clock,
                      color: QuanAnColors.danger,
                    ),
                    title: Text(_tenKhoa[e.key]!.$1),
                    subtitle: Text('Tới ${formatNgayGio(e.value)}'),
                    trailing: TextButton(
                      onPressed: () => moKhangNghi(
                        context,
                        dv,
                        loai: _tenKhoa[e.key]!.$2,
                        id: khoa,
                      ),
                      child: const Text('Kháng nghị'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      StreamBuilder<List<ViPham>>(
        stream: dv.baoCao.viPhamCuaToi(dv.uid),
        builder: (context, s) {
          if (s.hasError) {
            return const Text(
              'Không tải được danh sách vi phạm.',
              style: TextStyle(color: QuanAnColors.danger),
            );
          }
          final ds = s.data ?? const <ViPham>[];
          if (s.hasData && ds.isEmpty) {
            return const Text(
              'Không có vi phạm nào.',
              style: QuanAnText.bodySmall,
            );
          }
          return Column(
            children: [
              for (final v in ds)
                Card(
                  margin: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
                  child: ListTile(
                    minVerticalPadding: QuanAnSpacing.md,
                    title: Text(ViPham.loaiLabels[v.loai] ?? v.loai),
                    subtitle: Text(
                      '${formatNgayGio(v.luc)}${v.daGo ? ' · Đã gỡ' : ''}',
                    ),
                    trailing:
                        !v.daGo &&
                            DateTime.now().difference(v.luc).inDays <
                                cfg.khangNghiHanGuiNgay
                        ? TextButton(
                            onPressed: () => moKhangNghi(
                              context,
                              dv,
                              loai: 'vi_pham',
                              id: v.id,
                            ),
                            child: const Text('Kháng nghị'),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
      StreamBuilder<List<KhangNghi>>(
        stream: dv.baoCao.khangNghiCuaToi(dv.uid),
        builder: (context, s) => Column(
          children: [
            for (final k in s.data ?? const <KhangNghi>[])
              ListTile(
                dense: true,
                minVerticalPadding: QuanAnSpacing.sm,
                leading: const Icon(Icons.gavel_outlined),
                title: Text(
                  'Kháng nghị ${_tenQuyetDinh[k.loaiQuyetDinh] ?? k.loaiQuyetDinh}',
                ),
                subtitle: Text(
                  k.trangThai == 'cho_xu_ly'
                      ? 'Đang chờ admin xử lý'
                      : (KhangNghi.ketQuaLabels[k.ketQua] ?? 'Đã xử lý'),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
