/// Giá tiền luôn lưu dạng number, chỉ định dạng "100.000đ" khi hiển thị.
String formatPrice(num price) {
  final digits = price.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$bufferđ';
}
