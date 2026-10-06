import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../models/vui_choi_model.dart';
import '../services/vui_choi_service.dart';
import '../widgets/vui_choi_card.dart';
import 'dang_dia_diem_vui_choi_screen.dart';
import 'vui_choi_detail_screen.dart';

class VuiChoiListScreen extends StatefulWidget {
  const VuiChoiListScreen({Key? key}) : super(key: key);

  @override
  State<VuiChoiListScreen> createState() => _VuiChoiListScreenState();
}

class _VuiChoiListScreenState extends State<VuiChoiListScreen> {
  final VuiChoiService _service = VuiChoiService();
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'cafe', 'label': 'Cà phê'},
    {'id': 'rap_phim', 'label': 'Rạp phim'},
    {'id': 'cong_vien', 'label': 'Công viên'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Vui Chơi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Đăng địa điểm mới',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => DangDiaDiemVuiChoiScreen(
                    service: _service,
                    storage: FirebaseImageStorageService(),
                  ),
                ),
              );
              if (created == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng địa điểm thành công.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Thêm dữ liệu mẫu',
            onPressed: () async {
              await _service.taoDuLieuMau();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm 2 địa điểm mẫu!')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: _selectedCategory == cat['id'],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat['id']!);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Data List
          Expanded(
            child: StreamBuilder<List<VuiChoiModel>>(
              stream: _service.getDanhSachVuiChoi(category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Chưa có địa điểm nào.'));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return VuiChoiCard(
                      item: list[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VuiChoiDetailScreen(item: list[index]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
