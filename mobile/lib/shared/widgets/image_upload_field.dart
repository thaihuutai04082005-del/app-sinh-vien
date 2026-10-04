import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_storage_service.dart';

typedef ImagePickerCallback = Future<List<XFile>> Function(int maxCount);

/// Ô chọn nhiều ảnh: xem trước, upload ngay khi chọn, xóa, thử lại khi lỗi.
/// Trả về danh sách URL đã upload xong qua [onChanged].
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    required this.storage,
    required this.folder,
    required this.onChanged,
    this.label = 'Ảnh',
    this.helperText,
    this.maxImages = 6,
    this.pickImages,
    super.key,
  });

  final ImageStorageService storage;
  final String folder;
  final String label;
  final String? helperText;
  final int maxImages;

  /// (urls đã upload, còn ảnh đang upload hay không)
  final void Function(List<String> urls, bool isUploading) onChanged;

  /// Thay thế bộ chọn ảnh mặc định (dùng khi test).
  final ImagePickerCallback? pickImages;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

enum _UploadStatus { uploading, done, failed }

class _UploadItem {
  _UploadItem(this.bytes, this.fileName);

  final Uint8List bytes;
  final String fileName;
  _UploadStatus status = _UploadStatus.uploading;
  String? url;
  String? error;
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final _items = <_UploadItem>[];

  int get _remaining => widget.maxImages - _items.length;

  Future<List<XFile>> _defaultPick(int maxCount) async {
    final picker = ImagePicker();
    if (maxCount == 1) {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      return file == null ? const [] : [file];
    }
    return picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 80,
      limit: maxCount,
    );
  }

  Future<void> _pick() async {
    final files = await (widget.pickImages ?? _defaultPick)(_remaining);
    for (final file in files.take(_remaining)) {
      final item = _UploadItem(await file.readAsBytes(), file.name);
      if (!mounted) return;
      setState(() => _items.add(item));
      _upload(item);
    }
  }

  Future<void> _upload(_UploadItem item) async {
    setState(() {
      item
        ..status = _UploadStatus.uploading
        ..error = null;
    });
    _notify();
    try {
      final url = await widget.storage.upload(
        bytes: item.bytes,
        fileName: item.fileName,
        folder: widget.folder,
      );
      item
        ..url = url
        ..status = _UploadStatus.done;
    } catch (error) {
      item
        ..status = _UploadStatus.failed
        ..error = error is ImageUploadException
            ? error.message
            : 'Upload thất bại.';
    }
    if (!mounted || !_items.contains(item)) return;
    setState(() {});
    _notify();
  }

  void _remove(_UploadItem item) {
    setState(() => _items.remove(item));
    _notify();
  }

  void _notify() {
    widget.onChanged([
      for (final item in _items)
        if (item.url != null) item.url!,
    ], _items.any((item) => item.status == _UploadStatus.uploading));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label} (${_items.length}/${widget.maxImages})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helperText!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in _items)
              _Thumbnail(
                item: item,
                onRemove: () => _remove(item),
                onRetry: () => _upload(item),
              ),
            if (_remaining > 0) _AddButton(onTap: _pick),
          ],
        ),
      ],
    );
  }
}

const _thumbSize = 96.0;

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: _thumbSize,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: colors.primary),
              const SizedBox(height: 4),
              Text('Thêm ảnh', style: TextStyle(color: colors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  final _UploadItem item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _thumbSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(item.bytes, fit: BoxFit.cover),
          ),
          if (item.status != _UploadStatus.done)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: Colors.black54,
                child: item.status == _UploadStatus.uploading
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Tooltip(
                        message: item.error ?? 'Upload thất bại.',
                        child: InkWell(
                          onTap: onRetry,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: Colors.white),
                              Text(
                                'Thử lại',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          if (item.status == _UploadStatus.done)
            const Positioned(
              left: 6,
              bottom: 6,
              child: Icon(Icons.cloud_done, color: Colors.white, size: 18),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              onPressed: onRemove,
              tooltip: 'Xóa ảnh',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
