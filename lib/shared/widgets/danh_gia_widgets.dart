import 'package:flutter/material.dart';

import '../../core/services/image_storage_service.dart';
import '../../core/utils/formatters.dart';
import '../models/danh_gia.dart';
import 'image_gallery.dart';
import 'image_source_field.dart';
import 'image_upload_field.dart';

const _mauSao = Color(0xFFFFB300);

/// "★ 4,3 (12 đánh giá)", hoặc "Chưa có đánh giá".
class SaoTrungBinh extends StatelessWidget {
  const SaoTrungBinh({required this.diem, this.gon = false, super.key});

  final DiemDanhGia diem;

  /// Gọn cho thẻ trong danh sách: "★ 4,3 (12)".
  final bool gon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (diem.soLuot == 0) {
      return gon
          ? const SizedBox.shrink()
          : Text('Chưa có đánh giá', style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: _mauSao),
        const SizedBox(width: 2),
        Text(
          formatDiem(diem.trungBinh),
          style: style?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          gon ? ' (${diem.soLuot})' : ' (${diem.soLuot} đánh giá)',
          style: style,
        ),
      ],
    );
  }
}

/// 4.25 → "4,3".
String formatDiem(num d) => d.toStringAsFixed(1).replaceAll('.', ',');

/// Hàng 5 sao, bấm để chấm.
class ChonSao extends StatelessWidget {
  const ChonSao({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i sao',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _mauSao,
              size: 30,
            ),
          ),
      ],
    );
  }
}

class DanhGiaTile extends StatelessWidget {
  const DanhGiaTile({required this.danhGia, required this.tieuChi, super.key});

  final DanhGia danhGia;
  final List<TieuChi> tieuChi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = danhGia;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (d.createdAt != null)
                Text(
                  formatNgay(d.createdAt!),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= d.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: _mauSao,
                ),
              const SizedBox(width: 6),
              Text(formatDiem(d.rating), style: theme.textTheme.bodySmall),
            ],
          ),
          if (d.ratingDetail.isNotEmpty)
            Text(
              [
                for (final t in tieuChi)
                  if (d.ratingDetail[t.khoa] != null)
                    '${t.ten}: ${d.ratingDetail[t.khoa]}★',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          if (d.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d.comment),
          ],
          if (d.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final url in d.images)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 72,
                      child: NetworkPhoto(url),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Mục "Đánh giá" trên trang chi tiết: đủ 3 trạng thái đang tải / rỗng / lỗi.
class DanhGiaSection extends StatefulWidget {
  const DanhGiaSection({
    required this.taiDanhGia,
    required this.diem,
    required this.tieuChi,
    super.key,
  });

  final Future<List<DanhGia>> Function() taiDanhGia;
  final DiemDanhGia diem;
  final List<TieuChi> tieuChi;

  @override
  State<DanhGiaSection> createState() => _DanhGiaSectionState();
}

class _DanhGiaSectionState extends State<DanhGiaSection> {
  late Future<List<DanhGia>> _ds = widget.taiDanhGia();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Đánh giá',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            SaoTrungBinh(diem: widget.diem),
          ],
        ),
        FutureBuilder<List<DanhGia>>(
          future: _ds,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return TextButton(
                onPressed: () => setState(() => _ds = widget.taiDanhGia()),
                child: const Text('Chưa tải được đánh giá · Thử lại'),
              );
            }
            final ds = snap.data!;
            if (ds.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Chưa có ai đánh giá.',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }
            return Column(
              children: [
                for (final (i, d) in ds.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  DanhGiaTile(danhGia: d, tieuChi: widget.tieuChi),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Màn viết đánh giá: chấm sao từng tiêu chí, nhận xét, ảnh thực tế.
/// [gui] gửi lên server; gửi xong thì pop về `true`.
class VietDanhGiaScreen extends StatefulWidget {
  const VietDanhGiaScreen({
    required this.tieuDe,
    required this.tieuChi,
    required this.storage,
    required this.gui,
    this.pickImages,
    super.key,
  });

  final String tieuDe;
  final List<TieuChi> tieuChi;
  final ImageStorageService storage;
  final Future<void> Function(DanhGiaNhap) gui;
  final ImagePickerCallback? pickImages;

  @override
  State<VietDanhGiaScreen> createState() => _VietDanhGiaScreenState();
}

class _VietDanhGiaScreenState extends State<VietDanhGiaScreen> {
  final _diem = <String, int>{};
  final _nhanXet = TextEditingController();
  List<String> _anh = const [];
  bool _dangTaiAnh = false;
  bool _dangGui = false;
  bool _baoThieu = false;

  @override
  void dispose() {
    _nhanXet.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (widget.tieuChi.any((t) => _diem[t.khoa] == null)) {
      setState(() => _baoThieu = true);
      return;
    }
    setState(() => _dangGui = true);
    try {
      await widget.gui(
        DanhGiaNhap(
          ratingDetail: Map.of(_diem),
          comment: _nhanXet.text.trim(),
          images: _anh,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chưa gửi được: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.tieuDe)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final t in widget.tieuChi) ...[
            Text(t.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
            ChonSao(
              value: _diem[t.khoa] ?? 0,
              onChanged: (v) => setState(() => _diem[t.khoa] = v),
            ),
            const SizedBox(height: 8),
          ],
          if (_baoThieu)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Chấm sao đủ ${widget.tieuChi.length} tiêu chí.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          TextField(
            controller: _nhanXet,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Nhận xét (không bắt buộc)',
            ),
          ),
          const SizedBox(height: 12),
          ImageSourceField(
            storage: widget.storage,
            folder: 'danh_gia',
            label: 'Ảnh thực tế (không bắt buộc)',
            maxImages: 5,
            startWithLink: false,
            pickImages: widget.pickImages,
            onChanged: (urls, dangTai) => setState(() {
              _anh = urls;
              _dangTaiAnh = dangTai;
            }),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _dangTaiAnh || _dangGui ? null : _gui,
            child: Text(
              _dangTaiAnh
                  ? 'Đang tải ảnh...'
                  : _dangGui
                  ? 'Đang gửi...'
                  : 'Gửi đánh giá',
            ),
          ),
        ],
      ),
    );
  }
}
