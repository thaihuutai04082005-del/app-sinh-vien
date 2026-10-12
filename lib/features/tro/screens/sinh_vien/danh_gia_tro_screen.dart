import 'package:flutter/material.dart';

import '../../models/danh_gia.dart';
import '../../models/tro_config.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_media_field.dart';
import '../../widgets/tro_theme.dart';

/// TRO-SV-11 Viết / cập nhật đánh giá: 5 tiêu chí 1–5 sao, thẻ nhanh, nhận xét ≥ 20 ký tự, tối đa 5 ảnh (mục 2.9).
class DanhGiaTroScreen extends StatefulWidget {
  const DanhGiaTroScreen({
    required this.dv,
    required this.loaiNguon,
    required this.idNguon,
    this.tenPhong = '',
    super.key,
  });

  final TroDichVu dv;
  final String loaiNguon;
  final String idNguon;
  final String tenPhong;

  @override
  State<DanhGiaTroScreen> createState() => _DanhGiaTroScreenState();
}

class _DanhGiaTroScreenState extends State<DanhGiaTroScreen> {
  final _diem = <String, int>{};
  final _the = <String>{};
  final _nhanXet = TextEditingController();
  List<String> _anh = const [];
  bool _daNap = false;
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _nhanXet.dispose();
    super.dispose();
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
    if (_diem.isEmpty) loi = 'Chấm ít nhất 1 tiêu chí.';
    if (_nhanXet.text.trim().length < 20) loi ??= 'Nhận xét ít nhất 20 ký tự.';
    setState(() => _loi = loi);
    if (loi != null) return;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.danhGia.gui(
        loaiNguon: widget.loaiNguon,
        idNguon: widget.idNguon,
        diem: _diem,
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.tenPhong.isEmpty
            ? 'Đánh giá nhà trọ'
            : 'Đánh giá · phòng ${widget.tenPhong}',
      ),
    ),
    body: TroStream<DanhGia?>(
      stream: () =>
          widget.dv.danhGia.theoNguon(widget.loaiNguon, widget.idNguon),
      builder: (context, cu) {
        _nap(cu);
        return ListView(
          padding: const EdgeInsets.all(TroSpacing.screen),
          children: [
            if (cu != null)
              const Text(
                'Bạn đang cập nhật đánh giá đã viết.',
                style: TroText.bodySmall,
              ),
            for (final e in tieuChiDanhGiaLabels.entries)
              Row(
                children: [
                  Expanded(child: Text(e.value, style: TroText.body)),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i sao',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _diem[e.key] = i),
                      icon: Icon(
                        (_diem[e.key] ?? 0) >= i
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: TroColors.primary,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: TroSpacing.md),
            const Text('Thẻ nhanh', style: TroText.h3),
            const SizedBox(height: TroSpacing.sm),
            Wrap(
              spacing: TroSpacing.sm,
              runSpacing: TroSpacing.sm,
              children: [
                for (final e in theNhanhDanhGiaLabels.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _the.contains(e.key),
                    onSelected: (on) => setState(
                      () => on ? _the.add(e.key) : _the.remove(e.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TroSpacing.lg),
            TextField(
              controller: _nhanXet,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (ít nhất 20 ký tự)',
              ),
            ),
            const SizedBox(height: TroSpacing.lg),
            TroMediaField(
              storage: widget.dv.storage,
              folder: 'tro_anh',
              nhan: 'Ảnh',
              toiDa: 5,
              giaTri: _anh,
              onChanged: (v) => setState(() => _anh = v),
              pickImages: widget.dv.pickImages,
            ),
            if (_loi != null)
              Padding(
                padding: const EdgeInsets.only(top: TroSpacing.sm),
                child: Text(
                  _loi!,
                  style: const TextStyle(color: TroColors.danger),
                ),
              ),
            const SizedBox(height: TroSpacing.xl),
            FilledButton(
              onPressed: _dangGui ? null : _gui,
              child: Text(_dangGui ? 'Đang gửi...' : 'Gửi đánh giá'),
            ),
          ],
        );
      },
    ),
  );
}
