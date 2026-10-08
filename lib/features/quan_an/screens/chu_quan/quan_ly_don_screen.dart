import 'package:flutter/material.dart';

import '../../models/don_mon.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/don_chu_quan_actions.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'chi_tiet_don_chu_quan_screen.dart';

/// QA-CQ-03 Quản lý đơn hàng — mục đầu tiên của chủ quán, có chuông đơn mới và đếm ngược
/// 5 phút. Tab: Đơn mới · Đang làm · Sẵn sàng / Đang giao · Đã xong · Khiếu nại.
///
/// Nút theo trạng thái dùng các hàm điều kiện của [DonMon] (hệ thống vẫn kiểm tra lại);
/// mọi thao tác gửi `version`. Mã nhận món không hiện cho chủ quán (chỉ nhập mã khách đọc).
class QuanLyDonScreen extends StatefulWidget {
  const QuanLyDonScreen({
    required this.dv,
    this.quanId,
    this.layViTri,
    super.key,
  });

  final QuanAnDichVu dv;

  /// Chỉ xem đơn của một quán; null = mọi quán của chủ quán.
  final String? quanId;

  /// Thay cách lấy GPS (dùng khi thử); mặc định geolocator.
  final LayViTriGps? layViTri;

  @override
  State<QuanLyDonScreen> createState() => _QuanLyDonScreenState();
}

class _QuanLyDonScreenState extends State<QuanLyDonScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();
  final _daXuLyHan = <String>{};

  static const _tab = [
    'Đơn mới',
    'Đang làm',
    'Sẵn sàng / Đang giao',
    'Đã xong',
    'Khiếu nại',
  ];

  @override
  void initState() {
    super.initState();
    widget.dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
  }

  /// Chỉ số tab của đơn; -1 = không hiện (đơn chưa thanh toán / hết hạn thanh toán).
  static int tabCua(DonMon d) => switch (d.status) {
    'placed' => 0,
    'accepted' => 1,
    'ready' || 'delivering' || 'delivered' || 'not_received' => 2,
    'disputed' => 4,
    'pending_payment' || 'expired' => -1,
    _ => 3,
  };

  /// Đơn mới đã quá hạn xác nhận mà chưa được xử lý: nhờ hệ thống xử lý hạn (một lần mỗi đơn).
  void _xuLyHanNeuCan(List<DonMon> ds) {
    final now = DateTime.now();
    for (final d in ds) {
      final han = d.hanQuanNhan;
      if (d.status == 'placed' &&
          han != null &&
          now.isAfter(han) &&
          _daXuLyHan.add(d.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.dv.donMon.xuLyHan(d.id).catchError((_) {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Đơn hàng'),
      actions: [
        ChuongDonMoi(
          stream: () => widget.dv.donMon.donMoiCuaQuan(widget.dv.uid),
        ),
      ],
    ),
    body: QuanAnStream<List<DonMon>>(
      stream: () => widget.dv.donMon.cuaChuQuan(widget.dv.uid),
      thongBaoLoi: 'Không tải được danh sách đơn',
      builder: (context, tatCa) {
        final ds = [
          for (final d in tatCa)
            if (widget.quanId == null || d.quanId == widget.quanId) d,
        ];
        _xuLyHanNeuCan(ds);
        final theoTab = List.generate(5, (_) => <DonMon>[]);
        for (final d in ds) {
          final t = tabCua(d);
          if (t >= 0) theoTab[t].add(d);
        }
        // Đơn mới: đơn sắp hết hạn xác nhận lên đầu.
        theoTab[0].sort(
          (a, b) => (a.hanQuanNhan ?? DateTime(9999)).compareTo(
            b.hanQuanNhan ?? DateTime(9999),
          ),
        );
        return DefaultTabController(
          length: _tab.length,
          child: Column(
            children: [
              Material(
                color: QuanAnColors.white,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (var i = 0; i < _tab.length; i++)
                      Tab(
                        text: i == 3 || theoTab[i].isEmpty
                            ? _tab[i]
                            : '${_tab[i]} (${theoTab[i].length})',
                      ),
                  ],
                ),
              ),
              if (theoTab[0].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QuanAnSpacing.screen,
                    QuanAnSpacing.sm,
                    QuanAnSpacing.screen,
                    0,
                  ),
                  child: HopThongBao.canhBao(
                    noiDung:
                        'Có ${theoTab[0].length} đơn mới. Mỗi đơn cần được nhận '
                        'hoặc từ chối trong ${_cfg.quanXacNhanPhut} phút, '
                        'quá hạn đơn tự hủy và ảnh hưởng tỷ lệ nhận đơn.',
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (var i = 0; i < _tab.length; i++)
                      _DanhSachDon(
                        dv: widget.dv,
                        cfg: _cfg,
                        ds: theoTab[i],
                        layViTri: widget.layViTri,
                        tieuDeRong: _tieuDeRong[i],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  static const _tieuDeRong = [
    'Chưa có đơn mới',
    'Không có đơn nào đang làm',
    'Không có đơn nào sẵn sàng hoặc đang giao',
    'Chưa có đơn nào đã xong',
    'Không có khiếu nại',
  ];
}

class _DanhSachDon extends StatelessWidget {
  const _DanhSachDon({
    required this.dv,
    required this.cfg,
    required this.ds,
    required this.tieuDeRong,
    this.layViTri,
  });

  final QuanAnDichVu dv;
  final QuanAnConfig cfg;
  final List<DonMon> ds;
  final String tieuDeRong;
  final LayViTriGps? layViTri;

  @override
  Widget build(BuildContext context) => ds.isEmpty
      ? QuanAnEmptyState(
          icon: Icons.receipt_long_outlined,
          title: tieuDeRong,
          message: 'Đơn mới sẽ hiện ở đây kèm chuông báo.',
        )
      : LuoiCuon(
          children: [
            for (final d in ds)
              DonChuQuanThe(
                key: ValueKey(d.id),
                dv: dv,
                don: d,
                cfg: cfg,
                layViTri: layViTri,
                onMo: () => QuanAnDieuHuong.mo(
                  context,
                  (_) => ChiTietDonChuQuanScreen(dv: dv, donId: d.id),
                ),
              ),
          ],
        );
}
