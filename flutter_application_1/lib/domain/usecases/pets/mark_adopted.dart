import '../../repositories/pet_repository.dart';

class MarkAdopted {
  final PetRepository _repo;
  MarkAdopted(this._repo);

  Future<void> call({
    required String petId,
    required bool isAdopted,
  }) {
    return _repo.markAdopted(petId: petId, isAdopted: isAdopted);
  }
}
