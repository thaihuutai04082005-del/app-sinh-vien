import 'package:flutter/material.dart';

import '../models/thong_bao.dart';
import '../models/tin_nhan.dart';
import '../services/tro_dich_vu.dart';
import '../widgets/tro_theme.dart';
import 'sinh_vien/cua_toi_tro_screen.dart';
import 'sinh_vien/tro_sanh_screen.dart';
import 'tuong_tac/chat_screen.dart';
import 'tuong_tac/thong_bao_screen.dart';

/// Khung của module Tìm trọ: thanh điều hướng riêng 4 mục (mục 2.19 "Điều hướng").
/// Tin nhắn, thông báo chỉ của Tìm trọ. Màn rộng chuyển thanh điều hướng sang cột trái.
class TroShell extends StatefulWidget {
  const TroShell({required this.dv, this.tabBanDau = 0, super.key});

  final TroDichVu dv;
  final int tabBanDau;

  @override
  State<TroShell> createState() => _TroShellState();
}

class _TroShellState extends State<TroShell> {
  late int _tab = widget.tabBanDau;
  late final Stream<List<CuocTroChuyen>> _chat = widget.dv.chat.cuocCuaToi(
    widget.dv.uid,
  );
  late final Stream<List<ThongBao>> _tb = widget.dv.thongBao.cuaToi(
    widget.dv.uid,
  );

  void _veTrangChu() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final man = [
      TroSanhScreen(dv: widget.dv, onVeTrangChu: _veTrangChu),
      ChatListScreen(dv: widget.dv, onVeTrangChu: _veTrangChu),
      ThongBaoScreen(dv: widget.dv, onVeTrangChu: _veTrangChu),
      CuaToiTroScreen(dv: widget.dv, onVeTrangChu: _veTrangChu),
    ];
    return StreamBuilder<List<CuocTroChuyen>>(
      stream: _chat,
      builder: (context, chat) => StreamBuilder<List<ThongBao>>(
        stream: _tb,
        builder: (context, tb) {
          final soChat = (chat.data ?? const [])
              .where((c) => c.chuaDocCua(widget.dv.uid) > 0)
              .length;
          final soTb = (tb.data ?? const []).where((t) => !t.daDoc).length;
          Widget icon(IconData vien, IconData dac, int so, bool chon) {
            final i = Icon(chon ? dac : vien);
            return so == 0
                ? i
                : Badge(
                    backgroundColor: TroColors.danger,
                    label: Text('$so'),
                    child: i,
                  );
          }

          final muc = [
            (Icons.search_outlined, Icons.search, 'Khám phá', 0),
            (Icons.chat_bubble_outline, Icons.chat_bubble, 'Tin nhắn', soChat),
            (Icons.notifications_none, Icons.notifications, 'Thông báo', soTb),
            (Icons.person_outline, Icons.person, 'Của tôi', 0),
          ];
          final rong = MediaQuery.sizeOf(context).width >= 840;
          final noiDung = IndexedStack(index: _tab, children: man);
          if (rong) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _tab,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    labelType: NavigationRailLabelType.all,
                    leading: IconButton(
                      tooltip: 'Về trang chủ',
                      onPressed: _veTrangChu,
                      icon: const Icon(Icons.apps_rounded),
                    ),
                    destinations: [
                      for (var i = 0; i < muc.length; i++)
                        NavigationRailDestination(
                          icon: icon(
                            muc[i].$1,
                            muc[i].$2,
                            muc[i].$4,
                            _tab == i,
                          ),
                          label: Text(muc[i].$3),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: noiDung),
                ],
              ),
            );
          }
          return Scaffold(
            body: noiDung,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              backgroundColor: TroColors.white,
              indicatorColor: TroColors.primaryLight,
              destinations: [
                for (var i = 0; i < muc.length; i++)
                  NavigationDestination(
                    icon: icon(muc[i].$1, muc[i].$2, muc[i].$4, _tab == i),
                    label: muc[i].$3,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Nút về trang chủ app (lưới module) — đặt ở góc trên mỗi tab.
class NutVeTrangChu extends StatelessWidget {
  const NutVeTrangChu({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Về trang chủ',
    onPressed: onPressed,
    icon: const Icon(Icons.apps_rounded),
  );
}
