import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_list_view.dart';
import '../models/uu_dai.dart';
import '../services/shop_dich_vu.dart';

/// Voucher của shop mình (kênh người bán): tạo mã, xem lượt dùng, ngừng mã.
class VoucherScreen extends StatefulWidget {
  const VoucherScreen({required this.dv, super.key});

  final ShopDichVu dv;

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  late Future<List<Voucher>> _ds = widget.dv.uuDai.voucherCuaShop(
    widget.dv.uid,
  );

  Future<void> _reload() async {
    final f = widget.dv.uuDai.voucherCuaShop(widget.dv.uid);
    setState(() {
      _ds = f;
    });
    await f.catchError((_) => <Voucher>[]);
  }

  Future<void> _tao() async {
    final xong = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _TaoVoucherScreen(dv: widget.dv)),
    );
    if (xong == true) _reload();
  }

  Future<void> _ngung(Voucher v) async {
    try {
      await widget.dv.uuDai.ngungVoucher(v.code);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher của shop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tao,
        icon: const Icon(Icons.add),
        label: const Text('Tạo voucher'),
      ),
      body: AsyncListView<Voucher>(
        future: _ds,
        onRefresh: _reload,
        emptyIcon: Icons.confirmation_number_outlined,
        emptyText: 'Chưa có voucher nào.',
        itemBuilder: (context, v) => Card(
          child: ListTile(
            leading: const Icon(Icons.confirmation_number_outlined),
            title: Text(
              v.code,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${v.moTa(formatGiaGon)}\n'
              'Đã dùng ${v.usedCount}/${v.usageLimit} · hạn ${formatNgay(v.expiredAt)}',
            ),
            isThreeLine: true,
            trailing: v.conDung
                ? TextButton(
                    onPressed: () => _ngung(v),
                    child: const Text('Ngừng'),
                  )
                : const Text('Hết hiệu lực'),
          ),
        ),
      ),
    );
  }
}

class _TaoVoucherScreen extends StatefulWidget {
  const _TaoVoucherScreen({required this.dv});

  final ShopDichVu dv;

  @override
  State<_TaoVoucherScreen> createState() => _TaoVoucherScreenState();
}

class _TaoVoucherScreenState extends State<_TaoVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ma = TextEditingController();
  final _giaTri = TextEditingController();
  final _toiDa = TextEditingController();
  final _donToiThieu = TextEditingController(text: '0');
  final _soLuot = TextEditingController(text: '20');
  String _loai = 'percent';
  int _soNgay = 7;
  bool _dangGui = false;

  @override
  void dispose() {
    for (final c in [_ma, _giaTri, _toiDa, _donToiThieu, _soLuot]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangGui = true);
    try {
      await widget.dv.uuDai.taoVoucher(
        VoucherNhap(
          code: _ma.text.trim().toUpperCase(),
          discountType: _loai,
          discountValue: int.parse(_giaTri.text),
          maxDiscount: _loai == 'percent' && _toiDa.text.isNotEmpty
              ? int.parse(_toiDa.text)
              : null,
          minOrderValue: int.tryParse(_donToiThieu.text) ?? 0,
          usageLimit: int.parse(_soLuot.text),
          expiredAt: DateTime.now().add(Duration(days: _soNgay)),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chưa tạo được: $e')));
    }
  }

  String? Function(String?) _soTrong(int min, int max, String ten) => (v) {
    final n = int.tryParse(v ?? '');
    return n == null || n < min || n > max ? '$ten từ $min đến $max' : null;
  };

  @override
  Widget build(BuildContext context) {
    final so = [FilteringTextInputFormatter.digitsOnly];
    final phanTram = _loai == 'percent';
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo voucher')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _ma,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Mã voucher',
                hintText: 'VD: GIAM10',
              ),
              validator: (v) =>
                  RegExp(r'^[A-Za-z0-9]{4,15}$').hasMatch((v ?? '').trim())
                  ? null
                  : '4–15 chữ cái không dấu hoặc số',
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percent', label: Text('Giảm %')),
                ButtonSegment(value: 'fixed', label: Text('Giảm số tiền')),
              ],
              selected: {_loai},
              onSelectionChanged: (s) => setState(() => _loai = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _giaTri,
              keyboardType: TextInputType.number,
              inputFormatters: so,
              decoration: InputDecoration(
                labelText: phanTram ? 'Phần trăm giảm' : 'Số tiền giảm',
                suffixText: phanTram ? '%' : 'đ',
              ),
              validator: phanTram
                  ? _soTrong(1, 90, 'Phần trăm')
                  : _soTrong(1000, 5000000, 'Số tiền'),
            ),
            if (phanTram) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _toiDa,
                keyboardType: TextInputType.number,
                inputFormatters: so,
                decoration: const InputDecoration(
                  labelText: 'Giảm tối đa (không bắt buộc)',
                  suffixText: 'đ',
                ),
                validator: (v) => (v ?? '').isEmpty
                    ? null
                    : _soTrong(1000, 5000000, 'Giảm tối đa')(v),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _donToiThieu,
              keyboardType: TextInputType.number,
              inputFormatters: so,
              decoration: const InputDecoration(
                labelText: 'Đơn tối thiểu',
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _soLuot,
              keyboardType: TextInputType.number,
              inputFormatters: so,
              decoration: const InputDecoration(labelText: 'Số lượt dùng'),
              validator: _soTrong(1, 1000, 'Số lượt'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _soNgay,
              decoration: const InputDecoration(labelText: 'Hiệu lực'),
              items: [
                for (final n in [1, 3, 7, 14, 30, 90])
                  DropdownMenuItem(value: n, child: Text('$n ngày')),
              ],
              onChanged: (n) => setState(() => _soNgay = n ?? 7),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _dangGui ? null : _gui,
              child: Text(_dangGui ? 'Đang tạo...' : 'Tạo voucher'),
            ),
          ],
        ),
      ),
    );
  }
}
