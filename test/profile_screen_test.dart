import 'package:app_sinh_vien/features/auth/screens/profile_screen.dart';
import 'package:app_sinh_vien/features/auth/services/auth_service.dart';
import 'package:app_sinh_vien/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser implements User {
  @override
  String get uid => 'u1';
  @override
  String? get displayName => 'Tên Auth';
  @override
  String? get email => 'a@b.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  bool signedOut = false;
  Map<String, String>? saved;
  bool failLoad = false;

  @override
  User? get currentUser => _FakeUser();

  @override
  Future<AppUser?> loadProfile(String uid) async {
    if (failLoad) throw Exception('lỗi');
    return const AppUser(
      uid: 'u1',
      name: 'Thái Hữu Tài',
      email: 'a@b.com',
      phone: '0123456789',
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    saved = {'name': name, 'phone': phone};
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

void main() {
  testWidgets('Hiển thị hồ sơ đã tải', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authService: _FakeAuthService())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thái Hữu Tài'), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('Số điện thoại sai bị từ chối, đúng thì lưu', (tester) async {
    final auth = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authService: auth)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '12ab');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    expect(auth.saved, isNull);

    await tester.enterText(find.byType(TextFormField).last, '0987654321');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(auth.saved, {'name': 'Thái Hữu Tài', 'phone': '0987654321'});
  });

  testWidgets('Nút đăng xuất gọi signOut', (tester) async {
    final auth = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authService: auth)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pump();
    expect(auth.signedOut, isTrue);
  });

  testWidgets('Báo lỗi và cho thử lại khi tải thất bại', (tester) async {
    final auth = _FakeAuthService()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authService: auth)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được hồ sơ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
