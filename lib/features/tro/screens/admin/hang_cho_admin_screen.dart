import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../services/admin_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_status_badge.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import 'bao_cao_khang_nghi_admin_screen.dart';
import 'duyet_tro_screen.dart';
import 'khieu_nai_coc_screen.dart';

/// TRO-AD-03 Hàng chờ admin Tìm trọ: lọc theo loại, sắp theo cờ khẩn → khiếu nại tiền / báo cáo ưu tiên cao
/// → hồ sơ bị gắn cờ → còn lại theo thời gian (mục 2.12).
class HangChoAdminScreen extends StatefulWidget {
  const HangChoAdminScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  State<HangChoAdminScreen> createState() => _HangChoAdminScreenState();
}

class _HangChoAdminScreenState extends State<HangChoAdminScreen> {
  String? _loai;
  late Stream<List<ViecAdmin>> _hangCho = widget.dv.admin.hangCho();

  void _mo(ViecAdmin v) {
    final dv = widget.dv;
    switch (v.loai) {
      case 'khieu_nai':
        TroDieuHuong.mo(
          context,
          (_) => KhieuNaiCocScreen(dv: dv, datCocId: v.id),
        );
      case 'bao_cao' || 'khang_nghi':
        TroDieuHuong.mo(
          context,
          (_) => BaoCaoKhangNghiAdminScreen(dv: dv, viec: v),
        );
      default:
        TroDieuHuong.mo(context, (_) => DuyetTroScreen(dv: dv, viec: v));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Tìm trọ'),
      actions: [
        IconButton(
          tooltip: 'Cấu hình thời hạn (test)',
          onPressed: () => TroDieuHuong.mo(
            context,
            (_) => CauHinhAdminScreen(dv: widget.dv),
          ),
          icon: const Icon(Icons.timer_outlined),
        ),
      ],
    ),
    body: StreamBuilder<List<ViecAdmin>>(
      stream: _hangCho,
      builder: (context, s) {
        if (s.hasError) {
          return TroErrorState(
            onRetry: () => setState(() {
              _hangCho = widget.dv.admin.hangCho();
            }),
          );
        }
        if (!s.hasData) return const TroSkeletonList(count: 2);
        final ds = s.data!
            .where(
              (v) =>
                  _loai == null ||
                  v.loai == _loai ||
                  (_loai == 'chinh_sua' && v.loai.startsWith('chinh_sua')),
            )
            .toList();
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(TroSpacing.sm),
              child: Row(
                children: [
                  for (final (k, t) in const [
                    (null, 'Tất cả'),
                    ('nha_tro', 'Nhà trọ'),
                    ('phong', 'Phòng'),
                    ('chinh_sua', 'Chỉnh sửa chờ duyệt'),
                    ('bao_cao', 'Báo cáo'),
                    ('khieu_nai', 'Khiếu nại cọc'),
                    ('khang_nghi', 'Kháng nghị'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: TroSpacing.sm),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: _loai == k,
                        onSelected: (_) => setState(() => _loai = k),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ds.isEmpty
                  ? const TroEmptyState(
                      icon: Icons.task_alt,
                      title: 'Không có việc chờ xử lý',
                    )
                  : ListView.builder(
                      itemCount: ds.length,
                      itemBuilder: (context, i) {
                        final v = ds[i];
                        return ListTile(
                          leading: Icon(
                            v.uuTien == 0
                                ? Icons.priority_high
                                : (v.uuTien == 1
                                      ? Icons.flag
                                      : Icons.inbox_outlined),
                            color: v.uuTien <= 1
                                ? TroColors.danger
                                : TroColors.primary,
                          ),
                          title: Text(v.tieuDe),
                          subtitle: Text(
                            '${ViecAdmin.loaiLabels[v.loai]} · ${v.moTa} · ${formatNgayGio(v.luc)}',
                          ),
                          trailing: v.uuTien == 0
                              ? const TroStatusBadge(
                                  kind: TroBadgeKind.full,
                                  label: 'Cờ khẩn',
                                )
                              : null,
                          onTap: () => _mo(v),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

/// Admin đổi cấu hình thời hạn (mục 2.23: khi test được rút ngắn thời hạn qua file cấu hình).
class CauHinhAdminScreen extends StatefulWidget {
  const CauHinhAdminScreen({required this.dv, super.key});

  final TroDichVu dv;

  @override
  State<CauHinhAdminScreen> createState() => _CauHinhAdminScreenState();
}

class _CauHinhAdminScreenState extends State<CauHinhAdminScreen> {
  static const _khoa = {
    'choThanhToanPhut': 'Chờ thanh toán (phút)',
    'nhanPhongSauItNhatPhut': 'Nhận phòng sau ít nhất (phút)',
    'huyMienPhiPhut': 'Hủy miễn phí trong (phút)',
    'doiPhaiTruocPhut': 'Gửi yêu cầu thay đổi khi còn hơn (phút) tới T',
    'doiCachLucGuiItNhatPhut': 'Thời điểm mới cách lúc gửi ít nhất (phút)',
    'chuTraLoiDoiPhut': 'Chủ trả lời yêu cầu thay đổi (phút)',
    'anHanKhongDenPhut': 'Ân hạn "không đến" (phút)',
    'phanDoiPhut': 'Phản đối "không đến" (phút)',
    'nhacCuoiPhut': 'Nhắc cuối sau T (phút)',
    'tuHoanTatPhut': 'Tự hoàn tất sau T (phút)',
    'khieuNaiDenPhut': 'Khiếu nại tới T + (phút)',
    'baoKhongDenDenPhut': 'Báo "không đến" tới T + (phút)',
  };
  final _o = {for (final k in _khoa.keys) k: TextEditingController()};

  @override
  void dispose() {
    for (final c in _o.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cấu hình thời hạn (test)')),
    body: ListView(
      padding: const EdgeInsets.all(TroSpacing.screen),
      children: [
        const Text(
          'Để trống = dùng mặc định của đặc tả (bảng 2.16). Chỉ dùng khi test / demo.',
          style: TroText.bodySmall,
        ),
        for (final e in _khoa.entries)
          Padding(
            padding: const EdgeInsets.only(top: TroSpacing.sm),
            child: TextField(
              controller: _o[e.key],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: e.value),
            ),
          ),
        const SizedBox(height: TroSpacing.lg),
        FilledButton(
          onPressed: () => chayThaoTac(
            context,
            () => widget.dv.admin.goi('adminCauHinh', {
              'ghiDe': {
                for (final e in _o.entries)
                  if (num.tryParse(e.value.text.trim()) != null)
                    e.key: num.parse(e.value.text.trim()),
              },
            }),
            thanhCong: 'Đã lưu cấu hình',
          ),
          child: const Text('Lưu cấu hình'),
        ),
        TextButton(
          onPressed: () => chayThaoTac(
            context,
            () => widget.dv.admin.goi('adminCauHinh', {
              'ghiDe': <String, dynamic>{},
            }),
            thanhCong: 'Đã về mặc định',
          ),
          child: const Text('Về mặc định'),
        ),
      ],
    ),
  );
}
