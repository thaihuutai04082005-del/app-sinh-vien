import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../shop/screens/shop_screen.dart';
import '../shop/services/product_service.dart';
import '../tro/screens/phong_tro_list_screen.dart';
import '../tro/services/phong_tro_service.dart';
import '../vui_choi/screens/vui_choi_list_screen.dart';
import '../vui_choi/services/vui_choi_service.dart';
import '../xe_don_tro/screens/xe_don_tro_screen.dart';
import '../xe_don_tro/services/booking_xe_service.dart';

class _Module {
  const _Module(this.label, this.subtitle, this.icon, this.color, this.builder);

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Module chưa làm thì để null -> báo "sắp ra mắt".
  final Widget Function()? builder;
}

/// Trang chủ: lời chào, ô tìm module và lưới các module (giống ngành hàng
/// Shopee). Mỗi module sẽ được nhúng vào đây khi hoàn thành.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _modules = <_Module>[
    _Module(
      'Tìm trọ',
      'Chỗ ở vừa ý',
      Icons.home_work_outlined,
      const Color(0xFF0C6B5D),
      () => PhongTroListScreen(
        service: FirestorePhongTroService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    const _Module(
      'Quán ăn',
      'No bụng, nhẹ ví',
      Icons.restaurant_outlined,
      Color(0xFFE47A32),
      null,
    ),
    _Module(
      'Xe dọn trọ',
      'Báo giá rõ ràng',
      Icons.local_shipping_outlined,
      const Color(0xFF3578B8),
      () => XeDonTroScreen(
        service: FirestoreBookingXeService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    _Module(
      'Shop đồ rẻ',
      'Đồ hay, giá hời',
      Icons.checkroom_outlined,
      const Color(0xFFC6537A),
      () => ShopScreen(
        service: FirestoreProductService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    _Module(
      'Vui chơi',
      'Đi đâu hôm nay?',
      Icons.celebration_outlined,
      const Color(0xFF7657B5),
      () => VuiChoiListScreen(
        service: FirestoreVuiChoiService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
  ];

  String _query = '';

  List<_Module> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _modules;
    return [
      for (final m in _modules)
        if ('${m.label} ${m.subtitle}'.toLowerCase().contains(q)) m,
    ];
  }

  void _open(_Module module) {
    final builder = module.builder;
    if (builder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.label} sẽ sớm ra mắt')),
      );
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => builder()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.appName,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverList.list(
              children: [
                Text(
                  'DÀNH CHO ĐỜI SỐNG SINH VIÊN',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mọi thứ sinh viên cần, trong một nơi.',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SearchBar(
                  leading: const Icon(Icons.search),
                  hintText: 'Tìm mục: trọ, xe, shop...',
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Không có mục nào phù hợp')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width >= 1100
                      ? 5
                      : width >= 650
                      ? 3
                      : 2;
                  return SliverGrid.builder(
                    itemCount: visible.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: width >= 1100 ? 1.6 : 1.45,
                    ),
                    itemBuilder: (context, i) => _ModuleCard(
                      module: visible[i],
                      onTap: () => _open(visible[i]),
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final _Module module;
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Icon(module.icon, color: module.color, size: 28),
              ),
              const Spacer(),
              Text(
                module.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
