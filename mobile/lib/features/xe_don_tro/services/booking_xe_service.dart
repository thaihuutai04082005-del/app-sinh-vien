import '../../../core/services/api_client.dart';
import '../models/booking_xe.dart';

abstract interface class BookingXeService {
  Future<List<BookingXe>> getDanhSachYeuCau();

  /// Lưu yêu cầu mới; server gán id, status = "pending".
  Future<BookingXe> guiYeuCau(BookingXe booking);
}

class CloudflareBookingXeService implements BookingXeService {
  CloudflareBookingXeService({ApiClient? api}) : _api = api ?? ApiClient();

  static const _collection = 'booking_xe';
  final ApiClient _api;

  @override
  Future<List<BookingXe>> getDanhSachYeuCau() async =>
      (await _api.list(_collection)).map(BookingXe.fromMap).toList();

  @override
  Future<BookingXe> guiYeuCau(BookingXe booking) async =>
      BookingXe.fromMap(await _api.create(_collection, booking.toMap()));
}
