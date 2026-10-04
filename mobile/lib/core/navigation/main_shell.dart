import 'package:flutter/material.dart';

import '../../features/home/presentation/home_page.dart';
import '../../shared/widgets/empty_feature_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    EmptyFeaturePage(
      title: 'Khám phá',
      description: 'Nội dung phù hợp với trường và khu vực của bạn sẽ xuất hiện tại đây.',
      icon: Icons.explore_outlined,
    ),
    EmptyFeaturePage(
      title: 'Đăng tin',
      description:
          'Chọn loại nội dung bạn muốn chia sẻ với cộng đồng sinh viên.',
      icon: Icons.add_box_outlined,
    ),
    EmptyFeaturePage(
      title: 'Đã lưu',
      description: 'Bạn chưa lưu phòng, món đồ hoặc địa điểm nào.',
      icon: Icons.favorite_border,
    ),
    EmptyFeaturePage(
      title: 'Tài khoản',
      description:
          'Đăng nhập để xác thực sinh viên và quản lý nội dung của bạn.',
      icon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Đăng tin',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Đã lưu',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
