import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../housing/data/demo_housing_repository.dart';
import '../../housing/presentation/housing_page.dart';
import '../../../shared/widgets/empty_feature_page.dart';
import '../../shop/screens/shop_screen.dart';
import '../../shop/services/product_service.dart';
import '../../xe_don_tro/screens/xe_don_tro_screen.dart';
import '../../xe_don_tro/services/booking_xe_service.dart';

class _StudentModule {
  const _StudentModule(this.label, this.subtitle, this.icon, this.color);

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _modules = [
    _StudentModule(
      'Tìm trọ',
      'Chỗ ở vừa ý',
      Icons.apartment_outlined,
      Color(0xFF0C6B5D),
    ),
    _StudentModule(
      'Quán ăn',
      'No bụng, nhẹ ví',
      Icons.restaurant_outlined,
      Color(0xFFE47A32),
    ),
    _StudentModule(
      'Xe dọn trọ',
      'Báo giá rõ ràng',
      Icons.local_shipping_outlined,
      Color(0xFF3578B8),
    ),
    _StudentModule(
      'Shop đồ rẻ',
      'Đồ hay, giá hời',
      Icons.shopping_bag_outlined,
      Color(0xFFC6537A),
    ),
    _StudentModule(
      'Vui chơi',
      'Đi đâu hôm nay?',
      Icons.celebration_outlined,
      Color(0xFF7657B5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UniHub',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Thông báo',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  'DÀNH CHO ĐỜI SỐNG SINH VIÊN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mọi thứ sinh viên cần, trong một nơi.',
                  style: TextStyle(
                    fontSize: 31,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tìm kiếm, kết nối và chia sẻ những tiện ích thiết thực quanh trường và khu vực của bạn.',
                ),
                const SizedBox(height: 22),
                const SearchBar(
                  leading: Icon(Icons.search),
                  hintText: 'Tìm phòng, quán ăn, dịch vụ...',
                ),
                const SizedBox(height: 28),
                const Text(
                  'Khám phá UniHub',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columnCount = width >= 1100
                    ? 5
                    : width >= 650
                    ? 3
                    : 2;
                return SliverGrid.builder(
                  itemCount: _modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: width >= 1100 ? 1.45 : 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    return _ModuleCard(
                      module: module,
                      onTap: () => _openModule(context, index),
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

  void _openModule(BuildContext context, int index) {
    final module = _modules[index];
    final page = switch (index) {
      0 => HousingPage(repository: DemoHousingRepository()),
      2 => XeDonTroScreen(
        service: FirestoreBookingXeService(),
        storage: FirebaseImageStorageService(),
      ),
      3 => ShopScreen(
        service: FirestoreProductService(),
        storage: FirebaseImageStorageService(),
      ),
      _ => EmptyFeaturePage(
        title: module.label,
        description: 'Chưa có nội dung. Dữ liệu do cộng đồng sinh viên tạo sẽ xuất hiện tại đây.',
        icon: module.icon,
      ),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final _StudentModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon, color: module.color, size: 30),
              const Spacer(),
              Text(
                module.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                module.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
