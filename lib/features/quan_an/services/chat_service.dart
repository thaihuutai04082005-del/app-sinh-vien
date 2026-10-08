import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tin_nhan.dart';
import 'quan_an_api.dart';

/// Chat riêng của Quán ăn (mục 3.8). Gửi tin đi qua hệ thống (chặn, cảnh báo lừa đảo).
abstract interface class ChatService {
  Stream<List<CuocChat>> cuocCuaToi(String uid);
  Stream<CuocChat?> cuoc(String chatId);
  Stream<List<TinNhan>> tinNhan(String chatId);

  /// Gửi chữ / ảnh / thẻ tin. Có [quanId] hoặc [donId] thì gắn thẻ quán / đơn (đơn ưu tiên).
  /// Trả về cảnh báo lừa đảo (nếu tin có từ khóa chuyển tiền).
  Future<String?> gui(
    String nguoiNhan, {
    String? noiDung,
    String? quanId,
    String? donId,
    String? anh,
  });
  Future<void> daXem(String chatId);
  Future<void> chan(String chatId, {required bool chan});
}

class FirebaseChatService implements ChatService {
  FirebaseChatService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _c =>
      (_db ?? FirebaseFirestore.instance).collection('qa_chat');

  @override
  Stream<List<CuocChat>> cuocCuaToi(String uid) => _c
      .where('thanhVien', arrayContains: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CuocChat.fromMap(d.id, d.data())]
          ..sort(
            (a, b) => (b.tinCuoiLuc ?? DateTime(0)).compareTo(
              a.tinCuoiLuc ?? DateTime(0),
            ),
          ),
      );

  @override
  Stream<CuocChat?> cuoc(String chatId) => _c
      .doc(chatId)
      .snapshots()
      .map((s) => s.exists ? CuocChat.fromMap(s.id, s.data()!) : null);

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
    String? quanId,
    String? donId,
    String? anh,
  }) async {
    final theLoai = donId != null
        ? TheTin.loaiDon
        : (quanId != null ? TheTin.loaiQuan : null);
    final r = await api.goi('guiTin', {
      'nguoiNhan': nguoiNhan,
      if (theLoai != null) ...{
        'loai': 'the_tin',
        'the': {'loai': theLoai, 'id': donId ?? quanId},
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
