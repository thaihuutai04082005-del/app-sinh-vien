import 'package:app_sinh_vien/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPrice định dạng giá tiền kiểu Việt Nam', () {
    expect(formatPrice(100000), '100.000đ');
    expect(formatPrice(1500000), '1.500.000đ');
    expect(formatPrice(500), '500đ');
  });
}
