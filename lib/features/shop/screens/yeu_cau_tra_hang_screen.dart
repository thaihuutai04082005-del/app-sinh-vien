import 'package:flutter/material.dart';

import '../../../shared/widgets/image_source_field.dart';
import '../services/shop_dich_vu.dart';

/// Người mua yêu cầu trả hàng / hoàn tiền: lý do + ảnh hàng thực tế.
/// Gửi xong thì pop về `true`.
class YeuCauTraHangScreen extends StatefulWidget {
  const YeuCauTraHangScreen({
    required this.dv,
    required this.orderId,
    super.key,
  });

  final ShopDichVu dv;
  final String orderId;

  @override
  State<YeuCauTraHangScreen> createState() => _YeuCauTraHangScreenState();
}

class _YeuCauTraHangScreenState extends State<YeuCauTraHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDo = TextEditingController();
  List<String> _anh = const [];
  bool _dangTaiAnh = false;
  bool _dangGui = false;

  @override
  void dispose() {
    _lyDo.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangGui = true);
    try {
      await widget.dv.donHang.thaoTac(
        widget.orderId,
        'yeuCauTraHang',
        reason: _lyDo.text.trim(),
        images: _anh,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu trả hàng')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Shop có 2 ngày để trả lời, không trả lời thì coi như đồng ý. '
              'Đồng ý thì bạn gửi lại hàng và được hoàn tiền.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lyDo,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Lý do trả hàng',
                hintText: 'Sai size, rách, khác ảnh...',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nhập lý do trả hàng' : null,
            ),
            const SizedBox(height: 12),
            ImageSourceField(
              storage: widget.dv.storage,
              folder: 'tra_hang',
              label: 'Ảnh hàng nhận được',
              helperText: 'Chụp rõ chỗ lỗi để shop / admin dễ xem xét.',
              maxImages: 5,
              startWithLink: false,
              pickImages: widget.dv.pickImages,
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
                    : 'Gửi yêu cầu',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
