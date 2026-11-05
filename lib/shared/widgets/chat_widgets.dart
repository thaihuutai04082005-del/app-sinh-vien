import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../services/chat_service.dart';

/// Mở chat với [otherId] rồi vào màn trò chuyện; báo lỗi bằng SnackBar.
Future<void> moChatVoi(
  BuildContext context,
  ChatService chat,
  String uid,
  String otherId,
) async {
  try {
    final id = await chat.moChat(otherId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(chat: chat, uid: uid, chatId: id),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

/// Danh sách cuộc trò chuyện của một module, cập nhật realtime.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({
    required this.chat,
    required this.uid,
    this.goiY = '',
    super.key,
  });

  final ChatService chat;
  final String uid;

  /// Câu gợi ý khi chưa có cuộc nào.
  final String goiY;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: StreamBuilder<List<CuocChat>>(
        stream: chat.cuocCuaToi(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Chưa tải được tin nhắn: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ds = snap.data!;
          if (ds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có tin nhắn nào. $goiY',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: ds.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = ds[i];
              final chuaDoc = c.chuaDoc(uid);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  c.tenNguoiKia(uid),
                  style: TextStyle(
                    fontWeight: chuaDoc > 0 ? FontWeight.w800 : null,
                  ),
                ),
                subtitle: Text(
                  c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chuaDoc > 0
                    ? Badge(label: Text('$chuaDoc'))
                    : c.updatedAt == null
                    ? null
                    : Text(formatNgay(c.updatedAt!)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChatScreen(chat: chat, uid: uid, chatId: c.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Một cuộc trò chuyện: tin nhắn realtime, ô gửi tin.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.chat,
    required this.uid,
    required this.chatId,
    super.key,
  });

  final ChatService chat;
  final String uid;
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _o = TextEditingController();
  late final _cuoc = widget.chat.cuoc(widget.chatId);
  late final _tin = widget.chat.tinNhan(widget.chatId);
  bool _dangGui = false;

  @override
  void initState() {
    super.initState();
    widget.chat.daDoc(widget.chatId).catchError((_) {});
  }

  @override
  void dispose() {
    _o.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final text = _o.text.trim();
    if (text.isEmpty) return;
    setState(() => _dangGui = true);
    try {
      await widget.chat.guiTin(widget.chatId, text);
      _o.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<CuocChat?>(
          stream: _cuoc,
          builder: (context, snap) =>
              Text(snap.data?.tenNguoiKia(widget.uid) ?? 'Tin nhắn'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TinNhanChat>>(
              stream: _tin,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ds = snap.data!.reversed.toList();
                if (ds.isEmpty) {
                  return const Center(child: Text('Hãy gửi lời chào!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final t = ds[i];
                    final cuaToi = t.senderId == widget.uid;
                    return Align(
                      alignment: cuaToi
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cuaToi
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(t.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _o,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _gui(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gửi',
                    onPressed: _dangGui ? null : _gui,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
