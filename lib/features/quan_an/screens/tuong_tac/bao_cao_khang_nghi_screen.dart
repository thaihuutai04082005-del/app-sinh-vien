import 'package:flutter/material.dart';

import '../../services/bao_cao_service.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_theme.dart';

/// Các lý do báo cáo theo đối tượng (mục 3.10, lý do riêng mục 3.5h).
List<String> lyDoTheoDoiTuong(String loai) => switch (loai) {
  'quan' => [
    'quan_khong_ton_tai',
    'sai_gio',
    'sai_gia',
    'khuyen_mai_sai',
    'khai_sai_loai',
    'mat_ve_sinh',
    'chuyen_khoan_ngoai_app',
    'lua_dao',
    'khac',
  ],
  'mon' => [
    'sai_gia',
    'mat_ve_sinh',
    'chuyen_khoan_ngoai_app',
    'lua_dao',
    'khac',
  ],
  'nguoi_dung' => ['chuyen_khoan_ngoai_app', 'lua_dao', 'xuc_pham', 'khac'],
  _ => ['xuc_pham', 'chuyen_khoan_ngoai_app', 'lua_dao', 'spam', 'khac'],
};

/// QA-SV-16 Báo cáo (mục 3.10): quán, món, người dùng, đánh giá, tin nhắn.
/// [loai]: 'quan' | 'mon' | 'nguoi_dung' | 'danh_gia' | 'tin_nhan'.
Future<void> moBaoCao(
  BuildContext context,
  QuanAnDichVu dv, {
  required String loai,
  required String id,
  String? chatId,
  String? lyDoMacDinh,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => Theme(
    data: Theme.of(context),
    child: _BaoCaoSheet(
      dv: dv,
      loai: loai,
      id: id,
      chatId: chatId,
      lyDoMacDinh: lyDoMacDinh,
    ),
  ),
);

class _BaoCaoSheet extends StatefulWidget {
  const _BaoCaoSheet({
    required this.dv,
    required this.loai,
    required this.id,
    this.chatId,
    this.lyDoMacDinh,
  });

  final QuanAnDichVu dv;
  final String loai;
  final String id;
  final String? chatId;
  final String? lyDoMacDinh;

  @override
  State<_BaoCaoSheet> createState() => _BaoCaoSheetState();
}

class _BaoCaoSheetState extends State<_BaoCaoSheet> {
  late String? _lyDo = widget.lyDoMacDinh;
  final _ghiChu = TextEditingController();
  bool _dangGui = false;

  @override
  void dispose() {
    _ghiChu.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (_lyDo == null || _dangGui) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.baoCao.baoCao(
        loai: widget.loai,
        id: widget.id,
        chatId: widget.chatId,
        lyDo: _lyDo!,
        ghiChu: _ghiChu.text.trim(),
      ),
      thanhCong: 'Đã gửi báo cáo. Bạn sẽ được báo kết quả.',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(QuanAnSpacing.screen),
        children: [
          const Text('Báo cáo', style: QuanAnText.h2),
          const SizedBox(height: QuanAnSpacing.sm),
          RadioGroup<String>(
            groupValue: _lyDo,
            onChanged: (v) => setState(() => _lyDo = v),
            child: Column(
              children: [
                for (final k in lyDoTheoDoiTuong(widget.loai))
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: k,
                    title: Text(lyDoBaoCao[k] ?? k),
                    subtitle: lyDoUuTienCao.contains(k)
                        ? const Text('Ưu tiên cao')
                        : null,
                  ),
              ],
            ),
          ),
          TextField(
            controller: _ghiChu,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
          ),
          const SizedBox(height: QuanAnSpacing.lg),
          FilledButton(
            onPressed: _lyDo == null || _dangGui ? null : _gui,
            child: Text(_dangGui ? 'Đang gửi...' : 'Gửi báo cáo'),
          ),
          if (_lyDo == null)
            const Padding(
              padding: EdgeInsets.only(top: QuanAnSpacing.xs),
              child: Text(
                'Chọn một lý do để gửi báo cáo.',
                style: QuanAnText.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Kháng nghị (mục 3.15): ghi lý do + tối đa 3 bằng chứng; mỗi quyết định 1 lần, trong 7 ngày.
Future<void> moKhangNghi(
  BuildContext context,
  QuanAnDichVu dv, {
  required String loai,
  required String id,
  String? col,
}) async {
  final lyDo = TextEditingController();
  var bangChung = <String>[];
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Kháng nghị'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Đang kháng nghị thì hình phạt vẫn còn hiệu lực. Admin trả lời trong 48 giờ.',
                style: QuanAnText.bodySmall,
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              TextField(
                controller: lyDo,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lý do kháng nghị',
                ),
              ),
              const SizedBox(height: QuanAnSpacing.sm),
              QuanAnMediaField(
                storage: dv.storage,
                folder: 'quan_an_anh',
                nhan: 'Bằng chứng',
                toiDa: 3, // mục 3.15: tối đa 3 ảnh / video
                giaTri: bangChung,
                onChanged: (v) => setS(() => bangChung = v),
                pickImages: dv.pickImages,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi kháng nghị'),
          ),
        ],
      ),
    ),
  );
  // Không dispose controller ngay: hộp thoại còn đang chạy hiệu ứng đóng.
  final noiDung = lyDo.text.trim();
  if (ok == true && context.mounted) {
    await chayThaoTac(
      context,
      () => dv.baoCao.khangNghi(
        loai: loai,
        id: id,
        col: col,
        lyDo: noiDung,
        bangChung: bangChung,
      ),
      thanhCong: 'Đã gửi kháng nghị',
    );
  }
}
