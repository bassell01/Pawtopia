import '../../entities/favorites/favorite.dart';
import '../../entities/pets/pet.dart';
import '../../repositories/favorites_repository.dart';

class GetFavorites {
  final FavoritesRepository _repository;

  GetFavorites(this._repository);

  /// If you want Favorite records
  Future<List<Favorite>> call(String userId) {
    return _repository.getFavorites(userId);
  }
}

class GetFavoritePets {
  final FavoritesRepository _repository;

  GetFavoritePets(this._repository);

  /// Directly get Pet entities of favorites
  Future<List<Pet>> call(String userId) {
    return _repository.getFavoritePets(userId);
  }
}
