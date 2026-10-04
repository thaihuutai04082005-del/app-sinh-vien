enum RoomType { privateRoom, sharedRoom, studio }

class HousingListing {
  const HousingListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.price,
    required this.area,
    required this.roomType,
    required this.amenities,
    required this.isVerified,
  });

  final String id;
  final String ownerId;
  final String title;
  final String address;
  final int price;
  final double area;
  final RoomType roomType;
  final List<String> amenities;
  final bool isVerified;
}
