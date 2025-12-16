import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../models/favorites/favorite_model.dart';

abstract class FavoritesRemoteDataSource {
  Future<List<FavoriteModel>> getFavorites(String userId);
  Future<void> addToFavorites({
    required String userId,
    required String petId,
  });
  Future<void> removeFromFavorites({
    required String userId,
    required String petId,
  });
  Future<bool> isFavorite({
    required String userId,
    required String petId,
  });
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  FavoritesRemoteDataSourceImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestoreService.collection('favorites');

  @override
  Future<List<FavoriteModel>> getFavorites(String userId) async {
    final snapshot =
        await _favoritesCollection.where('userId', isEqualTo: userId).get();

    return snapshot.docs.map(FavoriteModel.fromFirestore).toList();
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required String petId,
  }) async {
    final existing = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('petId', isEqualTo: petId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final model = FavoriteModel(
      id: '',
      userId: userId,
      petId: petId,
      createdAt: DateTime.now(),
    );

    await _favoritesCollection.add(model.toFirestore());
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String petId,
  }) async {
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('petId', isEqualTo: petId)
        .limit(1)
        .get();

    for (final doc in snapshot.docs) {
      await _favoritesCollection.doc(doc.id).delete();
    }
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String petId,
  }) async {
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('petId', isEqualTo: petId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
