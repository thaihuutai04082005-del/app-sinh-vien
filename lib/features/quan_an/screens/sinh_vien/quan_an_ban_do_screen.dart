import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/quan_an_filter.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_card.dart';
import '../../widgets/quan_an_map_marker.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';

/// Gom các quán gần nhau thành cụm theo lưới, kích thước ô tùy mức zoom (~60 px).
/// Quán chưa có vị trí bị bỏ qua.
List<List<KetQuaQuan>> gomCumQuan(List<KetQuaQuan> ds, double zoom) {
  final o = 360 / math.pow(2, zoom) * (60 / 256);
  final cum = <String, List<KetQuaQuan>>{};
  for (final k in ds) {
    final v = k.quan.viTri;
    if (v == null) continue;
    final khoa = '${(v.latitude / o).floor()}_${(v.longitude / o).floor()}';
    cum.putIfAbsent(khoa, () => []).add(k);
  }
  return cum.values.toList();
}

/// Các điểm của vòng tròn bán kính [met] mét quanh [tam] (để vẽ viền nét đứt).
List<LatLng> _vongTron(LatLng tam, double met) {
  const soDiem = 72;
  final dLat = met / 111320;
  final dLng = met / (111320 * math.cos(tam.latitude * math.pi / 180));
  return [
    for (var i = 0; i < soDiem; i++)
      LatLng(
        tam.latitude + dLat * math.sin(2 * math.pi * i / soDiem),
        tam.longitude + dLng * math.cos(2 * math.pi * i / soDiem),
      ),
  ];
}

/// QA-SV-03 Sảnh — bản đồ: ghim viên thuốc hiện khoảng giá, xanh = đang mở, xám = đã đóng;
/// ghim gần nhau gom cụm; chạm ghim hiện thẻ nhỏ; kéo bản đồ sang chỗ khác hiện nút "Tìm ở khu vực này".
class QuanAnBanDo extends StatefulWidget {
  const QuanAnBanDo({
    required this.dv,
    required this.ketQua,
    required this.goc,
    required this.banKinhMet,
    required this.onTimKhuVuc,
    super.key,
  });

  final QuanAnDichVu dv;
  final List<KetQuaQuan> ketQua;
  final DiemGoc? goc;
  final int? banKinhMet;
  final ValueChanged<DiemGoc> onTimKhuVuc;

  @override
  State<QuanAnBanDo> createState() => _QuanAnBanDoState();
}

class _QuanAnBanDoState extends State<QuanAnBanDo> {
  static const _macDinh = LatLng(10.4599, 105.6377); // Cao Lãnh, Đồng Tháp
  final _map = MapController();
  double _zoom = 14;
  LatLng? _tam;
  bool _daKeo = false;
  String? _chonId;

  LatLng get _tamBanDau {
    final g = widget.goc;
    if (g != null) return LatLng(g.lat, g.lng);
    for (final k in widget.ketQua) {
      final v = k.quan.viTri;
      if (v != null) return LatLng(v.latitude, v.longitude);
    }
    return _macDinh;
  }

  @override
  void didUpdateWidget(QuanAnBanDo old) {
    super.didUpdateWidget(old);
    final g = widget.goc;
    if (g != null && (old.goc?.lat != g.lat || old.goc?.lng != g.lng)) {
      // Đổi điểm gốc (từ màn chọn điểm): đưa bản đồ về điểm mới.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.move(LatLng(g.lat, g.lng), _zoom);
      });
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  KetQuaQuan? get _chon {
    for (final k in widget.ketQua) {
      if (k.quan.id == _chonId) return k;
    }
    return null;
  }

  Marker _ghim(KetQuaQuan k) {
    final v = k.quan.viTri!;
    final sl = k.quan.soLieu;
    return Marker(
      point: LatLng(v.latitude, v.longitude),
      width: 120,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _chonId = k.quan.id),
        child: Center(
          child: QuanAnMapMarker.theoGia(
            giaTu: sl.giaP25,
            giaDen: sl.giaP75,
            dangMo: k.dangMo,
            dangChon: k.quan.id == _chonId,
          ),
        ),
      ),
    );
  }

  Marker _cum(List<KetQuaQuan> c) {
    final lat =
        c.map((k) => k.quan.viTri!.latitude).reduce((a, b) => a + b) / c.length;
    final lng =
        c.map((k) => k.quan.viTri!.longitude).reduce((a, b) => a + b) /
        c.length;
    return Marker(
      point: LatLng(lat, lng),
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _map.move(LatLng(lat, lng), math.min(_zoom + 2, 18)),
        child: Semantics(
          button: true,
          label: 'Cụm ${c.length} quán, bấm để phóng to',
          child: QuanAnMapCluster(soLuong: c.length),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacCum = gomCumQuan(widget.ketQua, _zoom);
    final g = widget.goc;
    final chon = _chon;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _tamBanDau,
            initialZoom: _zoom,
            onTap: (_, _) => setState(() => _chonId = null),
            onPositionChanged: (cam, coTay) => setState(() {
              _zoom = cam.zoom;
              _tam = cam.center;
              if (coTay) _daKeo = true;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app_sinh_vien',
            ),
            if (g != null && widget.banKinhMet != null)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _vongTron(
                      LatLng(g.lat, g.lng),
                      widget.banKinhMet!.toDouble(),
                    ),
                    color: QuanAnColors.primary.withValues(alpha: 0.08),
                    borderColor: QuanAnColors.primary,
                    borderStrokeWidth: 1.5,
                    pattern: const StrokePattern.dashed(segments: [8, 6]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (g != null)
                  Marker(
                    point: LatLng(g.lat, g.lng),
                    width: 48,
                    height: 48,
                    child: const QuanAnDiemGoc(kichThuoc: 20),
                  ),
                for (final c in cacCum) c.length == 1 ? _ghim(c.first) : _cum(c),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        if (_daKeo && _tam != null)
          Positioned(
            top: QuanAnSpacing.md,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.icon(
                onPressed: () {
                  widget.onTimKhuVuc(
                    DiemGoc(
                      lat: _tam!.latitude,
                      lng: _tam!.longitude,
                      ten: 'Khu vực trên bản đồ',
                    ),
                  );
                  setState(() => _daKeo = false);
                },
                icon: const Icon(Icons.search),
                label: const Text('Tìm ở khu vực này'),
              ),
            ),
          ),
        if (cacCum.isEmpty && chon == null)
          const Positioned(
            left: QuanAnSpacing.md,
            right: QuanAnSpacing.md,
            bottom: QuanAnSpacing.xxxl,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(QuanAnSpacing.md),
                  child: Text(
                    'Không có quán phù hợp trên bản đồ. Thử nới bộ lọc hoặc kéo sang khu vực khác.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        if (chon != null)
          Positioned(
            left: QuanAnSpacing.md,
            right: QuanAnSpacing.md,
            bottom: QuanAnSpacing.md,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: QuanAnCard(
                  ketQua: chon,
                  nutLuu: NutLuuQuan(
                    dv: widget.dv,
                    quanId: chon.quan.id,
                    chuQuanId: chon.quan.chuQuanId,
                  ),
                  onTap: () =>
                      QuanAnDieuHuong.quan(context, widget.dv, chon.quan.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
