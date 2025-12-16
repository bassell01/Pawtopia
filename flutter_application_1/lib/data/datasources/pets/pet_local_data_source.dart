import '../../models/pets/pet_model.dart';

abstract class PetLocalDataSource {
  Future<void> cachePets(List<PetModel> pets);
  Future<List<PetModel>> getCachedPets();
  Future<void> clearCache();
}

class PetLocalDataSourceImpl implements PetLocalDataSource {
  // Simple in-memory cache placeholder.
  // Replace later with Hive/SharedPreferences if needed.
  List<PetModel>? _cachedPets;

  @override
  Future<void> cachePets(List<PetModel> pets) async {
    _cachedPets = List<PetModel>.from(pets);
  }

  @override
  Future<List<PetModel>> getCachedPets() async {
    return _cachedPets ?? <PetModel>[];
  }

  @override
  Future<void> clearCache() async {
    _cachedPets = null;
  }
}
