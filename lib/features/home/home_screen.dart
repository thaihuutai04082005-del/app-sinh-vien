import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Trang chủ: lưới các module (giống ngành hàng Shopee).
/// Mỗi module sẽ được nhúng vào đây khi hoàn thành.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _modules = <(String, IconData)>[
    ('Tìm trọ', Icons.home_work_outlined),
    ('Quán ăn', Icons.restaurant_outlined),
    ('Xe dọn trọ', Icons.local_shipping_outlined),
    ('Shop đồ rẻ', Icons.checkroom_outlined),
    ('Vui chơi', Icons.celebration_outlined),
  ];

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
          for (final (label, icon) in _modules)
            Card(
              child: InkWell(
                onTap: () {},
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
