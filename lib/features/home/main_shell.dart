import 'package:flutter/material.dart';

import '../../core/widgets/async_state_view.dart';
import '../auth/screens/profile_screen.dart';
import 'home_screen.dart';

/// Khung chính sau đăng nhập: thanh điều hướng dưới giữa các mục.
class MainShell extends StatefulWidget {
  /// [pages] chỉ dùng khi test; mặc định là 4 mục thật của app.
  const MainShell({super.key, this.pages});

  final List<Widget>? pages;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _pages = widget.pages ??
      const [
        HomeScreen(),
        _ComingSoon(title: 'Tin nhắn'),
        _ComingSoon(title: 'Yêu thích'),
        ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Tin nhắn'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Yêu thích'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Cá nhân'),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyView(message: 'Tính năng sẽ sớm ra mắt'),
      );
}
