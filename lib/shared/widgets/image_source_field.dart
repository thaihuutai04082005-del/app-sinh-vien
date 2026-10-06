import 'package:flutter/material.dart';

import '../../core/services/image_storage_service.dart';
import 'image_upload_field.dart';
import 'image_url_field.dart';

/// Chọn ảnh theo 2 cách: dán link https hoặc tải ảnh từ máy lên Storage.
/// Chỉ báo ra danh sách URL của cách đang chọn; ảnh của cách còn lại được giữ
/// nguyên khi đổi qua lại.
class ImageSourceField extends StatefulWidget {
  const ImageSourceField({
    required this.storage,
    required this.folder,
    required this.onChanged,
    this.label = 'Ảnh',
    this.helperText,
    this.maxImages = 6,
    this.pickImages,
    this.startWithLink = true,
    super.key,
  });

  final ImageStorageService storage;
  final String folder;
  final String label;
  final String? helperText;
  final int maxImages;
  final ImagePickerCallback? pickImages;
  final bool startWithLink;
  final void Function(List<String> urls, bool isUploading) onChanged;

  @override
  State<ImageSourceField> createState() => _ImageSourceFieldState();
}

class _ImageSourceFieldState extends State<ImageSourceField> {
  late bool _useLink = widget.startWithLink;
  List<String> _linkImages = const [];
  List<String> _uploadedImages = const [];
  bool _uploading = false;

  void _notify() => widget.onChanged(
    _useLink ? _linkImages : _uploadedImages,
    !_useLink && _uploading,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.link),
              label: Text('Dán link ảnh'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.upload_outlined),
              label: Text('Tải ảnh từ máy'),
            ),
          ],
          selected: {_useLink},
          onSelectionChanged: (value) {
            setState(() => _useLink = value.first);
            _notify();
          },
        ),
        const SizedBox(height: 14),
        Visibility(
          visible: _useLink,
          maintainState: true,
          child: ImageUrlField(
            label: widget.label,
            helperText: widget.helperText ?? 'Dán link ảnh có sẵn trên mạng (https://). Ảnh đầu tiên làm ảnh bìa.',
            maxImages: widget.maxImages,
            onChanged: (urls) {
              _linkImages = urls;
              _notify();
            },
          ),
        ),
        Visibility(
          visible: !_useLink,
          maintainState: true,
          child: ImageUploadField(
            storage: widget.storage,
            folder: widget.folder,
            label: widget.label,
            helperText: widget.helperText,
            maxImages: widget.maxImages,
            pickImages: widget.pickImages,
            onChanged: (urls, isUploading) {
              _uploadedImages = urls;
              _uploading = isUploading;
              _notify();
            },
          ),
        ),
      ],
    );
  }
}
