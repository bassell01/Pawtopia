import '../entities/favorites/favorite.dart';
import '../entities/pets/pet.dart';

abstract class FavoritesRepository {
  /// Get all favorite records for a user.
  Future<List<Favorite>> getFavorites(String userId);

  /// Sometimes it's useful to directly fetch the pet list of favorites.
  Future<List<Pet>> getFavoritePets(String userId);

  Future<void> addToFavorites({
    required String userId,
    required String petId,
  });

  Future<void> removeFromFavorites({
    required String userId,
    required String petId,
  });

  /// Optional utility for quick check (for UI heart icon).
  Future<bool> isFavorite({
    required String userId,
    required String petId,
  });
}
