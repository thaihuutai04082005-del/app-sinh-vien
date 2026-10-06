import 'package:app_sinh_vien/core/services/daily_quota.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCredential implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  User? current;
  int anonymousCalls = 0;
  bool failNext = false;

  @override
  User? get currentUser => current;

  @override
  Future<UserCredential> signInAnonymously() async {
    anonymousCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (failNext) {
      failNext = false;
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    current = _FakeUser('anon-1');
    return _FakeCredential(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('đã đăng nhập thì dùng uid đó, không đăng nhập ẩn danh', () async {
    final auth = _FakeAuth()..current = _FakeUser('u1');
    final quota = DailyQuota(null, auth);
    expect(await quota.uidForTest(), 'u1');
    expect(auth.anonymousCalls, 0);
  });

  test(
    'chưa đăng nhập: nhiều lượt chạy song song chỉ đăng nhập ẩn danh 1 lần',
    () async {
      final auth = _FakeAuth();
      final quota = DailyQuota(null, auth);
      final uids = await Future.wait([
        for (var i = 0; i < 5; i++) quota.uidForTest(),
      ]);
      expect(uids, everyElement('anon-1'));
      expect(auth.anonymousCalls, 1);
    },
  );

  test(
    'đổi tài khoản sau khi đã lấy uid thì dùng uid mới, không dùng uid cũ',
    () async {
      final auth = _FakeAuth()..current = _FakeUser('u1');
      final quota = DailyQuota(null, auth);
      expect(await quota.uidForTest(), 'u1');
      auth.current = _FakeUser('u2');
      expect(await quota.uidForTest(), 'u2');
    },
  );

  test('đăng nhập ẩn danh lỗi thì lần sau thử lại được', () async {
    final auth = _FakeAuth()..failNext = true;
    final quota = DailyQuota(null, auth);
    await expectLater(
      quota.uidForTest(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(await quota.uidForTest(), 'anon-1');
    expect(auth.anonymousCalls, 2);
  });
}
