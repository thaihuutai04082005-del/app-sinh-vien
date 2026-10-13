import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/xe_don_tro/models/booking_xe.dart';
import 'package:app_sinh_vien/features/xe_don_tro/models/tai_xe.dart';
import 'package:app_sinh_vien/features/xe_don_tro/screens/booking_xe_detail_screen.dart';
import 'package:app_sinh_vien/features/xe_don_tro/screens/xe_don_tro_screen.dart';
import 'package:app_sinh_vien/features/xe_don_tro/services/xe_dich_vu.dart';
import 'package:app_sinh_vien/features/xe_don_tro/services/xe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<void> luuHoSoTaiXe({
    required String vehicleType,
    required String area,
    required String priceReference,
    String description = '',
  }) async => kho.taiXe.add(
    TaiXe(
      driverId: uid,
      name: 'Tài xế $uid',
      vehicleType: vehicleType,
      area: area,
      priceReference: priceReference,
      driverVerified: true,
    ),
  );

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
      case 'huy':
        d['status'] = 'cancelled';
        d['cancelReason'] = reason;
      default:
        throw const ApiException('Không hỗ trợ trong test');
    }
  }
}

XeDichVu _dv(_Kho kho, String uid) => XeDichVu(
  uid: uid,
  xe: _FakeXe(kho, uid),
  storage: _Storage(),
  pickImages: (_) async => [XFile.fromData(png, name: 'do.png')],
);

const _taiXeMau = TaiXe(
  driverId: 'tx',
  name: 'Anh Tư',
  vehicleType: 'xe_ba_gac',
  area: 'Thủ Đức',
  priceReference: '150k/chuyến',
  driverVerified: true,
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
        ),
      ]);
    await _pump(tester, XeDonTroScreen(dv: _dv(kho, 'sv')));

    expect(find.text('Anh Tư'), findsOneWidget);
    expect(find.text('Chính tôi'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Xe máy chở hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Anh Tư'), findsNothing);
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

  testWidgets('chưa có hồ sơ tài xế thì mời đăng ký, đăng ký xong hiện hồ sơ', (
    tester,
  ) async {
    final kho = _Kho();
    await _pump(tester, XeDonTroScreen(dv: _dv(kho, 'u')));
    await tester.tap(find.text('Tôi là tài xế'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký làm tài xế'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Loại xe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xe tải nhỏ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Khu vực hoạt động'),
      'Bình Thạnh',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bảng giá tham khảo'),
      '200k/chuyến',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tài xế u'), findsOneWidget);
    expect(find.text('Đang nhận đơn mới'), findsOneWidget);
    expect(find.text('Chưa có khách gửi yêu cầu.'), findsOneWidget);
  });
}
