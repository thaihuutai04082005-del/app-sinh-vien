import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/daily_quota.dart';
import '../models/vui_choi_model.dart';

/// Lấy và đăng dữ liệu điểm vui chơi. Giao diện luôn đi qua lớp này,
/// không gọi Firestore trực tiếp.
abstract interface class VuiChoiService {
  /// Danh sách điểm vui chơi, lọc theo [category] (null, rỗng hoặc "all" = tất cả).
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category});

  /// Đăng địa điểm mới; gán id và ownerId = uid người đăng. Mỗi tài khoản đăng
  /// tối đa số tin/ngày theo `DailyQuota` (ném `QuotaException` khi vượt).
  Future<VuiChoiModel> dangVuiChoi(VuiChoiModel item);
}

class FirestoreVuiChoiService implements VuiChoiService {
  FirestoreVuiChoiService({FirebaseFirestore? firestore, DailyQuota? quota})
    : _firestore = firestore,
      _quota = quota ?? DailyQuota(firestore);

  final FirebaseFirestore? _firestore;
  final DailyQuota _quota;

  @override
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category}) {
    Query<Map<String, dynamic>> query =
        (_firestore ?? FirebaseFirestore.instance).collection(
          Collections.vuiChoi,
        );

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs)
          VuiChoiModel.fromMap(doc.id, doc.data()),
      ],
    );
  }

  @override
  Future<VuiChoiModel> dangVuiChoi(VuiChoiModel item) async {
    final post = await _quota.createPost(
      Collections.vuiChoi,
      (uid) => item.toMap()..['ownerId'] = uid,
    );
    return VuiChoiModel.fromMap(post.id, post.data);
  }
}
