import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class AddPet {
  final PetRepository _repository;

  AddPet(this._repository);

  Future<String> call(Pet pet) {
    return _repository.addPet(pet);
  }
}
