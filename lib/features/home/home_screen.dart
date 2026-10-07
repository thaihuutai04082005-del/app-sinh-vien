import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../shop/screens/shop_screen.dart';
import '../shop/services/product_service.dart';
import '../tro/screens/phong_tro_list_screen.dart';
import '../tro/screens/tro_routes.dart';
import '../tro/services/phong_tro_service.dart';
import '../vui_choi/screens/vui_choi_list_screen.dart';
import '../vui_choi/services/vui_choi_service.dart';
import '../xe_don_tro/screens/xe_don_tro_screen.dart';
import '../xe_don_tro/services/booking_xe_service.dart';

/// Trang chủ: lưới các module (giống ngành hàng Shopee).
/// Mỗi module sẽ được nhúng vào đây khi hoàn thành.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Module chưa làm thì để `builder` là null -> báo "sắp ra mắt".
  static final _modules = <(String, IconData, Widget Function()?)>[
    (
      'Tìm trọ',
      Icons.home_work_outlined,
      () => PhongTroListScreen(
        service: FirestorePhongTroService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    ('Quán ăn', Icons.restaurant_outlined, null),
    (
      'Xe dọn trọ',
      Icons.local_shipping_outlined,
      () => XeDonTroScreen(
        service: FirestoreBookingXeService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    (
      'Shop đồ rẻ',
      Icons.checkroom_outlined,
      () => ShopScreen(
        service: FirestoreProductService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
    (
      'Vui chơi',
      Icons.celebration_outlined,
      () => VuiChoiListScreen(
        service: FirestoreVuiChoiService(),
        storage: FirebaseImageStorageService(),
      ),
    ),
  ];

  void _open(BuildContext context, String label, Widget Function()? builder) {
    if (builder == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label sẽ sớm ra mắt')));
      return;
    }
    // Tìm trọ có giao diện riêng (xanh biển – trắng) nên mở bằng route của module.
    final route = label == 'Tìm trọ'
        ? troRoute<void>((_) => builder())
        : MaterialPageRoute<void>(builder: (_) => builder());
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSizes.padding),
        crossAxisCount: 3,
        mainAxisSpacing: AppSizes.padding,
        crossAxisSpacing: AppSizes.padding,
        children: [
          for (final (label, icon, builder) in _modules)
            Card(
              child: InkWell(
                onTap: () => _open(context, label, builder),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(label, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
