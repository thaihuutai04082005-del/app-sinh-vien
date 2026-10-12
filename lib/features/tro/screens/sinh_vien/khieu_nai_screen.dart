import 'package:flutter/material.dart';

import '../../models/dat_coc.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';

/// TRO-SV-09 Gửi khiếu nại "Chủ trọ không thực hiện đúng cam kết" hoặc phản đối "không đến" (mục 2.5c):
/// bắt buộc mô tả + ảnh / video bằng chứng. Tiền tiếp tục được giữ, không bao giờ chuyển khi đang khiếu nại.
///
/// Đặc tả yêu cầu bằng chứng quay trong app có GPS; theo quyết định của nhóm, bản này cho tải lên / dán link
/// (quay trong app có GPS làm khi có máy Android thật).
class KhieuNaiScreen extends StatefulWidget {
  const KhieuNaiScreen({
    required this.dv,
    required this.datCoc,
    this.phanDoi = false,
    super.key,
  });

  final TroDichVu dv;
  final DatCoc datCoc;
  final bool phanDoi;

  @override
  State<KhieuNaiScreen> createState() => _KhieuNaiScreenState();
}

class _KhieuNaiScreenState extends State<KhieuNaiScreen> {
  String? _lyDo;
  final _moTa = TextEditingController();
  List<String> _bangChung = const [];
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _moTa.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    String? loi;
    if (!widget.phanDoi && _lyDo == null) loi = 'Chọn lý do.';
    if (_moTa.text.trim().length < 10) loi ??= 'Nhập mô tả (ít nhất 10 ký tự).';
    if (_bangChung.isEmpty) loi ??= 'Cần ít nhất 1 ảnh / video bằng chứng.';
    setState(() => _loi = loi);
    if (loi != null) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.datCoc.thaoTac(widget.datCoc.id, widget.datCoc.version, {
        'loai': widget.phanDoi ? 'SV_PHAN_DOI' : 'SV_KHIEU_NAI',
        'lyDo': _lyDo ?? 'phan_doi_khong_den',
        'moTa': _moTa.text.trim(),
        'bangChung': _bangChung,
      }),
      thanhCong: widget.phanDoi
          ? 'Đã gửi phản đối, admin sẽ xem xét'
          : 'Đã gửi khiếu nại, tiền cọc tiếp tục được giữ',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.phanDoi
            ? 'Phản đối "không đến nhận phòng"'
            : 'Chủ trọ không thực hiện đúng cam kết',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(TroSpacing.screen),
      children: [
        TroWarningBox(
          message: widget.phanDoi
              ? 'Bạn có 12 giờ để phản đối. Nếu bạn đã đến / đã nhận phòng, hãy mô tả và gửi bằng chứng.'
              : 'Khiếu nại sai sự thật bị admin bác 3 lần trong 30 ngày sẽ bị khóa đặt cọc trên app 30 ngày.',
        ),
        const SizedBox(height: TroSpacing.lg),
        if (!widget.phanDoi) ...[
          const Text('Lý do', style: TroText.h3),
          RadioGroup<String>(
            groupValue: _lyDo,
            onChanged: (v) => setState(() => _lyDo = v),
            child: Column(
              children: [
                for (final e in lyDoKhieuNaiLabels.entries)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: e.key,
                    title: Text(e.value),
                  ),
              ],
            ),
          ),
        ],
        TextField(
          controller: _moTa,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
        ),
        const SizedBox(height: TroSpacing.lg),
        TroMediaField(
          storage: widget.dv.storage,
          folder: 'tro_anh',
          nhan: 'Ảnh / video bằng chứng',
          goiY: 'Chụp tại nhà trọ, thấy rõ vấn đề.',
          toiThieu: 1,
          toiDa: 5,
          giaTri: _bangChung,
          onChanged: (v) => setState(() => _bangChung = v),
          pickImages: widget.dv.pickImages,
        ),
        if (_loi != null)
          Padding(
            padding: const EdgeInsets.only(top: TroSpacing.sm),
            child: Text(_loi!, style: const TextStyle(color: TroColors.danger)),
          ),
        const SizedBox(height: TroSpacing.xl),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: Text(_dangGui ? 'Đang gửi...' : 'Gửi'),
        ),
      ],
    ),
  );
}
