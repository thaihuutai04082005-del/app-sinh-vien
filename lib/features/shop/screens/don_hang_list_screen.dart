import 'package:flutter/material.dart';

import '../models/don_hang.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'don_hang_detail_screen.dart';

/// Đơn mua (người mua) hoặc đơn bán (người bán), chia tab theo trạng thái
/// như "Đơn mua" / "Kênh Người Bán" của Shopee.
class DonHangListScreen extends StatefulWidget {
  const DonHangListScreen({
    required this.dv,
    required this.laNguoiBan,
    super.key,
  });

  final ShopDichVu dv;
  final bool laNguoiBan;

  @override
  State<DonHangListScreen> createState() => _DonHangListScreenState();
}

class _DonHangListScreenState extends State<DonHangListScreen> {
  late Future<List<DonHang>> _don = _tai();

  Future<List<DonHang>> _tai() => widget.laNguoiBan
      ? widget.dv.donHang.donBan()
      : widget.dv.donHang.donMua();

  Future<void> _reload() async {
    final f = _tai();
    setState(() {
      _don = f;
    });
    await f.catchError((_) => <DonHang>[]);
  }

  @override
  Widget build(BuildContext context) {
    const trangThai = DonHang.statusLabels;
    return DefaultTabController(
      length: trangThai.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.laNguoiBan ? 'Đơn bán' : 'Đơn mua'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final l in trangThai.values) Tab(text: l)],
          ),
        ),
        body: FutureBuilder<List<DonHang>>(
          future: _don,
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
            final tatCa = snap.data!;
            return TabBarView(
              children: [
                for (final s in trangThai.keys)
                  _danhSach(context, [
                    for (final d in tatCa)
                      if (d.status == s) d,
                  ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _danhSach(BuildContext context, List<DonHang> ds) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ds.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Chưa có đơn nào.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: ds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => DonCard(
                don: ds[i],
                laNguoiBan: widget.laNguoiBan,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DonHangDetailScreen(dv: widget.dv, orderId: ds[i].id),
                    ),
                  );
                  _reload();
                },
              ),
            ),
    );
  }
}
