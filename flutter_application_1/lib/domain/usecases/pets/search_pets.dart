import '../../entities/pets/pet.dart';
import '../../repositories/pet_repository.dart';

class SearchPets {
  final PetRepository _repository;

  SearchPets(this._repository);

  Future<List<Pet>> call(String query) {
    return _repository.searchPets(query: query);
  }
}
