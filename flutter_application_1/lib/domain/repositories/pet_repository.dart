import '../entities/pets/pet.dart';

abstract class PetRepository {
  Future<List<Pet>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  });


  Stream<List<Pet>> watchPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  });

  Future<Pet> getPetDetails(String petId);
  Future<List<Pet>> searchPets({required String query});
  Future<List<Pet>> filterPets({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  });

  Future<String> addPet(Pet pet);
  Future<void> updatePet(Pet pet);
  Future<void> deletePet(String petId);
}
