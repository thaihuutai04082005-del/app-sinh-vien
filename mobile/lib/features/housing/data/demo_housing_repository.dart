import '../domain/housing_listing.dart';
import '../domain/housing_repository.dart';

/// Dữ liệu minh họa dành riêng cho bản beta công khai.
class DemoHousingRepository implements HousingRepository {
  static const _listings = <HousingListing>[
    HousingListing(
      id: 'demo-cao-lanh-studio',
      ownerId: 'demo-owner-1',
      title: 'Studio gần Đại học Đồng Tháp',
      address: 'Phường 6, TP. Cao Lãnh, Đồng Tháp',
      price: 2600000,
      area: 24,
      roomType: RoomType.studio,
      amenities: ['Máy lạnh', 'Wifi', 'Chỗ để xe'],
      isVerified: true,
    ),
    HousingListing(
      id: 'demo-tan-quy-dong',
      ownerId: 'demo-owner-2',
      title: 'Phòng riêng khu Tân Quy Đông',
      address: 'Tân Quy Đông, TP. Sa Đéc, Đồng Tháp',
      price: 1900000,
      area: 18,
      roomType: RoomType.privateRoom,
      amenities: ['Wifi', 'Gác lửng', 'Giờ giấc tự do'],
      isVerified: true,
    ),
    HousingListing(
      id: 'demo-o-ghep-my-phu',
      ownerId: 'demo-owner-3',
      title: 'Tìm bạn ở ghép khu Mỹ Phú',
      address: 'Mỹ Phú, TP. Cao Lãnh, Đồng Tháp',
      price: 1100000,
      area: 28,
      roomType: RoomType.sharedRoom,
      amenities: ['Bếp', 'Máy giặt', 'Wifi'],
      isVerified: false,
    ),
    HousingListing(
      id: 'demo-an-binh',
      ownerId: 'demo-owner-4',
      title: 'Phòng sáng thoáng gần bến xe',
      address: 'An Bình, TP. Cao Lãnh, Đồng Tháp',
      price: 2200000,
      area: 20,
      roomType: RoomType.privateRoom,
      amenities: ['Ban công', 'Chỗ để xe', 'Wifi'],
      isVerified: true,
    ),
  ];

  @override
  Future<List<HousingListing>> findAll() async => _listings;

  @override
  Future<HousingListing?> findById(String id) async {
    for (final listing in _listings) {
      if (listing.id == id) return listing;
    }
    return null;
  }
}
