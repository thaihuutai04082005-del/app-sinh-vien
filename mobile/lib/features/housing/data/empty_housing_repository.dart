import '../domain/housing_listing.dart';
import '../domain/housing_repository.dart';

class EmptyHousingRepository implements HousingRepository {
  @override
  Future<List<HousingListing>> findAll() async => const [];

  @override
  Future<HousingListing?> findById(String id) async => null;
}
