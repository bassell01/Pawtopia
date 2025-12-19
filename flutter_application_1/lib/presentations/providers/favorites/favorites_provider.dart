import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../../data/datasources/favorites/favorites_remote_data_source.dart';
import '../../../data/repositories_impl/favorites_repository_impl.dart';
import '../../../domain/repositories/favorites_repository.dart';
import '../../../domain/usecases/favorites/add_to_favorites.dart';
import '../../../domain/usecases/favorites/get_favorites.dart';
import '../../../domain/usecases/favorites/remove_from_favorites.dart';

import '../auth/auth_state_provider.dart'; // Dev2: must exist

import '../pets/pet_providers.dart';  // provides petRemoteDataSourceProvider

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreServiceProvider);
  return FavoritesRemoteDataSourceImpl(firestore);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final favDS = ref.watch(favoritesRemoteDataSourceProvider);
  final petDS = ref.watch(petRemoteDataSourceProvider);
  return FavoritesRepositoryImpl(
    favoritesRemoteDataSource: favDS,
    petRemoteDataSource: petDS,
  );
});

final addToFavoritesUseCaseProvider = Provider<AddToFavorites>((ref) {
  return AddToFavorites(ref.watch(favoritesRepositoryProvider));
});

final removeFromFavoritesUseCaseProvider = Provider<RemoveFromFavorites>((ref) {
  return RemoveFromFavorites(ref.watch(favoritesRepositoryProvider));
});

final getFavoritePetsUseCaseProvider = Provider<GetFavoritePets>((ref) {
  return GetFavoritePets(ref.watch(favoritesRepositoryProvider));
});

/// ✅ Baseline: load favorite pets for current user (Future)
final favoritePetsProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.watch(authStateProvider.future); // Dev2
  if (user == null) return <dynamic>[];

  final usecase = ref.watch(getFavoritePetsUseCaseProvider);
  return usecase(user.uid);
});
