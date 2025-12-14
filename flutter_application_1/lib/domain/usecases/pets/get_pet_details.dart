import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class GetPetDetails {
  final PetRepository _repository;

  GetPetDetails(this._repository);

  Future<Pet> call(String petId) {
    return _repository.getPetDetails(petId);
  }
}
