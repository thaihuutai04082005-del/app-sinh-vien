import 'package:app_sinh_vien/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trang chủ hiển thị đủ 5 module', (tester) async {
    await tester.pumpWidget(const AppSinhVien());
    for (final name in ['Tìm trọ', 'Quán ăn', 'Xe dọn trọ', 'Shop đồ rẻ', 'Vui chơi']) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
