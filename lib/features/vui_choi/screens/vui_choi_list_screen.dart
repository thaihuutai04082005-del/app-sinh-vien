import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../models/vui_choi_model.dart';
import '../services/vui_choi_service.dart';
import '../widgets/vui_choi_card.dart';
import 'dang_dia_diem_vui_choi_screen.dart';
import 'vui_choi_detail_screen.dart';

/// Danh sách điểm vui chơi, lọc theo loại hình.
/// Có đủ 3 trạng thái: đang tải, rỗng, lỗi (mục 7.4).
class VuiChoiListScreen extends StatefulWidget {
  const VuiChoiListScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    super.key,
  });

  final VuiChoiService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;

  @override
  State<VuiChoiListScreen> createState() => _VuiChoiListScreenState();
}

class _VuiChoiListScreenState extends State<VuiChoiListScreen> {
  static const _allCategories = {'all': 'Tất cả', ...vuiChoiCategoryLabels};

  String _selectedCategory = 'all';
  late Stream<List<VuiChoiModel>> _stream = _newStream();

  Stream<List<VuiChoiModel>> _newStream() =>
      widget.service.getDanhSachVuiChoi(category: _selectedCategory);

  void _selectCategory(String id) {
    setState(() {
      _selectedCategory = id;
      _stream = _newStream();
    });
  }

  void _retry() {
    setState(() {
      _stream = _newStream();
    });
  }

  Future<void> _openDangDiaDiem() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DangDiaDiemVuiChoiScreen(
          service: widget.service,
          storage: widget.storage,
          pickImages: widget.pickImages,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng địa điểm thành công.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm vui chơi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Đăng địa điểm mới',
            onPressed: _openDangDiaDiem,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final entry in _allCategories.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _selectedCategory == entry.key,
                      onSelected: (selected) {
                        if (selected) _selectCategory(entry.key);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<VuiChoiModel>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Chưa tải được danh sách điểm vui chơi. Vui lòng thử lại.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? const <VuiChoiModel>[];
                if (list.isEmpty) {
                  return const Center(child: Text('Chưa có địa điểm nào.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) => VuiChoiCard(
                    item: list[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VuiChoiDetailScreen(item: list[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
