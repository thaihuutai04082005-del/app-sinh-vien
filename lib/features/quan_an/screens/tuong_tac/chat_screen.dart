import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/image_gallery.dart';
import '../../models/tin_nhan.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import '../quan_an_shell.dart';
import 'bao_cao_khang_nghi_screen.dart';

/// QA-SV-14 Chat của module — danh sách cuộc trò chuyện (riêng Quán ăn, không lẫn module khác).
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({required this.dv, this.onVeTrangChu, super.key});

  final QuanAnDichVu dv;
  final VoidCallback? onVeTrangChu;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: NutVeTrangChu(onPressed: onVeTrangChu),
      title: const Text('Tin nhắn'),
    ),
    body: QuanAnStream<List<CuocChat>>(
      stream: () => dv.chat.cuocCuaToi(dv.uid),
      builder: (context, ds) => ds.isEmpty
          ? const QuanAnEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Chưa có tin nhắn',
              message:
                  'Nhắn tin cho chủ quán từ trang quán hoặc trang đơn món.',
            )
          : ListView.separated(
              itemCount: ds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = ds[i];
                final chuaDoc = c.chuaDocCua(dv.uid);
                return ListTile(
                  minVerticalPadding: QuanAnSpacing.md,
                  leading: const CircleAvatar(
                    backgroundColor: QuanAnColors.primaryLight,
                    child: Icon(Icons.person, color: QuanAnColors.primary),
                  ),
                  title: Text(
                    c.tenNguoiKia(dv.uid),
                    style: chuaDoc > 0 ? QuanAnText.h3 : QuanAnText.body,
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
                          style: QuanAnText.bodySmall,
                        ),
                      if (chuaDoc > 0)
                        Badge(
                          backgroundColor: QuanAnColors.danger,
                          label: Text('$chuaDoc'),
                        ),
                    ],
                  ),
                  onTap: () =>
                      QuanAnDieuHuong.chat(context, dv, c.nguoiKia(dv.uid)),
                );
              },
            ),
    ),
  );
}

/// Một cuộc trò chuyện: gửi chữ / ảnh / thẻ tin, Đã gửi / Đã xem, câu hỏi nhanh, cảnh báo lừa đảo, chặn, báo cáo.
class CuocChatScreen extends StatefulWidget {
  const CuocChatScreen({
    required this.dv,
    required this.nguoiKia,
    this.quanId,
    this.donId,
    super.key,
  });

  final QuanAnDichVu dv;
  final String nguoiKia;

  /// Mở từ một quán → tự gắn thẻ thông tin quán vào cuộc chat.
  final String? quanId;

  /// Mở từ một đơn → tự gắn thẻ thông tin đơn (ưu tiên hơn thẻ quán).
  final String? donId;

  @override
  State<CuocChatScreen> createState() => _CuocChatScreenState();
}

class _CuocChatScreenState extends State<CuocChatScreen> {
  final _o = TextEditingController();
  late final String _chatId = CuocChat.maCuoc(widget.dv.uid, widget.nguoiKia);
  bool _daGanThe = false;
  bool _dangGui = false;
  String? _canhBao;
  int _soTinDaXem = -1;

  /// Sinh viên (người mở từ quán / đơn, hoặc từng gửi thẻ tin) thấy câu hỏi nhanh; chủ quán thấy mẫu trả lời.
  late bool _laSinhVien = widget.quanId != null || widget.donId != null;

  String? get _idThe => widget.donId ?? widget.quanId;

  @override
  void dispose() {
    _o.dispose();
    super.dispose();
  }

  Future<void> _gui({
    String? noiDung,
    String? anh,
    String? quanId,
    String? donId,
  }) async {
    if (_dangGui) return;
    setState(() => _dangGui = true);
    String? canhBao;
    final ok = await chayThaoTac(
      context,
      () async => canhBao = await widget.dv.chat.gui(
        widget.nguoiKia,
        noiDung: noiDung,
        anh: anh,
        quanId: quanId,
        donId: donId,
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
        folder: 'quan_an_anh',
      );
      await widget.dv.chat.gui(widget.nguoiKia, anh: url);
    });
  }

  void _sauKhiTai(List<TinNhan> ds) {
    // Gắn thẻ quán / đơn 1 lần khi mở từ đó (nếu 20 tin gần nhất chưa có thẻ trỏ cùng đích).
    if (!_daGanThe && _idThe != null) {
      _daGanThe = true;
      final daCo = ds.reversed
          .take(20)
          .any((t) => t.loai == 'the_tin' && t.the?['id'] == _idThe);
      if (!daCo) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _gui(quanId: widget.quanId, donId: widget.donId),
        );
      }
    }
    // Từng gửi thẻ tin thì là sinh viên (chủ quán không gửi thẻ).
    if (!_laSinhVien &&
        ds.any((t) => t.loai == 'the_tin' && t.nguoiGui == widget.dv.uid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _laSinhVien = true);
      });
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
    return StreamBuilder<CuocChat?>(
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
                tooltip: 'Tùy chọn',
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
                  padding: const EdgeInsets.all(QuanAnSpacing.sm),
                  child: QuanAnWarningBox(message: _canhBao!),
                ),
              Expanded(
                child: c == null && cs.connectionState == ConnectionState.active
                    ? const QuanAnEmptyState(
                        icon: Icons.waving_hand_outlined,
                        title: 'Bắt đầu cuộc trò chuyện',
                      )
                    : QuanAnStream<List<TinNhan>>(
                        stream: () => widget.dv.chat.tinNhan(_chatId),
                        builder: (context, ds) {
                          _sauKhiTai(ds);
                          final cuoiCuaToi = ds.lastIndexWhere(
                            (t) => t.nguoiGui == widget.dv.uid,
                          );
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(QuanAnSpacing.md),
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
                  padding: EdgeInsets.all(QuanAnSpacing.md),
                  child: Text(
                    'Cuộc trò chuyện đã bị chặn, không gửi được tin nhắn.',
                    style: QuanAnText.bodySmall,
                  ),
                )
              else ...[
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: QuanAnSpacing.sm,
                    ),
                    children: [
                      for (final q
                          in _laSinhVien ? cauHoiNhanh : mauTraLoiNhanh)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: QuanAnSpacing.sm,
                          ),
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
                    padding: const EdgeInsets.all(QuanAnSpacing.sm),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Gửi ảnh',
                          onPressed: _guiAnh,
                          icon: const Icon(
                            Icons.image_outlined,
                            color: QuanAnColors.primary,
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
                            color: QuanAnColors.primary,
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

  final QuanAnDichVu dv;
  final TinNhan t;
  final String chatId;
  final bool cuaToi;
  final bool hienTrangThai;

  @override
  Widget build(BuildContext context) {
    Widget noiDung;
    final the = t.theTin;
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
          borderRadius: BorderRadius.circular(QuanAnRadius.input),
          child: NetworkPhoto(t.noiDung),
        ),
      );
    } else if (t.loai == 'the_tin' && the != null) {
      noiDung = InkWell(
        onTap: () => the.laDon
            ? QuanAnDieuHuong.don(context, dv, the.id)
            : QuanAnDieuHuong.quan(context, dv, the.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (the.anh.isNotEmpty)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkPhoto(the.anh),
                  ),
                ),
              const SizedBox(width: QuanAnSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      the.laDon
                          ? 'Đơn ${the.tieuDe}'.trim()
                          : (the.tieuDe.isEmpty ? 'Quán ăn' : the.tieuDe),
                      style: QuanAnText.label,
                    ),
                    if (the.gia != null)
                      Text(formatPrice(the.gia!), style: QuanAnText.price),
                    Text(
                      the.laDon ? 'Xem đơn' : 'Xem quán · Đặt món',
                      style: const TextStyle(
                        color: QuanAnColors.primary,
                        fontSize: 12,
                      ),
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
          color: cuaToi && t.loai == 'chu'
              ? QuanAnColors.white
              : QuanAnColors.textPrimary,
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
                horizontal: QuanAnSpacing.md,
                vertical: QuanAnSpacing.sm,
              ),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: cuaToi && t.loai == 'chu'
                    ? QuanAnColors.primary
                    : QuanAnColors.white,
                border: Border.all(color: QuanAnColors.border),
                borderRadius: BorderRadius.circular(QuanAnRadius.card),
              ),
              child: noiDung,
            ),
            if (t.coCanhBao && t.hienThi == 'hien')
              const SizedBox(
                width: 320,
                child: Text(
                  canhBaoLuaDao,
                  style: TextStyle(color: QuanAnColors.danger, fontSize: 12),
                ),
              ),
            if (hienTrangThai)
              Text(
                t.daXemLuc != null ? 'Đã xem' : 'Đã gửi',
                style: QuanAnText.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
