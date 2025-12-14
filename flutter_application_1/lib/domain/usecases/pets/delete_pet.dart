import '../../repositories/pet_repository.dart';

class DeletePet {
  final PetRepository _repository;

  DeletePet(this._repository);

  Future<void> call(String petId) {
    return _repository.deletePet(petId);
  }
}
