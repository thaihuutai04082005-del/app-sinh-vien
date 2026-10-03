import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'san_pham_detail_screen.dart';

/// Form người bán đăng sản phẩm: ảnh, tên, giá, size, tồn kho (mục 3.4).
/// Lưu xong thì pop về với [Product] đã tạo.
class DangSanPhamScreen extends StatefulWidget {
  const DangSanPhamScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    this.pickVideo,
    super.key,
  });

  final ProductService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  @override
  State<DangSanPhamScreen> createState() => _DangSanPhamScreenState();
}

const _sizeOptions = ['S', 'M', 'L', 'XL', 'XXL', 'Freesize'];

class _DangSanPhamScreenState extends State<DangSanPhamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  String? _category;
  final _sizes = <String>{};
  List<String> _images = const [];
  bool _isUploading = false;
  List<String> _videos = const [];
  bool _isUploadingVideo = false;
  bool _showImageError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showImageError = _images.isEmpty);
    if (!formValid || _images.isEmpty) return;

    final stock = int.parse(_stockController.text);
    final product = Product(
      id: '',
      shopId: '', // Gán id gian hàng khi có đăng nhập Firebase Auth.
      name: _nameController.text.trim(),
      images: _images,
      price: int.parse(_priceController.text),
      sizes: _sizeOptions.where(_sizes.contains).toList(),
      stock: stock,
      category: _category!,
      status: stock > 0 ? 'active' : 'out_of_stock',
      videos: _videos,
    );

    setState(() => _isSaving = true);
    try {
      final created = await widget.service.dangSanPham(product);
      if (mounted) Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chưa đăng được: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng sản phẩm')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ImageUploadField(
              storage: widget.storage,
              folder: 'products',
              label: 'Ảnh sản phẩm',
              helperText:
                  'Ảnh đầu tiên là ảnh bìa. Chụp rõ chất liệu và lỗi (nếu có).',
              maxImages: 8,
              pickImages: widget.pickImages,
              onChanged: (urls, isUploading) => setState(() {
                _images = urls;
                _isUploading = isUploading;
                if (urls.isNotEmpty) _showImageError = false;
              }),
            ),
            if (_showImageError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cần ít nhất 1 ảnh sản phẩm.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 22),
            VideoUploadField(
              storage: widget.storage,
              folder: 'products',
              helperText:
                  'Quay cận chất vải, form dáng khi mặc (khoảng 30–60 giây).',
              pickVideo: widget.pickVideo,
              onChanged: (urls, isUploading) => setState(() {
                _videos = urls;
                _isUploadingVideo = isUploading;
              }),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nhập tên sản phẩm'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Giá',
                      suffixText: 'đ',
                    ),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                        ? 'Nhập giá hợp lệ'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Tồn kho'),
                    validator: (value) => int.tryParse(value ?? '') == null
                        ? 'Nhập số lượng'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: [
                for (final entry in productCategoryLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Chọn danh mục' : null,
            ),
            const SizedBox(height: 18),
            Text(
              'Size',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in _sizeOptions)
                  FilterChip(
                    label: Text(size),
                    selected: _sizes.contains(size),
                    onSelected: (selected) => setState(() {
                      selected ? _sizes.add(size) : _sizes.remove(size);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isUploading || _isUploadingVideo || _isSaving
                  ? null
                  : _submit,
              icon: const Icon(Icons.storefront_outlined),
              label: Text(
                _isUploading || _isUploadingVideo
                    ? 'Đang tải lên...'
                    : _isSaving
                    ? 'Đang đăng...'
                    : 'Đăng sản phẩm',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
