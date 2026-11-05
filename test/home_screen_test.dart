import 'package:app_sinh_vien/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1300.0]) {
    testWidgets('Trang chủ không tràn bố cục ở chiều rộng $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Vui chơi'), 200);
      expect(tester.takeException(), isNull);
    });
  }

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

  testWidgets('Ô tìm kiếm lọc module theo tên', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.enterText(find.byType(TextField), 'shop');
    await tester.pump();
    expect(find.text('Shop đồ rẻ'), findsOneWidget);
    expect(find.text('Tìm trọ'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Không có mục nào phù hợp'), findsOneWidget);
  });
}
