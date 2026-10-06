import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../models/phong_tro.dart';
import '../services/phong_tro_service.dart';
import '../widgets/phong_tro_card.dart';
import 'dang_phong_tro_screen.dart';
import 'phong_tro_detail_screen.dart';

/// Danh sách phòng trọ: tìm theo tên/khu vực, lọc theo loại phòng và xác thực.
/// Có đủ 3 trạng thái: đang tải, rỗng, lỗi (mục 7.4).
class PhongTroListScreen extends StatefulWidget {
  const PhongTroListScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final PhongTroService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<PhongTroListScreen> createState() => _PhongTroListScreenState();
}

class _PhongTroListScreenState extends State<PhongTroListScreen> {
  late Future<List<PhongTro>> _future = widget.service.getDanhSachPhongTro();
  String _query = '';
  RoomType? _roomType;
  bool _verifiedOnly = false;

  void _reload() {
    setState(() {
      _future = widget.service.getDanhSachPhongTro();
    });
  }

  Future<void> _openForm() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DangPhongTroScreen(
          service: widget.service,
          storage: widget.storage,
          pickImages: widget.pickImages,
        ),
      ),
    );
    if (posted == true) _reload();
  }

  List<PhongTro> _filter(List<PhongTro> list) {
    final query = _query.trim().toLowerCase();
    return list
        .where((p) {
          final searchable = '${p.title} ${p.address}'.toLowerCase();
          return (query.isEmpty || searchable.contains(query)) &&
              (_roomType == null || p.roomType == _roomType) &&
              (!_verifiedOnly || p.ownerVerified);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm trọ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        tooltip: 'Đăng tin cho thuê',
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Đăng tin'),
      ),
      body: FutureBuilder<List<PhongTro>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chưa tải được danh sách phòng. Vui lòng thử lại.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final all = snapshot.data ?? const <PhongTro>[];
          final list = _filter(all);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  'Chỗ ở quanh bạn',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tìm nhanh theo khu vực, loại phòng và trạng thái xác thực.',
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Tên trường hoặc khu vực',
                    hintText: 'Ví dụ: Cao Lãnh',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _roomType == null,
                        onSelected: (_) => setState(() => _roomType = null),
                      ),
                      const SizedBox(width: 8),
                      for (final type in RoomType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type.label),
                            selected: _roomType == type,
                            onSelected: (_) => setState(() => _roomType = type),
                          ),
                        ),
                      FilterChip(
                        avatar: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('Đã xác thực'),
                        selected: _verifiedOnly,
                        onSelected: (v) => setState(() => _verifiedOnly = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${list.length} chỗ ở phù hợp',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  _EmptyState(hasData: all.isNotEmpty)
                else
                  for (final phongTro in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PhongTroCard(
                        phongTro: phongTro,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PhongTroDetailScreen(phongTro: phongTro),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasData});

  /// true: có phòng nhưng bị bộ lọc loại hết; false: chưa có phòng nào.
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasData ? 'Không tìm thấy phòng phù hợp' : 'Chưa có phòng nào',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Thử đổi từ khóa hoặc bỏ bớt bộ lọc.'
                : 'Các tin cho thuê sẽ hiện ở đây khi chủ trọ đăng.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
