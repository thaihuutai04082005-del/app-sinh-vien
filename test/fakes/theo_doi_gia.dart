import 'package:app_sinh_vien/shared/services/theo_doi_service.dart';

/// Theo dõi trong bộ nhớ: (người theo dõi, loại, id).
class TheoDoiGia implements TheoDoiService {
  TheoDoiGia(this.ds, this.uid);

  final Set<(String, String, String)> ds;
  final String uid;

  @override
  Future<bool> dangTheoDoi(String targetType, String targetId) async =>
      ds.contains((uid, targetType, targetId));

  @override
  Future<void> theoDoi(String targetType, String targetId) async =>
      ds.add((uid, targetType, targetId));

  @override
  Future<void> boTheoDoi(String targetType, String targetId) async =>
      ds.remove((uid, targetType, targetId));

  @override
  Future<List<String>> cuaToi(String targetType) async => [
    for (final (u, t, id) in ds)
      if (u == uid && t == targetType) id,
  ];

  @override
  Future<int> soNguoiTheoDoi(String targetId) async =>
      ds.where((e) => e.$2 == 'shop' && e.$3 == targetId).length;
}
