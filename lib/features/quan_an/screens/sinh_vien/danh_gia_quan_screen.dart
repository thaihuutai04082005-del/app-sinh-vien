import 'package:flutter/material.dart';

import '../../models/danh_gia.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';

String _d1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// QA-SV-13 Viết / cập nhật đánh giá (mục 3.4 Bước 6, 3.9): chấm 1–5 sao ĐỦ 4 tiêu chí
/// (Món ăn · Giá cả · Vệ sinh · Phục vụ), không có ô điểm tổng — điểm tổng thể là trung bình
/// 4 tiêu chí, hiện ngay khi chấm đủ; thẻ nhanh; nhận xét tối thiểu theo cấu hình; ảnh tối đa theo cấu hình.
class DanhGiaQuanScreen extends StatefulWidget {
  const DanhGiaQuanScreen({
    required this.dv,
    required this.quanId,
    required this.tenQuan,
    super.key,
  });

  final QuanAnDichVu dv;
  final String quanId;

  /// Rỗng thì tự đọc tên quán từ hệ thống.
  final String tenQuan;

  @override
  State<DanhGiaQuanScreen> createState() => _DanhGiaQuanScreenState();
}

class _DanhGiaQuanScreenState extends State<DanhGiaQuanScreen> {
  static const _bieuTuong = {
    'monAn': '🍜',
    'giaCa': '💰',
    'veSinh': '🧹',
    'phucVu': '🙋',
  };

  final _diem = <String, int>{};
  final _the = <String>{};
  final _nhanXet = TextEditingController();
  List<String> _anh = const [];
  QuanAnConfig _cfg = const QuanAnConfig();
  late Stream<DanhGia?> _cuaToi = widget.dv.danhGia.cuaToi(widget.quanId);
  late String _tenQuan = widget.tenQuan;
  bool _laChuQuan = false;
  bool _daNap = false;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _napQuan();
    _napCauHinh();
  }

  @override
  void dispose() {
    _nhanXet.dispose();
    super.dispose();
  }

  Future<void> _napQuan() async {
    try {
      final q = await widget.dv.quan.quan(widget.quanId).first;
      if (!mounted || q == null) return;
      setState(() {
        if (_tenQuan.isEmpty) _tenQuan = q.ten;
        _laChuQuan = widget.dv.uid.isNotEmpty && q.chuQuanId == widget.dv.uid;
      });
    } catch (_) {}
  }

  Future<void> _napCauHinh() async {
    try {
      final c = await widget.dv.donMon.cauHinh();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
  }

  void _nap(DanhGia? cu) {
    if (_daNap) return;
    _daNap = true;
    if (cu == null) return;
    _diem.addAll(cu.diem);
    _the.addAll(cu.the);
    _nhanXet.text = cu.nhanXet;
    _anh = cu.anh;
  }

  Future<void> _gui() async {
    String? loi;
    if (!duBonTieuChi(_diem)) loi = 'Hãy chấm đủ cả 4 tiêu chí.';
    if (_nhanXet.text.trim().length < _cfg.danhGiaNhanXetToiThieu) {
      loi ??= 'Nhận xét ít nhất ${_cfg.danhGiaNhanXetToiThieu} ký tự.';
    }
    setState(() => _loi = loi);
    if (loi != null) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.danhGia.gui(
        widget.quanId,
        diem: {for (final (ma, _) in tieuChiDanhGia) ma: _diem[ma]!},
        the: _the.toList(),
        nhanXet: _nhanXet.text.trim(),
        anh: _anh,
      ),
      thanhCong: 'Đã gửi đánh giá. Cảm ơn bạn!',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  Widget _hangSao(String ma, String nhan) {
    final diem = _diem[ma] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_bieuTuong[ma] ?? ''} $nhan', style: QuanAnText.label),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$nhan: $i sao',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => setState(() => _diem[ma] = i),
                  icon: Icon(
                    diem >= i ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 32,
                    color: QuanAnColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tong = tinhDiemTong(_diem);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tenQuan.isEmpty ? 'Đánh giá quán' : 'Đánh giá · $_tenQuan',
        ),
      ),
      body: widget.dv.uid.isEmpty
          ? const QuanAnEmptyState(
              icon: Icons.login_rounded,
              title: 'Vui lòng đăng nhập để đánh giá',
            )
          : _laChuQuan
          ? const QuanAnEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Chủ quán không đánh giá quán của mình',
              message: 'Bạn có thể trả lời công khai các đánh giá của khách.',
            )
          : StreamBuilder<DanhGia?>(
              stream: _cuaToi,
              builder: (context, snap) {
                if (snap.hasError) {
                  return QuanAnErrorState(
                    message: 'Không tải được đánh giá của bạn',
                    onRetry: () => setState(
                      () => _cuaToi = widget.dv.danhGia.cuaToi(widget.quanId),
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SingleChildScrollView(
                    child: QuanAnSkeletonList(count: 1),
                  );
                }
                final cu = snap.data;
                _nap(cu);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(QuanAnSpacing.screen),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (cu != null)
                            const Padding(
                              padding: EdgeInsets.only(
                                bottom: QuanAnSpacing.md,
                              ),
                              child: Text(
                                'Bạn đang cập nhật đánh giá đã viết.',
                                style: QuanAnText.bodySmall,
                              ),
                            ),
                          const Text(
                            'Chấm sao cho 4 tiêu chí',
                            style: QuanAnText.h3,
                          ),
                          const SizedBox(height: QuanAnSpacing.sm),
                          for (final (ma, nhan) in tieuChiDanhGia)
                            _hangSao(ma, nhan),
                          Container(
                            padding: const EdgeInsets.all(QuanAnSpacing.md),
                            decoration: BoxDecoration(
                              color: QuanAnColors.primaryLight,
                              borderRadius: BorderRadius.circular(
                                QuanAnRadius.button,
                              ),
                            ),
                            child: Text(
                              duBonTieuChi(_diem)
                                  ? '⭐ Điểm tổng thể: ${_d1(tong)} (trung bình 4 tiêu chí)'
                                  : 'Điểm tổng thể sẽ hiện khi bạn chấm đủ 4 tiêu chí.',
                              style: QuanAnText.label.copyWith(
                                color: QuanAnColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.lg),
                          const Text('Thẻ nhanh', style: QuanAnText.h3),
                          const SizedBox(height: QuanAnSpacing.sm),
                          Wrap(
                            spacing: QuanAnSpacing.sm,
                            runSpacing: QuanAnSpacing.sm,
                            children: [
                              for (final (ma, nhan, _) in theNhanhDanhGia)
                                FilterChip(
                                  label: Text(nhan),
                                  selected: _the.contains(ma),
                                  onSelected: (on) => setState(
                                    () => on ? _the.add(ma) : _the.remove(ma),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: QuanAnSpacing.lg),
                          TextField(
                            controller: _nhanXet,
                            maxLines: 5,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText:
                                  'Nhận xét (ít nhất ${_cfg.danhGiaNhanXetToiThieu} ký tự)',
                              helperText:
                                  '${_nhanXet.text.trim().length}/${_cfg.danhGiaNhanXetToiThieu}',
                            ),
                          ),
                          const SizedBox(height: QuanAnSpacing.lg),
                          QuanAnMediaField(
                            storage: widget.dv.storage,
                            folder: 'quan_an_danh_gia',
                            nhan: 'Ảnh',
                            toiDa: _cfg.danhGiaAnhToiDa,
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
                          const SizedBox(height: QuanAnSpacing.xl),
                          FilledButton(
                            onPressed: _dangGui ? null : _gui,
                            child: Text(
                              _dangGui ? 'Đang gửi...' : 'Gửi đánh giá',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
