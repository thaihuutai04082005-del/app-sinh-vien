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

/// Giờ Việt Nam (UTC+7) — mọi mốc giờ, hạn trong app đều hiện theo giờ này.
DateTime gioVietNam(DateTime t) => t.toUtc().add(const Duration(hours: 7));

String _hai(int n) => n.toString().padLeft(2, '0');

/// "14:00 10/10/2026" theo giờ Việt Nam.
String formatNgayGio(DateTime t) {
  final v = gioVietNam(t);
  return '${_hai(v.hour)}:${_hai(v.minute)} ${_hai(v.day)}/${_hai(v.month)}/${v.year}';
}

/// "10/10/2026" theo giờ Việt Nam.
String formatNgay(DateTime t) {
  final v = gioVietNam(t);
  return '${_hai(v.day)}/${_hai(v.month)}/${v.year}';
}

/// Giá gọn cho ghim bản đồ / thẻ: 1500000 → "1,5tr", 900000 → "900k".
String formatGiaGon(num gia) {
  if (gia >= 1000000) {
    final tr = gia / 1000000;
    final chuoi = tr == tr.roundToDouble()
        ? tr.toStringAsFixed(0)
        : tr.toStringAsFixed(1);
    return '${chuoi.replaceAll('.', ',')}tr';
  }
  return '${(gia / 1000).round()}k';
}

/// Đếm ngược: "2 ngày 3 giờ", "45 phút", "Đã tới hạn".
String formatConLai(Duration d) {
  if (d.inSeconds <= 0) return 'Đã tới hạn';
  if (d.inDays >= 1) return '${d.inDays} ngày ${d.inHours % 24} giờ';
  if (d.inHours >= 1) return '${d.inHours} giờ ${d.inMinutes % 60} phút';
  if (d.inMinutes >= 1) return '${d.inMinutes} phút';
  return '${d.inSeconds} giây';
}

/// Khoảng cách: 650 → "650 m", 1250 → "1,3 km".
String formatKhoangCach(double met) {
  if (met < 1000) return '${met.round()} m';
  return '${(met / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
