import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/quan_an_filter.dart';
import '../../services/quan_an_bo_nho.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_card.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../quan_an_shell.dart';
import 'chon_diem_goc_screen.dart';
import 'quan_an_ban_do_screen.dart';
import 'quan_an_bo_loc_sheet.dart';

/// Màn hình rộng từ mức này: danh sách bên trái + bản đồ bên phải cùng lúc (mục 3.19).
const _beRongMayTinh = 840.0;

/// QA-SV-01 Sảnh — danh sách quán (và chuyển sang bản đồ QA-SV-03, dùng chung bộ lọc).
/// Màn hình rộng hiện danh sách bên trái và bản đồ bên phải cùng lúc.
class QuanAnSanhScreen extends StatefulWidget {
  const QuanAnSanhScreen({required this.dv, this.onVeTrangChu, super.key});

  final QuanAnDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  State<QuanAnSanhScreen> createState() => _QuanAnSanhScreenState();
}

class _QuanAnSanhScreenState extends State<QuanAnSanhScreen> {
  QuanAnFilter _loc = QuanAnFilter.macDinh;
  DiemGoc? _goc;
  QuanAnConfig _cfg = const QuanAnConfig();
  bool _banDo = false;
  final _tim = TextEditingController();

  @override
  void initState() {
    super.initState();
    _napBoNho();
    _napCauHinh();
  }

  Future<void> _napBoNho() async {
    final loc = await QuanAnBoNho.docLoc();
    final goc = await QuanAnBoNho.docGoc();
    if (!mounted) return;
    setState(() {
      if (loc != null) {
        _loc = QuanAnFilter.fromJson(loc).copyWith(tuKhoa: _tim.text);
      }
      if (goc != null) {
        _goc = DiemGoc(lat: goc.lat, lng: goc.lng, ten: goc.ten);
      }
    });
  }

  Future<void> _napCauHinh() async {
    try {
      final c = await widget.dv.donMon.cauHinh();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {
      // Dùng con số mặc định; hệ thống vẫn kiểm tra lại khi cần.
    }
  }

  @override
  void dispose() {
    _tim.dispose();
    super.dispose();
  }

  void _doiLoc(QuanAnFilter f) {
    setState(() => _loc = f);
    QuanAnBoNho.luuLoc(f.toJson());
  }

  void _doiTuKhoa(String s) => setState(() => _loc = _loc.copyWith(tuKhoa: s));

  void _doiGoc(DiemGoc? g) {
    setState(() => _goc = g);
    QuanAnBoNho.luuGoc(g == null ? null : (lat: g.lat, lng: g.lng, ten: g.ten));
  }

  Future<DiemGoc?> _chonGoc() async {
    final g = await QuanAnDieuHuong.mo<DiemGoc>(
      context,
      (_) => ChonDiemGocScreen(banDau: _goc),
    );
    if (g != null) _doiGoc(g);
    return g;
  }

  /// "Gần tôi": cần điểm gốc; bật thì lọc trong bán kính vừa phải và xếp gần nhất.
  Future<void> _chipGanToi(bool dangBat) async {
    if (dangBat) {
      _doiLoc(_loc.copyWith(banKinhMet: null));
      return;
    }
    if (_goc == null && await _chonGoc() == null) return;
    final r = _cfg.banKinhMet;
    _doiLoc(
      _loc.copyWith(
        sapXep: SapXepQuan.ganNhat,
        banKinhMet: r.isEmpty ? null : r[r.length ~/ 2],
      ),
    );
  }

  Future<void> _moBoLoc(List<QuanAn> quan) async {
    final f = await moBoLoc(
      context,
      loc: _loc,
      goc: _goc,
      quan: quan,
      cfg: _cfg,
      onChonGoc: _chonGoc,
    );
    if (f != null) _doiLoc(f);
  }

  @override
  Widget build(BuildContext context) {
    final rong = MediaQuery.sizeOf(context).width >= _beRongMayTinh;
    return Scaffold(
      appBar: AppBar(
        leading: NutVeTrangChu(onPressed: widget.onVeTrangChu),
        title: const Text('Khám phá quán ăn'),
        actions: [
          if (!rong)
            IconButton(
              tooltip: _banDo ? 'Xem danh sách' : 'Xem trên bản đồ',
              onPressed: () => setState(() => _banDo = !_banDo),
              icon: Icon(
                _banDo ? Icons.view_list_rounded : Icons.map_outlined,
              ),
            ),
        ],
      ),
      body: QuanAnStream<List<QuanAn>>(
        stream: widget.dv.quan.quanDangHien,
        thongBaoLoi: 'Không tải được danh sách quán',
        builder: (context, quan) {
          final kq = locQuan(
            quan: quan,
            filter: _loc,
            goc: _goc,
            cfg: _cfg,
            now: DateTime.now(),
          );
          final dauTrang = _DauTrang(
            tim: _tim,
            loc: _loc,
            goc: _goc,
            cfg: _cfg,
            soQuan: kq.length,
            onTuKhoa: _doiTuKhoa,
            onLoc: _doiLoc,
            onGanToi: _chipGanToi,
            onChonGoc: _chonGoc,
            onMoBoLoc: () => _moBoLoc(quan),
          );
          final banDo = QuanAnBanDo(
            dv: widget.dv,
            ketQua: kq,
            goc: _goc,
            banKinhMet: _loc.banKinhMet,
            onTimKhuVuc: _doiGoc,
          );
          final danhSach = _DanhSach(
            dv: widget.dv,
            ketQua: kq,
            dauTrang: dauTrang,
            onXoaLoc: () => _doiLoc(_loc.xoaLoc()),
          );
          if (rong) {
            return Row(
              children: [
                SizedBox(width: 460, child: danhSach),
                const VerticalDivider(width: 1),
                Expanded(child: banDo),
              ],
            );
          }
          if (_banDo) {
            return Column(
              children: [
                dauTrang,
                Expanded(child: banDo),
              ],
            );
          }
          return danhSach;
        },
      ),
    );
  }
}

/// Phần đầu trang: tìm kiếm, chip nhanh, điểm gốc, số kết quả + sắp xếp.
class _DauTrang extends StatelessWidget {
  const _DauTrang({
    required this.tim,
    required this.loc,
    required this.goc,
    required this.cfg,
    required this.soQuan,
    required this.onTuKhoa,
    required this.onLoc,
    required this.onGanToi,
    required this.onChonGoc,
    required this.onMoBoLoc,
  });

  final TextEditingController tim;
  final QuanAnFilter loc;
  final DiemGoc? goc;
  final QuanAnConfig cfg;
  final int soQuan;
  final ValueChanged<String> onTuKhoa;
  final ValueChanged<QuanAnFilter> onLoc;
  final Future<void> Function(bool dangBat) onGanToi;
  final Future<DiemGoc?> Function() onChonGoc;
  final VoidCallback onMoBoLoc;

  @override
  Widget build(BuildContext context) {
    Widget chip(String nhan, bool chon, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: QuanAnSpacing.sm),
      child: FilterChip(
        label: Text(nhan),
        selected: chon,
        onSelected: (_) => onTap(),
      ),
    );
    final ganToi = goc != null && loc.banKinhMet != null;
    final hocNhom = loc.tienIch.contains('hoc_nhom');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QuanAnSpacing.screen,
        QuanAnSpacing.md,
        QuanAnSpacing.screen,
        QuanAnSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tim,
                  textInputAction: TextInputAction.search,
                  onChanged: onTuKhoa,
                  decoration: InputDecoration(
                    hintText: 'Tìm quán, tên món, tên đường...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: QuanAnColors.primary,
                    ),
                    suffixIcon: tim.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa chữ đã gõ',
                            onPressed: () {
                              tim.clear();
                              onTuKhoa('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    fillColor: QuanAnColors.primaryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(QuanAnRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(QuanAnRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: QuanAnSpacing.sm),
              Badge(
                isLabelVisible: loc.dangLoc,
                backgroundColor: QuanAnColors.primary,
                smallSize: 10,
                child: IconButton.outlined(
                  tooltip: 'Bộ lọc',
                  onPressed: onMoBoLoc,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  'Đang mở',
                  loc.dangMo,
                  () => onLoc(loc.copyWith(dangMo: !loc.dangMo)),
                ),
                chip('Gần tôi', ganToi, () => onGanToi(ganToi)),
                chip(
                  'Dưới ${formatGiaGon(cfg.chipGiaReDen)}',
                  loc.chipDuoiGiaRe(cfg),
                  () => onLoc(
                    loc.chipDuoiGiaRe(cfg)
                        ? loc.copyWith(giaTu: null, giaDen: null)
                        : loc.copyWith(giaTu: null, giaDen: cfg.chipGiaReDen),
                  ),
                ),
                chip(
                  'Đặt món',
                  loc.giaoHang,
                  () => onLoc(loc.copyWith(giaoHang: !loc.giaoHang)),
                ),
                chip(
                  'Khuyến mãi',
                  loc.coKhuyenMai,
                  () => onLoc(loc.copyWith(coKhuyenMai: !loc.coKhuyenMai)),
                ),
                chip('Học nhóm', hocNhom, () {
                  final t = {...loc.tienIch};
                  hocNhom ? t.remove('hoc_nhom') : t.add('hoc_nhom');
                  onLoc(loc.copyWith(tienIch: t));
                }),
              ],
            ),
          ),
          InkWell(
            onTap: onChonGoc,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 18,
                    color: QuanAnColors.primary,
                  ),
                  const SizedBox(width: QuanAnSpacing.xs),
                  Expanded(
                    child: Text(
                      goc == null
                          ? 'Chọn điểm gốc để tính khoảng cách'
                          : 'Điểm gốc: ${goc!.ten.isEmpty ? 'đã chọn' : goc!.ten}',
                      style: QuanAnText.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: QuanAnSpacing.sm),
                  const Text(
                    'Đổi',
                    style: TextStyle(
                      color: QuanAnColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text('$soQuan quán phù hợp', style: QuanAnText.label),
              ),
              const SizedBox(width: QuanAnSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: DropdownButton<SapXepQuan>(
                  value: loc.sapXep,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  selectedItemBuilder: (_) => [
                    for (final s in SapXepQuan.values)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Sắp xếp: ${s.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  items: [
                    for (final s in SapXepQuan.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (s) =>
                      s == null ? null : onLoc(loc.copyWith(sapXep: s)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Danh sách thẻ quán cuộn được, kèm [dauTrang] ở trên; rỗng thì hiện gợi ý xóa bộ lọc.
class _DanhSach extends StatelessWidget {
  const _DanhSach({
    required this.dv,
    required this.ketQua,
    required this.dauTrang,
    required this.onXoaLoc,
  });

  final QuanAnDichVu dv;
  final List<KetQuaQuan> ketQua;
  final Widget dauTrang;
  final VoidCallback onXoaLoc;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: dauTrang),
      if (ketQua.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: QuanAnEmptyState(
            title: 'Không tìm thấy quán phù hợp',
            message: 'Thử bỏ bớt bộ lọc hoặc tăng bán kính.',
            actionLabel: 'Xóa bộ lọc',
            onAction: onXoaLoc,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            QuanAnSpacing.screen,
            0,
            QuanAnSpacing.screen,
            QuanAnSpacing.xxxl,
          ),
          sliver: SliverList.separated(
            itemCount: ketQua.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: QuanAnSpacing.cardGap),
            itemBuilder: (context, i) {
              final k = ketQua[i];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: QuanAnCard(
                    ketQua: k,
                    nutLuu: NutLuuQuan(
                      dv: dv,
                      quanId: k.quan.id,
                      chuQuanId: k.quan.chuQuanId,
                    ),
                    onTap: () => QuanAnDieuHuong.quan(context, dv, k.quan.id),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}
