import 'package:geolocator/geolocator.dart';

typedef ToaDo = ({double lat, double lng});

/// Luồng vị trí của máy (test thay bằng luồng giả).
typedef ViTriStream = Stream<ToaDo> Function();

/// Vị trí GPS qua geolocator: xin quyền rồi theo dõi khi di chuyển ≥ 20 m.
/// Bản web chỉ chạy khi trang mở qua HTTPS và tab còn mở.
Stream<ToaDo> viTriGeolocator() async* {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Thiết bị đang tắt định vị.');
  }
  var quyen = await Geolocator.checkPermission();
  if (quyen == LocationPermission.denied) {
    quyen = await Geolocator.requestPermission();
  }
  if (quyen == LocationPermission.denied ||
      quyen == LocationPermission.deniedForever) {
    throw Exception('Chưa được cấp quyền vị trí.');
  }
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    ),
  ).map((p) => (lat: p.latitude, lng: p.longitude));
}
