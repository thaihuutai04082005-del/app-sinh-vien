import 'package:flutter/material.dart';

import '../services/xac_thuc_service.dart';

/// TK-04 Xác nhận người thật (Phần 4) — bản tối thiểu theo quyết định của nhóm:
/// chưa chụp CCCD / khuôn mặt trong app (làm khi có máy Android thật). Người dùng khai họ tên + số CCCD;
/// số CCCD chỉ lưu dạng băm + 4 số cuối; admin danh tính duyệt bằng tay.
class XacNhanDanhTinhScreen extends StatefulWidget {
  const XacNhanDanhTinhScreen({required this.service, super.key});

  final XacThucService service;

  @override
  State<XacNhanDanhTinhScreen> createState() => _XacNhanDanhTinhScreenState();
}

class _XacNhanDanhTinhScreenState extends State<XacNhanDanhTinhScreen> {
  final _ten = TextEditingController();
  final _cccd = TextEditingController();
  bool _dongY = false;
  bool _camKet = false;
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _ten.dispose();
    _cccd.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await widget.service.guiDanhTinh(
        hoTen: _ten.text.trim(),
        soCccd: _cccd.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi, chờ admin duyệt (mục tiêu 24 giờ)'),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } catch (_) {
      setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác nhận người thật')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Bắt buộc với người muốn cho thuê trọ / bán quán. Làm 1 lần cho mọi module; '
          'mỗi module vẫn duyệt hồ sơ kinh doanh riêng.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ten,
          decoration: const InputDecoration(
            labelText: 'Họ tên đầy đủ (như trên CCCD)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cccd,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: const InputDecoration(labelText: 'Số CCCD (12 chữ số)'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _dongY,
          onChanged: (v) => setState(() => _dongY = v ?? false),
          title: const Text(
            'Tôi đồng ý xử lý dữ liệu cá nhân: số CCCD chỉ lưu dạng mã băm và 4 số cuối để chống đăng ký trùng, '
            'chỉ admin danh tính xem để đối chiếu.',
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _camKet,
          onChanged: (v) => setState(() => _camKet = v ?? false),
          title: const Text('Tôi cam kết thông tin trên là đúng sự thật.'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: !_dongY || !_camKet || _dangGui ? null : _gui,
          child: Text(_dangGui ? 'Đang gửi...' : 'Gửi xác nhận'),
        ),
        if (_loi != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _loi!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
}
