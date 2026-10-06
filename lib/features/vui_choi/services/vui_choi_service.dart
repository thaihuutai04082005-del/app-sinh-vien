import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/vui_choi_model.dart';

/// Lấy dữ liệu điểm vui chơi. Giao diện luôn đi qua lớp này, không gọi Firestore trực tiếp.
abstract interface class VuiChoiService {
  /// Danh sách điểm vui chơi, lọc theo [category] (null, rỗng hoặc "all" = tất cả).
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category});
}

class FirestoreVuiChoiService implements VuiChoiService {
  FirestoreVuiChoiService([FirebaseFirestore? firestore])
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

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
}
