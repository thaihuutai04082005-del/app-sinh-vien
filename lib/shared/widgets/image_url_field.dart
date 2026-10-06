import 'package:flutter/material.dart';

import 'image_gallery.dart';

/// Link ảnh hợp lệ: https, có tên miền, không chứa khoảng trắng, tối đa 2000 ký tự.
/// Khớp với quy tắc `isHttpsUrl` trong `firestore.rules`.
bool isValidImageUrl(String value) {
  if (value.length > 2000 || value.contains(RegExp(r'\s'))) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.contains('.') &&
      uri.hasAuthority;
}

/// Ô dán link ảnh có sẵn trên mạng (không cần upload lên Storage): kiểm tra
/// link, xem trước, xóa. Trả về danh sách link qua [onChanged].
class ImageUrlField extends StatefulWidget {
  const ImageUrlField({
    required this.onChanged,
    this.label = 'Ảnh',
    this.helperText,
    this.maxImages = 6,
    super.key,
  });

  final String label;
  final String? helperText;
  final int maxImages;
  final void Function(List<String> urls) onChanged;

  @override
  State<ImageUrlField> createState() => _ImageUrlFieldState();
}

class _ImageUrlFieldState extends State<ImageUrlField> {
  final _controller = TextEditingController();
  final _urls = <String>[];
  String? _error;

  int get _remaining => widget.maxImages - _urls.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    String? error;
    if (value.isEmpty) {
      error = 'Dán link ảnh vào ô trên';
    } else if (!isValidImageUrl(value)) {
      error = 'Link phải bắt đầu bằng https:// và là đường dẫn hợp lệ';
    } else if (_urls.contains(value)) {
      error = 'Link này đã được thêm';
    } else if (_remaining <= 0) {
      error = 'Tối đa ${widget.maxImages} ảnh';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _urls.add(value);
      _error = null;
      _controller.clear();
    });
    widget.onChanged(List.unmodifiable(_urls));
  }

  void _remove(String url) {
    setState(() => _urls.remove(url));
    widget.onChanged(List.unmodifiable(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label} (${_urls.length}/${widget.maxImages})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helperText!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  labelText: 'Link ảnh',
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link),
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.tonal(
                onPressed: _remaining > 0 ? _add : null,
                child: const Text('Thêm'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final url in _urls)
              _LinkThumbnail(url: url, onRemove: () => _remove(url)),
          ],
        ),
      ],
    );
  }
}

const _thumbSize = 96.0;

class _LinkThumbnail extends StatelessWidget {
  const _LinkThumbnail({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _thumbSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: NetworkPhoto(url),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              tooltip: 'Xóa ảnh',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
