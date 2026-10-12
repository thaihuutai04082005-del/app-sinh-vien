import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../services/auth_service.dart';

/// Nhập mã 6 số gửi tới email. Đúng mã thì AuthGate tự chuyển sang trang chủ.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email, this.authService});

  final String? email;
  final AuthService? authService;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // Khớp CHO_GUI_LAI_GIAY trong functions-xac-nhan-email/index.js.
  static const _resendCooldown = 60;

  late final AuthService _auth = widget.authService ?? AuthService();
  final _codeCtrl = TextEditingController();
  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _verifying = false;
  bool _sending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _show('Mã gồm 6 chữ số', error: true);
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
    });
    try {
      await _auth.verifyCode(code);
    } catch (e) {
      if (mounted) _show(AuthService.messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await _auth.sendVerificationCode();
      if (!mounted) return;
      _show('Đã gửi mã mới.');
      _codeCtrl.clear();
      _startCooldown();
    } catch (e) {
      if (mounted) _show(AuthService.messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _show(String text, {bool error = false}) => setState(() {
    _message = text;
    _messageIsError = error;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nhập mã xác nhận',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã 6 số đã được gửi tới '
                    '${widget.email ?? 'email của bạn'}. '
                    'Nếu không thấy, hãy xem cả mục Spam/Thư rác.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      hintText: '••••••',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _messageIsError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _verifying ? null : _verify,
                    child: _verifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: (_cooldown > 0 || _sending) ? null : _resend,
                    child: Text(
                      _cooldown > 0
                          ? 'Gửi lại mã (${_cooldown}s)'
                          : 'Gửi lại mã',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _auth.signOut,
                    child: const Text('Dùng email khác / Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
