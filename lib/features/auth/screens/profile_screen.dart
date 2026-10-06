import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../shared/models/app_user.dart';
import '../services/auth_service.dart';

/// Hồ sơ cá nhân: xem/sửa tên, SĐT và đăng xuất.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late final AuthService _auth = widget.authService ?? AuthService();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) throw StateError('Chưa đăng nhập');
      final AppUser? profile = await _auth.loadProfile(user.uid);
      _nameCtrl.text = profile?.name ?? user.displayName ?? '';
      _phoneCtrl.text = profile?.phone ?? '';
      _email = profile?.email ?? user.email ?? '';
    } catch (_) {
      _loadError = 'Không tải được hồ sơ';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _auth.updateProfile(
        uid: _auth.currentUser!.uid,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Lưu không thành công, thử lại sau')),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_loadError != null) {
      return ErrorView(message: _loadError!, onRetry: _load);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 8),
            Text(_email, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                return RegExp(r'^\d{9,11}$').hasMatch(value)
                    ? null
                    : 'Số điện thoại không hợp lệ';
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu thay đổi'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _auth.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
