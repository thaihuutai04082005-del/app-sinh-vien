import 'package:flutter/material.dart';

import '../../../shared/widgets/async_list_view.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';

/// Admin Xe dọn trọ (`admins/{uid}.xe`) duyệt hồ sơ tài xế: xem biển số, ảnh xe, bằng lái.
class DuyetTaiXeScreen extends StatefulWidget {
  const DuyetTaiXeScreen({required this.dv, super.key});

  final XeDichVu dv;

  @override
  State<DuyetTaiXeScreen> createState() => _DuyetTaiXeScreenState();
}

class _DuyetTaiXeScreenState extends State<DuyetTaiXeScreen> {
  late Future<List<TaiXe>> _ds = widget.dv.xe.hoSoChoDuyet();

  Future<void> _reload() async {
    final f = widget.dv.xe.hoSoChoDuyet();
    setState(() {
      _ds = f;
    });
    await f.catchError((_) => <TaiXe>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt tài xế')),
      body: AsyncListView<TaiXe>(
        future: _ds,
        onRefresh: _reload,
        emptyIcon: Icons.fact_check_outlined,
        emptyText: 'Không có hồ sơ nào chờ duyệt.',
        itemBuilder: (context, t) =>
            _HoSoCard(dv: widget.dv, taiXe: t, onXong: _reload),
      ),
    );
  }
}

class _HoSoCard extends StatefulWidget {
  const _HoSoCard({
    required this.dv,
    required this.taiXe,
    required this.onXong,
  });

  final XeDichVu dv;
  final TaiXe taiXe;
  final VoidCallback onXong;

  @override
  State<_HoSoCard> createState() => _HoSoCardState();
}

class _HoSoCardState extends State<_HoSoCard> {
  late final _bangLai = widget.dv.xe.giayTo(widget.taiXe.driverId);
  bool _dangLam = false;

  Future<void> _duyet(bool dongY) async {
    String? lyDo;
    if (!dongY) {
      lyDo = await hoiLyDo(
        context,
        tieuDe: 'Từ chối hồ sơ',
        nutXacNhan: 'Từ chối',
      );
      if (lyDo == null) return;
    }
    setState(() => _dangLam = true);
    try {
      await widget.dv.xe.duyetTaiXe(
        widget.taiXe.driverId,
        dongY: dongY,
        lyDo: lyDo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dongY
                ? 'Đã duyệt ${widget.taiXe.name}.'
                : 'Đã từ chối ${widget.taiXe.name}.',
          ),
        ),
      );
      widget.onXong();
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLam = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.taiXe;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${t.loaiXe} · Biển số ${t.licensePlate} · ${t.area}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text('Bảng giá: ${t.priceReference}'),
            const SizedBox(height: 10),
            Text('Ảnh xe', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            _Anh(urls: t.vehiclePhotos),
            const SizedBox(height: 10),
            Text('Bằng lái', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            FutureBuilder<List<String>>(
              future: _bangLai,
              builder: (context, snap) => switch (snap) {
                AsyncSnapshot(hasError: true) => Text('${snap.error}'),
                AsyncSnapshot(hasData: true) => _Anh(urls: snap.data!),
                _ => const LinearProgressIndicator(),
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _dangLam ? null : () => _duyet(false),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _dangLam ? null : () => _duyet(true),
                    child: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Anh extends StatelessWidget {
  const _Anh({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const Text('Không có ảnh.');
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              child: InteractiveViewer(
                child: NetworkPhoto(urls[i], fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 160, child: NetworkPhoto(urls[i])),
          ),
        ),
      ),
    );
  }
}
