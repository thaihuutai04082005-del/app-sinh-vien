import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/check_in.dart';
import 'quan_an_api.dart';

/// Check-in tại quán (mục 3.4 Bước 3): cách quán ≤ 100 m, trong giờ mở cửa, 1 lần / quán / ngày.
abstract interface class CheckInService {
  /// Trả về khoảng cách (mét) hệ thống tính được tới quán.
  Future<num?> checkIn({
    required String quanId,
    required double lat,
    required double lng,
    String? anh,
    String? camNghi,
    bool congKhai = false,
  });

  /// Hôm nay (giờ Việt Nam) sinh viên đã check-in ở quán này chưa.
  Future<bool> daCheckInHomNay(String uid, String quanId);

  /// Các lần check-in của sinh viên (trang "Của tôi"), mới nhất trước.
  Stream<List<CheckIn>> cuaSinhVien(String uid);
}

class FirebaseCheckInService implements CheckInService {
  FirebaseCheckInService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<num?> checkIn({
    required String quanId,
    required double lat,
    required double lng,
    String? anh,
    String? camNghi,
    bool congKhai = false,
  }) async {
    final r = await api.goi('checkIn', {
      'quanId': quanId,
      'lat': lat,
      'lng': lng,
      if (anh != null && anh.isNotEmpty) 'anh': anh,
      if (camNghi != null && camNghi.trim().isNotEmpty)
        'camNghi': camNghi.trim(),
      'congKhai': congKhai,
    });
    return r['khoangCachM'] as num?;
  }

  @override
  Future<bool> daCheckInHomNay(String uid, String quanId) async {
    final s = await _f
        .collection('qa_check_in')
        .doc(maCheckIn(uid, quanId, DateTime.now()))
        .get();
    return s.exists;
  }

  @override
  Stream<List<CheckIn>> cuaSinhVien(String uid) => _f
      .collection('qa_check_in')
      .where('svId', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CheckIn.fromMap(d.id, d.data())]
          ..sort(
            (a, b) => (b.luc ?? DateTime(0)).compareTo(a.luc ?? DateTime(0)),
          ),
      );
}
