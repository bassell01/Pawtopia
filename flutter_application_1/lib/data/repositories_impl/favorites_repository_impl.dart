import '../../domain/entities/favorites/favorite.dart';
import '../../domain/entities/pets/pet.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites/favorites_remote_data_source.dart';
import '../datasources/pets/pet_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({
    required FavoritesRemoteDataSource favoritesRemoteDataSource,
    required PetRemoteDataSource petRemoteDataSource,
  })  : _favoritesRemoteDataSource = favoritesRemoteDataSource,
        _petRemoteDataSource = petRemoteDataSource;

  final FavoritesRemoteDataSource _favoritesRemoteDataSource;
  final PetRemoteDataSource _petRemoteDataSource;

  @override
  Future<List<Favorite>> getFavorites(String userId) async {
    final models = await _favoritesRemoteDataSource.getFavorites(userId);
    return models
        .map(
          (m) => Favorite(
            id: m.id,
            userId: m.userId,
            petId: m.petId,
            createdAt: m.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<Pet>> getFavoritePets(String userId) async {
    final favorites = await _favoritesRemoteDataSource.getFavorites(userId);

    // Simple implementation – multiple reads; you can optimize later.
    final pets = <Pet>[];
    for (final fav in favorites) {
      final petModel = await _petRemoteDataSource.getPetDetails(fav.petId);
      pets.add(petModel.toEntity());
    }
    return pets;
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required String petId,
  }) {
    return _favoritesRemoteDataSource.addToFavorites(
      userId: userId,
      petId: petId,
    );
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String petId,
  }) {
    return _favoritesRemoteDataSource.removeFromFavorites(
      userId: userId,
      petId: petId,
    );
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String petId,
  }) {
    return _favoritesRemoteDataSource.isFavorite(
      userId: userId,
      petId: petId,
    );
  }
}
