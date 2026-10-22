import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/danh_gia.dart';
import '../../../shared/widgets/danh_gia_widgets.dart';
import '../../../shared/widgets/detail_layout.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/video_player_view.dart';
import '../models/gio_hang.dart';
import '../models/product.dart';
import '../services/shop_dich_vu.dart';
import '../widgets/shop_widgets.dart';
import 'dang_san_pham_screen.dart';
import 'dat_hang_screen.dart';
import 'gian_hang_screen.dart';
import 'gio_hang_screen.dart';
import 'tra_gia_screen.dart';

/// Chi tiết sản phẩm: chọn size, số lượng, thêm vào giỏ / mua ngay.
/// Chủ sản phẩm thấy nút sửa, xóa thay cho nút mua.
class SanPhamDetailScreen extends StatefulWidget {
  const SanPhamDetailScreen({
    required this.dv,
    required this.productId,
    super.key,
  });

  final ShopDichVu dv;
  final String productId;

  @override
  State<SanPhamDetailScreen> createState() => _SanPhamDetailScreenState();
}

class _SanPhamDetailScreenState extends State<SanPhamDetailScreen> {
  late Future<Product> _product = widget.dv.products.getSanPham(
    widget.productId,
  );
  String? _size;
  int _soLuong = 1;
  bool _dangXoa = false;
  bool? _yeuThich;

  @override
  void initState() {
    super.initState();
    widget.dv.theoDoi
        .dangTheoDoi('product', widget.productId)
        .then((v) => mounted ? setState(() => _yeuThich = v) : null)
        .catchError((_) => null);
  }

  Future<void> _doiYeuThich() async {
    final cu = _yeuThich ?? false;
    setState(() => _yeuThich = !cu);
    try {
      cu
          ? await widget.dv.theoDoi.boTheoDoi('product', widget.productId)
          : await widget.dv.theoDoi.theoDoi('product', widget.productId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _yeuThich = cu);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _reload() => setState(() {
    _product = widget.dv.products.getSanPham(widget.productId);
  });

  DongGio? _dongDaChon(Product p) {
    if (p.sizes.isNotEmpty && _size == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn size trước đã.')));
      return null;
    }
    return DongGio.tu(p, size: _size ?? '', quantity: _soLuong);
  }

  void _themVaoGio(Product p) {
    final d = _dongDaChon(p);
    if (d == null) return;
    widget.dv.gioHang.them(d);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ.'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GioHangScreen(dv: widget.dv),
            ),
          ),
        ),
      ),
    );
  }

  void _muaNgay(Product p) {
    final d = _dongDaChon(p);
    if (d == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DatHangScreen(dv: widget.dv, dong: [d]),
      ),
    );
  }

  Future<void> _traGia(Product p) async {
    if (p.sizes.isNotEmpty && _size == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn size trước đã.')));
      return;
    }
    final kq = await _hoiTraGia(context, p.price);
    if (kq == null || !mounted) return;
    try {
      await widget.dv.uuDai.traGia(
        p.id,
        kq.$1,
        size: _size ?? '',
        message: kq.$2,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi trả giá, chờ shop trả lời.'),
          action: SnackBarAction(
            label: 'Xem',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TraGiaScreen(dv: widget.dv, laNguoiBan: false),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _sua(Product p) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DangSanPhamScreen(dv: widget.dv, sanPham: p),
      ),
    );
    if (id != null) _reload();
  }

  Future<void> _xoa(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text(
          '"${p.name}" sẽ biến mất khỏi shop. Đơn đã đặt vẫn giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Thôi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _dangXoa = true);
    try {
      await widget.dv.products.xoaSanPham(p.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXoa = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _product,
      builder: (context, snap) {
        final p = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(p?.name ?? 'Sản phẩm'),
            actions: [
              if (p != null && p.shopId != widget.dv.uid && _yeuThich != null)
                IconButton(
                  tooltip: _yeuThich! ? 'Bỏ yêu thích' : 'Yêu thích',
                  onPressed: _doiYeuThich,
                  icon: Icon(
                    _yeuThich! ? Icons.favorite : Icons.favorite_border,
                    color: _yeuThich! ? Colors.redAccent : null,
                  ),
                ),
              NutGioHang(
                gioHang: widget.dv.gioHang,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GioHangScreen(dv: widget.dv),
                  ),
                ),
              ),
            ],
          ),
          body: switch (snap) {
            AsyncSnapshot(connectionState: != ConnectionState.done) =>
              const Center(child: CircularProgressIndicator()),
            AsyncSnapshot(hasError: true) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            _ => _noiDung(context, p!),
          },
        );
      },
    );
  }

  Widget _noiDung(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final laChu = product.shopId == widget.dv.uid;
    final toiDa = product.stock.clamp(1, GioHang.soLuongToiDa);
    return DetailLayout(
      media: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageGallery(urls: product.images),
          for (final url in product.videos) ...[
            const SizedBox(height: 16),
            VideoPlayerView(url: url),
          ],
        ],
      ),
      info: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            formatPrice(product.price),
            style: TextStyle(
              fontSize: 26,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          SaoTrungBinh(diem: product.diem),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  productCategoryLabels[product.category] ?? product.category,
                ),
              ),
              Chip(
                label: Text(
                  product.conHang ? 'Còn ${product.stock}' : 'Hết hàng',
                ),
              ),
            ],
          ),
          if (product.shopName.isNotEmpty) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront),
              title: Text(product.shopName),
              subtitle: const Text('Xem gian hàng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GianHangScreen(
                    dv: widget.dv,
                    shopId: product.shopId,
                    shopName: product.shopName,
                  ),
                ),
              ),
            ),
          ],
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(product.description),
          ],
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Size',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in product.sizes)
                  laChu
                      ? Chip(label: Text(size))
                      : ChoiceChip(
                          label: Text(size),
                          selected: _size == size,
                          onSelected: (_) => setState(() => _size = size),
                        ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (laChu)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _dangXoa ? null : () => _sua(product),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _dangXoa ? null : () => _xoa(product),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_dangXoa ? 'Đang xóa...' : 'Xóa'),
                  ),
                ),
              ],
            )
          else if (product.conHang) ...[
            Row(
              children: [
                const Text('Số lượng'),
                const Spacer(),
                ChonSoLuong(
                  value: _soLuong.clamp(1, toiDa),
                  max: toiDa,
                  onChanged: (v) => setState(() => _soLuong = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _themVaoGio(product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Thêm vào giỏ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _muaNgay(product),
                    child: const Text('Mua ngay'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _traGia(product),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Trả giá với shop'),
            ),
          ] else
            const Text('Sản phẩm đã hết hàng.'),
          const SizedBox(height: 24),
          DanhGiaSection(
            taiDanhGia: () => widget.dv.danhGia.theoSanPham(product.id),
            diem: product.diem,
            tieuChi: tieuChiShop,
          ),
        ],
      ),
    );
  }
}

/// Hỏi giá muốn trả (từ 50% đến dưới giá niêm yết) và lời nhắn cho shop.
Future<(int, String)?> _hoiTraGia(BuildContext context, num giaNiemYet) {
  final gia = TextEditingController();
  final nhan = TextEditingController();
  final thapNhat = (giaNiemYet / 2).ceil();
  String? loi;
  return showDialog<(int, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Trả giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gia,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Giá bạn muốn trả',
                suffixText: 'đ',
                errorText: loi,
                helperText:
                    'Từ ${formatPrice(thapNhat)} đến dưới ${formatPrice(giaNiemYet)}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nhan,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (không bắt buộc)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thôi'),
          ),
          FilledButton(
            onPressed: () {
              final g = int.tryParse(gia.text) ?? 0;
              if (g < thapNhat || g >= giaNiemYet) {
                setState(() => loi = 'Giá chưa hợp lệ');
                return;
              }
              Navigator.pop(context, (g, nhan.text.trim()));
            },
            child: const Text('Gửi trả giá'),
          ),
        ],
      ),
    ),
  );
}
