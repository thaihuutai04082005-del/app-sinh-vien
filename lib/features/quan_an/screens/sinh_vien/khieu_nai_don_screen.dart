import 'package:flutter/material.dart';

import '../../models/don_mon.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/don_dem_nguoc_tile.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';

/// QA-SV-09 Khiếu nại đơn (đơn trả trên app) hoặc phản đối "Khách không nhận" (mục 3.5b, 3.5d).
///
/// - Khiếu nại: chọn lý do, mô tả, ảnh (bắt buộc trừ "Không nhận được món"). Tiền tiếp tục được giữ.
/// - Phản đối: mô tả + bằng chứng (không bắt buộc), trong hạn phản đối; chuyển admin xét.
class KhieuNaiDonScreen extends StatefulWidget {
  const KhieuNaiDonScreen({
    required this.dv,
    required this.don,
    this.phanDoi = false,
    super.key,
  });

  final QuanAnDichVu dv;
  final DonMon don;
  final bool phanDoi;

  @override
  State<KhieuNaiDonScreen> createState() => _KhieuNaiDonScreenState();
}

class _KhieuNaiDonScreenState extends State<KhieuNaiDonScreen> {
  String? _lyDo;
  final _moTa = TextEditingController();
  List<String> _anh = const [];
  bool _dangGui = false;
  String? _loi;
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh();

  @override
  void dispose() {
    _moTa.dispose();
    super.dispose();
  }

  bool get _canAnh =>
      !widget.phanDoi && _lyDo != null && lyDoKhieuNaiCanAnh(_lyDo!);

  Future<void> _gui() async {
    if (_dangGui) return;
    String? loi;
    if (!widget.phanDoi && _lyDo == null) loi = 'Chọn lý do.';
    if (_moTa.text.trim().length < (widget.phanDoi ? 5 : 10)) {
      loi ??= widget.phanDoi
          ? 'Nhập mô tả (ít nhất 5 ký tự).'
          : 'Nhập mô tả (ít nhất 10 ký tự).';
    }
    if (_canAnh && _anh.isEmpty) {
      loi ??= 'Lý do này cần ít nhất 1 ảnh bằng chứng.';
    }
    setState(() => _loi = loi);
    if (loi != null) return;
    setState(() => _dangGui = true);
    final d = widget.don;
    final ok = await chayThaoTac(
      context,
      () => widget.dv.donMon.thaoTac(d.id, d.version, {
        'loai': widget.phanDoi ? 'SV_PHAN_DOI' : 'SV_KHIEU_NAI',
        if (!widget.phanDoi) 'lyDo': _lyDo,
        'moTa': _moTa.text.trim(),
        'anh': _anh,
      }),
      thanhCong: widget.phanDoi
          ? 'Đã gửi phản đối, admin sẽ xem xét'
          : 'Đã gửi khiếu nại, tiền tiếp tục được giữ',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hanPhanDoi = widget.don.khongNhan?.hanPhanDoi;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.phanDoi ? 'Phản đối "khách không nhận"' : 'Khiếu nại đơn',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: FutureBuilder<QuanAnConfig>(
                  future: _cfg,
                  builder: (context, c) {
                    final cfg = c.data ?? const QuanAnConfig();
                    return ListView(
                      padding: const EdgeInsets.all(QuanAnSpacing.screen),
                      children: [
                        Text(
                          widget.don.tenQuan.isEmpty
                              ? 'Đơn món'
                              : 'Đơn tại ${widget.don.tenQuan}',
                          style: QuanAnText.h2,
                        ),
                        const SizedBox(height: QuanAnSpacing.md),
                        if (widget.phanDoi) ...[
                          if (hanPhanDoi != null) ...[
                            DonDemNguocTile(
                              nhan: 'Hạn phản đối',
                              moc: hanPhanDoi,
                              canhBao: true,
                            ),
                            const SizedBox(height: QuanAnSpacing.md),
                          ],
                          const QuanAnWarningBox(
                            message:
                                'Quán báo bạn không nhận món. Nếu bạn đã nhận món hoặc đã có mặt đúng hẹn, hãy mô tả và gửi bằng chứng (nếu có) để admin xem xét. Chưa có kết luận nào cho tới khi admin xét.',
                          ),
                        ] else
                          QuanAnWarningBox(
                            message:
                                'Tiền của đơn tiếp tục được giữ trong lúc khiếu nại. Khiếu nại sai sự thật bị admin bác ${cfg.khieuNaiSaiSoLan} lần trong ${cfg.chiSoNgay} ngày sẽ bị khóa đặt món trả trên app ${cfg.khieuNaiSaiKhoaNgay} ngày.',
                          ),
                        const SizedBox(height: QuanAnSpacing.lg),
                        if (!widget.phanDoi) ...[
                          const Text('Lý do', style: QuanAnText.h3),
                          RadioGroup<String>(
                            groupValue: _lyDo,
                            onChanged: (v) => setState(() => _lyDo = v),
                            child: Column(
                              children: [
                                for (final e in lyDoKhieuNaiDonLabels.entries)
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    value: e.key,
                                    title: Text(e.value),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.sm),
                        ],
                        TextField(
                          controller: _moTa,
                          maxLines: 5,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText: widget.phanDoi
                                ? 'Mô tả: vì sao bạn phản đối'
                                : 'Mô tả chi tiết',
                          ),
                        ),
                        const SizedBox(height: QuanAnSpacing.lg),
                        QuanAnMediaField(
                          storage: widget.dv.storage,
                          folder: 'quan_an_anh',
                          nhan: widget.phanDoi
                              ? 'Ảnh bằng chứng (không bắt buộc)'
                              : _canAnh
                              ? 'Ảnh bằng chứng (bắt buộc)'
                              : 'Ảnh bằng chứng (không bắt buộc với "Không nhận được món")',
                          goiY: widget.phanDoi
                              ? 'Ví dụ ảnh chụp tin nhắn, cuộc gọi nhỡ, nơi bạn đã chờ.'
                              : 'Chụp rõ món bị thiếu / sai / hư.',
                          toiThieu: _canAnh ? 1 : 0,
                          toiDa: 5,
                          giaTri: _anh,
                          onChanged: (v) => setState(() => _anh = v),
                          pickImages: widget.dv.pickImages,
                        ),
                        if (_loi != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: QuanAnSpacing.sm,
                            ),
                            child: Text(
                              _loi!,
                              style: const TextStyle(
                                color: QuanAnColors.danger,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: QuanAnColors.white,
              boxShadow: [
                BoxShadow(
                  color: QuanAnColors.primary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.all(QuanAnSpacing.screen),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _dangGui ? null : _gui,
                        child: _dangGui
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: QuanAnColors.white,
                                ),
                              )
                            : Text(
                                widget.phanDoi
                                    ? 'Gửi phản đối'
                                    : 'Gửi khiếu nại',
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
