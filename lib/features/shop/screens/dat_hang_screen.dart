import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/don_hang.dart';
import '../models/gio_hang.dart';
import '../models/uu_dai.dart';
import '../services/shop_dich_vu.dart';
import 'don_hang_list_screen.dart';

/// Thanh toán: thông tin nhận hàng, cách nhận, COD hoặc online (giả lập, app giữ tiền).
/// Server tính lại giá, trừ tồn kho và tách đơn theo shop.
class DatHangScreen extends StatefulWidget {
  const DatHangScreen({
    required this.dv,
    required this.dong,
    this.tuGioHang = false,
    super.key,
  });

  final ShopDichVu dv;
  final List<DongGio> dong;

  /// Đặt từ giỏ thì đặt xong bỏ các dòng đó khỏi giỏ.
  final bool tuGioHang;

  @override
  State<DatHangScreen> createState() => _DatHangScreenState();
}

class _DatHangScreenState extends State<DatHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ten = TextEditingController();
  final _sdt = TextEditingController();
  final _diaChi = TextEditingController();
  final _ghiChu = TextEditingController();
  String _cachNhan = 'giao_tan_tro';
  String _thanhToan = 'cod';
  final _maVoucher = TextEditingController();
  Voucher? _voucher;
  num _giam = 0;
  String? _loiVoucher;
  bool _dangApMa = false;
  bool _dangGui = false;
  String? _loi;

  late final _soShop = widget.dong.map((d) => d.shopId).toSet().length;
  late final num _tamTinh = widget.dong.fold<num>(
    0,
    (s, d) => s + d.price * d.quantity,
  );

  @override
  void dispose() {
    _ten.dispose();
    _sdt.dispose();
    _diaChi.dispose();
    _ghiChu.dispose();
    _maVoucher.dispose();
    super.dispose();
  }

  /// Tạm tính các món của một shop (voucher chỉ giảm cho đơn của shop phát mã).
  num _tamTinhShop(String shopId) => widget.dong
      .where((d) => d.shopId == shopId)
      .fold<num>(0, (s, d) => s + d.price * d.quantity);

  Future<void> _apMa() async {
    final ma = _maVoucher.text.trim();
    if (ma.isEmpty) return;
    setState(() {
      _dangApMa = true;
      _loiVoucher = null;
    });
    try {
      final v = await widget.dv.uuDai.timVoucher(ma);
      String? loi;
      num giam = 0;
      if (v == null) {
        loi = 'Mã voucher không tồn tại.';
      } else if (_tamTinhShop(v.shopId) == 0) {
        loi = 'Mã này chỉ dùng cho sản phẩm của ${v.shopName}.';
      } else {
        (giam, loi) = v.tinhGiam(_tamTinhShop(v.shopId));
      }
      setState(() {
        _voucher = loi == null ? v : null;
        _giam = giam;
        _loiVoucher = loi;
      });
    } catch (e) {
      setState(() => _loiVoucher = '$e');
    } finally {
      if (mounted) setState(() => _dangApMa = false);
    }
  }

  void _boMa() => setState(() {
    _voucher = null;
    _giam = 0;
    _maVoucher.clear();
  });

  Future<void> _dat() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      final ids = await widget.dv.donHang.datHang(
        widget.dong,
        ThongTinNhan(
          receiverName: _ten.text.trim(),
          phone: _sdt.text.trim(),
          deliveryMethod: _cachNhan,
          address: _diaChi.text.trim(),
          note: _ghiChu.text.trim(),
          paymentMethod: _thanhToan,
          voucherCode: _voucher?.code,
        ),
      );
      if (widget.tuGioHang) {
        widget.dv.gioHang.xoaNhieu(widget.dong.map((d) => d.khoa));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ids.length > 1
                ? 'Đã đặt ${ids.length} đơn (mỗi shop một đơn).'
                : 'Đã đặt hàng. Chờ shop xác nhận.',
          ),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DonHangListScreen(dv: widget.dv, laNguoiBan: false),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _loi = '$e');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt hàng')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final d in widget.dong)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (d.shopName.isNotEmpty) d.shopName,
                    if (d.size.isNotEmpty) 'Size ${d.size}',
                    'x${d.quantity}',
                  ].join(' · '),
                ),
                trailing: Text(formatPrice(d.price * d.quantity)),
              ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ten,
              decoration: const InputDecoration(labelText: 'Tên người nhận'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nhập tên người nhận' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sdt,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (v) {
                final s = (v ?? '').replaceAll(RegExp(r'[\s.-]'), '');
                return RegExp(r'^(0|\+84)\d{9}$').hasMatch(s)
                    ? null
                    : 'Số điện thoại không hợp lệ';
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Cách nhận hàng',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            RadioGroup<String>(
              groupValue: _cachNhan,
              onChanged: (v) => setState(() => _cachNhan = v!),
              child: Column(
                children: [
                  for (final e in DonHang.deliveryLabels.entries)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: e.key,
                      title: Text(e.value),
                    ),
                ],
              ),
            ),
            TextFormField(
              controller: _diaChi,
              decoration: InputDecoration(
                labelText: _cachNhan == 'giao_tan_tro'
                    ? 'Địa chỉ nhận hàng'
                    : 'Nơi hẹn lấy (không bắt buộc)',
              ),
              validator: (v) =>
                  _cachNhan == 'giao_tan_tro' && (v ?? '').trim().isEmpty
                  ? 'Nhập địa chỉ nhận hàng'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ghiChu,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn cho shop (không bắt buộc)',
              ),
            ),
            Text(
              'Thanh toán',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            RadioGroup<String>(
              groupValue: _thanhToan,
              onChanged: (v) => setState(() => _thanhToan = v!),
              child: Column(
                children: [
                  for (final e in DonHang.paymentLabels.entries)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: e.key,
                      title: Text(e.value),
                      subtitle: e.key == 'online'
                          ? const Text(
                              'App giữ tiền, chỉ chuyển cho shop khi bạn xác nhận '
                              'đã nhận hàng đúng mô tả.',
                            )
                          : null,
                    ),
                ],
              ),
            ),
            Text(
              'Shop phải xác nhận trong 2 ngày, quá hạn đơn tự hủy. '
              'Shop báo đã giao thì bạn có 3 ngày để yêu cầu trả hàng.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (_voucher == null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maVoucher,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Mã voucher của shop',
                        errorText: _loiVoucher,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      onPressed: _dangApMa ? null : _apMa,
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text('${_voucher!.code} · -${formatPrice(_giam)}'),
                subtitle: Text(_voucher!.moTa(formatGiaGon)),
                trailing: TextButton(
                  onPressed: _boMa,
                  child: const Text('Bỏ mã'),
                ),
              ),
            if (_soShop > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Giỏ có hàng của $_soShop shop, sẽ tách thành $_soShop đơn.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_loi != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _loi!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _dangGui ? null : _dat,
              child: Text(
                _dangGui
                    ? 'Đang đặt...'
                    : 'Đặt hàng · ${formatPrice(_tamTinh - _giam)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
