import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/daily_quota.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_source_field.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../models/phong_tro.dart';
import '../services/phong_tro_service.dart';

/// Form chủ trọ đăng tin cho thuê (task 2.5). Đăng xong thì pop về với `true`.
class DangPhongTroScreen extends StatefulWidget {
  const DangPhongTroScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final PhongTroService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<DangPhongTroScreen> createState() => _DangPhongTroScreenState();
}

class _DangPhongTroScreenState extends State<DangPhongTroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _electricController = TextEditingController(text: '0');
  final _waterController = TextEditingController(text: '0');
  final _areaController = TextEditingController();
  final _maxPeopleController = TextEditingController(text: '1');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  RoomType _roomType = RoomType.oRieng;
  final _amenities = <String>{};
  final _lifestyle = <String>{};
  bool _depositEnabled = false;
  List<String> _images = const [];
  bool _isUploading = false;
  bool _showImageError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _addressController,
      _priceController,
      _electricController,
      _waterController,
      _areaController,
      _maxPeopleController,
      _latitudeController,
      _longitudeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  String? _money(String? value, String message) {
    final n = int.tryParse(value?.trim() ?? '');
    return (n == null || n < 0) ? message : null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showImageError = _images.isEmpty);
    if (!formValid || _images.isEmpty) return;

    final phong = PhongTro(
      id: '',
      ownerId: '', // Service gán uid người đăng.
      title: _titleController.text.trim(),
      address: _addressController.text.trim(),
      images: _images,
      price: int.parse(_priceController.text.trim()),
      electricPrice: int.parse(_electricController.text.trim()),
      waterPrice: int.parse(_waterController.text.trim()),
      area: double.parse(_areaController.text.trim()),
      maxPeople: int.parse(_maxPeopleController.text.trim()),
      amenities: amenityLabels.keys.where(_amenities.contains).toList(),
      lifestylePrefs: lifestyleLabels.keys.where(_lifestyle.contains).toList(),
      depositEnabled: _depositEnabled,
      location: GeoPoint(
        double.parse(_latitudeController.text.trim()),
        double.parse(_longitudeController.text.trim()),
      ),
      roomType: _roomType,
    );

    setState(() => _isSaving = true);
    try {
      await widget.service.dangPhongTro(phong);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final message = error is QuotaException
          ? error.message
          : 'Chưa đăng được tin. Vui lòng thử lại.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _number(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    String? suffix,
    bool decimal = false,
    bool signed = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(
      decimal: decimal,
      signed: signed,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(
          signed
              ? r'[0-9.-]'
              : decimal
              ? r'[0-9.]'
              : r'[0-9]',
        ),
      ),
    ],
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: validator,
  );

  Widget _chips(
    Map<String, String> labels,
    Set<String> selected,
    String title,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final entry in labels.entries)
            FilterChip(
              label: Text(entry.value),
              selected: selected.contains(entry.key),
              onSelected: (on) => setState(() {
                on ? selected.add(entry.key) : selected.remove(entry.key);
              }),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng tin cho thuê')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ImageSourceField(
              storage: widget.storage,
              folder: 'phong_tro',
              label: 'Ảnh phòng',
              maxImages: 6,
              pickImages: widget.pickImages,
              onChanged: (urls, isUploading) => setState(() {
                _images = urls;
                _isUploading = isUploading;
                if (urls.isNotEmpty) _showImageError = false;
              }),
            ),
            // Luôn đúng 1 phần tử ở vị trí này để các ô nhập bên dưới không bị dựng lại.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _isUploading
                  ? const Text('Đang tải ảnh lên, vui lòng chờ...')
                  : _showImageError
                  ? Text(
                      'Cần ít nhất 1 ảnh phòng.',
                      style: TextStyle(color: error),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề tin'),
              validator: (v) => _required(v, 'Nhập tiêu đề tin'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RoomType>(
              initialValue: _roomType,
              decoration: const InputDecoration(labelText: 'Loại phòng'),
              items: [
                for (final type in RoomType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (v) => setState(() => _roomType = v ?? _roomType),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
              validator: (v) => _required(v, 'Nhập địa chỉ'),
            ),
            const SizedBox(height: 14),
            _number(
              _priceController,
              'Giá thuê / tháng',
              (v) => _money(v, 'Nhập giá thuê hợp lệ'),
              suffix: 'đ',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _number(
                    _electricController,
                    'Giá điện',
                    (v) => _money(v, 'Nhập giá điện'),
                    suffix: 'đ/kWh',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _number(
                    _waterController,
                    'Giá nước',
                    (v) => _money(v, 'Nhập giá nước'),
                    suffix: 'đ/m³',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _number(
                    _areaController,
                    'Diện tích',
                    (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      return (n == null || n <= 0) ? 'Nhập diện tích' : null;
                    },
                    suffix: 'm²',
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _number(_maxPeopleController, 'Số người tối đa', (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n < 1) ? 'Ít nhất 1 người' : null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _number(
                    _latitudeController,
                    'Vĩ độ',
                    (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      return (n == null || n < -90 || n > 90)
                          ? 'Vĩ độ -90 đến 90'
                          : null;
                    },
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _number(
                    _longitudeController,
                    'Kinh độ',
                    (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      return (n == null || n < -180 || n > 180)
                          ? 'Kinh độ -180 đến 180'
                          : null;
                    },
                    decimal: true,
                    signed: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _chips(amenityLabels, _amenities, 'Tiện ích'),
            const SizedBox(height: 14),
            _chips(lifestyleLabels, _lifestyle, 'Phong cách sống'),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cho phép đặt cọc'),
              value: _depositEnabled,
              onChanged: (v) => setState(() => _depositEnabled = v),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _isUploading || _isSaving ? null : _submit,
              icon: const Icon(Icons.add_home_work_outlined),
              label: Text(
                _isUploading
                    ? 'Đang tải ảnh...'
                    : _isSaving
                    ? 'Đang đăng...'
                    : 'Đăng tin',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
