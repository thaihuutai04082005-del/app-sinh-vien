import 'housing_listing.dart';

abstract interface class HousingRepository {
  Future<List<HousingListing>> findAll();
  Future<HousingListing?> findById(String id);
}
