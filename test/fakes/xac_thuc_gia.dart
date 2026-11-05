import 'package:app_sinh_vien/features/auth/models/xac_thuc.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';

/// XacThucService giả: trạng thái xác thực và quyền admin cố định.
class XacThucGia implements XacThucService {
  XacThucGia({
    this.trangThai = const XacThuc(),
    this.quyen = const QuyenAdmin(),
  });

  XacThuc trangThai;
  QuyenAdmin quyen;

  /// Đã OTP + đã xác thực danh tính.
  factory XacThucGia.day() => XacThucGia(
    trangThai: const XacThuc(
      sdt: '0912345678',
      sdtDaXacThuc: true,
      danhTinh: 'da_xac_thuc',
    ),
  );

  @override
  Stream<XacThuc> cuaToi(String uid) => Stream.value(trangThai);

  @override
  Stream<QuyenAdmin> quyenAdmin(String uid) => Stream.value(quyen);

  @override
  Future<String> guiOtp(String sdt) async => '';

  @override
  Future<void> xacNhanOtp(String ma) async {}

  @override
  Future<void> guiDanhTinh({
    required String hoTen,
    required String soCccd,
  }) async {}

  @override
  Stream<List<(String, String, String)>> danhTinhChoDuyet() =>
      Stream.value(const []);

  @override
  Future<void> duyetDanhTinh(
    String uid, {
    required bool dongY,
    String? lyDo,
  }) async {}
}
