import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../widgets/quan_an_theme.dart';

/// Ghim vị trí quán trên bản đồ (OpenStreetMap, không cần API key): gõ địa chỉ để tìm,
/// dùng vị trí hiện tại, hoặc kéo bản đồ để đặt ghim vào giữa. Trả về [GeoPoint] khi bấm
/// "Chọn điểm này". Dùng ở form đăng quán và màn sửa thông tin quán.
class ChonViTriQuanScreen extends StatefulWidget {
  const ChonViTriQuanScreen({
    this.banDau,
    this.tieuDe = 'Ghim vị trí quán',
    this.goiY,
    super.key,
  });

  final GeoPoint? banDau;
  final String tieuDe;

  /// Dòng nhắc trên bản đồ, ví dụ "Ghim đúng cửa quán".
  final String? goiY;

  @override
  State<ChonViTriQuanScreen> createState() => _ChonViTriQuanScreenState();
}

class _GoiY {
  const _GoiY(this.ten, this.lat, this.lng);

  final String ten;
  final double lat;
  final double lng;
}

class _ChonViTriQuanScreenState extends State<ChonViTriQuanScreen> {
  static const _macDinh = LatLng(10.4599, 105.6377); // Cao Lãnh, Đồng Tháp
  final _map = MapController();
  final _tim = TextEditingController();
  late LatLng _tam = widget.banDau == null
      ? _macDinh
      : LatLng(widget.banDau!.latitude, widget.banDau!.longitude);
  List<_GoiY> _goiY = const [];
  bool _dangTim = false;
  String? _thongBao;

  @override
  void dispose() {
    _tim.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _viTriHienTai() async {
    setState(() => _thongBao = null);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception();
      var quyen = await Geolocator.checkPermission();
      if (quyen == LocationPermission.denied) {
        quyen = await Geolocator.requestPermission();
      }
      if (quyen == LocationPermission.denied ||
          quyen == LocationPermission.deniedForever) {
        throw Exception();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _tam = LatLng(p.latitude, p.longitude));
      _map.move(_tam, 17);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _thongBao = 'Không lấy được vị trí (chưa cho phép định vị). Hãy gõ địa chỉ hoặc kéo bản đồ để chọn điểm.',
      );
    }
  }

  Future<void> _timDiaChi() async {
    final q = _tim.text.trim();
    if (q.length < 3) {
      setState(() => _thongBao = 'Gõ ít nhất 3 ký tự để tìm.');
      return;
    }
    setState(() {
      _dangTim = true;
      _thongBao = null;
    });
    var ds = <_GoiY>[];
    try {
      final r = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': q,
          'format': 'json',
          'limit': '5',
          'countrycodes': 'vn',
          'accept-language': 'vi',
        }),
      );
      if (r.statusCode == 200) {
        ds = [
          for (final x in jsonDecode(r.body) as List)
            _GoiY(
              x['display_name'] as String? ?? '',
              double.parse(x['lat'] as String),
              double.parse(x['lon'] as String),
            ),
        ];
      }
    } catch (_) {
      ds = [];
    }
    if (!mounted) return;
    setState(() {
      _dangTim = false;
      _goiY = ds;
      _thongBao = ds.isEmpty
          ? 'Không tìm thấy địa chỉ, thử gõ cụ thể hơn hoặc kéo bản đồ.'
          : null;
    });
  }

  void _chonGoiY(_GoiY g) {
    setState(() {
      _goiY = const [];
      _tam = LatLng(g.lat, g.lng);
    });
    _map.move(_tam, 17);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.tieuDe)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(QuanAnSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tim,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _timDiaChi(),
                      decoration: const InputDecoration(
                        hintText: 'Gõ địa chỉ, tên đường, phường...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  OutlinedButton(
                    onPressed: _dangTim ? null : _timDiaChi,
                    child: Text(_dangTim ? '...' : 'Tìm'),
                  ),
                ],
              ),
              for (final g in _goiY)
                ListTile(
                  dense: true,
                  minVerticalPadding: 12,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: QuanAnColors.primary,
                  ),
                  title: Text(
                    g.ten,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _chonGoiY(g),
                ),
              const SizedBox(height: QuanAnSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viTriHienTai,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Dùng vị trí hiện tại'),
                ),
              ),
              if (_thongBao != null)
                Padding(
                  padding: const EdgeInsets.only(top: QuanAnSpacing.sm),
                  child: Text(
                    _thongBao!,
                    style: const TextStyle(color: QuanAnColors.warning),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _tam,
                  initialZoom: 16,
                  onPositionChanged: (cam, _) => _tam = cam.center,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_sinh_vien',
                  ),
                  const SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
              const IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(
                    Icons.location_pin,
                    size: 44,
                    color: QuanAnColors.primary,
                  ),
                ),
              ),
              Positioned(
                top: QuanAnSpacing.sm,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(QuanAnSpacing.sm),
                    child: Text(
                      widget.goiY ?? 'Kéo bản đồ để đặt ghim vào giữa',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.screen),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  GeoPoint(_tam.latitude, _tam.longitude),
                ),
                child: const Text('Chọn điểm này'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
