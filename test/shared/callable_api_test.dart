import 'package:app_sinh_vien/features/shop/services/don_hang_service.dart';
import 'package:app_sinh_vien/features/shop/services/uu_dai_service.dart';
import 'package:app_sinh_vien/features/xe_don_tro/services/xe_service.dart';
import 'package:app_sinh_vien/shared/services/callable_api.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

class _Result<T> implements HttpsCallableResult<T> {
  _Result(this.data);

  @override
  final T data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Callable implements HttpsCallable {
  final calls = <Map<String, dynamic>>[];

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    calls.add(Map<String, dynamic>.from(parameters as Map));
    return _Result<T>(<String, dynamic>{} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Functions implements FirebaseFunctions {
  final callable = _Callable();
  String? name;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    this.name = name;
    return callable;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Shop: xác nhận đơn giữ tên API và thao tác riêng biệt', () async {
    final fn = _Functions();
    final service = FirebaseDonHangService(
      uid: 'shop',
      api: FirebaseCallableApi('shopApi', fn),
    );
    await service.thaoTac('order-1', 'xacNhan');
    expect(fn.name, 'shopApi');
    expect(fn.callable.calls.single, {
      'hanhDong': 'thaoTacDon',
      'orderId': 'order-1',
      'thaoTac': 'xacNhan',
    });
  });

  test('Xe: báo giá gửi đúng tên API, thao tác và giá', () async {
    final fn = _Functions();
    final service = FirebaseXeService(
      uid: 'driver',
      api: FirebaseCallableApi('xeApi', fn),
    );
    await service.thaoTac('booking-1', 'baoGia', price: 150000);
    expect(fn.name, 'xeApi');
    expect(fn.callable.calls.single, {
      'hanhDong': 'thaoTacDon',
      'bookingId': 'booking-1',
      'thaoTac': 'baoGia',
      'price': 150000,
    });
  });

  test('Trả giá: chấp nhận đề nghị không ghi đè tên API', () async {
    final fn = _Functions();
    final service = FirebaseUuDaiService(
      uid: 'shop',
      api: FirebaseCallableApi('shopApi', fn),
    );
    await service.phanHoiTraGia('offer-1', 'chapNhan');
    expect(fn.callable.calls.single, {
      'hanhDong': 'phanHoiTraGia',
      'offerId': 'offer-1',
      'thaoTac': 'chapNhan',
    });
  });

  test('Tham số không được đổi lệnh định tuyến của callable', () async {
    final fn = _Functions();
    await FirebaseCallableApi('shopApi', fn).goi('datHang', {
      'hanhDong': 'xoaSanPham',
    });
    expect(fn.callable.calls.single['hanhDong'], 'datHang');
  });
}
