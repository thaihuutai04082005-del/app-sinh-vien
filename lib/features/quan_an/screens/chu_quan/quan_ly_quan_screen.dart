import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/services/xac_thuc_service.dart';
import '../../models/gio_mo_cua.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'cai_dat_dat_mon_screen.dart';
import 'dang_quan_screen.dart';
import 'doanh_thu_screen.dart';
import 'quan_ly_dat_ban_screen.dart';
import 'quan_ly_don_screen.dart';
import 'quan_ly_gio_mo_cua_screen.dart';
import 'quan_ly_khuyen_mai_screen.dart';
import 'quan_ly_menu_screen.dart';
import 'sua_thong_tin_quan_screen.dart';

/// Trang quản lý MỘT quán (mục 3.3 Bước 6): trạng thái, cảnh báo cần xử lý và lối tới
/// đơn hàng, đặt bàn, menu, khuyến mãi, giờ mở cửa, doanh thu, sửa thông tin...
class QuanLyQuanScreen extends StatefulWidget {
  const QuanLyQuanScreen({required this.dv, required this.quanId, super.key});

  final QuanAnDichVu dv;
  final String quanId;

  @override
  State<QuanLyQuanScreen> createState() => _QuanLyQuanScreenState();
}

class _QuanLyQuanScreenState extends State<QuanLyQuanScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý quán')),
    body: QuanAnStream<QuanAn?>(
      stream: () => widget.dv.quan.quan(widget.quanId),
      thongBaoLoi: 'Không tải được thông tin quán',
      builder: (context, q) => q == null
          ? const QuanAnEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Không tìm thấy quán',
              message: 'Quán có thể đã bị xóa.',
            )
          : _NoiDung(dv: widget.dv, quan: q, cfg: _cfg),
    ),
  );
}

class _NoiDung extends StatefulWidget {
  const _NoiDung({required this.dv, required this.quan, required this.cfg});

  final QuanAnDichVu dv;
  final QuanAn quan;
  final QuanAnConfig cfg;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  bool _dangChay = false;

  QuanAn get _q => widget.quan;
  QuanAnDichVu get _dv => widget.dv;

  Future<void> _mo(WidgetBuilder b) => QuanAnDieuHuong.mo(context, b);

  Future<void> _hienLoi(String tieuDe, Object e) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tieuDe),
      content: Text(
        e is ApiException ? e.message : 'Có lỗi xảy ra, vui lòng thử lại.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );

  Future<void> _vanHoatDong() async {
    await chayThaoTac(
      context,
      () => _dv.quan.thaoTac('xacNhanConHoatDong', {'quanId': _q.id}),
      thanhCong: 'Cảm ơn bạn, quán tiếp tục hiển thị',
    );
  }

  Future<void> _anHien(bool an) async {
    final ok = await xacNhan(
      context,
      tieuDe: an ? 'Ẩn quán?' : 'Hiện lại quán?',
      noiDung: an
          ? 'Quán biến khỏi danh sách và bản đồ, khách không đặt mới được. '
                'Đơn đang chờ quán xác nhận sẽ bị hủy và hoàn tiền; bàn đã xác nhận bị hủy (không tính lỗi khách). '
                'Đơn quán đã nhận vẫn phải làm xong.'
          : 'Quán hiện lại trên danh sách và nhận đơn / đặt bàn bình thường.',
      dongY: an ? 'Ẩn quán' : 'Hiện quán',
      nguyHiem: an,
    );
    if (!ok || !mounted) return;
    await chayThaoTac(
      context,
      () => _dv.quan.thaoTac('anHienQuan', {'quanId': _q.id, 'an': an}),
      thanhCong: an ? 'Đã ẩn quán' : 'Đã hiện lại quán',
    );
  }

  Future<void> _ngung() async {
    final ok = await xacNhan(
      context,
      tieuDe: 'Ngừng kinh doanh?',
      noiDung:
          'Quán "${_q.ten}" sẽ chuyển sang "Ngừng kinh doanh" và biến khỏi danh sách. '
          'Không thể ngừng khi còn đơn chưa hoàn tất, bàn đã xác nhận, tiền đang giữ hoặc khiếu nại. '
          'Hành động này không hoàn tác được.',
      dongY: 'Ngừng kinh doanh',
      nguyHiem: true,
    );
    if (!ok || !mounted) return;
    setState(() => _dangChay = true);
    try {
      await _dv.quan.thaoTac('ngungKinhDoanh', {'quanId': _q.id});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quán đã ngừng kinh doanh')));
    } catch (e) {
      // Hệ thống chặn khi còn giao dịch và giải thích bằng chữ: hiện nguyên văn.
      if (mounted) await _hienLoi('Chưa ngừng kinh doanh được', e);
    } finally {
      if (mounted) setState(() => _dangChay = false);
    }
  }

  QuanAnBadgeKind _kindTrangThai(String t) => switch (t) {
    'active' => QuanAnBadgeKind.moCua,
    'pending_review' || 'rejected' || 'suspended' => QuanAnBadgeKind.canhBao,
    'hidden' => QuanAnBadgeKind.tamNghi,
    'closed' => QuanAnBadgeKind.dongCua,
    _ => QuanAnBadgeKind.chung,
  };

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final cfg = widget.cfg;
    final now = DateTime.now();
    final daDuyet = const {
      'active',
      'hidden',
      'suspended',
    }.contains(q.trangThai);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QuanAnSpacing.screen),
      child: TrangRong(
        rongToiDa: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TieuDeQuan(
              quan: q,
              now: now,
              kind: _kindTrangThai(q.trangThai),
              cfg: cfg,
            ),
            ..._canhBao(q, cfg).map(
              (w) => Padding(
                padding: const EdgeInsets.only(top: QuanAnSpacing.cardGap),
                child: w,
              ),
            ),
            const SizedBox(height: QuanAnSpacing.cardGap),
            if (q.suaNhapDuoc)
              KhoiThongTin(
                tieuDe: q.trangThai == 'rejected'
                    ? 'Sửa và gửi duyệt lại'
                    : 'Hoàn thiện bản nháp',
                phu: 'Quán chưa được duyệt nên chưa dùng được các mục quản lý. Sửa thông tin rồi gửi duyệt.',
                child: FilledButton.icon(
                  onPressed: () => _mo((_) => DangQuanScreen(dv: _dv, quan: q)),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Mở form sửa quán'),
                ),
              )
            else if (q.trangThai == 'pending_review')
              const HopThongBao(
                noiDung: 'Quán đang chờ admin duyệt. Duyệt xong bạn sẽ nhận được thông báo và dùng được các mục quản lý.',
              )
            else ...[
              LuoiLoiTat(muc: _loiTat(q, daDuyet)),
              const SizedBox(height: QuanAnSpacing.lg),
              _KhoiNguyHiem(
                quan: q,
                dangChay: _dangChay,
                onAnHien: _anHien,
                onNgung: _ngung,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<MucLoiTat> _loiTat(QuanAn q, bool daDuyet) {
    final hkd = q.laHoKinhDoanh;
    final dongCua = q.trangThai == 'closed';
    return [
      if (hkd && !dongCua)
        MucLoiTat(
          icon: Icons.receipt_long_rounded,
          nhan: 'Đơn hàng',
          moTa: q.nhanDatMon
              ? 'Nhận, chuẩn bị, giao và đóng đơn'
              : 'Chưa bật đặt món, xem đơn cũ',
          onTap: () => _mo((_) => QuanLyDonScreen(dv: _dv, quanId: q.id)),
        ),
      if (hkd && !dongCua)
        MucLoiTat(
          icon: Icons.event_seat_rounded,
          nhan: 'Đặt bàn',
          moTa: q.nhanDatBan
              ? 'Xác nhận, từ chối, khách đã đến'
              : 'Chưa bật nhận đặt bàn',
          onTap: () => _mo((_) => QuanLyDatBanScreen(dv: _dv)),
        ),
      if (!dongCua)
        MucLoiTat(
          icon: Icons.restaurant_menu_rounded,
          nhan: 'Menu',
          moTa: 'Sửa món, bật tắt còn / hết',
          onTap: () => _mo((_) => QuanLyMenuScreen(dv: _dv, quanId: q.id)),
        ),
      if (!dongCua)
        MucLoiTat(
          icon: Icons.local_offer_outlined,
          nhan: 'Khuyến mãi',
          moTa: hkd
              ? 'Tạo, sửa, dừng (tối đa ${widget.cfg.khuyenMaiToiDaHoKinhDoanh})'
              : 'Tối đa ${widget.cfg.khuyenMaiToiDaBanLe}, chỉ hiển thị, không tự trừ',
          onTap: () => _mo((_) => QuanLyKhuyenMaiScreen(dv: _dv, quanId: q.id)),
        ),
      if (!dongCua)
        MucLoiTat(
          icon: Icons.schedule_rounded,
          nhan: 'Giờ mở cửa / Tạm nghỉ',
          moTa: 'Lịch tuần, nghỉ hôm nay, tạm ngưng nhận đơn',
          onTap: () => _mo((_) => QuanLyGioMoCuaScreen(dv: _dv, quanId: q.id)),
        ),
      if (hkd)
        MucLoiTat(
          icon: Icons.bar_chart_rounded,
          nhan: 'Doanh thu',
          moTa: 'Số đơn, tiền theo ngày / tuần',
          onTap: () => _mo((_) => DoanhThuScreen(dv: _dv, quanId: q.id)),
        ),
      if (!dongCua)
        MucLoiTat(
          icon: Icons.edit_note_rounded,
          nhan: 'Sửa thông tin',
          moTa: hkd
              ? 'Mô tả, tiện ích, ảnh, tên, địa chỉ'
              : 'Mô tả, tiện ích, ảnh; nâng cấp lên hộ kinh doanh',
          onTap: () => _mo((_) => SuaThongTinQuanScreen(dv: _dv, quan: q)),
        ),
      if (hkd && !dongCua)
        MucLoiTat(
          icon: Icons.delivery_dining_rounded,
          nhan: 'Cài đặt đặt món',
          moTa: q.datMon.bat
              ? 'Đang bật · ${q.datMon.phiGiaoMoTa}'
              : 'Đang tắt, bật để nhận đặt món qua app',
          onTap: () => _mo((_) => CaiDatDatMonScreen(dv: _dv, quan: q)),
        ),
    ];
  }

  List<Widget> _canhBao(QuanAn q, QuanAnConfig cfg) {
    final w = <Widget>[];
    if (q.trangThai == 'rejected' &&
        q.lyDoTuChoi != null &&
        q.lyDoTuChoi!.isNotEmpty) {
      w.add(QuanAnWarningBox(message: 'Quán bị từ chối: ${q.lyDoTuChoi}'));
    }
    if (q.trangThai == 'suspended') {
      w.add(
        const HopThongBao.loi(
          noiDung: 'Quán đang bị đình chỉ nên không nhận giao dịch mới. Đơn đang chạy vẫn phải xử lý bình thường. Nếu thấy chưa đúng, bạn có thể kháng nghị.',
        ),
      );
    }
    if (q.trangThai == 'hidden' && q.anBoi == 'admin') {
      w.add(
        const HopThongBao.canhBao(
          noiDung: 'Quán đang bị admin ẩn. Bạn chưa tự hiện lại được, hãy xem thông báo hoặc kháng nghị.',
        ),
      );
    }
    if (q.khoaBan) {
      w.add(
        const HopThongBao.loi(
          noiDung: 'Bạn đang bị khóa bán trong module Quán ăn: không nhận đơn mới, không bán mới.',
        ),
      );
    }
    if (q.hanXacNhanHoatDong != null && q.trangThai == 'active') {
      w.add(
        HopThongBao.canhBao(
          noiDung:
              'Quán chưa có cập nhật, check-in hay đơn nào trong ${cfg.nhacConHoatDongNgay} ngày. '
              'Hãy xác nhận trước ${formatNgayGio(q.hanXacNhanHoatDong!)}, nếu không quán sẽ bị ẩn.',
          child: FilledButton(
            onPressed: _dangChay ? null : _vanHoatDong,
            child: const Text('Quán vẫn hoạt động'),
          ),
        ),
      );
    }
    final ks = q.khaiSaiLoai;
    if (ks != null) {
      w.add(
        HopThongBao.canhBao(
          noiDung: [
            'Admin nghi quán khai sai loại quán.',
            if (ks.lyDo.isNotEmpty) 'Lý do: ${ks.lyDo.join('; ')}.',
            if (ks.hanChuyen != null)
              'Hãy chuyển đúng loại trước ${formatNgayGio(ks.hanChuyen!)}, quá hạn quán sẽ bị ẩn.',
          ].join(' '),
          child: q.laHoKinhDoanh
              ? null
              : OutlinedButton(
                  onPressed: () =>
                      _mo((_) => SuaThongTinQuanScreen(dv: _dv, quan: q)),
                  child: const Text('Nâng cấp lên hộ kinh doanh'),
                ),
        ),
      );
    }
    if (q.coBanChinhSua) {
      final nangCap = q.banChinhSua!['loai'] == 'nang_cap';
      final truong = [
        for (final k in q.banChinhSua!.keys)
          if (_tenTruong.containsKey(k)) _tenTruong[k]!,
      ];
      w.add(
        HopThongBao(
          noiDung: nangCap
              ? 'Yêu cầu nâng cấp lên hộ kinh doanh đang chờ admin duyệt. Quán vẫn hoạt động như cũ.'
              : 'Bản chỉnh sửa đang chờ duyệt'
                    '${truong.isEmpty ? '' : ' (${truong.join(', ')})'}. '
                    'Trong lúc chờ, bản cũ vẫn hiện cho khách.',
        ),
      );
    }
    if (q.lyDoTuChoi != null &&
        q.lyDoTuChoi!.isNotEmpty &&
        q.trangThai != 'rejected' &&
        !q.coBanChinhSua) {
      w.add(
        QuanAnWarningBox(
          message:
              'Bản chỉnh sửa gần nhất bị từ chối: ${q.lyDoTuChoi}. Quán vẫn giữ thông tin cũ.',
        ),
      );
    }
    return w;
  }
}

const _tenTruong = {
  'ten': 'tên quán',
  'diaChi': 'địa chỉ',
  'phuong': 'phường / xã',
  'viTri': 'vị trí ghim',
  'anhMatTien': 'ảnh mặt tiền',
  'luuDong': 'bán lưu động',
  'ghiChuViTri': 'ghi chú chỗ bán',
};

class _TieuDeQuan extends StatelessWidget {
  const _TieuDeQuan({
    required this.quan,
    required this.now,
    required this.kind,
    required this.cfg,
  });

  final QuanAn quan;
  final DateTime now;
  final QuanAnBadgeKind kind;
  final QuanAnConfig cfg;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final mo = q.trangThai == 'active' ? q.moCua(now, cfg: cfg) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(QuanAnSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.ten.isEmpty ? '(Chưa đặt tên)' : q.ten,
              style: QuanAnText.h2,
            ),
            const SizedBox(height: QuanAnSpacing.sm),
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.xs,
              children: [
                QuanAnStatusBadge(kind: kind, label: q.trangThaiLabel),
                QuanAnStatusBadge(
                  kind: QuanAnBadgeKind.xacThuc,
                  label: q.loaiQuanLabel,
                ),
                if (mo != null)
                  QuanAnStatusBadge(
                    kind: switch (mo.trangThai) {
                      TrangThaiMoCua.mo => QuanAnBadgeKind.moCua,
                      TrangThaiMoCua.sapDong => QuanAnBadgeKind.sapDong,
                      TrangThaiMoCua.dong => QuanAnBadgeKind.dongCua,
                      TrangThaiMoCua.tamNghi => QuanAnBadgeKind.tamNghi,
                    },
                    label: mo.trangThai.label,
                  ),
              ],
            ),
            if (mo != null) ...[
              const SizedBox(height: QuanAnSpacing.sm),
              Text(mo.thongDiep, style: QuanAnText.bodySmall),
            ],
            if (q.diaChi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: QuanAnSpacing.xs),
                child: Text(q.diaChi, style: QuanAnText.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _KhoiNguyHiem extends StatelessWidget {
  const _KhoiNguyHiem({
    required this.quan,
    required this.dangChay,
    required this.onAnHien,
    required this.onNgung,
  });

  final QuanAn quan;
  final bool dangChay;
  final Future<void> Function(bool an) onAnHien;
  final Future<void> Function() onNgung;

  @override
  Widget build(BuildContext context) {
    final q = quan;
    final coTheAn = q.trangThai == 'active';
    final coTheHien = q.trangThai == 'hidden' && q.anBoi != 'admin';
    final dongCua = q.trangThai == 'closed';
    if (dongCua) {
      return const HopThongBao(
        noiDung: 'Quán đã ngừng kinh doanh. Bạn vẫn xem được doanh thu và xử lý khiếu nại còn lại.',
      );
    }
    return KhoiThongTin(
      tieuDe: 'Ẩn hoặc ngừng quán',
      phu: 'Ẩn quán chỉ chặn đơn và đặt bàn mới, đơn đang chạy đi tiếp. Ngừng kinh doanh thì không mở lại được.',
      child: Wrap(
        spacing: QuanAnSpacing.sm,
        runSpacing: QuanAnSpacing.sm,
        children: [
          if (coTheAn)
            OutlinedButton.icon(
              onPressed: dangChay ? null : () => onAnHien(true),
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Ẩn quán'),
            ),
          if (coTheHien)
            OutlinedButton.icon(
              onPressed: dangChay ? null : () => onAnHien(false),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Hiện lại quán'),
            ),
          OutlinedButton.icon(
            style: kieuNutNguyHiem(),
            onPressed: dangChay ? null : onNgung,
            icon: const Icon(Icons.store_mall_directory_outlined),
            label: Text(dangChay ? 'Đang xử lý...' : 'Ngừng kinh doanh'),
          ),
        ],
      ),
    );
  }
}
