import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/khang_nghi.dart';
import '../../models/tro_config.dart';
import '../../services/admin_service.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';

/// TRO-AD-04 Xử lý báo cáo · kháng nghị · khóa chức năng người dùng (mục 2.10, 2.12, 2.15).
class BaoCaoKhangNghiAdminScreen extends StatelessWidget {
  const BaoCaoKhangNghiAdminScreen({
    required this.dv,
    required this.viec,
    super.key,
  });

  final TroDichVu dv;
  final ViecAdmin viec;

  Future<void> _xong(
    BuildContext context,
    Future<void> Function() f,
    String ok,
  ) async {
    if (await chayThaoTac(context, f, thanhCong: ok) && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = viec.duLieu;
    return Scaffold(
      appBar: AppBar(
        title: Text(viec.loai == 'bao_cao' ? 'Báo cáo' : 'Kháng nghị'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TroSpacing.screen),
        children: viec.loai == 'bao_cao'
            ? _baoCao(context, m)
            : _khangNghi(context, m),
      ),
    );
  }

  List<Widget> _baoCao(BuildContext context, Map<String, dynamic> m) {
    final dt = (m['doiTuong'] as Map?) ?? const {};
    final noiQuy = m['lyDo'] == 'noi_quy_sai';
    return [
      Text(lyDoBaoCaoLabels[m['lyDo']] ?? '${m['lyDo']}', style: TroText.h2),
      Text('Đối tượng: ${dt['loai']} · ${dt['id']}', style: TroText.bodySmall),
      if (m['uuTienCao'] == true)
        const Text('Ưu tiên cao', style: TextStyle(color: TroColors.danger)),
      Text(
        m['duocTinh'] == true
            ? 'Báo cáo được tính (đã OTP, tài khoản ≥ 7 ngày)'
            : 'Báo cáo không tính vào ngưỡng gắn cờ',
        style: TroText.bodySmall,
      ),
      const SizedBox(height: TroSpacing.sm),
      Text('Ghi chú: ${m['ghiChu'] ?? ''}'),
      if (noiQuy) ...[
        Text(
          'Tiêu chí bị sai: ${(m['tieuChiSai'] as List? ?? const []).join(', ')}',
        ),
        const Text(
          'So với BẢN CHỤP nội quy lúc cọc (không so với tin hiện tại). Chủ đổi nội quy sau khi sinh viên đã nhận phòng → bác báo cáo.',
          style: TroText.bodySmall,
        ),
      ],
      if (dt['loai'] == 'nha_tro')
        TextButton(
          onPressed: () => TroDieuHuong.nhaTro(context, dv, dt['id'] as String),
          child: const Text('Mở nhà trọ'),
        ),
      if (dt['loai'] == 'phong')
        TextButton(
          onPressed: () => TroDieuHuong.phong(context, dv, dt['id'] as String),
          child: const Text('Mở phòng'),
        ),
      const Divider(height: 32),
      FilledButton(
        onPressed: () => _xong(
          context,
          () => dv.admin.goi('adminXuLyBaoCao', {
            'id': viec.id,
            'hopLe': true,
            'anDoiTuong': true,
            'ghiViPhamChu': noiQuy,
          }),
          'Đã xác nhận và ẩn đối tượng',
        ),
        child: Text(
          noiQuy ? 'Hợp lệ: ghi 1 vi phạm cho chủ trọ' : 'Hợp lệ: ẩn đối tượng',
        ),
      ),
      const SizedBox(height: TroSpacing.sm),
      OutlinedButton(
        onPressed: () => _xong(
          context,
          () => dv.admin.goi('adminXuLyBaoCao', {'id': viec.id, 'hopLe': true}),
          'Đã ghi nhận',
        ),
        child: const Text('Hợp lệ nhưng không ẩn'),
      ),
      const SizedBox(height: TroSpacing.sm),
      OutlinedButton(
        onPressed: () => _xong(
          context,
          () =>
              dv.admin.goi('adminXuLyBaoCao', {'id': viec.id, 'hopLe': false}),
          'Đã bác báo cáo',
        ),
        child: const Text('Báo cáo sai — bác (khôi phục nếu đang ẩn tạm)'),
      ),
      const Divider(height: 32),
      if (dt['loai'] == 'nguoi_dung')
        Wrap(
          spacing: TroSpacing.sm,
          children: [
            for (final (k, t) in const [
              ('coc', 'Khóa đặt cọc'),
              ('bao_cao', 'Khóa báo cáo'),
              ('dang_tin', 'Khóa đăng tin / nhận cọc'),
            ])
              OutlinedButton(
                onPressed: () => chayThaoTac(
                  context,
                  () => dv.admin.goi('adminKhoaChucNang', {
                    'uid': dt['id'],
                    'chucNang': k,
                    'lyDo': m['lyDo'],
                  }),
                  thanhCong: 'Đã khóa 30 ngày',
                ),
                child: Text(t),
              ),
          ],
        ),
    ];
  }

  List<Widget> _khangNghi(BuildContext context, Map<String, dynamic> m) {
    final qd = (m['quyetDinh'] as Map?) ?? const {};
    final xoaViPham = qd['loai'] == 'vi_pham' || qd['loai'] == 'khieu_nai_sai';
    return [
      Text('Kháng nghị: ${qd['loai']}', style: TroText.h2),
      if (m['hanTraLoi'] != null)
        Text(
          'Trả lời trước ${formatNgayGio((m['hanTraLoi'] as dynamic).toDate() as DateTime)}',
          style: TroText.bodySmall,
        ),
      const SizedBox(height: TroSpacing.sm),
      Text(m['lyDo'] as String? ?? ''),
      for (final b in List<String>.from(m['bangChung'] as List? ?? const []))
        Text(b, style: TroText.bodySmall),
      const Text(
        'Đang kháng nghị thì hình phạt vẫn còn hiệu lực.',
        style: TroText.bodySmall,
      ),
      const Divider(height: 32),
      if (xoaViPham)
        FilledButton(
          onPressed: () => _xong(
            context,
            () => dv.admin.goi('adminXuLyKhangNghi', {
              'id': viec.id,
              'ketQua': 'xoa_vi_pham',
            }),
            'Đã xóa lần vi phạm',
          ),
          child: Text(KhangNghi.ketQuaLabels['xoa_vi_pham']!),
        )
      else
        FilledButton(
          onPressed: () => _xong(
            context,
            () => dv.admin.goi('adminXuLyKhangNghi', {
              'id': viec.id,
              'ketQua': 'go_khoa',
            }),
            'Đã gỡ khóa',
          ),
          child: Text(KhangNghi.ketQuaLabels['go_khoa']!),
        ),
      const SizedBox(height: TroSpacing.sm),
      OutlinedButton(
        onPressed: () => _xong(
          context,
          () => dv.admin.goi('adminXuLyKhangNghi', {
            'id': viec.id,
            'ketQua': 'giu_nguyen',
          }),
          'Đã giữ nguyên',
        ),
        child: Text(KhangNghi.ketQuaLabels['giu_nguyen']!),
      ),
    ];
  }
}
