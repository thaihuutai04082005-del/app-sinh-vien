import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tin_nhan.dart';
import 'tro_api.dart';

/// Chat riêng của Tìm trọ (mục 2.8). Gửi tin đi qua hệ thống (chặn, cảnh báo, chống tự giao dịch).
abstract interface class ChatService {
  Stream<List<CuocTroChuyen>> cuocCuaToi(String uid);
  Stream<CuocTroChuyen?> cuoc(String chatId);
  Stream<List<TinNhan>> tinNhan(String chatId);

  /// Trả về cảnh báo lừa đảo (nếu tin có từ khóa chuyển tiền).
  Future<String?> gui(
    String nguoiNhan, {
    String? noiDung,
    String? phongId,
    String? anh,
  });
  Future<void> daXem(String chatId);
  Future<void> chan(String chatId, {required bool chan});
}

class FirebaseChatService implements ChatService {
  FirebaseChatService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _c =>
      (_db ?? FirebaseFirestore.instance).collection('tro_chat');

  @override
  Stream<List<CuocTroChuyen>> cuocCuaToi(String uid) => _c
      .where('thanhVien', arrayContains: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CuocTroChuyen.fromMap(d.id, d.data())]
          ..sort(
            (a, b) => (b.tinCuoiLuc ?? DateTime(0)).compareTo(
              a.tinCuoiLuc ?? DateTime(0),
            ),
          ),
      );

  @override
  Stream<CuocTroChuyen?> cuoc(String chatId) => _c
      .doc(chatId)
      .snapshots()
      .map((s) => s.exists ? CuocTroChuyen.fromMap(s.id, s.data()!) : null);

  @override
  Stream<List<TinNhan>> tinNhan(String chatId) => _c
      .doc(chatId)
      .collection('tin_nhan')
      .orderBy('guiLuc')
      .limitToLast(200)
      .snapshots()
      .map((s) => [for (final d in s.docs) TinNhan.fromMap(d.id, d.data())]);

  @override
  Future<String?> gui(
    String nguoiNhan, {
    String? noiDung,
    String? phongId,
    String? anh,
  }) async {
    final r = await api.goi('guiTin', {
      'nguoiNhan': nguoiNhan,
      if (phongId != null) ...{
        'loai': 'the_tin',
        'the': {'phongId': phongId},
      },
      if (anh != null) ...{'loai': 'anh', 'anh': anh},
      'noiDung': ?noiDung,
    });
    return r['canhBao'] as String?;
  }

  @override
  Future<void> daXem(String chatId) => api.goi('daXemChat', {'chatId': chatId});

  @override
  Future<void> chan(String chatId, {required bool chan}) =>
      api.goi('chanChat', {'chatId': chatId, 'chan': chan});
}
