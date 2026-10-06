import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vui_choi_model.dart';

class VuiChoiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> themVuiChoi(VuiChoiModel item) {
    return _db.collection('vui_choi').doc(item.id).set(item.toMap());
  }

  Future<void> taoDuLieuMau() async {
    final danhSach = [
      VuiChoiModel(
        id: 'cafe_mau_01',
        name: 'Cà phê Sân Vườn Xanh',
        images: ['https://picsum.photos/seed/cafe1/600/400'],
        category: 'cafe',
        location: const GeoPoint(10.7769, 106.7009),
        address: '123 Đường Mẫu, Quận 1',
        openHour: '07:00',
        closeHour: '22:00',
        ticketPrice: 0,
      ),
      VuiChoiModel(
        id: 'cong_vien_mau_01',
        name: 'Công viên Hồ Sen',
        images: ['https://picsum.photos/seed/park1/600/400'],
        category: 'cong_vien',
        location: const GeoPoint(10.7800, 106.6950),
        address: '45 Đường Công Viên, Quận 3',
        openHour: '05:00',
        closeHour: '21:00',
        ticketPrice: 10000,
      ),
    ];

    for (final item in danhSach) {
      await themVuiChoi(item);
    }
  }
}