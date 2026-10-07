import 'package:flutter/material.dart';

import '../services/xac_thuc_service.dart';

/// TK-03 Xác thực số điện thoại bằng OTP (Phần 4).
/// Bản THỬ NGHIỆM: chưa gửi SMS thật, mã luôn là 123456 (đặc tả mục 5.2: "OTP thử nghiệm khi demo").
class XacThucSdtScreen extends StatefulWidget {
  const XacThucSdtScreen({required this.service, super.key});

  final XacThucService service;

  @override
  State<XacThucSdtScreen> createState() => _XacThucSdtScreenState();
}

class _XacThucSdtScreenState extends State<XacThucSdtScreen> {
  final _sdt = TextEditingController();
  final _ma = TextEditingController();
  bool _daGui = false;
  bool _dangXuLy = false;
  String? _thongBao;
  String? _loi;

  @override
  void dispose() {
    _sdt.dispose();
    _ma.dispose();
    super.dispose();
  }

  Future<void> _chay(Future<void> Function() viec) async {
    setState(() {
      _dangXuLy = true;
      _loi = null;
    });
    try {
      await viec();
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } catch (_) {
      setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác thực số điện thoại')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Mỗi số điện thoại chỉ gắn với 1 tài khoản. Số đã xác thực dùng cho mọi module.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _sdt,
          enabled: !_daGui,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '09xxxxxxxx',
          ),
        ),
        const SizedBox(height: 12),
        if (!_daGui)
          FilledButton(
            onPressed: _dangXuLy
                ? null
                : () => _chay(() async {
                    final goiY = await widget.service.guiOtp(_sdt.text.trim());
                    setState(() {
                      _daGui = true;
                      _thongBao = goiY;
                    });
                  }),
            child: const Text('Gửi mã OTP'),
          )
        else ...[
          if (_thongBao != null && _thongBao!.isNotEmpty)
            Text(
              _thongBao!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _ma,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Mã OTP (6 số, hết hạn sau 5 phút)',
            ),
          ),
          FilledButton(
            onPressed: _dangXuLy
                ? null
                : () => _chay(() async {
                    await widget.service.xacNhanOtp(_ma.text.trim());
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xác thực số điện thoại'),
                      ),
                    );
                    Navigator.pop(context, true);
                  }),
            child: const Text('Xác nhận'),
          ),
          TextButton(
            onPressed: _dangXuLy ? null : () => setState(() => _daGui = false),
            child: const Text('Đổi số / gửi lại mã'),
          ),
        ],
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
