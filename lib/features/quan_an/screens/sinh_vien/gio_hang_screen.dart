import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/gio_hang.dart';
import '../../models/quan_an.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'dat_mon_screen.dart';

/// QA-SV-06 Giỏ hàng: giỏ chỉ có món của 1 quán; đổi số lượng, xóa món, sửa ghi chú.
/// Tạm tính chỉ để xem — hệ thống tính lại toàn bộ giá khi đặt món (mục 3.4 Bước 5).
class GioHangScreen extends StatefulWidget {
  const GioHangScreen({required this.dv, super.key});

  final QuanAnDichVu dv;

  @override
  State<GioHangScreen> createState() => _GioHangScreenState();
}

class _GioHangScreenState extends State<GioHangScreen> {
  bool _dangMo = false;

  Future<void> _datMon(String quanId) async {
    if (_dangMo) return;
    setState(() => _dangMo = true);
    QuanAn? quan;
    final ok = await chayThaoTac(context, () async {
      quan = await widget.dv.quan.quan(quanId).first;
    });
    if (!mounted) return;
    setState(() => _dangMo = false);
    if (!ok) return;
    final q = quan;
    if (q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy quán này nữa.')),
      );
      return;
    }
    await QuanAnDieuHuong.mo(
      context,
      (_) => DatMonScreen(dv: widget.dv, quan: q),
    );
  }

  Future<void> _xoaGio() async {
    final dongY = await xacNhan(
      context,
      tieuDe: 'Xóa cả giỏ?',
      noiDung: 'Tất cả món trong giỏ sẽ bị xóa.',
      dongY: 'Xóa giỏ',
      nguyHiem: true,
    );
    if (dongY) widget.dv.gioHang.xoaHet();
  }

  Future<void> _suaGhiChu(DongGioHang d) async {
    final ctl = TextEditingController(text: d.ghiChu);
    final moi = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Ghi chú cho ${d.ten}'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            hintText: 'Ví dụ: ít cay, không hành',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    ctl.dispose();
    if (moi == null || moi == d.ghiChu.trim()) return;
    final g = widget.dv.gioHang;
    final quanId = g.gio.quanId;
    final tenQuan = g.gio.tenQuan;
    final goc = d;
    g.xoaDong(goc.khoa);
    g.them(
      quanId: quanId,
      tenQuan: tenQuan,
      dong: DongGioHang(
        monId: goc.monId,
        ten: goc.ten,
        gia: goc.gia,
        soLuong: goc.soLuong,
        tuyChon: goc.tuyChon,
        ghiChu: moi,
        anh: goc.anh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Giỏ hàng'),
      actions: [
        ListenableBuilder(
          listenable: widget.dv.gioHang,
          builder: (context, _) => widget.dv.gioHang.gio.laRong
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Xóa cả giỏ',
                  onPressed: _xoaGio,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.dv.gioHang,
      builder: (context, _) {
        final gio = widget.dv.gioHang.gio;
        if (gio.laRong) {
          return QuanAnEmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Giỏ hàng đang trống',
            message: 'Chọn món ở trang quán để thêm vào giỏ.',
            actionLabel: 'Về quán',
            onAction: () => Navigator.of(context).maybePop(),
          );
        }
        return Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.all(QuanAnSpacing.screen),
                    children: [
                      _TenQuan(dv: widget.dv, gio: gio),
                      const SizedBox(height: QuanAnSpacing.md),
                      for (final d in gio.dong) ...[
                        _DongGio(
                          dong: d,
                          onBot: () => widget.dv.gioHang.boBot(d.khoa),
                          onThem: () => widget.dv.gioHang.themMotPhan(d.khoa),
                          onXoa: () => widget.dv.gioHang.xoaDong(d.khoa),
                          onGhiChu: () => _suaGhiChu(d),
                        ),
                        const SizedBox(height: QuanAnSpacing.cardGap),
                      ],
                      const Text(
                        'Giá trong giỏ chỉ để xem. Khi bạn bấm đặt món, hệ thống tính lại toàn bộ giá theo menu hiện tại (kèm khuyến mãi và phí giao).',
                        style: QuanAnText.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ThanhDuoi(
              tamTinh: gio.tamTinh,
              soMon: gio.soMon,
              dangMo: _dangMo,
              onDat: () => _datMon(gio.quanId),
            ),
          ],
        );
      },
    ),
  );
}

class _TenQuan extends StatelessWidget {
  const _TenQuan({required this.dv, required this.gio});

  final QuanAnDichVu dv;
  final GioHang gio;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.storefront_outlined, color: QuanAnColors.primary),
      const SizedBox(width: QuanAnSpacing.sm),
      Expanded(
        child: Text(
          gio.tenQuan.isEmpty ? 'Quán đã chọn' : gio.tenQuan,
          style: QuanAnText.h2,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      TextButton(
        onPressed: () => QuanAnDieuHuong.quan(context, dv, gio.quanId),
        child: const Text('Thêm món'),
      ),
    ],
  );
}

class _DongGio extends StatelessWidget {
  const _DongGio({
    required this.dong,
    required this.onBot,
    required this.onThem,
    required this.onXoa,
    required this.onGhiChu,
  });

  final DongGioHang dong;
  final VoidCallback onBot;
  final VoidCallback onThem;
  final VoidCallback onXoa;
  final VoidCallback onGhiChu;

  @override
  Widget build(BuildContext context) {
    final tuyChon = dong.tuyChon
        .map((t) => '${t.nhom}: ${t.ten}')
        .join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(QuanAnSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dong.anh.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(QuanAnRadius.button),
                    child: Image.network(
                      dong.anh,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.restaurant,
                          color: QuanAnColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dong.ten, style: QuanAnText.h3),
                      if (tuyChon.isNotEmpty)
                        Text(tuyChon, style: QuanAnText.bodySmall),
                      if (dong.ghiChu.trim().isNotEmpty)
                        Text(
                          'Ghi chú: ${dong.ghiChu.trim()}',
                          style: QuanAnText.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: QuanAnSpacing.sm),
                Text(formatPrice(dong.thanhTien), style: QuanAnText.price),
              ],
            ),
            const SizedBox(height: QuanAnSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: QuanAnSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Bớt một phần',
                      onPressed: onBot,
                      icon: const Icon(Icons.remove_circle_outline),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${dong.soLuong}',
                        style: QuanAnText.h3,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Thêm một phần',
                      onPressed: onThem,
                      icon: const Icon(Icons.add_circle_outline),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: onGhiChu,
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Ghi chú'),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                    IconButton(
                      tooltip: 'Xóa món',
                      onPressed: onXoa,
                      color: QuanAnColors.danger,
                      icon: const Icon(Icons.delete_outline),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThanhDuoi extends StatelessWidget {
  const _ThanhDuoi({
    required this.tamTinh,
    required this.soMon,
    required this.dangMo,
    required this.onDat,
  });

  final num tamTinh;
  final int soMon;
  final bool dangMo;
  final VoidCallback onDat;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: QuanAnColors.white,
      boxShadow: [
        BoxShadow(
          color: QuanAnColors.primary.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Tạm tính · $soMon món', style: QuanAnText.bodySmall),
                      Text(formatPrice(tamTinh), style: QuanAnText.price),
                    ],
                  ),
                ),
                const SizedBox(width: QuanAnSpacing.md),
                FilledButton(
                  onPressed: dangMo ? null : onDat,
                  child: dangMo
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: QuanAnColors.white,
                          ),
                        )
                      : const Text('Đặt món'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
