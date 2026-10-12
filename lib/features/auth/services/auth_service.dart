import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/app_user.dart';

/// Gọi Firebase Auth + Firestore cho đăng ký / đăng nhập.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _authOverride = auth,
       _firestoreOverride = firestore,
       _functionsOverride = functions;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;
  // Cùng region với functions-xac-nhan-email/index.js.
  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Như [authStateChanges] nhưng phát cả khi hồ sơ user đổi (vd. vừa xác
  /// nhận email bằng [verifyCode]).
  Stream<User?> get userChanges => _auth.userChanges();

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
    try {
      await sendVerificationCode();
    } on FirebaseFunctionsException {
      // Tài khoản đã tạo; người dùng bấm "Gửi lại mã" ở màn xác nhận.
    }
  }

  /// Nhờ server gửi mã 6 số tới email của tài khoản đang đăng nhập.
  Future<void> sendVerificationCode() async {
    await _functions.httpsCallable('guiMaXacNhan').call<void>();
  }

  /// Gửi mã người dùng nhập lên server; đúng thì email được xác nhận và
  /// [userChanges] phát user mới để AuthGate chuyển trang.
  Future<void> verifyCode(String code) async {
    await _functions.httpsCallable('xacNhanMa').call<void>({
      'code': code.trim(),
    });
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    // Làm mới token để claim email_verified có hiệu lực và userChanges phát.
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Firebase gửi link đặt lại mật khẩu tới [email]. Không báo lỗi khi email
  /// chưa đăng ký (chống dò tài khoản), nên UI chỉ nói "nếu có tài khoản...".
  Future<void> sendPasswordReset(String email) async {
    _auth.setLanguageCode('vi');
    await _auth.sendPasswordResetEmail(email: email.trim());
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
    if (error is FirebaseFunctionsException) {
      // Server đã trả câu tiếng Việt cho các lỗi do người dùng.
      const userErrors = {
        'invalid-argument',
        'not-found',
        'deadline-exceeded',
        'permission-denied',
        'resource-exhausted',
      };
      if (userErrors.contains(error.code) && error.message != null) {
        return error.message!;
      }
    }
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
        case 'user-disabled':
          return 'Tài khoản đã bị khoá';
      }
    }
    return 'Đã có lỗi xảy ra, vui lòng thử lại';
  }
}
