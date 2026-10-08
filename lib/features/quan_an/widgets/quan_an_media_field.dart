import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/image_url_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import 'quan_an_theme.dart';

/// Ô chọn ảnh / video của module Quán ăn: dán link https hoặc tải từ máy, có sẵn giá trị cũ
/// (sửa bản nháp), xóa được, và (với ảnh) chọn 1 ảnh làm ảnh bìa.
///
/// - Nhiều ảnh: đặt [toiThieu] / [toiDa] (ví dụ ảnh mặt tiền 1–3, ảnh khác 0–10, đánh giá tối đa 5).
/// - Chỉ 1 ảnh (ảnh món, ảnh bìa): [toiDa] = 1; chọn ảnh mới khi đã đủ thì ảnh cũ bị thay.
///
/// Theo quyết định của nhóm, video tạm cho dán link / tải lên (quay trong app có GPS làm sau, khi có máy Android thật).
class QuanAnMediaField extends StatefulWidget {
  const QuanAnMediaField({
    required this.storage,
    required this.folder,
    required this.giaTri,
    required this.onChanged,
    this.laVideo = false,
    this.toiThieu = 0,
    this.toiDa = 10,
    this.anhBia,
    this.onChonAnhBia,
    this.nhan = 'Ảnh',
    this.goiY,
    this.pickImages,
    this.pickVideo,
    super.key,
  });

  final ImageStorageService storage;
  final String folder;
  final List<String> giaTri;
  final ValueChanged<List<String>> onChanged;
  final bool laVideo;
  final int toiThieu;
  final int toiDa;
  final String? anhBia;
  final ValueChanged<String>? onChonAnhBia;
  final String nhan;
  final String? goiY;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  @override
  State<QuanAnMediaField> createState() => _QuanAnMediaFieldState();
}

class _QuanAnMediaFieldState extends State<QuanAnMediaField> {
  final _link = TextEditingController();
  String? _loi;
  bool _dangTai = false;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _du => widget.giaTri.length >= widget.toiDa;

  bool get _chiMotAnh => widget.toiDa == 1;

  void _them(String url) {
    if (widget.giaTri.contains(url)) {
      setState(() => _loi = 'Đã có trong danh sách');
      return;
    }
    // Chế độ 1 ảnh: ảnh mới thay ảnh cũ.
    widget.onChanged(_chiMotAnh ? [url] : [...widget.giaTri, url]);
    if (!widget.laVideo && (widget.anhBia == null || widget.anhBia!.isEmpty)) {
      widget.onChonAnhBia?.call(url);
    }
  }

  void _themLink() {
    final s = _link.text.trim();
    if (!isValidImageUrl(s)) {
      setState(
        () => _loi = 'Link phải bắt đầu bằng https:// và là đường dẫn hợp lệ',
      );
      return;
    }
    setState(() => _loi = null);
    _link.clear();
    _them(s);
  }

  Future<void> _taiLen() async {
    setState(() {
      _loi = null;
      _dangTai = true;
    });
    try {
      if (widget.laVideo) {
        final f =
            await (widget.pickVideo ??
                () => ImagePicker().pickVideo(source: ImageSource.gallery))();
        if (f == null) return;
        final bytes = await f.readAsBytes();
        if (bytes.length > VideoUploadField.maxBytes) {
          throw const ImageUploadException('Video vượt quá 15 MB.');
        }
        _them(
          await widget.storage.upload(
            bytes: bytes,
            fileName: f.name,
            folder: widget.folder,
          ),
        );
      } else {
        final ds =
            await (widget.pickImages ??
                (n) async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1600,
                    imageQuality: 85,
                  );
                  return f == null ? <XFile>[] : [f];
                })(_chiMotAnh ? 1 : widget.toiDa - widget.giaTri.length);
        final conLai = _chiMotAnh ? 1 : widget.toiDa - widget.giaTri.length;
        for (final f in ds.take(conLai)) {
          _them(
            await widget.storage.upload(
              bytes: await f.readAsBytes(),
              fileName: f.name,
              folder: widget.folder,
            ),
          );
        }
      }
    } on ImageUploadException catch (e) {
      setState(() => _loi = e.message);
    } catch (_) {
      setState(() => _loi = 'Tải lên thất bại, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final soLuong = '${widget.giaTri.length}/${widget.toiDa}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.nhan} ($soLuong${widget.toiThieu > 0 ? ', tối thiểu ${widget.toiThieu}' : ''})',
          style: QuanAnText.label,
        ),
        if (widget.goiY != null) ...[
          const SizedBox(height: QuanAnSpacing.xs),
          Text(widget.goiY!, style: QuanAnText.bodySmall),
        ],
        const SizedBox(height: QuanAnSpacing.sm),
        if (widget.giaTri.isNotEmpty)
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [
              for (final url in widget.giaTri)
                _ONho(
                  url: url,
                  laVideo: widget.laVideo,
                  laBia: !widget.laVideo && url == widget.anhBia,
                  onXoa: () =>
                      widget.onChanged([...widget.giaTri]..remove(url)),
                  onChonBia: widget.laVideo || widget.onChonAnhBia == null
                      ? null
                      : () => widget.onChonAnhBia!(url),
                ),
            ],
          ),
        if (!_du || _chiMotAnh) ...[
          const SizedBox(height: QuanAnSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _link,
                  decoration: InputDecoration(
                    labelText: widget.laVideo
                        ? 'Link video (https://)'
                        : 'Link ảnh (https://)',
                  ),
                  onSubmitted: (_) => _themLink(),
                ),
              ),
              const SizedBox(width: QuanAnSpacing.sm),
              OutlinedButton(onPressed: _themLink, child: const Text('Thêm')),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          OutlinedButton.icon(
            onPressed: _dangTai ? null : _taiLen,
            icon: _dangTai
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    widget.laVideo
                        ? Icons.video_library_outlined
                        : Icons.add_photo_alternate_outlined,
                  ),
            label: Text(
              _dangTai
                  ? 'Đang tải lên...'
                  : (widget.laVideo ? 'Tải video từ máy' : 'Tải ảnh từ máy'),
            ),
          ),
        ],
        if (_loi != null)
          Padding(
            padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
            child: Text(
              _loi!,
              style: const TextStyle(color: QuanAnColors.danger),
            ),
          ),
      ],
    );
  }
}

class _ONho extends StatelessWidget {
  const _ONho({
    required this.url,
    required this.laVideo,
    required this.laBia,
    required this.onXoa,
    this.onChonBia,
  });

  final String url;
  final bool laVideo;
  final bool laBia;
  final VoidCallback onXoa;
  final VoidCallback? onChonBia;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    height: 96,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(QuanAnRadius.input),
          child: laVideo
              ? const ColoredBox(
                  color: QuanAnColors.primaryLight,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: QuanAnColors.primary,
                    size: 40,
                  ),
                )
              : NetworkPhoto(url),
        ),
        if (laBia)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: QuanAnColors.primary,
                borderRadius: BorderRadius.circular(QuanAnRadius.pill),
              ),
              child: const Text(
                'Ảnh bìa',
                style: TextStyle(color: QuanAnColors.white, fontSize: 11),
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            tooltip: 'Xóa',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(backgroundColor: QuanAnColors.white),
            onPressed: onXoa,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
        if (onChonBia != null && !laBia)
          Positioned(
            left: 0,
            bottom: 0,
            child: IconButton(
              tooltip: 'Chọn làm ảnh bìa',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(backgroundColor: QuanAnColors.white),
              onPressed: onChonBia,
              icon: const Icon(Icons.star_border, size: 16),
            ),
          ),
      ],
    ),
  );
}
