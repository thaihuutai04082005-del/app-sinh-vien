import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/gio_hang.dart';
import '../../models/mon_an.dart';
import '../../models/quan_an.dart';
import '../../services/gio_hang_service.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_theme.dart';
import '../../widgets/tuy_chon_mon_group.dart';

/// Số phần tối đa của một dòng trong giỏ (giới hạn giao diện, hệ thống kiểm tra lại khi đặt).
const _soLuongToiDa = 99;
const _ghiChuToiDa = 200;

/// QA-SV-05 Chi tiết món: chọn số lượng, tùy chọn (phải chọn đủ phần bắt buộc), ghi chú,
/// "Thêm vào giỏ · 85.000đ". Thêm món của quán khác khi giỏ đang có món quán này thì hỏi
/// "Xóa giỏ hiện tại?". Món hết không thêm được.
Future<void> moChiTietMon(
  BuildContext context,
  QuanAnDichVu dv,
  QuanAn quan,
  MonAn mon,
) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Theme(
      data: Theme.of(context),
      child: _MonAnSheet(dv: dv, quan: quan, mon: mon, messenger: messenger),
    ),
  );
}

class _MonAnSheet extends StatefulWidget {
  const _MonAnSheet({
    required this.dv,
    required this.quan,
    required this.mon,
    required this.messenger,
  });

  final QuanAnDichVu dv;
  final QuanAn quan;
  final MonAn mon;
  final ScaffoldMessengerState messenger;

  @override
  State<_MonAnSheet> createState() => _MonAnSheetState();
}

class _MonAnSheetState extends State<_MonAnSheet> {
  final _chon = <String, List<String>>{};
  final _ghiChu = TextEditingController();
  int _soLuong = 1;
  String? _loi;
  bool _dangThem = false;

  MonAn get _mon => widget.mon;

  @override
  void dispose() {
    _ghiChu.dispose();
    super.dispose();
  }

  List<TuyChonDaChon> get _tuyChonDaChon => [
    for (final nhom in _mon.tuyChon)
      for (final ten in _chon[nhom.ten] ?? const <String>[])
        TuyChonDaChon(
          nhom: nhom.ten,
          ten: ten,
          giaThem: nhom.lua
              .firstWhere(
                (l) => l.ten == ten,
                orElse: () => const LuaChon(ten: ''),
              )
              .giaThem,
        ),
  ];

  num get _donGia =>
      _mon.gia + _tuyChonDaChon.fold<num>(0, (s, t) => s + t.giaThem);

  /// Lý do chưa thêm được vào giỏ (null = thêm được).
  String? _lyDoKhongThem(DateTime now) {
    if (!_mon.conHang) return 'Món này đã hết.';
    if (widget.dv.uid.isEmpty) return 'Vui lòng đăng nhập để đặt món.';
    if (widget.dv.uid == widget.quan.chuQuanId) {
      return 'Bạn không đặt món ở quán của chính mình.';
    }
    if (!widget.quan.nhanDatMon) return 'Quán này không nhận đặt món qua app.';
    if (!widget.quan.datMonDuocLuc(now)) {
      return 'Quán đang đóng cửa hoặc tạm ngưng nhận đơn, chưa đặt món được.';
    }
    return null;
  }

  Future<void> _them() async {
    final loi = _mon.kiemTraTuyChon(_chon);
    if (loi != null) {
      setState(() => _loi = loi);
      return;
    }
    setState(() {
      _loi = null;
      _dangThem = true;
    });
    final dong = DongGioHang(
      monId: _mon.id,
      ten: _mon.ten,
      gia: _mon.gia,
      soLuong: _soLuong,
      tuyChon: _tuyChonDaChon,
      ghiChu: _ghiChu.text.trim(),
      anh: _mon.anh,
    );
    final gio = widget.dv.gioHang;
    final tenCu = gio.gio.tenQuan;
    var daThem = gio.them(
      quanId: widget.quan.id,
      tenQuan: widget.quan.ten,
      dong: dong,
    );
    if (daThem == KetQuaThemGio.needConfirm) {
      if (!mounted) return;
      final dongY = await xacNhan(
        context,
        tieuDe: 'Xóa giỏ hiện tại?',
        noiDung:
            'Giỏ đang có món của quán "$tenCu". Mỗi giỏ chỉ chứa món của một quán, '
            'thêm món này sẽ xóa các món cũ.',
        dongY: 'Xóa giỏ và thêm',
        nguyHiem: true,
      );
      if (dongY) {
        gio.xacNhanDoiQuan();
        daThem = KetQuaThemGio.daThem;
      } else {
        gio.huyDoiQuan();
      }
    }
    if (!mounted) return;
    if (daThem == KetQuaThemGio.daThem) {
      Navigator.pop(context);
      widget.messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              const SizedBox(width: 8),
              Expanded(child: Text('Đã thêm $_soLuong ${_mon.ten} vào giỏ')),
            ],
          ),
        ),
      );
    } else {
      setState(() => _dangThem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyDo = _lyDoKhongThem(DateTime.now());
    final tong = _donGia * _soLuong;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, cuon) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuanAnSpacing.screen,
              QuanAnSpacing.md,
              QuanAnSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _mon.ten,
                    style: QuanAnText.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: cuon,
              padding: const EdgeInsets.symmetric(
                horizontal: QuanAnSpacing.screen,
              ),
              children: [
                if (_mon.anh.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(QuanAnRadius.card),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: NetworkPhoto(_mon.anh),
                    ),
                  ),
                  const SizedBox(height: QuanAnSpacing.md),
                ],
                Text(formatPrice(_mon.gia), style: QuanAnText.price),
                if (_mon.moTa.isNotEmpty) ...[
                  const SizedBox(height: QuanAnSpacing.sm),
                  Text(_mon.moTa, style: QuanAnText.body),
                ],
                if (!_mon.conHang) ...[
                  const SizedBox(height: QuanAnSpacing.md),
                  const Text(
                    'Món này đã hết.',
                    style: TextStyle(
                      color: QuanAnColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                for (final nhom in _mon.tuyChon) ...[
                  const SizedBox(height: QuanAnSpacing.lg),
                  TuyChonMonGroup(
                    nhom: nhom,
                    dangChon: _chon[nhom.ten] ?? const [],
                    onChanged: (v) => setState(() {
                      _chon[nhom.ten] = v;
                      _loi = null;
                    }),
                  ),
                ],
                const SizedBox(height: QuanAnSpacing.lg),
                const Text('Ghi chú cho quán', style: QuanAnText.h3),
                const SizedBox(height: QuanAnSpacing.sm),
                TextField(
                  controller: _ghiChu,
                  maxLength: _ghiChuToiDa,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: ít cay, không hành...',
                  ),
                ),
                const SizedBox(height: QuanAnSpacing.sm),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Số lượng', style: QuanAnText.h3),
                    ),
                    IconButton.outlined(
                      tooltip: 'Bớt một phần',
                      onPressed: _soLuong > 1
                          ? () => setState(() => _soLuong--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_soLuong',
                        textAlign: TextAlign.center,
                        style: QuanAnText.h2,
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Thêm một phần',
                      onPressed: _soLuong < _soLuongToiDa
                          ? () => setState(() => _soLuong++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_loi != null)
                  Padding(
                    padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                    child: Text(
                      _loi!,
                      style: const TextStyle(color: QuanAnColors.danger),
                    ),
                  ),
                const SizedBox(height: QuanAnSpacing.xl),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(QuanAnSpacing.screen),
              decoration: BoxDecoration(
                color: QuanAnColors.white,
                boxShadow: QuanAnTheme.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lyDo != null && _mon.conHang)
                    Padding(
                      padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
                      child: Text(lyDo, style: QuanAnText.bodySmall),
                    ),
                  FilledButton(
                    onPressed: lyDo != null || _dangThem ? null : _them,
                    child: _dangThem
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: QuanAnColors.white,
                            ),
                          )
                        : Text(
                            _mon.conHang
                                ? 'Thêm vào giỏ · ${formatPrice(tong)}'
                                : 'Món đã hết',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
