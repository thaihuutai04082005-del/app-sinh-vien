import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/quan_an_filter.dart';
import '../../widgets/quan_an_theme.dart';

/// Lấy vị trí hiện tại. Không cho phép định vị → null (app gợi ý chọn trên bản đồ, mục 3.7).
Future<DiemGoc?> viTriHienTai() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var quyen = await Geolocator.checkPermission();
    if (quyen == LocationPermission.denied) {
      quyen = await Geolocator.requestPermission();
    }
    if (quyen == LocationPermission.denied ||
        quyen == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return DiemGoc(lat: p.latitude, lng: p.longitude, ten: 'Vị trí hiện tại');
  } catch (_) {
    return null;
  }
}

/// Tìm địa chỉ trên OpenStreetMap (Nominatim) — không cần API key.
Future<List<DiemGoc>> timDiaChi(String q) async {
  if (q.trim().length < 3) return const [];
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': q,
    'format': 'json',
    'limit': '5',
    'countrycodes': 'vn',
    'accept-language': 'vi',
  });
  try {
    final r = await http.get(uri);
    if (r.statusCode != 200) return const [];
    final ds = jsonDecode(r.body) as List;
    return [
      for (final x in ds)
        DiemGoc(
          lat: double.parse(x['lat'] as String),
          lng: double.parse(x['lon'] as String),
          ten: x['display_name'] as String? ?? '',
        ),
    ];
  } catch (_) {
    return const [];
  }
}

/// Chọn điểm gốc để tính khoảng cách (mục 3.7): vị trí hiện tại, hoặc gõ địa chỉ / kéo bản đồ
/// để đặt ghim. Cũng dùng để chọn địa chỉ giao hàng. Trả về [DiemGoc] qua `Navigator.pop`.
class ChonDiemGocScreen extends StatefulWidget {
  const ChonDiemGocScreen({
    this.banDau,
    this.tieuDe = 'Chọn điểm gốc',
    this.choPhepViTriHienTai = true,
    super.key,
  });

  final DiemGoc? banDau;
  final String tieuDe;
  final bool choPhepViTriHienTai;

  @override
  State<ChonDiemGocScreen> createState() => _ChonDiemGocScreenState();
}

class _ChonDiemGocScreenState extends State<ChonDiemGocScreen> {
  static const _macDinh = LatLng(10.4599, 105.6377); // Cao Lãnh, Đồng Tháp
  final _map = MapController();
  final _tim = TextEditingController();
  late LatLng _tam = widget.banDau == null
      ? _macDinh
      : LatLng(widget.banDau!.lat, widget.banDau!.lng);
  List<DiemGoc> _goiY = const [];
  bool _dangTim = false;
  bool _dangLayViTri = false;
  String? _thongBao;

  @override
  void dispose() {
    _tim.dispose();
    super.dispose();
  }

  Future<void> _viTriHienTai() async {
    setState(() {
      _thongBao = null;
      _dangLayViTri = true;
    });
    final g = await viTriHienTai();
    if (!mounted) return;
    if (g == null) {
      setState(() {
        _dangLayViTri = false;
        _thongBao = 'Không lấy được vị trí (chưa cho phép định vị). Hãy gõ địa chỉ hoặc kéo bản đồ để chọn điểm.';
      });
      return;
    }
    Navigator.pop(context, g);
  }

  Future<void> _timDiaChi() async {
    setState(() => _dangTim = true);
    final ds = await timDiaChi(_tim.text);
    if (!mounted) return;
    setState(() {
      _dangTim = false;
      _goiY = ds;
      _thongBao = ds.isEmpty
          ? 'Không tìm thấy địa chỉ, thử gõ cụ thể hơn hoặc kéo bản đồ.'
          : null;
    });
  }

  void _chonGoiY(DiemGoc g) {
    setState(() {
      _goiY = const [];
      _tam = LatLng(g.lat, g.lng);
    });
    _map.move(_tam, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    minVerticalPadding: QuanAnSpacing.sm,
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
                if (widget.choPhepViTriHienTai) ...[
                  const SizedBox(height: QuanAnSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _dangLayViTri ? null : _viTriHienTai,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _dangLayViTri
                            ? 'Đang lấy vị trí...'
                            : 'Dùng vị trí hiện tại',
                      ),
                    ),
                  ),
                ],
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
                    initialZoom: 15,
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
                const Positioned(
                  top: QuanAnSpacing.sm,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(QuanAnSpacing.sm),
                      child: Text('Kéo bản đồ để đặt ghim vào giữa'),
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
                    DiemGoc(
                      lat: _tam.latitude,
                      lng: _tam.longitude,
                      ten: _tim.text.trim().isEmpty
                          ? 'Điểm đã chọn trên bản đồ'
                          : _tim.text.trim(),
                    ),
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
}
