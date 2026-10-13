import 'package:flutter/material.dart';

import '../../../shared/widgets/async_list_view.dart';
import '../../auth/models/xac_thuc.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';
import '../widgets/xe_widgets.dart';
import 'booking_xe_detail_screen.dart';
import 'dang_ky_tai_xe_screen.dart';
import 'dat_xe_screen.dart';
import 'duyet_tai_xe_screen.dart';

/// Xe dọn trọ (mục 3.3): tìm xe và gửi yêu cầu báo giá, theo dõi đơn của mình,
/// và khu vực cho tài xế (hồ sơ + đơn khách gửi).
class XeDonTroScreen extends StatefulWidget {
  const XeDonTroScreen({required this.dv, this.initialTab = 0, super.key});

  final XeDichVu dv;

  /// 0 = Tìm xe, 1 = Đơn của tôi, 2 = Tôi là tài xế.
  final int initialTab;

  @override
  State<XeDonTroScreen> createState() => _XeDonTroScreenState();
}

class _XeDonTroScreenState extends State<XeDonTroScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab,
  );
  late final _quyen = widget.dv.xacThuc.quyenAdmin(widget.dv.uid);
  final _donCuaToiKey = GlobalKey<_DonCuaToiTabState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _datXe(TaiXe taiXe) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DatXeScreen(dv: widget.dv, taiXe: taiXe),
      ),
    );
    if (id == null || !mounted) return;
    _tabs.animateTo(1);
    _donCuaToiKey.currentState?.reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu, chờ tài xế báo giá.')),
    );
    await moChiTietDon(context, widget.dv, id);
    _donCuaToiKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xe dọn trọ'),
        actions: [
          StreamBuilder<QuyenAdmin>(
            stream: _quyen,
            builder: (context, snap) => snap.data?.xe == true
                ? TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DuyetTaiXeScreen(dv: widget.dv),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Duyệt tài xế'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Tìm xe'),
            Tab(text: 'Đơn của tôi'),
            Tab(text: 'Tôi là tài xế'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TimXeTab(dv: widget.dv, onDatXe: _datXe),
          _DonCuaToiTab(key: _donCuaToiKey, dv: widget.dv),
          _TaiXeTab(dv: widget.dv),
        ],
      ),
    );
  }
}

Future<void> moChiTietDon(BuildContext context, XeDichVu dv, String id) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingXeDetailScreen(dv: dv, bookingId: id),
      ),
    );

class _TimXeTab extends StatefulWidget {
  const _TimXeTab({required this.dv, required this.onDatXe});

  final XeDichVu dv;
  final void Function(TaiXe) onDatXe;

  @override
  State<_TimXeTab> createState() => _TimXeTabState();
}

class _TimXeTabState extends State<_TimXeTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<TaiXe>> _taiXe = _tai();
  String? _loai;

  Future<List<TaiXe>> _tai() async {
    final ds = await widget.dv.xe.danhSachTaiXe();
    return [
      for (final t in ds)
        if (t.driverId != widget.dv.uid &&
            (_loai == null || t.vehicleType == _loai))
          t,
    ];
  }

  Future<void> _reload() async {
    final f = _tai();
    setState(() {
      _taiXe = f;
    });
    await f.catchError((_) => <TaiXe>[]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final (key, label) in [
                (null, 'Tất cả'),
                ...TaiXe.loaiXeLabels.entries.map((e) => (e.key, e.value)),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _loai == key,
                    onSelected: (_) {
                      _loai = key;
                      _reload();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncListView<TaiXe>(
            future: _taiXe,
            onRefresh: _reload,
            emptyIcon: Icons.local_shipping_outlined,
            emptyText: 'Chưa có tài xế nào sẵn sàng. Kéo xuống để tải lại.',
            itemBuilder: (context, t) =>
                TaiXeCard(taiXe: t, onDatXe: () => widget.onDatXe(t)),
          ),
        ),
      ],
    );
  }
}

class _DonCuaToiTab extends StatefulWidget {
  const _DonCuaToiTab({required this.dv, super.key});

  final XeDichVu dv;

  @override
  State<_DonCuaToiTab> createState() => _DonCuaToiTabState();
}

class _DonCuaToiTabState extends State<_DonCuaToiTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<BookingXe>> _don = widget.dv.xe.donCuaToi();

  Future<void> reload() async {
    final f = widget.dv.xe.donCuaToi();
    setState(() {
      _don = f;
    });
    await f.catchError((_) => <BookingXe>[]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncListView<BookingXe>(
      future: _don,
      onRefresh: reload,
      emptyIcon: Icons.inventory_2_outlined,
      emptyText: 'Bạn chưa đặt xe nào. Chọn tài xế ở tab "Tìm xe".',
      itemBuilder: (context, b) => BookingCard(
        booking: b,
        onTap: () async {
          await moChiTietDon(context, widget.dv, b.id);
          reload();
        },
      ),
    );
  }
}

class _TaiXeTab extends StatefulWidget {
  const _TaiXeTab({required this.dv});

  final XeDichVu dv;

  @override
  State<_TaiXeTab> createState() => _TaiXeTabState();
}

class _TaiXeTabState extends State<_TaiXeTab>
    with AutomaticKeepAliveClientMixin {
  late Future<TaiXe?> _hoSo = widget.dv.xe.hoSoTaiXe(widget.dv.uid);
  late Future<List<BookingXe>> _don = widget.dv.xe.donDuocGiao();
  bool _doiTrangThai = false;

  Future<void> _reload() async {
    final h = widget.dv.xe.hoSoTaiXe(widget.dv.uid);
    final d = widget.dv.xe.donDuocGiao();
    setState(() {
      _hoSo = h;
      _don = d;
    });
    await Future.wait([h, d]).catchError((_) => <Object?>[]);
  }

  Future<void> _moForm(TaiXe? hoSo) async {
    final approval = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DangKyTaiXeScreen(dv: widget.dv, hoSo: hoSo),
      ),
    );
    if (approval == null || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approval == 'approved' ? 'Đã lưu hồ sơ.' : 'Đã gửi hồ sơ. Admin duyệt xong bạn sẽ hiện trong danh sách tìm xe.',
        ),
      ),
    );
  }

  Future<void> _doi(TaiXe t, bool sanSang) async {
    setState(() => _doiTrangThai = true);
    try {
      await widget.dv.xe.doiTrangThaiTaiXe(sanSang ? 'available' : 'busy');
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _doiTrangThai = false);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<TaiXe?>(
      future: _hoSo,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: FilledButton.tonal(
              onPressed: _reload,
              child: Text('${snap.error} · Thử lại'),
            ),
          );
        }
        final hoSo = snap.data;
        if (hoSo == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bạn có xe tải nhỏ, ba gác hay xe máy chở hàng? '
                    'Đăng ký để nhận đơn chuyển trọ của sinh viên.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _moForm(null),
                    child: const Text('Đăng ký làm tài xế'),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TaiXeCard(
                taiXe: hoSo,
                trailing: IconButton(
                  tooltip: 'Sửa hồ sơ',
                  onPressed: () => _moForm(hoSo),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
            if (!hoSo.daDuyet)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TrangThaiDuyet(taiXe: hoSo, onSua: () => _moForm(hoSo)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang nhận đơn mới'),
                  subtitle: Text(
                    hoSo.sanSang
                        ? 'Sinh viên đang thấy bạn trong danh sách.'
                        : 'Bạn đang ẩn khỏi danh sách tìm xe.',
                  ),
                  value: hoSo.sanSang,
                  onChanged: _doiTrangThai ? null : (v) => _doi(hoSo, v),
                ),
              ),
            Expanded(
              child: AsyncListView<BookingXe>(
                future: _don,
                onRefresh: _reload,
                emptyIcon: Icons.inbox_outlined,
                emptyText: 'Chưa có khách gửi yêu cầu.',
                itemBuilder: (context, b) => BookingCard(
                  booking: b,
                  laTaiXe: true,
                  onTap: () async {
                    await moChiTietDon(context, widget.dv, b.id);
                    _reload();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrangThaiDuyet extends StatelessWidget {
  const _TrangThaiDuyet({required this.taiXe, required this.onSua});

  final TaiXe taiXe;
  final VoidCallback onSua;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tuChoi = taiXe.approval == 'rejected';
    return Card(
      color: tuChoi ? colors.errorContainer : colors.secondaryContainer,
      child: ListTile(
        leading: Icon(tuChoi ? Icons.block : Icons.hourglass_top),
        title: Text(TaiXe.approvalLabels[taiXe.approval] ?? taiXe.approval),
        subtitle: Text(
          tuChoi
              ? 'Lý do: ${taiXe.rejectReason ?? ''}. Sửa hồ sơ rồi gửi lại.'
              : 'Admin Xe dọn trọ đang xem hồ sơ xe của bạn. '
                    'Được duyệt thì bạn mới hiện trong danh sách tìm xe.',
        ),
        trailing: tuChoi
            ? TextButton(onPressed: onSua, child: const Text('Sửa'))
            : null,
      ),
    );
  }
}
