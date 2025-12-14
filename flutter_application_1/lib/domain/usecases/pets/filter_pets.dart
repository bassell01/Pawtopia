import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class FilterPets {
  final PetRepository _repository;

  FilterPets(this._repository);

  Future<List<Pet>> call({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  }) {
    return _repository.filterPets(
      type: type,
      gender: gender,
      location: location,
      minAgeInMonths: minAgeInMonths,
      maxAgeInMonths: maxAgeInMonths,
      onlyAvailable: onlyAvailable,
    );
  }
}
