import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/phong_tro.dart';

/// Lấy dữ liệu phòng trọ. Giao diện luôn đi qua lớp này, không viết cứng dữ liệu.
abstract interface class PhongTroService {
  /// Các phòng đang còn trống (`status == "available"`), mới nhất trước.
  Future<List<PhongTro>> getDanhSachPhongTro();
}

class FirestorePhongTroService implements PhongTroService {
  FirestorePhongTroService([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  @override
  Future<List<PhongTro>> getDanhSachPhongTro() async {
    final snapshot = await (_firestore ?? FirebaseFirestore.instance)
        .collection(Collections.phongTro)
        .where('status', isEqualTo: 'available')
        .limit(100)
        .get();
    final list = [
      for (final doc in snapshot.docs) PhongTro.fromMap(doc.id, doc.data()),
    ];
    // Sắp xếp phía app để không phải tạo composite index.
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        ));
    return list;
  }
}
