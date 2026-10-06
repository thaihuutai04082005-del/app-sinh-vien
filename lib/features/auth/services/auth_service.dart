import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/app_user.dart';

/// Gọi Firebase Auth + Firestore cho đăng ký / đăng nhập.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db
        .collection(Collections.users)
        .doc(user.uid)
        .set(
          AppUser(
            uid: user.uid,
            name: name.trim(),
            email: email.trim(),
          ).toMap(),
        );
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Đọc hồ sơ từ collection `users`; null nếu chưa có document.
  Future<AppUser?> loadProfile(String uid) async {
    final doc = await _db.collection(Collections.users).doc(uid).get();
    final data = doc.data();
    return data == null ? null : AppUser.fromMap(data);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    final ref = _db.collection(Collections.users).doc(uid);
    try {
      // Rules chỉ cho sửa name và phone.
      await ref.update({'name': name.trim(), 'phone': phone.trim()});
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      // Chưa có hồ sơ (vd. tài khoản tạo từ trước) -> tạo mới.
      await ref.set(
        AppUser(
          uid: uid,
          name: name.trim(),
          email: _auth.currentUser?.email ?? '',
          phone: phone.trim(),
        ).toMap(),
      );
    }
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  /// Đổi mã lỗi Firebase thành câu tiếng Việt cho người dùng.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Email không hợp lệ';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng';
        case 'email-already-in-use':
          return 'Email này đã được đăng ký';
        case 'weak-password':
          return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
        case 'network-request-failed':
          return 'Không có kết nối mạng';
        case 'too-many-requests':
          return 'Thử quá nhiều lần, vui lòng đợi một lúc';
      }
    }
    return 'Đã có lỗi xảy ra, vui lòng thử lại';
  }
}
