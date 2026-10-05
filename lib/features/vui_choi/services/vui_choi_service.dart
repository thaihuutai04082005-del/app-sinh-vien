import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vui_choi_model.dart';

class VuiChoiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách điểm vui chơi (có lọc theo category)
  Stream<List<VuiChoiModel>> getDanhSachVuiChoi({String? category}) {
    Query query = _db.collection('vui_choi');

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VuiChoiModel.fromFirestore(doc))
          .toList();
    });
  }
}