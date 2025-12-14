import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class UpdatePet {
  final PetRepository _repository;

  UpdatePet(this._repository);

  Future<void> call(Pet pet) {
    return _repository.updatePet(pet);
  }
}
