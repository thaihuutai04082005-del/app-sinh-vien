import 'package:flutter/material.dart';

import '../models/vui_choi_model.dart';
import '../services/vui_choi_service.dart';
import '../widgets/vui_choi_card.dart';
import 'vui_choi_detail_screen.dart';

/// Danh sách điểm vui chơi, lọc theo loại hình.
/// Có đủ 3 trạng thái: đang tải, rỗng, lỗi (mục 7.4).
class VuiChoiListScreen extends StatefulWidget {
  const VuiChoiListScreen({required this.service, super.key});

  final VuiChoiService service;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm vui chơi')),
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
