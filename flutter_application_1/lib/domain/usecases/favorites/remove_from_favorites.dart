import '../../repositories/favorites_repository.dart';

class RemoveFromFavorites {
  final FavoritesRepository _repository;

  RemoveFromFavorites(this._repository);

  Future<void> call({
    required String userId,
    required String petId,
  }) {
    return _repository.removeFromFavorites(
      userId: userId,
      petId: petId,
    );
  }
}
