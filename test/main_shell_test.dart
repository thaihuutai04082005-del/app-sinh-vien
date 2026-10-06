import 'package:app_sinh_vien/features/home/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Thanh điều hướng chuyển được giữa các mục', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(
          pages: [
            Text('Trang A'),
            Text('Trang B'),
            Text('Trang C'),
            Text('Trang D'),
          ],
        ),
      ),
    );
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.text('Yêu thích'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pump();
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 3);
  });
}
