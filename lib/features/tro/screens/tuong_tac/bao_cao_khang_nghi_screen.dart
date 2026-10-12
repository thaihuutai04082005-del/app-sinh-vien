import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_theme.dart';

/// TRO-SV-15 Báo cáo (mục 2.10): nhà trọ, phòng, người dùng, đánh giá, tin nhắn.
/// Báo cáo "Nội quy không đúng tại thời điểm giao dịch" bắt chọn tiêu chí bị sai và thời điểm xảy ra.
Future<void> moBaoCao(
  BuildContext context,
  TroDichVu dv, {
  required String loai,
  required String id,
  String? chatId,
  String? datCocId,
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
      datCocId: datCocId,
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
    this.datCocId,
    this.lyDoMacDinh,
  });

  final TroDichVu dv;
  final String loai;
  final String id;
  final String? chatId;
  final String? datCocId;
  final String? lyDoMacDinh;

  @override
  State<_BaoCaoSheet> createState() => _BaoCaoSheetState();
}

class _BaoCaoSheetState extends State<_BaoCaoSheet> {
  late String? _lyDo = widget.lyDoMacDinh;
  final _ghiChu = TextEditingController();
  final _tieuChi = <String>{};
  DateTime? _thoiDiem;
  bool _dangGui = false;

  @override
  void dispose() {
    _ghiChu.dispose();
    super.dispose();
  }

  List<String> get _cacLyDo => switch (widget.loai) {
    'nha_tro' || 'phong' => [
      'khong_ton_tai',
      'sai_gia_mo_ta',
      'noi_quy_sai',
      'da_cho_thue_van_dang',
      'chuyen_coc_ngoai_app',
      'lua_dao',
      'khac',
    ],
    'nguoi_dung' => ['chuyen_coc_ngoai_app', 'lua_dao', 'xuc_pham', 'khac'],
    _ => ['xuc_pham', 'chuyen_coc_ngoai_app', 'lua_dao', 'khac'],
  };

  Future<void> _gui() async {
    if (_lyDo == null) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.baoCao.baoCao(
        loai: widget.loai,
        id: widget.id,
        chatId: widget.chatId,
        lyDo: _lyDo!,
        ghiChu: _ghiChu.text.trim(),
        tieuChiSai: _tieuChi.toList(),
        thoiDiemXayRa: _thoiDiem,
        datCocId: widget.datCocId,
      ),
      thanhCong: 'Đã gửi báo cáo. Bạn sẽ được báo kết quả.',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final noiQuy = _lyDo == 'noi_quy_sai';
    final duDieuKien =
        _lyDo != null &&
        (!noiQuy || (_tieuChi.isNotEmpty && _thoiDiem != null));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(TroSpacing.screen),
        children: [
          const Text('Báo cáo', style: TroText.h2),
          const SizedBox(height: TroSpacing.sm),
          RadioGroup<String>(
            groupValue: _lyDo,
            onChanged: (v) => setState(() => _lyDo = v),
            child: Column(
              children: [
                for (final k in _cacLyDo)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: k,
                    title: Text(lyDoBaoCaoLabels[k] ?? k),
                    subtitle: k == 'chuyen_coc_ngoai_app' || k == 'lua_dao'
                        ? const Text('Ưu tiên cao')
                        : null,
                  ),
              ],
            ),
          ),
          if (noiQuy) ...[
            const Text('Tiêu chí bị sai', style: TroText.h3),
            Wrap(
              spacing: TroSpacing.sm,
              children: [
                for (final (k, t) in const [
                  ('gioGiac', 'Giờ giấc ra vào'),
                  ('thuCung', 'Nuôi thú cưng'),
                  ('oQuaDem', 'Ở qua đêm'),
                  ('baoTruocTuan', 'Báo trước khi trả phòng'),
                ])
                  FilterChip(
                    label: Text(t),
                    selected: _tieuChi.contains(k),
                    onSelected: (on) => setState(
                      () => on ? _tieuChi.add(k) : _tieuChi.remove(k),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TroSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDate: DateTime.now(),
                );
                if (d != null) setState(() => _thoiDiem = d);
              },
              icon: const Icon(Icons.event),
              label: Text(
                _thoiDiem == null
                    ? 'Thời điểm phát hiện / xảy ra'
                    : formatNgay(_thoiDiem!),
              ),
            ),
            const SizedBox(height: TroSpacing.xs),
            const Text(
              'Chỉ được chấp nhận khi nội quy đã sai từ lúc giao dịch / nhận phòng. Chủ đổi nội quy sau đó không tính.',
              style: TroText.bodySmall,
            ),
          ],
          TextField(
            controller: _ghiChu,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
          ),
          const SizedBox(height: TroSpacing.lg),
          FilledButton(
            onPressed: !duDieuKien || _dangGui ? null : _gui,
            child: Text(_dangGui ? 'Đang gửi...' : 'Gửi báo cáo'),
          ),
        ],
      ),
    );
  }
}

/// Kháng nghị (mục 2.15): ghi lý do + tối đa 3 bằng chứng; mỗi quyết định 1 lần, trong 7 ngày.
Future<void> moKhangNghi(
  BuildContext context,
  TroDichVu dv, {
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
                style: TroText.bodySmall,
              ),
              const SizedBox(height: TroSpacing.sm),
              TextField(
                controller: lyDo,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lý do (ít nhất 10 ký tự)',
                ),
              ),
              const SizedBox(height: TroSpacing.sm),
              TroMediaField(
                storage: dv.storage,
                folder: 'tro_anh',
                nhan: 'Bằng chứng',
                toiDa: 3,
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
  if (ok == true && context.mounted) {
    await chayThaoTac(
      context,
      () => dv.baoCao.khangNghi(
        loai: loai,
        id: id,
        col: col,
        lyDo: lyDo.text.trim(),
        bangChung: bangChung,
      ),
      thanhCong: 'Đã gửi kháng nghị',
    );
  }
}
