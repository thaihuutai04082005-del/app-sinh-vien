import 'package:app_sinh_vien/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trang chủ hiển thị đủ 5 module', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    for (final name in [
      'Tìm trọ',
      'Quán ăn',
      'Xe dọn trọ',
      'Shop đồ rẻ',
      'Vui chơi',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
