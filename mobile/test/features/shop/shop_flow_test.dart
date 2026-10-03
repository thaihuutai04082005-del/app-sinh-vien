import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unihub_student_app/core/services/image_storage_service.dart';
import 'package:unihub_student_app/features/shop/models/product.dart';
import 'package:unihub_student_app/features/shop/screens/shop_screen.dart';
import 'package:unihub_student_app/features/shop/services/product_service.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _InstantStorage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/images/$folder/$fileName';
}

class _MemoryProductService implements ProductService {
  final products = <Product>[];

  @override
  Future<List<Product>> getDanhSachSanPham() async => List.of(products);

  @override
  Future<Product> getSanPham(String id) async =>
      products.firstWhere((p) => p.id == id);

  @override
  Future<Product> dangSanPham(Product product) async {
    final saved = Product.fromMap({
      ...product.toMap(),
      'id': 'p${products.length + 1}',
    });
    products.insert(0, saved);
    return saved;
  }
}

Future<List<XFile>> _pickOne(int _) async => [
  XFile.fromData(_png, name: 'ao.png'),
];

Future<void> _pumpShop(WidgetTester tester, ProductService service) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ShopScreen(
        service: service,
        storage: _InstantStorage(),
        pickImages: _pickOne,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'đăng sản phẩm xong thì xem được chi tiết và thấy trong danh sách',
    (tester) async {
      final service = _MemoryProductService();
      await _pumpShop(tester, service);

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
        find.widgetWithText(TextFormField, 'Giá'),
        '85000',
      );
      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng sản phẩm'));
      await tester.pumpAndSettle();

      // Mở ngay màn chi tiết của sản phẩm vừa đăng.
      expect(find.text('85.000đ'), findsOneWidget);
      expect(
        service.products.single.images.single,
        startsWith('https://cdn.test/images/products/'),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Áo thun basic'), findsOneWidget);
      expect(find.textContaining('Chưa có sản phẩm nào'), findsNothing);
    },
  );

  testWidgets('không cho đăng sản phẩm khi chưa có ảnh', (tester) async {
    await _pumpShop(tester, _MemoryProductService());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng sản phẩm'));
    await tester.pump();

    expect(find.text('Cần ít nhất 1 ảnh sản phẩm.'), findsOneWidget);
  });
}
