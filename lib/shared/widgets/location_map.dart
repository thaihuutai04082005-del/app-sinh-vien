import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Đường dẫn chỉ đường tới tọa độ (mở bằng app/website Google Maps, không cần API key).
Uri directionsUri(double latitude, double longitude) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '$latitude,$longitude'},
);

typedef OpenUrl = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Bản đồ OpenStreetMap có ghim 1 vị trí kèm nút "Chỉ đường".
/// Dùng OpenStreetMap vì Google Maps Platform không bán cho tài khoản thanh toán tại Việt Nam.
class LocationMap extends StatelessWidget {
  const LocationMap({
    required this.latitude,
    required this.longitude,
    this.height = 220,
    this.openUrl = _launchExternal,
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;
  final OpenUrl openUrl;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_sinh_vien',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_pin,
                        size: 44,
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => openUrl(directionsUri(latitude, longitude)),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Chỉ đường'),
        ),
      ],
    );
  }
}
