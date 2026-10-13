import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../shared/models/app_user.dart';
import '../../quan_an/screens/quan_an_routes.dart';
import '../../quan_an/screens/quan_an_shell.dart';
import '../../quan_an/services/quan_an_dich_vu.dart';
import '../../shop/screens/kenh_nguoi_ban_screen.dart';
import '../../shop/services/shop_dich_vu.dart';
import '../../tro/screens/tro_routes.dart';
import '../../tro/screens/tro_shell.dart';
import '../../tro/services/tro_dich_vu.dart';
import '../../xe_don_tro/screens/xe_don_tro_screen.dart';
import '../../xe_don_tro/services/xe_dich_vu.dart';
import '../models/xac_thuc.dart';
import '../services/auth_service.dart';
import '../services/xac_thuc_service.dart';
import 'admin_danh_tinh_screen.dart';
import 'xac_nhan_danh_tinh_screen.dart';
import 'xac_thuc_sdt_screen.dart';

/// Hồ sơ cá nhân: xem/sửa tên, SĐT, xác thực tài khoản (OTP, CCCD),
/// lối vào các chương trình hợp tác của từng module, và đăng xuất.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authService, this.xacThucService});

  final AuthService? authService;
  final XacThucService? xacThucService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late final AuthService _auth = widget.authService ?? AuthService();
  late final XacThucService _xacThuc =
      widget.xacThucService ?? FirebaseXacThucService();
  late final String _uid = _auth.currentUser?.uid ?? '';
  late final Stream<XacThuc> _trangThai = _xacThuc.cuaToi(_uid);
  late final Stream<QuyenAdmin> _quyen = _xacThuc.quyenAdmin(_uid);

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
            const SizedBox(height: 28),
            _tieuDe(context, 'Xác thực tài khoản'),
            StreamBuilder<XacThuc>(
              stream: _trangThai,
              builder: (context, snap) => _xacThucTiles(snap.data),
            ),
            StreamBuilder<QuyenAdmin>(
              stream: _quyen,
              builder: (context, snap) => snap.data?.danhTinh == true
                  ? ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Duyệt danh tính'),
                      subtitle: const Text('Dành cho admin'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _mo(AdminDanhTinhScreen(service: _xacThuc)),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            _tieuDe(context, 'Hợp tác với app'),
            ..._hopTacTiles(),
            const SizedBox(height: 24),
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

  void _mo(Widget man) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => man));

  Widget _tieuDe(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _xacThucTiles(XacThuc? xt) {
    final t = xt ?? const XacThuc();
    final moDanhTinh = t.danhTinh == 'chua' || t.danhTinh == 'tu_choi';
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            t.daOtp ? Icons.verified : Icons.phone_android,
            color: t.daOtp ? Theme.of(context).colorScheme.primary : null,
          ),
          title: const Text('Số điện thoại (OTP)'),
          subtitle: Text(
            xt == null
                ? 'Đang tải...'
                : t.daOtp
                ? 'Đã xác thực · ${t.sdt}'
                : 'Chưa xác thực · cần để đặt cọc, đặt món, đăng bán',
          ),
          trailing: t.daOtp ? null : const Icon(Icons.chevron_right),
          onTap: xt == null || t.daOtp
              ? null
              : () => _mo(XacThucSdtScreen(service: _xacThuc)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            t.daXacThucDanhTinh ? Icons.verified_user : Icons.badge_outlined,
            color: t.daXacThucDanhTinh
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: const Text('Danh tính (CCCD)'),
          subtitle: Text(
            xt == null
                ? 'Đang tải...'
                : [
                    XacThuc.danhTinhLabels[t.danhTinh] ?? t.danhTinh,
                    if (t.danhTinh == 'tu_choi' && t.lyDoTuChoi != null)
                      t.lyDoTuChoi!,
                    if (moDanhTinh) 'cần để làm chủ trọ, chủ quán, tài xế',
                  ].join(' · '),
          ),
          trailing: moDanhTinh ? const Icon(Icons.chevron_right) : null,
          onTap: xt != null && moDanhTinh
              ? () => _mo(XacNhanDanhTinhScreen(service: _xacThuc))
              : null,
        ),
      ],
    );
  }

  /// Mỗi chương trình hợp tác nằm trong module của nó; ở đây chỉ là lối vào.
  List<Widget> _hopTacTiles() {
    Widget tile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
    return [
      tile(
        Icons.local_shipping_outlined,
        'Làm tài xế dọn trọ',
        'Cần CCCD đã duyệt, admin duyệt hồ sơ xe',
        () => _mo(XeDonTroScreen(dv: XeDichVu.firebase(), initialTab: 2)),
      ),
      tile(
        Icons.storefront_outlined,
        'Bán đồ trên Shop đồ rẻ',
        'Cần xác thực số điện thoại',
        () => _mo(KenhNguoiBanScreen(dv: ShopDichVu.firebase())),
      ),
      tile(
        Icons.home_work_outlined,
        'Cho thuê phòng trọ',
        'Đăng nhà trọ trong mục Tìm trọ',
        () => Navigator.of(context)
            .push(troRoute<void>((_) => TroShell(dv: TroDichVu.firebase()))),
      ),
      tile(
        Icons.restaurant_outlined,
        'Mở quán ăn',
        'Đăng quán trong mục Quán ăn',
        () => Navigator.of(context).push(
          quanAnRoute<void>((_) => QuanAnShell(dv: QuanAnDichVu.firebase())),
        ),
      ),
    ];
  }
}
