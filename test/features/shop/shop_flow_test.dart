import 'package:app_sinh_vien/features/shop/models/don_hang.dart';
import 'package:app_sinh_vien/features/shop/models/gio_hang.dart';
import 'package:app_sinh_vien/features/shop/screens/don_hang_detail_screen.dart';
import 'package:app_sinh_vien/features/shop/screens/san_pham_detail_screen.dart';
import 'package:app_sinh_vien/features/shop/screens/shop_screen.dart';
import 'package:app_sinh_vien/features/shop/services/shop_dich_vu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/xac_thuc_gia.dart';
import 'fakes.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

Future<void> _pumpShop(WidgetTester tester, ShopDichVu dv) =>
    _pump(tester, ShopScreen(dv: dv));

void main() {
  testWidgets(
    'đăng sản phẩm xong thì xem được chi tiết và thấy trong danh sách',
    (tester) async {
      final kho = KhoGia();
      await _pumpShop(tester, shopDv(kho, 'ban'));

      expect(find.textContaining('Chưa có sản phẩm nào'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm ảnh'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên sản phẩm'),
        'Áo thun basic',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mô tả'),
        'Cotton 100%, mặc 2 lần',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Giá'),
        '85000',
      );
      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng sản phẩm'));
      await tester.pumpAndSettle();

      // Mở ngay màn chi tiết của sản phẩm vừa đăng; chủ thấy nút sửa / xóa.
      expect(find.text('85.000đ'), findsOneWidget);
      expect(find.text('Cotton 100%, mặc 2 lần'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sửa'), findsOneWidget);
      expect(find.text('Thêm vào giỏ'), findsNothing);
      expect(
        kho.products.single.images.single,
        startsWith('https://cdn.test/images/products/'),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Áo thun basic'), findsOneWidget);
      expect(find.textContaining('Chưa có sản phẩm nào'), findsNothing);
    },
  );

  testWidgets('không cho đăng sản phẩm khi chưa có ảnh', (tester) async {
    await _pumpShop(tester, shopDv(KhoGia(), 'ban'));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng sản phẩm'));
    await tester.pump();

    expect(find.text('Cần ít nhất 1 ảnh sản phẩm.'), findsOneWidget);
  });

  testWidgets('chưa xác thực số điện thoại thì chưa cho đăng bán', (
    tester,
  ) async {
    await _pumpShop(tester, shopDv(KhoGia(), 'ban', xacThuc: XacThucGia()));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Xác thực số điện thoại'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Tên sản phẩm'), findsNothing);
  });

  testWidgets('lọc theo danh mục và mức giá', (tester) async {
    final kho = KhoGia()
      ..products.addAll([
        sanPhamMau(id: 'a', name: 'Áo khoác', price: 140000),
        sanPhamMau(id: 'b', name: 'Quần jean', category: 'quan', price: 90000),
      ]);
    await _pumpShop(tester, shopDv(kho, 'mua'));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Quần'));
    await tester.pumpAndSettle();
    expect(find.text('Quần jean'), findsOneWidget);
    expect(find.text('Áo khoác'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dưới 100k'));
    await tester.pumpAndSettle();
    expect(find.text('Quần jean'), findsOneWidget);
    expect(find.text('Áo khoác'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Dưới 150k'));
    await tester.pumpAndSettle();
    expect(find.text('Áo khoác'), findsOneWidget);
  });

  testWidgets(
    'chọn size, thêm giỏ, đặt hàng thì giỏ trống và thấy đơn chờ xác nhận',
    (tester) async {
      final kho = KhoGia()..products.add(sanPhamMau(id: 'a'));
      final dv = shopDv(kho, 'mua');
      await _pumpShop(tester, dv);

      await tester.tap(find.text('Áo thun basic'));
      await tester.pumpAndSettle();

      // Chưa chọn size thì không cho thêm.
      await tester.tap(find.text('Thêm vào giỏ'));
      await tester.pump();
      expect(find.text('Chọn size trước đã.'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'L'));
      await tester.tap(find.byTooltip('Thêm'));
      await tester.pump();
      await tester.tap(find.text('Thêm vào giỏ'));
      await tester.pump();
      expect(dv.gioHang.soMon, 2);

      await tester.tap(find.byTooltip('Giỏ hàng'));
      await tester.pumpAndSettle();
      expect(find.text('170.000đ'), findsOneWidget);
      await tester.tap(find.text('Đặt hàng (2)'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên người nhận'),
        'An',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '0912 345 678',
      );
      // Giao tận trọ bắt buộc địa chỉ.
      await tester.tap(find.textContaining('Đặt hàng ·'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập địa chỉ nhận hàng'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Địa chỉ nhận hàng'),
        'KTX khu B',
      );
      await tester.tap(find.textContaining('Đặt hàng ·'));
      await tester.pumpAndSettle();

      expect(dv.gioHang.dong, isEmpty);
      final don = kho.orders.single;
      expect(don.items.single.size, 'L');
      expect(don.items.single.quantity, 2);
      expect(find.text('Đơn mua'), findsOneWidget);
      expect(find.text('Shop ban'), findsOneWidget);
    },
  );

  testWidgets('shop xác nhận đơn; người mua không thấy nút xác nhận', (
    tester,
  ) async {
    final kho = KhoGia();
    final mua = shopDv(kho, 'mua');
    kho.products.add(sanPhamMau(id: 'a', sizes: const []));
    await mua.donHang.datHang(
      [DongGio.tu(kho.products.single, size: '', quantity: 1)],
      const ThongTinNhan(
        receiverName: 'An',
        phone: '0912345678',
        deliveryMethod: 'hen_lay',
      ),
    );
    final id = kho.orders.single.id;

    await _pump(tester, DonHangDetailScreen(dv: mua, orderId: id));
    expect(find.text('Xác nhận đơn'), findsNothing);
    expect(find.text('Hủy đơn'), findsOneWidget);

    await _pump(
      tester,
      DonHangDetailScreen(dv: shopDv(kho, 'ban'), orderId: id),
    );
    await tester.tap(find.text('Xác nhận đơn'));
    await tester.pumpAndSettle();
    expect(kho.orders.single.status, 'to_ship');
    expect(find.text('Bắt đầu giao hàng'), findsOneWidget);
  });

  testWidgets(
    'nhận hàng xong thì đánh giá 3 tiêu chí, hiện trên trang sản phẩm',
    (tester) async {
      final kho = KhoGia();
      final mua = shopDv(kho, 'mua');
      kho.products.add(sanPhamMau(id: 'a', sizes: const []));
      await mua.donHang.datHang(
        [DongGio.tu(kho.products.single, size: '', quantity: 1)],
        const ThongTinNhan(
          receiverName: 'An',
          phone: '0912345678',
          deliveryMethod: 'hen_lay',
        ),
      );
      final id = kho.orders.single.id;

      // Chưa nhận hàng thì chưa có nút đánh giá.
      await _pump(tester, DonHangDetailScreen(dv: mua, orderId: id));
      expect(find.text('Đánh giá đơn hàng'), findsNothing);

      await mua.donHang.thaoTac(id, 'daNhan');
      await _pump(
        tester,
        DonHangDetailScreen(key: UniqueKey(), dv: mua, orderId: id),
      );
      await tester.tap(find.text('Đánh giá đơn hàng'));
      await tester.pumpAndSettle();

      // Thiếu tiêu chí thì chưa gửi.
      await tester.tap(find.byTooltip('5 sao').first);
      await tester.pump();
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pump();
      expect(find.text('Chấm sao đủ 3 tiêu chí.'), findsOneWidget);
      expect(kho.danhGia.ds, isEmpty);

      await tester.tap(find.byTooltip('4 sao').at(1));
      await tester.tap(find.byTooltip('4 sao').at(2));
      await tester.enterText(
        find.widgetWithText(TextField, 'Nhận xét (không bắt buộc)'),
        'Áo đẹp, đúng hình',
      );
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();

      expect(find.text('Bạn đã đánh giá đơn này.'), findsOneWidget);
      expect(find.text('Đánh giá đơn hàng'), findsNothing);
      final dg = kho.danhGia.ds.single;
      expect(dg.$4.ratingDetail, {'quality': 5, 'accuracy': 4, 'service': 4});
      expect(dg.$3, ['a']);

      await _pump(tester, SanPhamDetailScreen(dv: mua, productId: 'a'));
      expect(
        find.text('Áo đẹp, đúng hình', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Chất lượng sản phẩm: 5★', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  test(
    'giỏ hàng lưu lại theo tài khoản và kẹp số lượng theo tồn kho',
    () async {
      final luu = BoNhoLuuGioHang();
      final gio = GioHang(uid: 'u1', luu: luu);
      await gio.san;
      final p = sanPhamMau(id: 'a', stock: 3);
      gio.them(DongGio.tu(p, size: 'M', quantity: 2));
      gio.them(DongGio.tu(p, size: 'M', quantity: 2));
      gio.them(DongGio.tu(p, size: 'L', quantity: 1));
      expect(gio.dong.length, 2);
      expect(gio.dong.first.quantity, 3);
      expect(gio.tamTinh, 85000 * 4);

      final moLai = GioHang(uid: 'u1', luu: luu);
      await moLai.san;
      expect(moLai.soMon, 4);

      final nguoiKhac = GioHang(uid: 'u2', luu: luu);
      await nguoiKhac.san;
      expect(nguoiKhac.dong, isEmpty);
    },
  );
}
