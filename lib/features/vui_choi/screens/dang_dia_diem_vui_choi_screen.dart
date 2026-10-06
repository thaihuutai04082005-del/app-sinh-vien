import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/daily_quota.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/image_url_field.dart';
import '../models/vui_choi_model.dart';
import '../services/vui_choi_service.dart';

class DangDiaDiemVuiChoiScreen extends StatefulWidget {
  const DangDiaDiemVuiChoiScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final VuiChoiService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<DangDiaDiemVuiChoiScreen> createState() =>
      _DangDiaDiemVuiChoiScreenState();
}

class _DangDiaDiemVuiChoiScreenState extends State<DangDiaDiemVuiChoiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _openHourController = TextEditingController(text: '08:00');
  final _closeHourController = TextEditingController(text: '22:00');
  final _ticketPriceController = TextEditingController(text: '0');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _category;
  // Ảnh có 2 nguồn: dán link (không cần Storage) hoặc upload từ máy.
  bool _useLink = true;
  List<String> _linkImages = const [];
  List<String> _uploadedImages = const [];
  List<String> get _images => _useLink ? _linkImages : _uploadedImages;
  bool _uploading = false;
  bool get _isUploading => !_useLink && _uploading;
  bool _showImageError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _openHourController.dispose();
    _closeHourController.dispose();
    _ticketPriceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _hourValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nhập giờ theo định dạng HH:mm';
    final regex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (!regex.hasMatch(text)) return 'Giờ không hợp lệ (VD: 08:30)';
    return null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showImageError = _images.isEmpty);
    if (!formValid || _images.isEmpty) return;

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());
    final item = VuiChoiModel(
      id: '',
      name: _nameController.text.trim(),
      images: _images,
      category: _category!,
      location: GeoPoint(latitude, longitude),
      address: _addressController.text.trim(),
      openHour: _openHourController.text.trim(),
      closeHour: _closeHourController.text.trim(),
      ticketPrice: double.parse(_ticketPriceController.text.trim()),
    );

    setState(() => _isSaving = true);
    try {
      await widget.service.dangVuiChoi(item);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final message = error is QuotaException
          ? error.message
          : 'Chưa đăng được địa điểm. Vui lòng thử lại.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng địa điểm vui chơi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              onSelectionChanged: (value) => setState(() {
                _useLink = value.first;
                if (_images.isNotEmpty) _showImageError = false;
              }),
            ),
            const SizedBox(height: 14),
            // Cả hai ô luôn nằm trong cây (chỉ ẩn/hiện) để không mất ảnh đã chọn
            // khi đổi chế độ và không làm các ô nhập bên dưới bị dựng lại.
            Visibility(
              visible: _useLink,
              maintainState: true,
              child: ImageUrlField(
                label: 'Ảnh địa điểm',
                helperText: 'Dán link ảnh có sẵn trên mạng (https://). Ảnh đầu tiên làm ảnh bìa.',
                maxImages: 6,
                onChanged: (urls) => setState(() {
                  _linkImages = urls;
                  if (urls.isNotEmpty) _showImageError = false;
                }),
              ),
            ),
            Visibility(
              visible: !_useLink,
              maintainState: true,
              child: ImageUploadField(
                storage: widget.storage,
                folder: 'vui_choi',
                label: 'Ảnh địa điểm',
                helperText: 'Ảnh đầu tiên sẽ làm ảnh bìa. Nên chụp rõ không gian và biển tên.',
                maxImages: 6,
                pickImages: widget.pickImages,
                onChanged: (urls, isUploading) => setState(() {
                  _uploadedImages = urls;
                  _uploading = isUploading;
                  if (urls.isNotEmpty) _showImageError = false;
                }),
              ),
            ),
            // Luôn đúng 1 phần tử ở vị trí này: nếu lúc có lúc không thì các ô nhập
            // bên dưới bị dựng lại và mất lỗi vừa hiện.
            _ImageStatus(
              uploading: _isUploading,
              showError: _showImageError && !_isUploading,
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên địa điểm'),
              validator: (value) =>
                  _requiredValidator(value, 'Nhập tên địa điểm'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Loại địa điểm'),
              items: [
                for (final entry in vuiChoiCategoryLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Chọn loại địa điểm' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
              validator: (value) => _requiredValidator(value, 'Nhập địa chỉ'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openHourController,
                    decoration: const InputDecoration(labelText: 'Mở cửa'),
                    validator: _hourValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _closeHourController,
                    decoration: const InputDecoration(labelText: 'Đóng cửa'),
                    validator: _hourValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ticketPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Giá vé',
                suffixText: 'đ',
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || price < 0) return 'Nhập giá vé hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Vĩ độ'),
                    validator: (value) {
                      final lat = double.tryParse(value?.trim() ?? '');
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Vĩ độ -90 đến 90';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Kinh độ'),
                    validator: (value) {
                      final lng = double.tryParse(value?.trim() ?? '');
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Kinh độ -180 đến 180';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isUploading || _isSaving ? null : _submit,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                _isUploading
                    ? 'Đang tải ảnh...'
                    : _isSaving
                    ? 'Đang đăng...'
                    : 'Đăng địa điểm',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái dưới ô chọn ảnh: đang tải, thiếu ảnh hoặc không hiện gì.
class _ImageStatus extends StatelessWidget {
  const _ImageStatus({required this.uploading, required this.showError});

  final bool uploading;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Đang tải ảnh lên, vui lòng chờ...'),
      );
    }
    if (showError) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Cần ít nhất 1 ảnh địa điểm.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
