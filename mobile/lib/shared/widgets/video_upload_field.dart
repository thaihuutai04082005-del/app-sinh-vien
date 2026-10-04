import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_storage_service.dart';

typedef VideoPickerCallback = Future<XFile?> Function();

/// Chọn 1 video, kiểm tra dung lượng rồi upload ngay; trả URL qua [onChanged].
class VideoUploadField extends StatefulWidget {
  const VideoUploadField({
    required this.storage,
    required this.folder,
    required this.onChanged,
    this.helperText,
    this.pickVideo,
    super.key,
  });

  /// Giới hạn của Workers KV (25 MiB mỗi giá trị).
  static const maxBytes = 25 * 1024 * 1024;

  final ImageStorageService storage;
  final String folder;
  final String? helperText;

  /// (urls đã upload, đang upload hay không)
  final void Function(List<String> urls, bool isUploading) onChanged;

  /// Thay thế bộ chọn video mặc định (dùng khi test).
  final VideoPickerCallback? pickVideo;

  @override
  State<VideoUploadField> createState() => _VideoUploadFieldState();
}

enum _Status { empty, uploading, done, failed }

class _VideoUploadFieldState extends State<VideoUploadField> {
  _Status _status = _Status.empty;
  XFile? _file;
  int _size = 0;
  String? _url;
  String? _error;

  Future<XFile?> _defaultPick() => ImagePicker().pickVideo(
    source: ImageSource.gallery,
    maxDuration: const Duration(seconds: 60),
  );

  Future<void> _pick() async {
    final file = await (widget.pickVideo ?? _defaultPick)();
    if (file == null || !mounted) return;
    final size = await file.length();
    setState(() {
      _file = file;
      _size = size;
    });
    if (size > VideoUploadField.maxBytes) {
      setState(() {
        _status = _Status.failed;
        _error =
            'Video ${_formatSize(size)} vượt quá 25 MB. Hãy quay ngắn hơn (khoảng 30–60 giây).';
      });
      _notify();
      return;
    }
    await _upload();
  }

  Future<void> _upload() async {
    final file = _file!;
    setState(() {
      _status = _Status.uploading;
      _error = null;
    });
    _notify();
    try {
      final url = await widget.storage.upload(
        bytes: await file.readAsBytes(),
        fileName: file.name,
        folder: widget.folder,
      );
      if (!mounted || _file != file) return;
      setState(() {
        _url = url;
        _status = _Status.done;
      });
    } catch (error) {
      if (!mounted || _file != file) return;
      setState(() {
        _status = _Status.failed;
        _error = error is ImageUploadException
            ? error.message
            : 'Upload thất bại.';
      });
    }
    _notify();
  }

  void _remove() {
    setState(() {
      _status = _Status.empty;
      _file = null;
      _url = null;
      _error = null;
    });
    _notify();
  }

  void _notify() => widget.onChanged(
    _url == null ? const [] : [_url!],
    _status == _Status.uploading,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video (không bắt buộc)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helperText!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        if (_status == _Status.empty)
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.video_call_outlined),
            label: const Text('Thêm video (tối đa 25 MB)'),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: _status == _Status.failed
                  ? colors.errorContainer
                  : colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              child: Row(
                children: [
                  switch (_status) {
                    _Status.uploading => const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    _Status.done => Icon(
                      Icons.cloud_done,
                      color: colors.primary,
                    ),
                    _ => Icon(Icons.error_outline, color: colors.error),
                  },
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _file?.name ?? 'video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(switch (_status) {
                          _Status.uploading =>
                            'Đang tải lên ${_formatSize(_size)}...',
                          _Status.done => 'Đã tải lên (${_formatSize(_size)})',
                          _ => _error ?? 'Upload thất bại.',
                        }, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (_status == _Status.failed &&
                      _size <= VideoUploadField.maxBytes)
                    IconButton(
                      onPressed: _upload,
                      tooltip: 'Thử lại',
                      icon: const Icon(Icons.refresh),
                    ),
                  IconButton(
                    onPressed: _status == _Status.uploading ? null : _remove,
                    tooltip: 'Xóa video',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _formatSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
