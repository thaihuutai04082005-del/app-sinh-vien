import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/daily_quota.dart';
import '../models/phong_tro.dart';

/// Lấy dữ liệu phòng trọ. Giao diện luôn đi qua lớp này, không viết cứng dữ liệu.
abstract interface class PhongTroService {
  /// Các phòng đang còn trống (`status == "available"`), mới nhất trước.
  Future<List<PhongTro>> getDanhSachPhongTro();

  /// Đăng tin cho thuê; gán id và ownerId = uid người đăng. Mỗi tài khoản đăng
  /// tối đa số tin/ngày theo `DailyQuota` (ném `QuotaException` khi vượt).
  Future<PhongTro> dangPhongTro(PhongTro phong);
}

class FirestorePhongTroService implements PhongTroService {
  FirestorePhongTroService({FirebaseFirestore? firestore, DailyQuota? quota})
    : _firestore = firestore,
      _quota = quota ?? DailyQuota(firestore);

  final FirebaseFirestore? _firestore;
  final DailyQuota _quota;

  @override
  Future<PhongTro> dangPhongTro(PhongTro phong) async {
    final post = await _quota.createPost(
      Collections.phongTro,
      (uid) => phong.toMap()..['ownerId'] = uid,
    );
    return PhongTro.fromMap(post.id, post.data);
  }

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
    list.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return list;
  }
}
