import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

import '../../../core/services/daily_quota.dart';
import '../models/booking_xe.dart';

abstract interface class BookingXeService {
  Future<List<BookingXe>> getDanhSachYeuCau();

  /// Lưu yêu cầu mới; gán id, userId = uid người gửi, status = "pending".
  Future<BookingXe> guiYeuCau(BookingXe booking);
}

class FirestoreBookingXeService implements BookingXeService {
  FirestoreBookingXeService({this._firestore, DailyQuota? quota})
    : _quota = quota ?? DailyQuota(_firestore);

  final FirebaseFirestore? _firestore;
  final DailyQuota _quota;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      (_firestore ?? FirebaseFirestore.instance).collection(Collections.bookingXe);

  @override
  Future<List<BookingXe>> getDanhSachYeuCau() async {
    final snapshot = await _bookings
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<BookingXe> guiYeuCau(BookingXe booking) async {
    final post = await _quota.createPost(
      'booking_xe',
      (uid) => booking.toMap()
        ..remove('id')
        ..['userId'] = uid
        ..['status'] = 'pending'
        // Firestore lưu thời điểm dạng timestamp thay vì chuỗi ISO.
        ..['scheduledAt'] = Timestamp.fromDate(booking.scheduledAt),
    );
    return _fromMap({...post.data, 'id': post.id});
  }

  static BookingXe _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      _fromMap({...?doc.data(), 'id': doc.id});

  static BookingXe _fromMap(Map<String, dynamic> data) {
    final scheduledAt = data['scheduledAt'];
    if (scheduledAt is Timestamp) {
      data['scheduledAt'] = scheduledAt.toDate().toUtc().toIso8601String();
    }
    return BookingXe.fromMap(data);
  }
}
