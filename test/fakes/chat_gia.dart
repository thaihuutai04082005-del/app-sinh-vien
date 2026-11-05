import 'dart:async';

import 'package:app_sinh_vien/shared/services/chat_service.dart';

/// Chat trong bộ nhớ, dùng chung giữa các "người dùng" của một test.
class KhoChat {
  final cuoc = <String, CuocChat>{};
  final tin = <String, List<TinNhanChat>>{};
  final _doi = StreamController<void>.broadcast();

  void baoDoi() => _doi.add(null);

  /// Phát giá trị hiện tại rồi phát lại mỗi khi dữ liệu đổi.
  Stream<T> theoDoi<T>(T Function() lay) => Stream.multi((c) {
    c.add(lay());
    final sub = _doi.stream.listen((_) => c.add(lay()));
    c.onCancel = sub.cancel;
  });
}

class ChatGia implements ChatService {
  ChatGia(this.kho, this.uid);

  final KhoChat kho;
  final String uid;

  @override
  Stream<List<CuocChat>> cuocCuaToi() => kho.theoDoi(
    () => [
      for (final c in kho.cuoc.values)
        if (c.participantIds.contains(uid)) c,
    ],
  );

  @override
  Stream<CuocChat?> cuoc(String chatId) => kho.theoDoi(() => kho.cuoc[chatId]);

  @override
  Stream<List<TinNhanChat>> tinNhan(String chatId) =>
      kho.theoDoi(() => List.of(kho.tin[chatId] ?? const <TinNhanChat>[]));

  @override
  Future<String> moChat(String otherId) async {
    final ids = [uid, otherId]..sort();
    final id = ids.join('_');
    kho.cuoc[id] ??= CuocChat(
      id: id,
      participantIds: ids,
      names: {for (final p in ids) p: 'Người $p'},
    );
    return id;
  }

  @override
  Future<void> guiTin(String chatId, String text) async {
    (kho.tin[chatId] ??= []).add(
      TinNhanChat(id: '${kho.tin[chatId]!.length}', senderId: uid, text: text),
    );
    final c = kho.cuoc[chatId]!;
    kho.cuoc[chatId] = CuocChat(
      id: c.id,
      participantIds: c.participantIds,
      names: c.names,
      lastMessage: text,
      lastSenderId: uid,
      unread: {c.nguoiKia(uid): c.chuaDoc(c.nguoiKia(uid)) + 1},
    );
    kho.baoDoi();
  }

  @override
  Future<void> daDoc(String chatId) async {}
}
