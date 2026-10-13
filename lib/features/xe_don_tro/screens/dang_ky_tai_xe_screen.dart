import 'package:flutter/material.dart';

import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';

/// Đăng ký / sửa hồ sơ tài xế: loại xe, khu vực, bảng giá tham khảo (mục 3.3).
/// Server chỉ nhận khi tài khoản đã xác thực danh tính. Lưu xong pop về `true`.
class DangKyTaiXeScreen extends StatefulWidget {
  const DangKyTaiXeScreen({required this.dv, this.hoSo, super.key});

  final XeDichVu dv;
  final TaiXe? hoSo;

  @override
  State<DangKyTaiXeScreen> createState() => _DangKyTaiXeScreenState();
}

class _DangKyTaiXeScreenState extends State<DangKyTaiXeScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _vehicleType = widget.hoSo?.vehicleType;
  late final _area = TextEditingController(text: widget.hoSo?.area);
  late final _price = TextEditingController(text: widget.hoSo?.priceReference);
  late final _desc = TextEditingController(text: widget.hoSo?.description);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _area.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.dv.xe.luuHoSoTaiXe(
        vehicleType: _vehicleType!,
        area: _area.text.trim(),
        priceReference: _price.text.trim(),
        description: _desc.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sua = widget.hoSo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(sua ? 'Sửa hồ sơ tài xế' : 'Đăng ký làm tài xế'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!sua)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('Cần xác thực danh tính'),
                  subtitle: Text(
                    'Để sinh viên yên tâm, chỉ tài khoản đã xác thực CCCD '
                    '(trang Hồ sơ) mới đăng ký làm tài xế được.',
                  ),
                ),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'Loại xe'),
              items: [
                for (final e in TaiXe.loaiXeLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _vehicleType = v),
              validator: (v) => v == null ? 'Chọn loại xe' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _area,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Khu vực hoạt động',
                hintText: 'VD: Thủ Đức, Quận 9, Bình Thạnh',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nhập khu vực' : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _price,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Bảng giá tham khảo',
                hintText: 'VD: 150k/chuyến dưới 5km, +10k/km',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nhập bảng giá tham khảo' : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Giới thiệu (không bắt buộc)',
                hintText: 'Có phụ bốc xếp, nhận tháo lắp giường tủ...',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(
                _saving
                    ? 'Đang lưu...'
                    : sua
                    ? 'Lưu hồ sơ'
                    : 'Đăng ký',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
