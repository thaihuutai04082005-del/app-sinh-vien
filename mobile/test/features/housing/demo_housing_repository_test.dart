import 'package:flutter_test/flutter_test.dart';
import 'package:unihub_student_app/features/housing/data/demo_housing_repository.dart';

void main() {
  group('DemoHousingRepository', () {
    test(
      'cung cấp dữ liệu beta có thể dùng ngay khi chưa kết nối Firebase',
      () async {
        final repository = DemoHousingRepository();

        final listings = await repository.findAll();

        expect(listings, hasLength(greaterThanOrEqualTo(4)));
        expect(
          listings.map((listing) => listing.id).toSet(),
          hasLength(listings.length),
        );
        expect(listings.every((listing) => listing.price > 0), isTrue);
      },
    );

    test('tìm đúng phòng theo id và trả null khi không tồn tại', () async {
      final repository = DemoHousingRepository();
      final listings = await repository.findAll();

      expect(await repository.findById(listings.first.id), listings.first);
      expect(await repository.findById('khong-ton-tai'), isNull);
    });
  });
}
