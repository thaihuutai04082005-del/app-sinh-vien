import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/dat_coc.dart';
import '../../models/khieu_nai.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';

/// TRO-AD-02 Khiếu nại cọc: so bản chụp thông tin lúc cọc với bằng chứng hai bên, lịch sử khoản cọc
/// → chọn 1 trong 3 hướng. Không bao giờ tự chuyển tiền khi đang khiếu nại (mục 2.12).
class KhieuNaiCocScreen extends StatelessWidget {
  const KhieuNaiCocScreen({
    required this.dv,
    required this.datCocId,
    super.key,
  });

  final TroDichVu dv;
  final String datCocId;

  Future<void> _quyet(BuildContext context, DatCoc d, String ketLuan) async {
    final lyDo = TextEditingController();
    var phongSau = 'available';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(KhieuNai.ketLuanLabels[ketLuan]!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ketLuan == 'chu_vi_pham')
                DropdownButtonFormField<String>(
                  initialValue: phongSau,
                  decoration: const InputDecoration(
                    labelText: 'Phòng sau khi hoàn tiền',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Còn trống'),
                    ),
                    DropdownMenuItem(
                      value: 'rented',
                      child: Text('Đã cho thuê (cho người khác)'),
                    ),
                    DropdownMenuItem(
                      value: 'hidden',
                      child: Text('Tạm ẩn (phòng có vấn đề)'),
                    ),
                  ],
                  onChanged: (v) => setS(() => phongSau = v ?? 'available'),
                ),
              TextField(
                controller: lyDo,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do quyết định (ghi nhật ký)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Quyết định'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final xong = await chayThaoTac(
      context,
      () => dv.admin.goi('adminQuyetKhieuNai', {
        'datCocId': d.id,
        'ketLuan': ketLuan,
        'phongSau': phongSau,
        'lyDo': lyDo.text.trim(),
      }),
      thanhCong: 'Đã quyết định',
    );
    if (xong && context.mounted) Navigator.pop(context);
  }

  Future<void> _luaDao(BuildContext context, DatCoc d) async {
    final lyDo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết luận chủ trọ lừa đảo / giấy tờ giả'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ẩn mọi nhà trọ của chủ, hoàn 100% mọi khoản cọc app còn giữ (khoản đã hoàn tất không đảo ngược), gửi đề nghị khóa cả tài khoản tới admin danh tính.',
            ),
            TextField(
              controller: lyDo,
              decoration: const InputDecoration(labelText: 'Lý do'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TroColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kết luận'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await chayThaoTac(
        context,
        () => dv.admin.goi('adminLuaDao', {
          'chuTroId': d.chuTroId,
          'lyDo': lyDo.text.trim(),
        }),
        thanhCong: 'Đã xử lý',
      );
    }
  }

  Widget _bangChung(List<String> ds) => Wrap(
    spacing: TroSpacing.sm,
    runSpacing: TroSpacing.sm,
    children: [
      for (final u in ds)
        SizedBox(
          width: 120,
          height: 120,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(u)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetworkPhoto(u),
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Khiếu nại cọc')),
    body: TroStream<DatCoc?>(
      stream: () => dv.datCoc.datCoc(datCocId),
      builder: (context, d) {
        if (d == null) return const TroEmptyState(title: 'Không tìm thấy');
        final k = d.khieuNai;
        final bc = d.chupThongTin ?? const {};
        final p = (bc['phong'] as Map?) ?? const {};
        final nq = ((bc['nhaTro'] as Map?)?['noiQuy'] as Map?) ?? const {};
        return ListView(
          padding: const EdgeInsets.all(TroSpacing.screen),
          children: [
            Text('${d.tenPhong} · ${d.tenNhaTro}', style: TroText.h2),
            Text(
              '${formatPrice(d.soTien)} · T = ${formatNgayGio(d.t)} · ${d.trangThaiLabel}',
              style: TroText.bodySmall,
            ),
            if (k?.coKhan ?? false)
              const Text(
                '⚠ Cờ khẩn: treo quá 72 giờ',
                style: TextStyle(color: TroColors.danger),
              ),
            const Divider(height: 32),
            Text(
              k?.loai == 'phan_doi'
                  ? 'Sinh viên phản đối "không đến"'
                  : 'Sinh viên khiếu nại: ${lyDoKhieuNaiLabels[k?.lyDo] ?? k?.lyDo ?? ''}',
              style: TroText.h3,
            ),
            Text(k?.moTa ?? '', style: TroText.body),
            _bangChung(k?.bangChung ?? const []),
            const SizedBox(height: TroSpacing.md),
            const Text('Chủ trọ trả lời', style: TroText.h3),
            Text(
              k?.chuTraLoi ?? 'Chưa trả lời (quá 24 giờ thì quyết dựa trên bằng chứng sinh viên).',
              style: TroText.body,
            ),
            _bangChung(k?.chuBangChung ?? const []),
            if (d.khongDen != null)
              Text(
                'Chủ báo "không đến" lúc ${formatNgayGio(d.khongDen!.luc)}',
                style: TroText.bodySmall,
              ),
            if (d.doi != null)
              Text(
                'Yêu cầu thay đổi: ${d.doi!.ketQua} → ${formatNgayGio(d.doi!.thoiDiemMoi)}',
                style: TroText.bodySmall,
              ),
            const Divider(height: 32),
            const Text('Bản chụp thông tin lúc cọc', style: TroText.h3),
            Text(
              'Giá ${formatPrice((p['giaThue'] as num?) ?? 0)} · ${p['dienTich'] ?? '?'} m² · tối đa ${p['soNguoiToiDa'] ?? '?'} người',
            ),
            Text(
              'Tiện ích: ${[for (final t in (p['tienIch'] as List? ?? const [])) tienIchPhongLabels[t] ?? t].join(', ')}',
            ),
            Text(
              'Nội quy: ${nq['gioGiac'] == 'tu_do' ? 'Tự do 24/24' : 'Đóng cửa ${nq['gioDongCua'] ?? ''}'} · thú cưng ${nq['thuCung'] == true ? 'có' : 'không'} · qua đêm ${nq['oQuaDem'] == true ? 'có' : 'không'} · báo trước ${nq['baoTruocTuan'] ?? '?'} tuần',
            ),
            if ((p['anh'] as List?)?.isNotEmpty ?? false)
              _bangChung(List<String>.from(p['anh'] as List)),
            const Divider(height: 32),
            if (d.status == 'disputed') ...[
              FilledButton(
                onPressed: () => _quyet(context, d, 'chu_vi_pham'),
                child: const Text('Chủ trọ vi phạm — hoàn 100%'),
              ),
              const SizedBox(height: TroSpacing.sm),
              OutlinedButton(
                onPressed: () => _quyet(context, d, 'sv_da_nhan'),
                child: const Text('Sinh viên đã nhận phòng — chuyển tiền'),
              ),
              const SizedBox(height: TroSpacing.sm),
              OutlinedButton(
                onPressed: () => _quyet(context, d, 'sv_khong_den'),
                child: const Text('Sinh viên không đến — mất cọc'),
              ),
              const SizedBox(height: TroSpacing.lg),
            ],
            TextButton(
              onPressed: () => _luaDao(context, d),
              style: TextButton.styleFrom(foregroundColor: TroColors.danger),
              child: const Text('Kết luận chủ trọ lừa đảo / giấy tờ giả'),
            ),
          ],
        );
      },
    ),
  );
}
