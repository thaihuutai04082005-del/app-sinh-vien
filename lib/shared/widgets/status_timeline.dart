import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../services/callable_api.dart';

/// Lịch sử trạng thái của đơn, mốc mới nhất ở dưới cùng.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    required this.moc,
    required this.nhanTrangThai,
    required this.nhanNguoiLam,
    super.key,
  });

  final List<MocTrangThai> moc;
  final Map<String, String> nhanTrangThai;
  final Map<String, String> nhanNguoiLam;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < moc.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    i == moc.length - 1
                        ? Icons.radio_button_checked
                        : Icons.check_circle_outline,
                    size: 18,
                    color: colors.primary,
                  ),
                  if (i < moc.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: colors.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: nhanTrangThai[moc[i].status] ?? moc[i].status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text:
                            '  ${formatNgayGio(moc[i].at)}'
                            '${nhanNguoiLam[moc[i].by] == null ? '' : ' · ${nhanNguoiLam[moc[i].by]}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Hộp thoại hỏi lý do (hủy đơn...). Trả về null nếu người dùng bỏ qua.
Future<String?> hoiLyDo(
  BuildContext context, {
  required String tieuDe,
  String nutXacNhan = 'Xác nhận',
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tieuDe),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 300,
        decoration: const InputDecoration(labelText: 'Lý do'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Thôi'),
        ),
        FilledButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              Navigator.pop(context, ctrl.text.trim());
            }
          },
          child: Text(nutXacNhan),
        ),
      ],
    ),
  );
}
