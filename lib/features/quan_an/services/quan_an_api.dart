import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/services/xac_thuc_service.dart';

export '../../auth/services/xac_thuc_service.dart' show ApiException;

/// Gọi backend của module (callable `quanAnApi`). Hệ thống quyết định, app chỉ gửi yêu cầu.
abstract interface class QuanAnApi {
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo,
  ]);
}

class FirebaseQuanAnApi implements QuanAnApi {
  FirebaseQuanAnApi([this._fn]);

  final FirebaseFunctions? _fn;

  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo = const {},
  ]) async {
    try {
      final r = await (_fn ?? FirebaseFunctions.instance)
          .httpsCallable('quanAnApi')
          .call({'hanhDong': hanhDong, ...thamSo});
      final data = r.data;
      return data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{'ketQua': data};
    } on FirebaseFunctionsException catch (e) {
      throw ApiException(e.message ?? 'Có lỗi xảy ra, vui lòng thử lại.');
    }
  }
}
