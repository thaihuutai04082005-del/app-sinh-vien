import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/tin_nhan.dart';
import '../../services/tro_dich_vu.dart';
import '../../widgets/tro_async.dart';
import '../../widgets/tro_states.dart';
import '../../widgets/tro_theme.dart';
import '../tro_routes.dart';
import '../tro_shell.dart';
import 'bao_cao_khang_nghi_screen.dart';

/// TRO-SV-13 Chat của module — danh sách cuộc trò chuyện (riêng Tìm trọ, không lẫn module khác).
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({required this.dv, this.onVeTrangChu, super.key});

  final TroDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: NutVeTrangChu(onPressed: onVeTrangChu),
      title: const Text('Tin nhắn'),
    ),
    body: TroStream<List<CuocTroChuyen>>(
      stream: () => dv.chat.cuocCuaToi(dv.uid),
      builder: (context, ds) => ds.isEmpty
          ? const TroEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Chưa có tin nhắn',
              message:
                  'Nhắn tin cho chủ trọ từ trang nhà trọ hoặc trang phòng.',
            )
          : ListView.separated(
              itemCount: ds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = ds[i];
                final chuaDoc = c.chuaDocCua(dv.uid);
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: TroColors.primaryLight,
                    child: Icon(Icons.person, color: TroColors.primary),
                  ),
                  title: Text(
                    c.tenNguoiKia(dv.uid),
                    style: chuaDoc > 0 ? TroText.h3 : TroText.body,
                  ),
                  subtitle: Text(
                    c.tinCuoi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (c.tinCuoiLuc != null)
                        Text(
                          formatNgayGio(c.tinCuoiLuc!).split(' ').first,
                          style: TroText.bodySmall,
                        ),
                      if (chuaDoc > 0)
                        Badge(
                          backgroundColor: TroColors.danger,
                          label: Text('$chuaDoc'),
                        ),
                    ],
                  ),
                  onTap: () =>
                      TroDieuHuong.chat(context, dv, c.nguoiKia(dv.uid)),
                );
              },
            ),
    ),
  );
}

/// Một cuộc trò chuyện: gửi chữ / ảnh / thẻ tin, Đã gửi / Đã xem, câu hỏi nhanh, cảnh báo lừa đảo, chặn, báo cáo.
class CuocTroChuyenScreen extends StatefulWidget {
  const CuocTroChuyenScreen({
    required this.dv,
    required this.nguoiKia,
    this.phongId,
    super.key,
  });

  final TroDichVu dv;
  final String nguoiKia;

  /// Mở từ một phòng → tự gắn thẻ thông tin phòng vào cuộc chat.
  final String? phongId;

  @override
  State<CuocTroChuyenScreen> createState() => _CuocTroChuyenScreenState();
}

class _CuocTroChuyenScreenState extends State<CuocTroChuyenScreen> {
  final _o = TextEditingController();
  late final String _chatId = CuocTroChuyen.maCuoc(
    widget.dv.uid,
    widget.nguoiKia,
  );
  bool _daGanThe = false;
  bool _dangGui = false;
  String? _canhBao;
  int _soTinDaXem = -1;

  @override
  void dispose() {
    _o.dispose();
    super.dispose();
  }

  Future<void> _gui({String? noiDung, String? anh, String? phongId}) async {
    if (_dangGui) return;
    setState(() => _dangGui = true);
    String? canhBao;
    final ok = await chayThaoTac(
      context,
      () async => canhBao = await widget.dv.chat.gui(
        widget.nguoiKia,
        noiDung: noiDung,
        anh: anh,
        phongId: phongId,
      ),
    );
    if (!mounted) return;
    setState(() {
      _dangGui = false;
      if (canhBao != null) _canhBao = canhBao;
    });
    if (ok && noiDung != null) _o.clear();
  }

  Future<void> _guiAnh() async {
    final f =
        await (widget.dv.pickImages?.call(1) ??
            ImagePicker()
                .pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  imageQuality: 85,
                )
                .then((x) => x == null ? <XFile>[] : [x]));
    if (f.isEmpty || !mounted) return;
    await chayThaoTac(context, () async {
      final url = await widget.dv.storage.upload(
        bytes: await f.first.readAsBytes(),
        fileName: f.first.name,
        folder: 'tro_anh',
      );
      await widget.dv.chat.gui(widget.nguoiKia, anh: url);
    });
  }

  void _sauKhiTai(List<TinNhan> ds) {
    // Gắn thẻ phòng 1 lần khi mở từ phòng (nếu 20 tin gần nhất chưa có thẻ của phòng này).
    if (!_daGanThe && widget.phongId != null) {
      _daGanThe = true;
      final daCo = ds.reversed
          .take(20)
          .any(
            (t) => t.loai == 'the_tin' && t.the?['phongId'] == widget.phongId,
          );
      if (!daCo) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _gui(phongId: widget.phongId),
        );
      }
    }
    final chuaXem = ds
        .where((t) => t.nguoiGui != widget.dv.uid && t.daXemLuc == null)
        .length;
    if (chuaXem > 0 && ds.length != _soTinDaXem) {
      _soTinDaXem = ds.length;
      widget.dv.chat.daXem(_chatId).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CuocTroChuyen?>(
      stream: widget.dv.chat.cuoc(_chatId),
      builder: (context, cs) {
        final c = cs.data;
        final toiChan = c?.chanBoi.contains(widget.dv.uid) ?? false;
        final biChan = c?.biChan ?? false;
        return Scaffold(
          appBar: AppBar(
            title: Text(c?.tenNguoiKia(widget.dv.uid) ?? 'Tin nhắn'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'chan') {
                    await chayThaoTac(
                      context,
                      () => widget.dv.chat.chan(_chatId, chan: !toiChan),
                      thanhCong: toiChan ? 'Đã bỏ chặn' : 'Đã chặn người này',
                    );
                  } else if (v == 'bao_cao') {
                    await moBaoCao(
                      context,
                      widget.dv,
                      loai: 'nguoi_dung',
                      id: widget.nguoiKia,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'chan',
                    child: Text(toiChan ? 'Bỏ chặn' : 'Chặn'),
                  ),
                  const PopupMenuItem(
                    value: 'bao_cao',
                    child: Text('Báo cáo người dùng'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_canhBao != null)
                Padding(
                  padding: const EdgeInsets.all(TroSpacing.sm),
                  child: TroWarningBox(message: _canhBao!),
                ),
              Expanded(
                child: c == null && cs.connectionState == ConnectionState.active
                    ? const TroEmptyState(
                        icon: Icons.waving_hand_outlined,
                        title: 'Bắt đầu cuộc trò chuyện',
                      )
                    : TroStream<List<TinNhan>>(
                        stream: () => widget.dv.chat.tinNhan(_chatId),
                        builder: (context, ds) {
                          _sauKhiTai(ds);
                          final cuoiCuaToi = ds.lastIndexWhere(
                            (t) => t.nguoiGui == widget.dv.uid,
                          );
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(TroSpacing.md),
                            itemCount: ds.length,
                            itemBuilder: (context, i) {
                              final idx = ds.length - 1 - i;
                              final t = ds[idx];
                              return _Bong(
                                dv: widget.dv,
                                t: t,
                                chatId: _chatId,
                                cuaToi: t.nguoiGui == widget.dv.uid,
                                hienTrangThai: idx == cuoiCuaToi,
                              );
                            },
                          );
                        },
                      ),
              ),
              if (biChan)
                const Padding(
                  padding: EdgeInsets.all(TroSpacing.md),
                  child: Text(
                    'Cuộc trò chuyện đã bị chặn, không gửi được tin nhắn.',
                    style: TroText.bodySmall,
                  ),
                )
              else ...[
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TroSpacing.sm,
                    ),
                    children: [
                      for (final q
                          in widget.phongId != null
                              ? cauHoiNhanh
                              : mauTraLoiNhanh)
                        Padding(
                          padding: const EdgeInsets.only(right: TroSpacing.sm),
                          child: ActionChip(
                            label: Text(q),
                            onPressed: () => _o.text = q,
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(TroSpacing.sm),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Gửi ảnh',
                          onPressed: _guiAnh,
                          icon: const Icon(
                            Icons.image_outlined,
                            color: TroColors.primary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _o,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gửi',
                          onPressed: _dangGui
                              ? null
                              : () => _o.text.trim().isEmpty
                                    ? null
                                    : _gui(noiDung: _o.text.trim()),
                          icon: const Icon(
                            Icons.send_rounded,
                            color: TroColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bong extends StatelessWidget {
  const _Bong({
    required this.dv,
    required this.t,
    required this.chatId,
    required this.cuaToi,
    required this.hienTrangThai,
  });

  final TroDichVu dv;
  final TinNhan t;
  final String chatId;
  final bool cuaToi;
  final bool hienTrangThai;

  @override
  Widget build(BuildContext context) {
    Widget noiDung;
    if (t.hienThi != 'hien') {
      noiDung = const Text(
        'Tin nhắn đã bị ẩn',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    } else if (t.loai == 'anh') {
      noiDung = SizedBox(
        width: 200,
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TroRadius.input),
          child: NetworkPhoto(t.noiDung),
        ),
      );
    } else if (t.loai == 'the_tin' && t.the != null) {
      final the = t.the!;
      noiDung = InkWell(
        onTap: () => TroDieuHuong.phong(context, dv, the['phongId'] as String),
        child: SizedBox(
          width: 240,
          child: Row(
            children: [
              if ((the['anh'] as String? ?? '').isNotEmpty)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkPhoto(the['anh'] as String),
                  ),
                ),
              const SizedBox(width: TroSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phòng ${the['ten'] ?? ''}', style: TroText.label),
                    if (the['gia'] is num)
                      Text(
                        '${formatPrice(the['gia'] as num)}/tháng',
                        style: TroText.price,
                      ),
                    const Text(
                      'Xem phòng · Đặt cọc',
                      style: TextStyle(color: TroColors.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      noiDung = Text(
        t.noiDung,
        style: TextStyle(
          color: cuaToi ? TroColors.white : TroColors.textPrimary,
        ),
      );
    }
    return Align(
      alignment: cuaToi ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: cuaToi
            ? null
            : () => moBaoCao(
                context,
                dv,
                loai: 'tin_nhan',
                id: t.id,
                chatId: chatId,
              ),
        child: Column(
          crossAxisAlignment: cuaToi
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(
                horizontal: TroSpacing.md,
                vertical: TroSpacing.sm,
              ),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: cuaToi && t.loai == 'chu'
                    ? TroColors.primary
                    : TroColors.white,
                border: Border.all(color: TroColors.border),
                borderRadius: BorderRadius.circular(TroRadius.card),
              ),
              child: noiDung,
            ),
            if (t.coCanhBao && t.hienThi == 'hien')
              const SizedBox(
                width: 320,
                child: Text(
                  canhBaoLuaDao,
                  style: TextStyle(color: TroColors.danger, fontSize: 12),
                ),
              ),
            if (hienTrangThai)
              Text(
                t.daXemLuc != null ? 'Đã xem' : 'Đã gửi',
                style: TroText.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
