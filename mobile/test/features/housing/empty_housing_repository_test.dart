import 'package:flutter_test/flutter_test.dart';
import 'package:unihub_student_app/features/housing/data/empty_housing_repository.dart';

void main() {
  test('kho phòng trọ ban đầu không chứa dữ liệu dựng sẵn', () async {
    final repository = EmptyHousingRepository();

    expect(await repository.findAll(), isEmpty);
    expect(await repository.findById('khong-ton-tai'), isNull);
  });
}
