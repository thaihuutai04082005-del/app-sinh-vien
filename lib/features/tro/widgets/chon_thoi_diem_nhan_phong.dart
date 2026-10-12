import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import 'tro_theme.dart';

/// Kiểm tra thời điểm nhận phòng (mục 2.16): ≥ lúc cọc + 2 giờ, ≥ ngày có thể vào ở, ≤ lúc cọc + 14 ngày.
/// Trả về lỗi tiếng Việt hoặc null. Hệ thống kiểm tra lại khi tạo khoản cọc.
String? kiemTraThoiDiem(
  DateTime? t, {
  required DateTime now,
  required Duration itNhat,
  required Duration toiDa,
  DateTime? ngayVaoO,
  String moc = 'bây giờ',
}) {
  if (t == null) return 'Chọn ngày và giờ nhận phòng.';
  if (t.isBefore(now.add(itNhat))) {
    return 'Phải cách $moc ít nhất ${_dai(itNhat)}.';
  }
  if (ngayVaoO != null && t.isBefore(ngayVaoO)) {
    return 'Không được trước ngày có thể vào ở (${formatNgay(ngayVaoO)}).';
  }
  if (t.isAfter(now.add(toiDa))) {
    return 'Không được quá ${_dai(toiDa)} kể từ $moc.';
  }
  return null;
}

String _dai(Duration d) => d.inDays >= 1
    ? '${d.inDays} ngày'
    : d.inHours >= 1
    ? '${d.inHours} giờ'
    : '${d.inMinutes} phút';

/// Chọn ngày + giờ nhận phòng (giờ Việt Nam).
class ChonThoiDiemNhanPhong extends StatelessWidget {
  const ChonThoiDiemNhanPhong({
    required this.giaTri,
    required this.onChanged,
    this.loi,
    this.nhan = 'Thời điểm nhận phòng',
    super.key,
  });

  final DateTime? giaTri;
  final ValueChanged<DateTime> onChanged;
  final String? loi;
  final String nhan;

  Future<void> _chon(BuildContext context) async {
    final now = DateTime.now();
    final ngay = await showDatePicker(
      context: context,
      initialDate: giaTri ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Chọn ngày nhận phòng',
    );
    if (ngay == null || !context.mounted) return;
    final gio = await showTimePicker(
      context: context,
      initialTime: giaTri == null
          ? const TimeOfDay(hour: 14, minute: 0)
          : TimeOfDay.fromDateTime(giaTri!),
      helpText: 'Chọn giờ nhận phòng',
    );
    if (gio == null) return;
    // Người dùng chọn theo giờ Việt Nam (UTC+7).
    onChanged(
      DateTime.utc(
        ngay.year,
        ngay.month,
        ngay.day,
        gio.hour,
        gio.minute,
      ).subtract(const Duration(hours: 7)).toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _chon(context),
    borderRadius: BorderRadius.circular(TroRadius.input),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: nhan,
        errorText: loi,
        suffixIcon: const Icon(Icons.event_rounded),
      ),
      child: Text(
        giaTri == null ? 'Chọn ngày + giờ' : formatNgayGio(giaTri!),
        style: TroText.body,
      ),
    ),
  );
}
