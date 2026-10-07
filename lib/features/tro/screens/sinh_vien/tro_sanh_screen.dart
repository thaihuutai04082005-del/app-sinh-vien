import 'package:flutter/material.dart';

import '../../models/nha_tro.dart';
import '../../models/phong_tro.dart';
import '../../models/tro_filter.dart';
import '../../services/tro_bo_nho.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/nha_tro_card.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tro_shell.dart';
import 'chon_diem_goc_screen.dart';
import 'tro_ban_do_screen.dart';
import 'tro_bo_loc_sheet.dart';

/// TRO-SV-01 Sảnh — danh sách (và chuyển sang bản đồ TRO-SV-04, dùng chung bộ lọc).
class TroSanhScreen extends StatefulWidget {
  const TroSanhScreen({required this.dv, this.onVeTrangChu, super.key});

  final TroDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  State<TroSanhScreen> createState() => _TroSanhScreenState();
}

class _TroSanhScreenState extends State<TroSanhScreen> {
  TroFilter _loc = TroFilter.macDinh;
  DiemGoc? _goc;
  bool _banDo = false;
  final _tim = TextEditingController();

  @override
  void initState() {
    super.initState();
    TroBoNho.docLoc().then((f) => mounted ? setState(() => _loc = f) : null);
    TroBoNho.docGoc().then((g) => mounted ? setState(() => _goc = g) : null);
  }

  @override
  void dispose() {
    _tim.dispose();
    super.dispose();
  }

  void _doiLoc(TroFilter f) {
    setState(() => _loc = f);
    TroBoNho.luuLoc(f);
  }

  void _doiGoc(DiemGoc? g) {
    setState(() => _goc = g);
    TroBoNho.luuGoc(g);
  }

  Future<void> _chonGoc() async {
    final g = await TroDieuHuong.mo<DiemGoc>(
      context,
      (_) => ChonDiemGocScreen(banDau: _goc),
    );
    if (g != null) _doiGoc(g);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: NutVeTrangChu(onPressed: widget.onVeTrangChu),
        title: const Text('Tìm trọ'),
        actions: [
          IconButton(
            tooltip: _banDo ? 'Xem danh sách' : 'Xem trên bản đồ',
            onPressed: () => setState(() => _banDo = !_banDo),
            icon: Icon(_banDo ? Icons.view_list_rounded : Icons.map_outlined),
          ),
        ],
      ),
      body: TroStream<List<NhaTro>>(
        stream: widget.dv.nhaTro.nhaTroDangHien,
        builder: (context, nha) => TroStream<List<PhongTro>>(
          stream: widget.dv.nhaTro.phongConTrong,
          builder: (context, phong) {
            final kq = locNhaTro(
              nhaTro: nha,
              phong: phong,
              filter: _loc,
              goc: _goc,
            );
            final dauTrang = _DauTrang(
              tim: _tim,
              loc: _loc,
              goc: _goc,
              ketQua: kq,
              onLoc: _doiLoc,
              onChonGoc: _chonGoc,
              onMoBoLoc: () async {
                final f = await moBoLoc(
                  context,
                  loc: _loc,
                  goc: _goc,
                  nhaTro: nha,
                  phong: phong,
                  onChonGoc: _chonGoc,
                );
                if (f != null) _doiLoc(f);
              },
            );
            if (_banDo) {
              return Column(
                children: [
                  dauTrang,
                  Expanded(
                    child: TroBanDo(
                      dv: widget.dv,
                      ketQua: kq,
                      goc: _goc,
                      banKinhMet: _loc.banKinhMet,
                      onTimKhuVuc: (g) => _doiGoc(g),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: dauTrang),
                if (kq.danhSach.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: TroEmptyState(
                      title: 'Không tìm thấy nhà trọ phù hợp',
                      message: 'Thử nới khoảng giá hoặc tăng bán kính.',
                      actionLabel: 'Xóa bộ lọc',
                      onAction: () => _doiLoc(_loc.xoaLoc()),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      TroSpacing.screen,
                      0,
                      TroSpacing.screen,
                      TroSpacing.xxxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: kq.danhSach.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: TroSpacing.cardGap),
                      itemBuilder: (context, i) {
                        final k = kq.danhSach[i];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: NhaTroCard(
                              ketQua: k,
                              dangLoc: _loc.dangLoc,
                              nutLuu: NutLuuNhaTro(
                                dv: widget.dv,
                                nhaTroId: k.nhaTro.id,
                                chuTroId: k.nhaTro.chuTroId,
                              ),
                              onTap: () => TroDieuHuong.nhaTro(
                                context,
                                widget.dv,
                                k.nhaTro.id,
                                phongPhuHop: _loc.dangLoc
                                    ? {for (final p in k.phongPhuHop) p.id}
                                    : const {},
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DauTrang extends StatelessWidget {
  const _DauTrang({
    required this.tim,
    required this.loc,
    required this.goc,
    required this.ketQua,
    required this.onLoc,
    required this.onChonGoc,
    required this.onMoBoLoc,
  });

  final TextEditingController tim;
  final TroFilter loc;
  final DiemGoc? goc;
  final KetQuaLoc ketQua;
  final ValueChanged<TroFilter> onLoc;
  final VoidCallback onChonGoc;
  final VoidCallback onMoBoLoc;

  @override
  Widget build(BuildContext context) {
    Widget chip(String nhan, bool chon, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: TroSpacing.sm),
      child: FilterChip(
        label: Text(nhan),
        selected: chon,
        onSelected: (_) => onTap(),
      ),
    );
    final duoi2 = loc.giaDen == 2000000 && loc.giaTu == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TroSpacing.screen,
        TroSpacing.md,
        TroSpacing.screen,
        TroSpacing.md,
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
                  onChanged: (s) => onLoc(loc.copyWith(tuKhoa: s)),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên trọ, tên đường, phường...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: TroColors.primary,
                    ),
                    filled: true,
                    fillColor: TroColors.primaryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TroRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TroRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TroSpacing.sm),
              Badge(
                isLabelVisible: loc.dangLoc,
                backgroundColor: TroColors.primary,
                smallSize: 10,
                child: IconButton.outlined(
                  tooltip: 'Bộ lọc',
                  onPressed: onMoBoLoc,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: TroSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  'Gần tôi',
                  loc.sapXep == SapXep.ganNhat && goc != null,
                  () {
                    if (goc == null) {
                      onChonGoc();
                    } else {
                      onLoc(loc.copyWith(sapXep: SapXep.ganNhat));
                    }
                  },
                ),
                chip(
                  'Dưới 2tr',
                  duoi2,
                  () => onLoc(
                    duoi2
                        ? loc.copyWith(giaDen: null)
                        : loc.copyWith(giaTu: null, giaDen: 2000000),
                  ),
                ),
                chip(
                  'Có gác',
                  loc.coGac == true,
                  () => onLoc(
                    loc.coGac == true
                        ? loc.copyWith(coGac: null)
                        : loc.copyWith(loaiHinh: 'phong', coGac: true),
                  ),
                ),
                chip('Máy lạnh', loc.tienIch.contains('may_lanh'), () {
                  final t = {...loc.tienIch};
                  t.contains('may_lanh')
                      ? t.remove('may_lanh')
                      : t.add('may_lanh');
                  onLoc(loc.copyWith(tienIch: t));
                }),
                chip(
                  'Còn phòng',
                  loc.chiConPhong,
                  () => onLoc(loc.copyWith(chiConPhong: !loc.chiConPhong)),
                ),
              ],
            ),
          ),
          const SizedBox(height: TroSpacing.xs),
          InkWell(
            onTap: onChonGoc,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TroSpacing.xs),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 18,
                    color: TroColors.primary,
                  ),
                  const SizedBox(width: TroSpacing.xs),
                  Expanded(
                    child: Text(
                      goc == null
                          ? 'Chọn điểm gốc để tính khoảng cách'
                          : 'Điểm gốc: ${goc!.ten.isEmpty ? 'đã chọn' : goc!.ten}',
                      style: TroText.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'Đổi',
                    style: TextStyle(
                      color: TroColors.primary,
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
                child: Text(
                  '${ketQua.soNhaTro} nhà trọ · ${ketQua.soPhong} phòng phù hợp',
                  style: TroText.label,
                ),
              ),
              DropdownButton<SapXep>(
                value: loc.sapXep,
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in SapXep.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) =>
                    s == null ? null : onLoc(loc.copyWith(sapXep: s)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nút ❤️ lưu nhà trọ (chủ trọ không lưu được nhà trọ của mình).
class NutLuuNhaTro extends StatelessWidget {
  const NutLuuNhaTro({
    required this.dv,
    required this.nhaTroId,
    required this.chuTroId,
    super.key,
  });

  final TroDichVu dv;
  final String nhaTroId;
  final String chuTroId;

  @override
  Widget build(BuildContext context) {
    if (chuTroId == dv.uid) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: dv.nhaTro.daLuu(dv.uid, nhaTroId),
      builder: (context, s) {
        final luu = s.data ?? false;
        return IconButton(
          tooltip: luu ? 'Bỏ lưu' : 'Lưu nhà trọ',
          style: IconButton.styleFrom(
            backgroundColor: TroColors.white,
            fixedSize: const Size(40, 40),
          ),
          onPressed: () => chayThaoTac(
            context,
            () => dv.nhaTro.luu(dv.uid, nhaTroId, luu: !luu),
            thanhCong: luu ? 'Đã bỏ lưu' : 'Đã lưu nhà trọ — bạn sẽ được báo khi có phòng trống hoặc giảm giá',
          ),
          icon: Icon(
            luu ? Icons.favorite : Icons.favorite_border,
            color: luu ? TroColors.danger : TroColors.primary,
          ),
        );
      },
    );
  }
}
