import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/image_source_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../../auth/models/xac_thuc.dart';
import '../../auth/screens/xac_thuc_sdt_screen.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';

/// Form người bán đăng / sửa sản phẩm: ảnh, tên, mô tả, giá, size, tồn kho (mục 3.4).
/// Lưu xong thì pop về với id sản phẩm.
class DangSanPhamScreen extends StatefulWidget {
  const DangSanPhamScreen({required this.dv, this.sanPham, super.key});

  final ShopDichVu dv;

  /// Có giá trị thì đang sửa sản phẩm này.
  final Product? sanPham;

  @override
  State<DangSanPhamScreen> createState() => _DangSanPhamScreenState();
}

class _DangSanPhamScreenState extends State<DangSanPhamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Product? _cu = widget.sanPham;
  late final _nameController = TextEditingController(text: _cu?.name);
  late final _descController = TextEditingController(text: _cu?.description);
  late final _priceController = TextEditingController(
    text: _cu?.price.round().toString(),
  );
  late final _stockController = TextEditingController(
    text: '${_cu?.stock ?? 1}',
  );
  late String? _category = _cu?.category;
  late final _sizes = <String>{...?_cu?.sizes};
  List<String> _images = const [];
  bool _isUploading = false;
  List<String> _videos = const [];
  bool _isUploadingVideo = false;
  bool _showImageError = false;
  bool _isSaving = false;
  late final _xacThuc = widget.dv.xacThuc.cuaToi(widget.dv.uid);

  /// Khi sửa: chưa chọn ảnh / video mới thì giữ cái cũ.
  List<String> get _anhGui =>
      _images.isEmpty && _cu != null ? _cu.images : _images;
  List<String> get _videoGui =>
      _videos.isEmpty && _cu != null ? _cu.videos : _videos;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showImageError = _anhGui.isEmpty);
    if (!formValid || _anhGui.isEmpty) return;

    final sp = SanPhamNhap(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      images: _anhGui,
      videos: _videoGui,
      price: int.parse(_priceController.text),
      sizes: productSizes.where(_sizes.contains).toList(),
      stock: int.parse(_stockController.text),
      category: _category!,
    );

    setState(() => _isSaving = true);
    try {
      final cu = _cu;
      final String id;
      if (cu == null) {
        id = await widget.dv.products.dangSanPham(sp);
      } else {
        await widget.dv.products.suaSanPham(cu.id, sp);
        id = cu.id;
      }
      if (mounted) Navigator.of(context).pop(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chưa lưu được: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sua = _cu != null;
    return Scaffold(
      appBar: AppBar(title: Text(sua ? 'Sửa sản phẩm' : 'Đăng sản phẩm')),
      body: StreamBuilder<XacThuc>(
        stream: _xacThuc,
        builder: (context, snap) {
          // Đang sửa thì đã từng đăng được, không chặn lại.
          if (sua || snap.data?.daOtp == true) return _form(context, sua);
          if (!snap.hasData && !snap.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          return _canOtp(context);
        },
      ),
    );
  }

  Widget _canOtp(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_android,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Ai cũng bán được trên Shop đồ rẻ, chỉ cần xác thực số điện thoại '
              'một lần để người mua liên hệ được với bạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => XacThucSdtScreen(service: widget.dv.xacThuc),
                ),
              ),
              child: const Text('Xác thực số điện thoại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, bool sua) {
    final cu = _cu;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (cu != null && _images.isEmpty) ...[
            Text(
              'Ảnh hiện tại (chọn ảnh mới bên dưới để thay toàn bộ)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cu.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 72,
                    child: NetworkPhoto(cu.images[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ImageSourceField(
            storage: widget.dv.storage,
            folder: 'products',
            startWithLink: false,
            label: sua ? 'Ảnh mới' : 'Ảnh sản phẩm',
            helperText:
                'Ảnh đầu tiên là ảnh bìa. Chụp rõ chất liệu và lỗi (nếu có).',
            maxImages: 8,
            pickImages: widget.dv.pickImages,
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
            storage: widget.dv.storage,
            folder: 'products',
            helperText: cu != null && cu.videos.isNotEmpty
                ? 'Đang có 1 video. Chọn video mới để thay.'
                : 'Quay cận chất vải, form dáng khi mặc (khoảng 30 giây).',
            pickVideo: widget.dv.pickVideo,
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
          TextFormField(
            controller: _descController,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              hintText:
                  'Chất liệu, số đo, tình trạng (mới / đã qua sử dụng)...',
            ),
          ),
          const SizedBox(height: 6),
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
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1000
                      ? 'Giá từ 1.000đ'
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
            'Size (bỏ trống nếu không có size)',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in productSizes)
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
                  ? 'Đang lưu...'
                  : sua
                  ? 'Lưu thay đổi'
                  : 'Đăng sản phẩm',
            ),
          ),
        ],
      ),
    );
  }
}
