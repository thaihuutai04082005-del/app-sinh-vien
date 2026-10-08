import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/models/xac_thuc.dart';
import '../../../auth/screens/admin_danh_tinh_screen.dart';
import '../../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../../../auth/screens/xac_thuc_sdt_screen.dart';
import '../../models/coc_truc_tiep.dart';
import '../../models/dat_coc.dart';
import '../../models/khang_nghi.dart';
import '../../models/nha_tro.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tro_shell.dart';
import '../tuong_tac/bao_cao_khang_nghi_screen.dart';
import '../tuong_tac/thong_bao_screen.dart';
import 'xac_nhan_da_thue_screen.dart';

/// TRO-SV-10 Của tôi — Trọ: khoản cọc, nhà trọ đã lưu, phòng đã thuê, vi phạm và kháng nghị;
/// lối vào quản lý của chủ trọ và admin.
class CuaToiTroScreen extends StatelessWidget {
  const CuaToiTroScreen({required this.dv, this.onVeTrangChu, super.key});

  final TroDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: NutVeTrangChu(onPressed: onVeTrangChu),
      title: const Text('Của tôi'),
    ),
    body: StreamBuilder<XacThuc>(
      stream: dv.xacThuc.cuaToi(dv.uid),
      builder: (context, xtSnap) {
        final xt = xtSnap.data ?? const XacThuc();
        return ListView(
          padding: const EdgeInsets.all(TroSpacing.screen),
          children: [
            _TaiKhoan(dv: dv, xt: xt),
            const SizedBox(height: TroSpacing.lg),
            _KhoanCoc(dv: dv),
            const SizedBox(height: TroSpacing.lg),
            _DaLuu(dv: dv),
            const SizedBox(height: TroSpacing.lg),
            if (xt.sdt != null) _CocTrucTiepCuaToi(dv: dv, sdt: xt.sdt!),
            _ViPham(dv: dv, khoa: xt.sdt ?? dv.uid),
            const SizedBox(height: TroSpacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.home_work_outlined,
                      color: TroColors.primary,
                    ),
                    title: const Text('Cho thuê trọ — Quản lý nhà trọ của tôi'),
                    subtitle: const Text(
                      'Đăng nhà trọ, phòng; tiền cọc; cọc trực tiếp; ví',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => TroDieuHuong.quanLy(context, dv),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tune, color: TroColors.primary),
                    title: const Text('Cài đặt thông báo'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => TroDieuHuong.mo(
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
                final q = s.data ?? const QuyenAdmin();
                if (!q.tro && !q.danhTinh) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(top: TroSpacing.lg),
                  child: Column(
                    children: [
                      if (q.tro)
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: TroColors.primary,
                          ),
                          title: const Text('Admin Tìm trọ — hàng chờ'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => TroDieuHuong.admin(context, dv),
                        ),
                      if (q.danhTinh)
                        ListTile(
                          leading: const Icon(
                            Icons.badge_outlined,
                            color: TroColors.primary,
                          ),
                          title: const Text(
                            'Admin danh tính — duyệt xác nhận người thật',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => TroDieuHuong.mo(
                            context,
                            (_) => AdminDanhTinhScreen(service: dv.xacThuc),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

class _TaiKhoan extends StatelessWidget {
  const _TaiKhoan({required this.dv, required this.xt});

  final TroDichVu dv;
  final XacThuc xt;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          leading: Icon(
            xt.daOtp ? Icons.verified_user : Icons.phone_iphone,
            color: xt.daOtp ? TroColors.success : TroColors.warning,
          ),
          title: Text(
            xt.daOtp
                ? 'Số điện thoại ${xt.sdt}'
                : 'Chưa xác thực số điện thoại',
          ),
          subtitle: Text(
            xt.daOtp
                ? 'Đã xác thực OTP'
                : 'Cần để đặt cọc, báo cáo được tính, đăng tin',
          ),
          trailing: TextButton(
            onPressed: () => TroDieuHuong.mo(
              context,
              (_) => XacThucSdtScreen(service: dv.xacThuc),
            ),
            child: Text(xt.daOtp ? 'Đổi số' : 'Xác thực'),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.badge_outlined,
            color: xt.daXacThucDanhTinh
                ? TroColors.success
                : TroColors.textSecondary,
          ),
          title: Text(XacThuc.danhTinhLabels[xt.danhTinh] ?? xt.danhTinh),
          subtitle: Text(
            xt.danhTinh == 'tu_choi'
                ? 'Lý do: ${xt.lyDoTuChoi ?? ''}'
                : 'Bắt buộc với chủ trọ trước khi gửi duyệt nhà trọ',
          ),
          trailing: xt.daXacThucDanhTinh || xt.danhTinh == 'cho_duyet'
              ? null
              : TextButton(
                  onPressed: () => TroDieuHuong.mo(
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

class _KhoanCoc extends StatelessWidget {
  const _KhoanCoc({required this.dv});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DatCoc>>(
    stream: dv.datCoc.cuaSinhVien(dv.uid),
    builder: (context, s) {
      final ds = s.data ?? const <DatCoc>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khoản cọc của tôi', style: TroText.h2),
          const SizedBox(height: TroSpacing.sm),
          if (!s.hasData) const LinearProgressIndicator(),
          if (s.hasData && ds.isEmpty)
            const Text('Chưa có khoản cọc nào.', style: TroText.bodySmall),
          for (final d in ds)
            Card(
              child: ListTile(
                title: Text('${d.tenPhong} · ${d.tenNhaTro}'),
                subtitle: Text(
                  'Nhận phòng ${formatNgayGio(d.t)}${d.coDanhGia ? ' · Có thể đánh giá' : ''}',
                ),
                trailing: TroStatusBadge(
                  kind: d.dangDienRa
                      ? TroBadgeKind.reserved
                      : (d.status == 'released'
                            ? TroBadgeKind.rented
                            : TroBadgeKind.full),
                  label: d.trangThaiLabel,
                ),
                onTap: () => TroDieuHuong.datCoc(context, dv, d.id),
              ),
            ),
        ],
      );
    },
  );
}

class _DaLuu extends StatelessWidget {
  const _DaLuu({required this.dv});

  final TroDichVu dv;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<String>>(
    stream: dv.nhaTro.nhaTroDaLuu(dv.uid),
    builder: (context, s) {
      final ds = s.data ?? const <String>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhà trọ đã lưu ❤️', style: TroText.h2),
          const SizedBox(height: TroSpacing.sm),
          if (s.hasData && ds.isEmpty)
            const Text('Chưa lưu nhà trọ nào.', style: TroText.bodySmall),
          for (final id in ds)
            StreamBuilder<NhaTro?>(
              stream: dv.nhaTro.nhaTro(id),
              builder: (context, n) => n.data == null
                  ? const SizedBox.shrink()
                  : Card(
                      child: ListTile(
                        title: Text(n.data!.ten),
                        subtitle: Text(
                          n.data!.conPhong
                              ? 'Còn ${n.data!.soLieu.soPhongTrong} phòng'
                              : 'Hết phòng — bạn sẽ được báo khi có phòng trống',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => TroDieuHuong.nhaTro(context, dv, id),
                      ),
                    ),
            ),
        ],
      );
    },
  );
}

class _CocTrucTiepCuaToi extends StatelessWidget {
  const _CocTrucTiepCuaToi({required this.dv, required this.sdt});

  final TroDichVu dv;
  final String sdt;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CocTrucTiep>>(
    stream: dv.cocTrucTiep.cuaNguoiCoc(sdt),
    builder: (context, s) {
      final ds = s.data ?? const <CocTrucTiep>[];
      if (ds.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: TroSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phòng đã thuê (cọc trực tiếp)', style: TroText.h2),
            for (final c in ds)
              Card(
                child: ListTile(
                  title: Text('Phòng ${c.tenPhong}'),
                  subtitle: Text(
                    CocTrucTiep.ketQuaLabels[c.ketQua] ?? c.ketQua,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => TroDieuHuong.mo(
                    context,
                    (_) => XacNhanDaThueScreen(dv: dv, id: c.id),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ViPham extends StatelessWidget {
  const _ViPham({required this.dv, required this.khoa});

  final TroDichVu dv;
  final String khoa;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Vi phạm và kháng nghị', style: TroText.h2),
      const SizedBox(height: TroSpacing.sm),
      StreamBuilder<Map<String, DateTime?>>(
        stream: dv.baoCao.khoaCuaToi(khoa),
        builder: (context, s) {
          final now = DateTime.now();
          final khoa = {
            for (final e in (s.data ?? const <String, DateTime?>{}).entries)
              if (e.value != null && e.value!.isAfter(now)) e.key: e.value!,
          };
          if (khoa.isEmpty) return const SizedBox.shrink();
          const ten = {
            'khoaCocDen': ('Khóa đặt cọc trên app', 'khoa_coc'),
            'khoaBaoCaoDen': ('Khóa báo cáo', 'khoa_bao_cao'),
            'khoaDangTinDen': ('Khóa đăng tin / nhận cọc', 'khoa_dang_tin'),
          };
          return Column(
            children: [
              for (final e in khoa.entries)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.lock_clock,
                      color: TroColors.danger,
                    ),
                    title: Text(ten[e.key]!.$1),
                    subtitle: Text('Tới ${formatNgayGio(e.value)}'),
                    trailing: TextButton(
                      onPressed: () => moKhangNghi(
                        context,
                        dv,
                        loai: ten[e.key]!.$2,
                        id: this.khoa,
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
          final ds = s.data ?? const <ViPham>[];
          if (s.hasData && ds.isEmpty) {
            return const Text(
              'Không có vi phạm nào.',
              style: TroText.bodySmall,
            );
          }
          return Column(
            children: [
              for (final v in ds)
                Card(
                  child: ListTile(
                    title: Text(ViPham.loaiLabels[v.loai] ?? v.loai),
                    subtitle: Text(
                      '${formatNgayGio(v.luc)}${v.daGo ? ' · Đã gỡ' : ''}',
                    ),
                    trailing:
                        !v.daGo && DateTime.now().difference(v.luc).inDays < 7
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
                leading: const Icon(Icons.gavel_outlined),
                title: Text('Kháng nghị ${k.loaiQuyetDinh}'),
                subtitle: Text(
                  k.trangThai == 'cho_xu_ly'
                      ? 'Đang chờ admin (trả lời trong 48 giờ)'
                      : (KhangNghi.ketQuaLabels[k.ketQua] ?? ''),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
