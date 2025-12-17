import '../../domain/entities/pets/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pets/pet_local_data_source.dart';
import '../datasources/pets/pet_remote_data_source.dart';
import '../models/pets/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl({
    required PetRemoteDataSource remoteDataSource,
    required PetLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final PetRemoteDataSource _remote;
  final PetLocalDataSource _local;

  @override
  Future<List<Pet>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) async {
    final models = await _remote.getPets(
      type: type,
      location: location,
      onlyAvailable: onlyAvailable,
    );
    await _local.cachePets(models);
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Stream<List<Pet>> watchPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) {
    return _remote
        .watchPets(type: type, location: location, onlyAvailable: onlyAvailable)
        .map((e) => e.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Pet> getPetDetails(String petId) async {
    return (await _remote.getPetDetails(petId)).toEntity();
  }

  @override
  Future<List<Pet>> searchPets({required String query}) async {
    return (await _remote.searchPets(query: query))
        .map((e) => e.toEntity())
        .toList();
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
    return (await _remote.filterPets(
      type: type,
      gender: gender,
      location: location,
      minAgeInMonths: minAgeInMonths,
      maxAgeInMonths: maxAgeInMonths,
      onlyAvailable: onlyAvailable,
    ))
        .map((e) => e.toEntity())
        .toList();
  }

  @override
  Future<String> addPet(Pet pet) {
    return _remote.addPet(PetModel.fromEntity(pet));
  }

  @override
  Future<void> updatePet(Pet pet) {
    return _remote.updatePet(PetModel.fromEntity(pet));
  }

  @override
  Future<void> deletePet(String petId) {
    return _remote.deletePet(petId);
  }

  @override
  Future<void> markAdopted({
    required String petId,
    required bool isAdopted,
  }) {
    return _remote.markAdopted(petId: petId, isAdopted: isAdopted);
  }
}
