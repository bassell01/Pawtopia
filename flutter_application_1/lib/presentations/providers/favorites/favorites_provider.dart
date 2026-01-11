import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../../data/datasources/favorites/favorites_remote_data_source.dart';
import '../../../data/repositories_impl/favorites_repository_impl.dart';
import '../../../domain/repositories/favorites_repository.dart';
import '../../../domain/usecases/favorites/add_to_favorites.dart';
import '../../../domain/usecases/favorites/get_favorites.dart';
import '../../../domain/usecases/favorites/remove_from_favorites.dart';

import '../auth/auth_state_provider.dart';
import '../pets/pet_providers.dart';

final favoritesRemoteDataSourceProvider =
    Provider<FavoritesRemoteDataSource>((ref) {
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

final favoritePetsProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return <dynamic>[];

  final usecase = ref.watch(getFavoritePetsUseCaseProvider);
  return usecase(user.uid);
});

final isFavoriteProvider =
    StreamProvider.family.autoDispose<bool, String>((ref, petId) async* {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    yield false;
    return;
  }

  final favs = await ref.watch(favoritePetsProvider.future);

  final isFav = favs.any((p) => (p as dynamic).id == petId);
  yield isFav;
});

final toggleFavoriteProvider =
    Provider.autoDispose<Future<void> Function(String petId)>((ref) {
  final add = ref.watch(addToFavoritesUseCaseProvider);
  final remove = ref.watch(removeFromFavoritesUseCaseProvider);

  return (String petId) async {
    final user = await ref.read(authStateProvider.future);
    if (user == null) return;

    final favs = await ref.read(favoritePetsProvider.future);
    final isFav = favs.any((p) => (p as dynamic).id == petId);

    if (isFav) {
      await remove(
        userId: user.uid,
        petId: petId,
      );
    } else {
      await add(
        userId: user.uid,
        petId: petId,
      );
    }

    // ✅ Force refresh after toggle so UI updates immediately
    ref.invalidate(favoritePetsProvider);
    ref.invalidate(isFavoriteProvider(petId));
  };
});

/// ✅ NEW: live favorites count for a pet (how many users favorited it)
final favoritesCountProvider =
    StreamProvider.family.autoDispose<int, String>((ref, petId) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.watchFavoritesCount(petId);
});
