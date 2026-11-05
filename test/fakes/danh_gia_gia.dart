import 'package:app_sinh_vien/shared/models/danh_gia.dart';
import 'package:app_sinh_vien/shared/services/danh_gia_service.dart';

/// Đánh giá trong bộ nhớ: (targetType, targetId, productIds, đánh giá).
class DanhGiaGia implements DanhGiaService {
  final ds = <(String, String, List<String>, DanhGia)>[];

  void them(
    String targetType,
    String targetId,
    DanhGiaNhap nhap, {
    List<String> productIds = const [],
    String userName = 'Người mua',
  }) {
    final diem = nhap.ratingDetail.values;
    ds.insert(0, (
      targetType,
      targetId,
      productIds,
      DanhGia(
        id: 'r${ds.length + 1}',
        userName: userName,
        rating: diem.reduce((a, b) => a + b) / diem.length,
        ratingDetail: nhap.ratingDetail,
        comment: nhap.comment,
        images: nhap.images,
        createdAt: DateTime(2026, 10, 22),
      ),
    ));
  }

  @override
  Future<List<DanhGia>> theoDoiTuong(
    String targetType,
    String targetId,
  ) async => [
    for (final (t, id, _, d) in ds)
      if (t == targetType && id == targetId) d,
  ];

  @override
  Future<List<DanhGia>> theoSanPham(String productId) async => [
    for (final (_, _, sp, d) in ds)
      if (sp.contains(productId)) d,
  ];
}
