import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_view.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Đã đăng nhập -> [signedInBuilder], chưa -> màn hình đăng nhập,
/// đăng nhập nhưng chưa xác nhận email -> màn hình chờ xác nhận.
/// Màn hình sau đăng nhập do main.dart truyền vào để module auth không phải
/// import module khác.
class AuthGate extends StatelessWidget {
  const AuthGate({required this.signedInBuilder, super.key, this.authService});

  final WidgetBuilder signedInBuilder;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();
    return StreamBuilder<User?>(
      stream: auth.userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        if (snapshot.hasError) {
          return const Scaffold(body: ErrorView());
        }
        final user = snapshot.data;
        if (user == null) return LoginScreen(authService: authService);
        if (!user.emailVerified) {
          return VerifyEmailScreen(email: user.email, authService: authService);
        }
        return signedInBuilder(context);
      },
    );
  }
}
