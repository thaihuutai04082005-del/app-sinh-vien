import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_xe.dart';

abstract interface class BookingXeService {
  Future<List<BookingXe>> getDanhSachYeuCau();

  /// Lưu yêu cầu mới; Firestore gán id, status = "pending".
  Future<BookingXe> guiYeuCau(BookingXe booking);
}

class FirestoreBookingXeService implements BookingXeService {
  FirestoreBookingXeService({this._firestore});

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      (_firestore ?? FirebaseFirestore.instance).collection('booking_xe');

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
    final map = booking.toMap()
      ..remove('id')
      ..['status'] = 'pending';
    final ref = await _bookings.add({
      ...map,
      // Firestore lưu thời điểm dạng timestamp thay vì chuỗi ISO.
      'scheduledAt': Timestamp.fromDate(booking.scheduledAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return BookingXe.fromMap({...map, 'id': ref.id});
  }

  static BookingXe _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = {...?doc.data(), 'id': doc.id};
    final scheduledAt = data['scheduledAt'];
    if (scheduledAt is Timestamp) {
      data['scheduledAt'] = scheduledAt.toDate().toUtc().toIso8601String();
    }
    return BookingXe.fromMap(data);
  }
}
