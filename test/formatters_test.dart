import 'package:app_sinh_vien/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPrice định dạng giá tiền kiểu Việt Nam', () {
    expect(formatPrice(100000), '100.000đ');
    expect(formatPrice(1500000), '1.500.000đ');
    expect(formatPrice(500), '500đ');
  });

  test('ngày giờ luôn hiện theo giờ Việt Nam (UTC+7)', () {
    final t = DateTime.utc(2026, 10, 10, 7, 0);
    expect(formatNgayGio(t), '14:00 10/10/2026');
    expect(formatNgay(DateTime.utc(2026, 10, 9, 18)), '10/10/2026');
  });

  test('giá gọn, khoảng cách, đếm ngược', () {
    expect(formatGiaGon(1500000), '1,5tr');
    expect(formatGiaGon(2000000), '2tr');
    expect(formatGiaGon(900000), '900k');
    expect(formatKhoangCach(650), '650 m');
    expect(formatKhoangCach(1250), '1,3 km');
    expect(formatConLai(const Duration(hours: 27)), '1 ngày 3 giờ');
    expect(formatConLai(Duration.zero), 'Đã tới hạn');
  });
}
