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

  /// ✅ NEW: live count of how many users favorited this pet
  Stream<int> watchFavoritesCount(String petId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  FavoritesRemoteDataSourceImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestoreService.col('favorites');

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
    // ✅ Prevent duplicates (same user favorites same pet more than once)
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

    // =============================
    // Notifications part (your existing code)
    // =============================

    final petSnap = await _firestoreService.col('pets').doc(petId).get();
    final petData = petSnap.data();
    if (petData == null) return;

    final ownerId = (petData['ownerId'] as String?) ?? '';
    if (ownerId.isEmpty) return;

    // Don't notify if user favorited their own pet
    if (ownerId == userId) return;

    final petName = (petData['name'] as String?) ?? 'your pet';

    // Fetch favoriter profile name
    final senderSnap = await _firestoreService.col('profiles').doc(userId).get();
    final senderData = senderSnap.data();
    final senderName =
        (senderData?['displayName'] as String?) ??
        (senderData?['fullName'] as String?) ??
        (senderData?['email'] as String?) ??
        'Someone';

    // Create notification for the owner
    await _firestoreService.col('profiles/$ownerId/notifications').add({
      'title': 'Pet favorited',
      'body': '$senderName favorited $petName ❤️',
      'type': 'favorite',
      'deepLink': '/pets/$petId',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'petId': petId,
        'fromUserId': userId,
        'fromUserName': senderName,
      },
    });
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

  @override
  Stream<int> watchFavoritesCount(String petId) {
    // ✅ This is the key line: "how many docs have petId == this pet"
    return _favoritesCollection
        .where('petId', isEqualTo: petId)
        .snapshots()
        .map((snap) => snap.size);
  }
}
