import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class GetPets {
  final PetRepository _repository;

  GetPets(this._repository);

  Future<List<Pet>> call({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) {
    return _repository.getPets(
      type: type,
      location: location,
      onlyAvailable: onlyAvailable,
    );
  }
}
