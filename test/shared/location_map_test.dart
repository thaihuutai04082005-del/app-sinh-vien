import 'package:app_sinh_vien/shared/widgets/location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('đường dẫn chỉ đường chứa tọa độ đích', () {
    final uri = directionsUri(10.46, 105.63);
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['destination'], '10.46,105.63');
  });

  testWidgets('hiện bản đồ và nút Chỉ đường mở đúng link', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMap(
            latitude: 10.46,
            longitude: 105.63,
            openUrl: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    await tester.tap(find.text('Chỉ đường'));
    expect(opened, directionsUri(10.46, 105.63));
  });
}
