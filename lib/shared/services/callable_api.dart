import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/services/firebase_emulator.dart';
import '../../features/auth/services/xac_thuc_service.dart';

export '../../features/auth/services/xac_thuc_service.dart' show ApiException;

/// Gọi một callable kiểu `{ hanhDong, ...thamSo }`. Hệ thống quyết định, app chỉ gửi yêu cầu.
abstract interface class CallableApi {
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo,
  ]);
}

/// Callable ở region asia-southeast1 (functions-xe-shop).
class FirebaseCallableApi implements CallableApi {
  FirebaseCallableApi(this.ten, [this._fn]);

  final String ten;
  final FirebaseFunctions? _fn;

  FirebaseFunctions get _functions {
    if (_fn != null) return _fn;
    final fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
    if (dungEmulator) fn.useFunctionsEmulator('127.0.0.1', 5001);
    return fn;
  }

  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo = const {},
  ]) async {
    try {
      final r = await _functions.httpsCallable(ten).call({
        'hanhDong': hanhDong,
        ...thamSo,
      });
      final data = r.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on FirebaseFunctionsException catch (e) {
      throw ApiException(e.message ?? 'Có lỗi xảy ra, vui lòng thử lại.');
    }
  }
}

/// Đọc mốc thời gian từ Firestore (Timestamp), mili giây hoặc chuỗi ISO.
DateTime? docThoiGian(Object? v) => switch (v) {
  DateTime() => v,
  int() => DateTime.fromMillisecondsSinceEpoch(v),
  String() => DateTime.tryParse(v),
  Timestamp() => v.toDate(),
  _ => null,
};

/// Một mốc trong lịch sử trạng thái của đơn (`lichSu` do server ghi).
class MocTrangThai {
  const MocTrangThai({
    required this.status,
    required this.by,
    required this.at,
  });

  final String status;
  final String by;
  final DateTime at;

  static List<MocTrangThai> docDanhSach(Object? v) => [
    for (final m in v is List ? v : const [])
      if (m is Map)
        MocTrangThai(
          status: m['status'] as String? ?? '',
          by: m['by'] as String? ?? '',
          at: docThoiGian(m['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
}
