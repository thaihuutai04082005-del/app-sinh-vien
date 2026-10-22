import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import 'callable_api.dart';

/// Một cuộc trò chuyện — `chats/{chatId}` (mục 7.3), dùng chung Shop và Xe dọn trọ.
class CuocChat {
  const CuocChat({
    required this.id,
    required this.participantIds,
    this.names = const {},
    this.lastMessage = '',
    this.lastSenderId,
    this.unread = const {},
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> names;
  final String lastMessage;
  final String? lastSenderId;

  /// uid → số tin chưa đọc.
  final Map<String, int> unread;
  final DateTime? updatedAt;

  String nguoiKia(String uid) =>
      participantIds.firstWhere((p) => p != uid, orElse: () => '');

  String tenNguoiKia(String uid) => names[nguoiKia(uid)] ?? 'Người dùng';

  int chuaDoc(String uid) => unread[uid] ?? 0;

  factory CuocChat.fromMap(Map<String, dynamic> m) => CuocChat(
    id: m['id'] as String? ?? '',
    participantIds: (m['participantIds'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    names: {
      for (final e in (m['names'] as Map? ?? const {}).entries)
        '${e.key}': '${e.value}',
    },
    lastMessage: m['lastMessage'] as String? ?? '',
    lastSenderId: m['lastSenderId'] as String?,
    unread: {
      for (final e in (m['unread'] as Map? ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    },
    updatedAt: docThoiGian(m['updatedAt']),
  );
}

class TinNhanChat {
  const TinNhanChat({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory TinNhanChat.fromMap(Map<String, dynamic> m) => TinNhanChat(
    id: m['id'] as String? ?? '',
    senderId: m['senderId'] as String? ?? '',
    text: m['text'] as String? ?? '',
    createdAt: docThoiGian(m['createdAt']),
  );
}

/// Chat của một module (`shop` | `xe`): đọc realtime, gửi qua callable của module.
abstract interface class ChatService {
  Stream<List<CuocChat>> cuocCuaToi();
  Stream<CuocChat?> cuoc(String chatId);
  Stream<List<TinNhanChat>> tinNhan(String chatId);

  /// Mở (hoặc lấy lại) cuộc trò chuyện với [otherId], trả về chatId.
  Future<String> moChat(String otherId);
  Future<void> guiTin(String chatId, String text);
  Future<void> daDoc(String chatId);
}

class FirebaseChatService implements ChatService {
  /// [module]: shop | xe; [api]: callable của module đó (shopApi / xeApi).
  FirebaseChatService({
    required this.uid,
    required this.module,
    required this.api,
    this._db,
  });

  final String uid;
  final String module;
  final CallableApi api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      (_db ?? FirebaseFirestore.instance).collection(Collections.chats);

  @override
  Stream<List<CuocChat>> cuocCuaToi() => uid.isEmpty
      ? Stream.value(const [])
      : _chats
            .where('module', isEqualTo: module)
            .where('participantIds', arrayContains: uid)
            .orderBy('updatedAt', descending: true)
            .limit(100)
            .snapshots()
            .map(
              (s) => [
                for (final d in s.docs)
                  CuocChat.fromMap({...d.data(), 'id': d.id}),
              ],
            );

  @override
  Stream<CuocChat?> cuoc(String chatId) => _chats
      .doc(chatId)
      .snapshots()
      .map(
        (d) => d.exists ? CuocChat.fromMap({...d.data()!, 'id': d.id}) : null,
      );

  @override
  Stream<List<TinNhanChat>> tinNhan(String chatId) => _chats
      .doc(chatId)
      .collection(Collections.messages)
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            TinNhanChat.fromMap({...d.data(), 'id': d.id}),
        ],
      );

  @override
  Future<String> moChat(String otherId) async =>
      (await api.goi('moChat', {'otherId': otherId}))['id'] as String;

  @override
  Future<void> guiTin(String chatId, String text) =>
      api.goi('guiTin', {'chatId': chatId, 'text': text});

  @override
  Future<void> daDoc(String chatId) => api.goi('daDoc', {'chatId': chatId});
}
