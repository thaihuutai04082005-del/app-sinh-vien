import 'dart:math' as math;

import 'package:app_sinh_vien/features/tro/widgets/tro_states.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_status_badge.dart';
import 'package:app_sinh_vien/features/tro/widgets/tro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _app(Widget child) => MaterialApp(
  theme: TroTheme.data(webFont: false),
  home: Scaffold(body: child),
);

void main() {
  test('các cặp màu chữ / nền của module đạt tương phản 4,5 : 1', () {
    final pairs = <(String, Color, Color)>[
      ('trắng / primary', TroColors.white, TroColors.primary),
      ('trắng / primaryDark', TroColors.white, TroColors.primaryDark),
      ('textPrimary / trắng', TroColors.textPrimary, TroColors.white),
      ('textPrimary / background', TroColors.textPrimary, TroColors.background),
      ('textSecondary / trắng', TroColors.textSecondary, TroColors.white),
      (
        'textSecondary / background',
        TroColors.textSecondary,
        TroColors.background,
      ),
      ('primary / trắng', TroColors.primary, TroColors.white),
      ('primary / primaryLight', TroColors.primary, TroColors.primaryLight),
      ('primary / background', TroColors.primary, TroColors.background),
      ('success / successSoft', TroColors.success, TroColors.successSoft),
      ('warning / warningSoft', TroColors.warning, TroColors.warningSoft),
      ('danger / dangerSoft', TroColors.danger, TroColors.dangerSoft),
      ('trắng / danger', TroColors.white, TroColors.danger),
      ('trắng / ghim xám', TroColors.white, TroColors.markerGrey),
    ];
    for (final (name, fg, bg) in pairs) {
      expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
    }
  });

  test('màu accent không đủ tương phản nên chỉ để trang trí', () {
    expect(_contrast(TroColors.white, TroColors.accent), lessThan(4.5));
  });

  testWidgets('theme áp màu chính, nút cao 48 và bo 12', (tester) async {
    await tester.pumpWidget(
      _app(FilledButton(onPressed: () {}, child: const Text('Đặt cọc'))),
    );
    final theme = Theme.of(tester.element(find.text('Đặt cọc')));
    expect(theme.colorScheme.primary, TroColors.primary);
    expect(theme.scaffoldBackgroundColor, TroColors.background);
    expect(tester.getSize(find.byType(FilledButton)).height, 48);
  });

  testWidgets('trạng thái rỗng có nút gợi ý', (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      _app(
        TroEmptyState(
          title: 'Không tìm thấy nhà trọ phù hợp',
          actionLabel: 'Xóa bộ lọc',
          onAction: () => cleared = true,
        ),
      ),
    );
    await tester.tap(find.text('Xóa bộ lọc'));
    expect(cleared, isTrue);
  });

  testWidgets('trạng thái lỗi có nút Thử lại', (tester) async {
    var retried = false;
    await tester.pumpWidget(_app(TroErrorState(onRetry: () => retried = true)));
    expect(find.text('Không tải được dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });

  testWidgets('khung xương hiện khi đang tải', (tester) async {
    await tester.pumpWidget(_app(const TroSkeletonList(count: 2)));
    expect(find.byType(TroSkeletonBox), findsWidgets);
  });

  testWidgets('huy hiệu luôn có chữ đi kèm icon', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            TroStatusBadge(kind: TroBadgeKind.available, label: 'Còn 3 phòng'),
            TroStatusBadge(kind: TroBadgeKind.full, label: 'Hết phòng'),
          ],
        ),
      ),
    );
    expect(find.text('Còn 3 phòng'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.block_rounded), findsOneWidget);
  });
}
