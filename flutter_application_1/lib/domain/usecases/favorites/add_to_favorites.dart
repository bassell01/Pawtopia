import '../../repositories/favorites_repository.dart';

class AddToFavorites {
  final FavoritesRepository _repository;

  AddToFavorites(this._repository);

  Future<void> call({
    required String userId,
    required String petId,
  }) {
    return _repository.addToFavorites(
      userId: userId,
      petId: petId,
    );
  }
}

