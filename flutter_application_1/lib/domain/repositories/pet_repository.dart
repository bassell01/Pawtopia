import '../entities/pets/pet.dart';

abstract class PetRepository {
  /// Get all pets (you can later add pagination).
  Future<List<Pet>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable, // if true → not adopted
  });

  /// Get single pet by id.
  Future<Pet> getPetDetails(String petId);

  /// Search by text (name, breed, description, etc.).
  Future<List<Pet>> searchPets({
    required String query,
  });

  /// Filter with multiple options (type, age range, gender, location).
  Future<List<Pet>> filterPets({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  });

  /// CRUD
  Future<String> addPet(Pet pet);        // returns generated id
  Future<void> updatePet(Pet pet);
  Future<void> deletePet(String petId);
}
