import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/tro_filter.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/nha_tro_card.dart';
import '../../widgets/tro_map_marker.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';

/// Gom các nhà trọ gần nhau thành cụm theo lưới, kích thước ô tùy mức zoom (~60 px).
List<List<KetQuaNhaTro>> gomCum(List<KetQuaNhaTro> ds, double zoom) {
  final o = 360 / math.pow(2, zoom) * (60 / 256);
  final cum = <String, List<KetQuaNhaTro>>{};
  for (final k in ds) {
    final v = k.nhaTro.viTri;
    if (v == null) continue;
    final khoa = '${(v.latitude / o).floor()}_${(v.longitude / o).floor()}';
    cum.putIfAbsent(khoa, () => []).add(k);
  }
  return cum.values.toList();
}

/// TRO-SV-04 Sảnh — bản đồ: ghim hiện giá, xanh = còn phòng, xám = hết phòng; ghim gần nhau gom cụm;
/// bấm ghim hiện thẻ nhỏ; kéo bản đồ sang chỗ khác hiện nút "Tìm ở khu vực này".
class TroBanDo extends StatefulWidget {
  const TroBanDo({
    required this.dv,
    required this.ketQua,
    required this.goc,
    required this.banKinhMet,
    required this.onTimKhuVuc,
    super.key,
  });

  final TroDichVu dv;
  final KetQuaLoc ketQua;
  final DiemGoc? goc;
  final int? banKinhMet;
  final ValueChanged<DiemGoc> onTimKhuVuc;

  @override
  State<TroBanDo> createState() => _TroBanDoState();
}

class _TroBanDoState extends State<TroBanDo> {
  final _map = MapController();
  double _zoom = 14;
  LatLng? _tam;
  bool _daKeo = false;
  KetQuaNhaTro? _chon;

  LatLng get _tamBanDau {
    final g = widget.goc;
    if (g != null) return LatLng(g.lat, g.lng);
    final co = widget.ketQua.danhSach.where((k) => k.nhaTro.viTri != null);
    if (co.isNotEmpty) {
      final v = co.first.nhaTro.viTri!;
      return LatLng(v.latitude, v.longitude);
    }
    return const LatLng(10.4599, 105.6377);
  }

  @override
  Widget build(BuildContext context) {
    final cacCum = gomCum(widget.ketQua.danhSach, _zoom);
    final g = widget.goc;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _tamBanDau,
            initialZoom: _zoom,
            onTap: (_, _) => setState(() => _chon = null),
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
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(g.lat, g.lng),
                    radius: widget.banKinhMet!.toDouble(),
                    useRadiusInMeter: true,
                    color: TroColors.primary.withValues(alpha: 0.08),
                    borderColor: TroColors.primary,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (g != null)
                  Marker(
                    point: LatLng(g.lat, g.lng),
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TroColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: TroColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: TroColors.accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final c in cacCum)
                  if (c.length == 1)
                    Marker(
                      point: LatLng(
                        c.first.nhaTro.viTri!.latitude,
                        c.first.nhaTro.viTri!.longitude,
                      ),
                      width: 120,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => setState(() => _chon = c.first),
                        child: Center(
                          child: TroMapMarker(
                            gia: c.first.giaThapNhat,
                            conPhong: !c.first.hetPhong,
                            dangChon: identical(_chon, c.first),
                          ),
                        ),
                      ),
                    )
                  else
                    Marker(
                      point: LatLng(
                        c
                                .map((k) => k.nhaTro.viTri!.latitude)
                                .reduce((a, b) => a + b) /
                            c.length,
                        c
                                .map((k) => k.nhaTro.viTri!.longitude)
                                .reduce((a, b) => a + b) /
                            c.length,
                      ),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _map.move(
                          LatLng(
                            c.first.nhaTro.viTri!.latitude,
                            c.first.nhaTro.viTri!.longitude,
                          ),
                          math.min(_zoom + 2, 18),
                        ),
                        child: TroMapCluster(soLuong: c.length),
                      ),
                    ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        if (_daKeo && _tam != null)
          Positioned(
            top: TroSpacing.md,
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
        if (_chon != null)
          Positioned(
            left: TroSpacing.md,
            right: TroSpacing.md,
            bottom: TroSpacing.md,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: NhaTroCard(
                  ketQua: _chon!,
                  onTap: () => TroDieuHuong.nhaTro(
                    context,
                    widget.dv,
                    _chon!.nhaTro.id,
                    phongPhuHop: {for (final p in _chon!.phongPhuHop) p.id},
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
