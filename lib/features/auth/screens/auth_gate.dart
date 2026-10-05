import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_view.dart';
import '../../home/home_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Đã đăng nhập -> trang chủ, chưa -> màn hình đăng nhập.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        if (snapshot.hasError) {
          return const Scaffold(body: ErrorView());
        }
        if (snapshot.data == null) return LoginScreen(authService: authService);
        return const HomeScreen();
      },
    );
  }
}
