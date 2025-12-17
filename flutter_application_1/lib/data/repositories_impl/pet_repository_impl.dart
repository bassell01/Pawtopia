import '../../domain/entities/pets/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pets/pet_local_data_source.dart';
import '../datasources/pets/pet_remote_data_source.dart';
import '../models/pets/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl({
    required PetRemoteDataSource remoteDataSource,
    required PetLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final PetRemoteDataSource _remoteDataSource;
  final PetLocalDataSource _localDataSource;

  @override
  Future<List<Pet>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) async {
    final models = await _remoteDataSource.getPets(
      type: type,
      location: location,
      onlyAvailable: onlyAvailable,
    );

    await _localDataSource.cachePets(models);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Pet>> watchPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) {
    return _remoteDataSource
        .watchPets(type: type, location: location, onlyAvailable: onlyAvailable)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Pet> getPetDetails(String petId) async {
    final model = await _remoteDataSource.getPetDetails(petId);
    return model.toEntity();
  }

  @override
  Future<List<Pet>> searchPets({required String query}) async {
    final models = await _remoteDataSource.searchPets(query: query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Pet>> filterPets({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  }) async {
    final models = await _remoteDataSource.filterPets(
      type: type,
      gender: gender,
      location: location,
      minAgeInMonths: minAgeInMonths,
      maxAgeInMonths: maxAgeInMonths,
      onlyAvailable: onlyAvailable,
    );

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> addPet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    return _remoteDataSource.addPet(model);
  }

  @override
  Future<void> updatePet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    await _remoteDataSource.updatePet(model);
  }

  @override
  Future<void> deletePet(String petId) {
    return _remoteDataSource.deletePet(petId);
  }
}
