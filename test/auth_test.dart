import 'package:app_sinh_vien/features/auth/screens/login_screen.dart';
import 'package:app_sinh_vien/features/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Đăng nhập báo lỗi khi để trống', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('Đăng nhập báo lỗi khi email sai định dạng', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(find.byType(TextFormField).first, 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  test('messageFor dịch mã lỗi Firebase sang tiếng Việt', () {
    expect(
      AuthService.messageFor(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      'Email này đã được đăng ký',
    );
    expect(
      AuthService.messageFor(FirebaseAuthException(code: 'invalid-credential')),
      'Email hoặc mật khẩu không đúng',
    );
    expect(
      AuthService.messageFor(Exception('x')),
      'Đã có lỗi xảy ra, vui lòng thử lại',
    );
  });
}
