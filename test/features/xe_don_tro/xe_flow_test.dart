import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/models/xac_thuc.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/xe_don_tro/models/booking_xe.dart';
import 'package:app_sinh_vien/features/xe_don_tro/models/tai_xe.dart';
import 'package:app_sinh_vien/features/xe_don_tro/screens/booking_xe_detail_screen.dart';
import 'package:app_sinh_vien/features/xe_don_tro/screens/xe_don_tro_screen.dart';
import 'package:app_sinh_vien/features/xe_don_tro/services/xe_dich_vu.dart';
import 'package:app_sinh_vien/features/xe_don_tro/services/xe_service.dart';
import 'package:app_sinh_vien/shared/models/danh_gia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../fakes/danh_gia_gia.dart';
import '../../fakes/xac_thuc_gia.dart';
import '../shop/fakes.dart' show png;

class _Storage implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$folder/$fileName';
}

/// Dữ liệu dùng chung giữa sinh viên và tài xế trong 1 test.
class _Kho {
  final taiXe = <TaiXe>[];
  final don = <String, Map<String, dynamic>>{};
  final bangLai = <String, List<String>>{};
  final danhGia = DanhGiaGia();
}

class _FakeXe implements XeService {
  _FakeXe(this.kho, this.uid);

  final _Kho kho;
  final String uid;

  @override
  Future<List<TaiXe>> danhSachTaiXe() async => [
    for (final t in kho.taiXe)
      if (t.sanSang) t,
  ];

  @override
  Future<TaiXe?> hoSoTaiXe(String uid) async {
    for (final t in kho.taiXe) {
      if (t.driverId == uid) return t;
    }
    return null;
  }

  @override
  Future<String> luuHoSoTaiXe(HoSoTaiXeNhap h) async {
    kho.taiXe.removeWhere((t) => t.driverId == uid);
    kho.taiXe.add(
      TaiXe(
        driverId: uid,
        name: 'Tài xế $uid',
        vehicleType: h.vehicleType,
        licensePlate: h.licensePlate,
        vehiclePhotos: h.vehiclePhotos,
        area: h.area,
        priceReference: h.priceReference,
        priceTrip: h.priceTrip,
        pricePerKm: h.pricePerKm,
        priceHourly: h.priceHourly,
        driverVerified: true,
      ),
    );
    kho.bangLai[uid] = h.licensePhotos;
    return 'pending';
  }

  @override
  Future<List<String>> giayTo(String driverId) async =>
      kho.bangLai[driverId] ?? const [];

  @override
  Future<List<TaiXe>> hoSoChoDuyet() async => [
    for (final t in kho.taiXe)
      if (t.approval == 'pending') t,
  ];

  @override
  Future<void> duyetTaiXe(
    String driverId, {
    required bool dongY,
    String? lyDo,
  }) async {
    final i = kho.taiXe.indexWhere((t) => t.driverId == driverId);
    final t = kho.taiXe[i];
    kho.taiXe[i] = TaiXe(
      driverId: t.driverId,
      name: t.name,
      vehicleType: t.vehicleType,
      area: t.area,
      priceReference: t.priceReference,
      licensePlate: t.licensePlate,
      vehiclePhotos: t.vehiclePhotos,
      approval: dongY ? 'approved' : 'rejected',
      rejectReason: lyDo,
    );
  }

  @override
  Future<void> doiTrangThaiTaiXe(String status) async {}

  List<BookingXe> _theo(String truong) => [
    for (final e in kho.don.entries)
      if (e.value[truong] == uid) BookingXe.fromMap({...e.value, 'id': e.key}),
  ];

  @override
  Future<List<BookingXe>> donCuaToi() async => _theo('userId');

  @override
  Future<List<BookingXe>> donDuocGiao() async => _theo('driverId');

  @override
  Future<BookingXe> getBooking(String id) async =>
      BookingXe.fromMap({...kho.don[id]!, 'id': id});

  @override
  Future<String> guiYeuCau(YeuCauXe yeuCau) async {
    final id = 'b${kho.don.length + 1}';
    kho.don[id] = {
      ...yeuCau.toMap(),
      'userId': uid,
      'userName': 'SV $uid',
      'driverName': 'Tài xế ${yeuCau.driverId}',
      'status': 'pending',
    };
    return id;
  }

  @override
  Future<void> thaoTac(
    String bookingId,
    String hanhDong, {
    int? price,
    String? reason,
  }) async {
    final d = kho.don[bookingId]!;
    switch (hanhDong) {
      case 'baoGia':
        d['status'] = 'quoted';
        d['quotedPrice'] = price;
      case 'chapNhan':
        d['status'] = 'confirmed';
        d['driverPhone'] = '0900000000';
      case 'batDau':
        d['status'] = 'in_progress';
      case 'hoanThanh':
        d['status'] = 'done';
      case 'huy':
        d['status'] = 'cancelled';
        d['cancelReason'] = reason;
      default:
        throw const ApiException('Không hỗ trợ trong test');
    }
  }

  @override
  Future<void> danhGia(String bookingId, DanhGiaNhap danhGia) async {
    final d = kho.don[bookingId]!;
    if (d['status'] != 'done' || d['reviewed'] == true) {
      throw const ApiException('Không đánh giá được chuyến này.');
    }
    kho.danhGia.them('xe_don_tro', d['driverId'] as String, danhGia);
    d['reviewed'] = true;
  }
}

XeDichVu _dv(_Kho kho, String uid, {XacThucGia? xacThuc}) => XeDichVu(
  uid: uid,
  xe: _FakeXe(kho, uid),
  storage: _Storage(),
  xacThuc: xacThuc ?? XacThucGia.day(),
  danhGia: kho.danhGia,
  pickImages: (_) async => [XFile.fromData(png, name: 'do.png')],
);

const _taiXeMau = TaiXe(
  driverId: 'tx',
  name: 'Anh Tư',
  vehicleType: 'xe_ba_gac',
  area: 'Thủ Đức',
  priceReference: '150k/chuyến',
  driverVerified: true,
  approval: 'approved',
);

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('danh sách tìm xe không hiện chính mình, lọc theo loại xe', (
    tester,
  ) async {
    final kho = _Kho()
      ..taiXe.addAll([
        _taiXeMau,
        const TaiXe(
          driverId: 'sv',
          name: 'Chính tôi',
          vehicleType: 'xe_may',
          area: 'Q1',
          priceReference: '50k',
          approval: 'approved',
        ),
      ]);
    await _pump(tester, XeDonTroScreen(dv: _dv(kho, 'sv')));

    expect(find.text('Anh Tư'), findsOneWidget);
    expect(find.text('Chính tôi'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Xe máy chở hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Anh Tư'), findsNothing);
  });

  test('so sánh xe: xếp theo giá chuyến hoặc theo đánh giá', () {
    TaiXe tx(String id, {num? gia, num tong = 0, int luot = 0}) => TaiXe(
      driverId: id,
      name: id,
      vehicleType: 'xe_ba_gac',
      area: '',
      priceReference: '',
      priceTrip: gia,
      diem: DiemDanhGia(tong: tong, soLuot: luot),
    );
    final ds = [
      tx('a', gia: 300000, tong: 9, luot: 2),
      tx('b'),
      tx('c', gia: 150000, tong: 4, luot: 1),
      tx('d', gia: 200000, tong: 13.5, luot: 3),
    ];
    String ten(List<TaiXe> l) => l.map((t) => t.driverId).join();
    expect(ten(xepTaiXe(ds, 'gia')), 'cdab');
    // a 4,5 (2 lượt) và d 4,5 (3 lượt): nhiều lượt hơn đứng trước.
    expect(ten(xepTaiXe(ds, 'danhGia')), 'dacb');
    expect(ten(xepTaiXe(ds, null)), 'abcd');
  });

  testWidgets('đặt xe: cần ảnh và số điện thoại, gửi xong mở đơn chờ báo giá', (
    tester,
  ) async {
    final kho = _Kho()..taiXe.add(_taiXeMau);
    await _pump(tester, XeDonTroScreen(dv: _dv(kho, 'sv')));

    await tester.tap(find.text('Đặt xe, xin báo giá'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Điểm đi'),
      'KTX khu A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Điểm đến'),
      'Hẻm 12 Lê Văn Việt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số điện thoại liên hệ'),
      '123',
    );
    await tester.tap(find.text('Gửi yêu cầu báo giá'));
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    expect(find.text('Cần ít nhất 1 ảnh đồ đạc.'), findsOneWidget);
    expect(find.text('Chọn ngày giờ cần chuyển'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số điện thoại liên hệ'),
      '0912345678',
    );
    await tester.tap(find.text('Thêm ảnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn thời gian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gửi yêu cầu báo giá'));
    await tester.pumpAndSettle();

    final don = kho.don.values.single;
    expect(don['driverId'], 'tx');
    expect(don['contactPhone'], '0912345678');
    expect(find.text('Đơn chuyển trọ'), findsOneWidget);
    expect(find.text('Chờ báo giá'), findsOneWidget);
    expect(find.text('Tài xế chưa báo giá'), findsOneWidget);
    // Sinh viên không có nút báo giá.
    expect(find.text('Báo giá'), findsNothing);
    expect(find.text('Hủy yêu cầu'), findsOneWidget);
  });

  testWidgets('tài xế báo giá, sinh viên chấp nhận thì thấy số tài xế', (
    tester,
  ) async {
    final kho = _Kho()..taiXe.add(_taiXeMau);
    final id = await _dv(kho, 'sv').xe.guiYeuCau(
      YeuCauXe(
        driverId: 'tx',
        fromAddress: 'A',
        toAddress: 'B',
        scheduledAt: DateTime(2026, 10, 20, 8),
        contactPhone: '0912345678',
        itemPhotos: const ['https://cdn.test/1.jpg'],
      ),
    );

    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'tx'), bookingId: id),
    );
    expect(find.textContaining('0912345678'), findsOneWidget);
    await tester.tap(find.text('Báo giá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Giá'), '500');
    await tester.tap(find.text('Gửi báo giá'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập giá từ 1.000đ'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Giá'), '350000');
    await tester.tap(find.text('Gửi báo giá'));
    await tester.pumpAndSettle();
    expect(kho.don[id]!['quotedPrice'], 350000);
    expect(find.text('Báo lại giá'), findsOneWidget);

    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'sv'), bookingId: id),
    );
    await tester.tap(find.text('Chấp nhận giá 350.000đ'));
    await tester.pumpAndSettle();
    expect(kho.don[id]!['status'], 'confirmed');
    expect(find.textContaining('0900000000'), findsOneWidget);
  });

  testWidgets('chuyến hoàn thành thì sinh viên đánh giá tài xế một lần', (
    tester,
  ) async {
    final kho = _Kho()..taiXe.add(_taiXeMau);
    kho.don['b1'] = {
      'userId': 'sv',
      'driverId': 'tx',
      'fromAddress': 'A',
      'toAddress': 'B',
      'status': 'in_progress',
      'quotedPrice': 300000,
      'itemPhotos': ['https://cdn.test/1.jpg'],
    };
    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'sv'), bookingId: 'b1'),
    );
    expect(find.text('Đánh giá tài xế'), findsNothing);

    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'tx'), bookingId: 'b1'),
    );
    await tester.tap(find.text('Hoàn thành'));
    await tester.pumpAndSettle();
    // Tài xế không tự đánh giá mình.
    expect(find.text('Đánh giá tài xế'), findsNothing);

    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'sv'), bookingId: 'b1'),
    );
    await tester.tap(find.text('Đánh giá tài xế'));
    await tester.pumpAndSettle();
    expect(find.text('Giá đúng như báo'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('5 sao').at(i));
    }
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã đánh giá chuyến này.'), findsOneWidget);
    expect(kho.don['b1']!['reviewed'], true);
    expect(await kho.danhGia.theoDoiTuong('xe_don_tro', 'tx'), hasLength(1));
  });

  testWidgets('hủy yêu cầu phải nhập lý do', (tester) async {
    final kho = _Kho();
    kho.don['b1'] = {
      'userId': 'sv',
      'driverId': 'tx',
      'fromAddress': 'A',
      'toAddress': 'B',
      'status': 'pending',
      'itemPhotos': ['https://cdn.test/1.jpg'],
    };
    await _pump(
      tester,
      BookingXeDetailScreen(dv: _dv(kho, 'sv'), bookingId: 'b1'),
    );
    await tester.tap(find.text('Hủy yêu cầu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hủy đơn'));
    await tester.pumpAndSettle();
    expect(kho.don['b1']!['status'], 'pending');

    await tester.enterText(find.byType(TextField), 'Đổi ngày');
    await tester.tap(find.widgetWithText(FilledButton, 'Hủy đơn'));
    await tester.pumpAndSettle();
    expect(kho.don['b1']!['status'], 'cancelled');
    expect(find.text('Đổi ngày'), findsOneWidget);
  });

  testWidgets('chưa xác thực CCCD thì chưa cho đăng ký tài xế', (tester) async {
    await _pump(
      tester,
      XeDonTroScreen(
        dv: _dv(_Kho(), 'u', xacThuc: XacThucGia()),
        initialTab: 2,
      ),
    );
    await tester.tap(find.text('Đăng ký làm tài xế'));
    await tester.pumpAndSettle();
    expect(find.text('Xác thực danh tính'), findsOneWidget);
    expect(find.text('Biển số xe'), findsNothing);
  });

  testWidgets(
    'đăng ký tài xế: cần biển số, ảnh xe, bằng lái; gửi xong chờ duyệt',
    (tester) async {
      final kho = _Kho();
      await _pump(tester, XeDonTroScreen(dv: _dv(kho, 'u'), initialTab: 2));
      await tester.tap(find.text('Đăng ký làm tài xế'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Loại xe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xe tải nhỏ').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Biển số xe'),
        'abc',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Khu vực hoạt động'),
        'Bình Thạnh',
      );
      await tester.ensureVisible(find.text('Gửi hồ sơ để duyệt'));
      await tester.tap(find.text('Gửi hồ sơ để duyệt'));
      await tester.pumpAndSettle();
      expect(find.text('Biển số không hợp lệ'), findsOneWidget);
      expect(find.textContaining('Nhập ít nhất một mức giá'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Theo chuyến (từ)'),
        '200000',
      );
      expect(
        find.text('Cần ít nhất 1 ảnh xe và 1 ảnh bằng lái.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Biển số xe'),
        '59C1-234.56',
      );
      await tester.ensureVisible(find.text('Thêm ảnh').first);
      await tester.tap(find.text('Thêm ảnh').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm ảnh').last);
      await tester.tap(find.text('Thêm ảnh').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gửi hồ sơ để duyệt'));
      await tester.tap(find.text('Gửi hồ sơ để duyệt'));
      await tester.pumpAndSettle();

      final t = kho.taiXe.single;
      expect(t.licensePlate, '59C1-234.56');
      expect(t.priceTrip, 200000);
      expect(t.vehiclePhotos.single, startsWith('https://cdn.test/xe_anh/'));
      expect(
        kho.bangLai['u']!.single,
        startsWith('https://cdn.test/xe_rieng/'),
      );
      expect(find.text('Đang chờ duyệt'), findsOneWidget);
      // Chưa duyệt thì không có công tắc nhận đơn.
      expect(find.text('Đang nhận đơn mới'), findsNothing);
    },
  );

  testWidgets('admin Xe dọn trọ duyệt hồ sơ thì tài xế hết chờ duyệt', (
    tester,
  ) async {
    final kho = _Kho()
      ..taiXe.add(
        const TaiXe(
          driverId: 'tx2',
          name: 'Chú Năm',
          vehicleType: 'xe_tai_nho',
          area: 'Q7',
          priceReference: '300k',
          licensePlate: '51F12345',
        ),
      )
      ..bangLai['tx2'] = ['https://cdn.test/bang.jpg'];
    final admin = _dv(
      kho,
      'ad',
      xacThuc: XacThucGia(quyen: const QuyenAdmin(xe: true)),
    );
    await _pump(tester, XeDonTroScreen(dv: admin));
    // Chưa duyệt thì sinh viên không thấy.
    expect(find.text('Chú Năm'), findsNothing);

    await tester.tap(find.text('Duyệt tài xế'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Biển số 51F12345'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Duyệt'));
    await tester.pumpAndSettle();
    expect(kho.taiXe.single.approval, 'approved');
    expect(find.text('Không có hồ sơ nào chờ duyệt.'), findsOneWidget);
  });

  testWidgets('không phải admin thì không thấy nút duyệt', (tester) async {
    await _pump(tester, XeDonTroScreen(dv: _dv(_Kho(), 'sv')));
    expect(find.text('Duyệt tài xế'), findsNothing);
  });
}
