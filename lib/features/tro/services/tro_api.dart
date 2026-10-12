import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/services/xac_thuc_service.dart';

export '../../auth/services/xac_thuc_service.dart' show ApiException;

/// Gọi backend của module (callable `troApi`). Hệ thống quyết định, app chỉ gửi yêu cầu.
abstract interface class TroApi {
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo,
  ]);
}

class FirebaseTroApi implements TroApi {
  FirebaseTroApi([this._fn]);

  final FirebaseFunctions? _fn;

  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo = const {},
  ]) async {
    try {
      final r = await (_fn ?? FirebaseFunctions.instance)
          .httpsCallable('troApi')
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
