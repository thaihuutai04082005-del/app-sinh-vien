import 'package:app_sinh_vien/shared/widgets/image_url_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<List<String>>> _pump(WidgetTester tester, {int max = 6}) async {
  final calls = <List<String>>[];
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ImageUrlField(
          label: 'Ảnh địa điểm',
          maxImages: max,
          onChanged: calls.add,
        ),
      ),
    ),
  );
  return calls;
}

Future<void> _addLink(WidgetTester tester, String link) async {
  await tester.enterText(find.byType(TextField), link);
  await tester.tap(find.text('Thêm'));
  await tester.pump();
}

void main() {
  group('isValidImageUrl', () {
    test('chấp nhận link https hợp lệ', () {
      expect(isValidImageUrl('https://picsum.photos/seed/a/600/400'), isTrue);
      expect(isValidImageUrl('https://example.com/a.jpg?x=1&y=2'), isTrue);
    });

    test('từ chối link không an toàn hoặc sai định dạng', () {
      expect(isValidImageUrl('http://example.com/a.jpg'), isFalse);
      expect(isValidImageUrl('javascript:alert(1)'), isFalse);
      expect(isValidImageUrl('ftp://example.com/a.jpg'), isFalse);
      expect(isValidImageUrl('example.com/a.jpg'), isFalse);
      expect(isValidImageUrl('https://localhost/a.jpg'), isFalse);
      expect(isValidImageUrl('https://'), isFalse);
      expect(isValidImageUrl('https://exa mple.com/a.jpg'), isFalse);
      expect(isValidImageUrl('abc'), isFalse);
      expect(isValidImageUrl(''), isFalse);
      expect(isValidImageUrl('https://example.com/${'a' * 2000}'), isFalse);
    });
  });

  testWidgets('thêm link hợp lệ thì báo về và xóa ô nhập', (tester) async {
    final calls = await _pump(tester);
    await _addLink(tester, '  https://example.com/a.jpg  ');
    expect(calls.single, ['https://example.com/a.jpg']);
    expect(find.text('Ảnh địa điểm (1/6)'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('gửi bằng phím Enter cũng thêm được', (tester) async {
    final calls = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'https://example.com/a.jpg');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(calls.single, ['https://example.com/a.jpg']);
  });

  testWidgets('từ chối link http, link sai và ô trống, không gọi onChanged', (
    tester,
  ) async {
    final calls = await _pump(tester);

    await tester.tap(find.text('Thêm'));
    await tester.pump();
    expect(find.text('Dán link ảnh vào ô trên'), findsOneWidget);

    await _addLink(tester, 'http://example.com/a.jpg');
    expect(
      find.text('Link phải bắt đầu bằng https:// và là đường dẫn hợp lệ'),
      findsOneWidget,
    );

    await _addLink(tester, 'không phải link');
    expect(
      find.text('Link phải bắt đầu bằng https:// và là đường dẫn hợp lệ'),
      findsOneWidget,
    );
    expect(calls, isEmpty);
  });

  testWidgets('không thêm trùng link', (tester) async {
    final calls = await _pump(tester);
    await _addLink(tester, 'https://example.com/a.jpg');
    await _addLink(tester, 'https://example.com/a.jpg');
    expect(find.text('Link này đã được thêm'), findsOneWidget);
    expect(calls, hasLength(1));
  });

  testWidgets('đủ số ảnh tối đa thì khóa nút Thêm', (tester) async {
    final calls = await _pump(tester, max: 2);
    await _addLink(tester, 'https://example.com/1.jpg');
    await _addLink(tester, 'https://example.com/2.jpg');
    expect(calls.last, hasLength(2));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Thêm'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('xóa ảnh thì báo danh sách mới', (tester) async {
    final calls = await _pump(tester);
    await _addLink(tester, 'https://example.com/1.jpg');
    await _addLink(tester, 'https://example.com/2.jpg');
    await tester.tap(find.byTooltip('Xóa ảnh').first);
    await tester.pump();
    expect(calls.last, ['https://example.com/2.jpg']);
    expect(find.text('Ảnh địa điểm (1/6)'), findsOneWidget);
  });
}
