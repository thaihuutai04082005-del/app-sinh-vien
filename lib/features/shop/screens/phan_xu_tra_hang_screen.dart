import 'package:flutter/material.dart';

import '../../../shared/widgets/async_list_view.dart';
import '../models/don_hang.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'don_hang_detail_screen.dart';

/// Admin Shop (`admins/{uid}.shop`): các đơn người mua khiếu nại vì shop từ chối trả hàng.
class PhanXuTraHangScreen extends StatefulWidget {
  const PhanXuTraHangScreen({required this.dv, super.key});

  final ShopDichVu dv;

  @override
  State<PhanXuTraHangScreen> createState() => _PhanXuTraHangScreenState();
}

class _PhanXuTraHangScreenState extends State<PhanXuTraHangScreen> {
  late Future<List<DonHang>> _ds = widget.dv.donHang.donKhieuNai();

  Future<void> _reload() async {
    final f = widget.dv.donHang.donKhieuNai();
    setState(() {
      _ds = f;
    });
    await f.catchError((_) => <DonHang>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phân xử trả hàng')),
      body: AsyncListView<DonHang>(
        future: _ds,
        onRefresh: _reload,
        emptyIcon: Icons.gavel_outlined,
        emptyText: 'Không có khiếu nại nào đang chờ.',
        itemBuilder: (context, d) => DonCard(
          don: d,
          laNguoiBan: false,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DonHangDetailScreen(
                  dv: widget.dv,
                  orderId: d.id,
                  laAdmin: true,
                ),
              ),
            );
            _reload();
          },
        ),
      ),
    );
  }
}
