import 'package:flutter/material.dart';

import '../services/xac_thuc_service.dart';

/// TK-AD-01 Admin danh tính duyệt xác nhận người thật (mọi lần duyệt được ghi nhật ký ở server).
class AdminDanhTinhScreen extends StatelessWidget {
  const AdminDanhTinhScreen({required this.service, super.key});

  final XacThucService service;

  Future<void> _duyet(BuildContext context, String uid, bool dongY) async {
    String? lyDo;
    if (!dongY) {
      final c = TextEditingController();
      lyDo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lý do từ chối'),
          content: TextField(controller: c),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      if (lyDo == null) return;
    }
    try {
      await service.duyetDanhTinh(uid, dongY: dongY, lyDo: lyDo);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Duyệt danh tính')),
    body: StreamBuilder<List<(String, String, String)>>(
      stream: service.danhTinhChoDuyet(),
      builder: (context, s) {
        if (s.hasError) {
          return const Center(child: Text('Không tải được dữ liệu'));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final ds = s.data!;
        if (ds.isEmpty) {
          return const Center(child: Text('Không có hồ sơ chờ duyệt'));
        }
        return ListView(
          children: [
            for (final (uid, ten, cccd4) in ds)
              ListTile(
                title: Text(ten),
                subtitle: Text('CCCD ****$cccd4 · $uid'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Từ chối',
                      onPressed: () => _duyet(context, uid, false),
                      icon: const Icon(Icons.close),
                    ),
                    IconButton(
                      tooltip: 'Duyệt',
                      onPressed: () => _duyet(context, uid, true),
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
