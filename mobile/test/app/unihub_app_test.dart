import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub_student_app/app/unihub_app.dart';

void main() {
  testWidgets('trang chủ giới thiệu đúng năm module dành cho sinh viên', (
    tester,
  ) async {
    await tester.pumpWidget(const UniHubApp());

    expect(find.text('Mọi thứ sinh viên cần, trong một nơi.'), findsOneWidget);
    for (final label in [
      'Tìm trọ',
      'Quán ăn',
      'Xe dọn trọ',
      'Shop đồ rẻ',
      'Vui chơi',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('màn hình rộng hiển thị năm module trên cùng một hàng', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const UniHubApp());

    final moduleCenters = [
      'Tìm trọ',
      'Quán ăn',
      'Xe dọn trọ',
      'Shop đồ rẻ',
      'Vui chơi',
    ].map((label) => tester.getCenter(find.text(label))).toList();

    expect(moduleCenters.map((point) => point.dy).toSet(), hasLength(1));
  });

  testWidgets('module tìm trọ có dữ liệu beta và lọc được theo khu vực', (
    tester,
  ) async {
    await tester.pumpWidget(const UniHubApp());

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tìm trọ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dữ liệu minh họa'), findsOneWidget);
    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Cao Lãnh');
    await tester.pump();

    expect(find.text('Studio gần Đại học Đồng Tháp'), findsOneWidget);
    expect(find.text('Phòng riêng khu Tân Quy Đông'), findsNothing);
  });
}
