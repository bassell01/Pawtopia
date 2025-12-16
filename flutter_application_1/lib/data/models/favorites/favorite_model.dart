import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/favorites/favorite.dart';

class FavoriteModel extends Favorite {
  const FavoriteModel({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
  });

  factory FavoriteModel.fromEntity(Favorite favorite) {
    return FavoriteModel(
      id: favorite.id,
      userId: favorite.userId,
      petId: favorite.petId,
      createdAt: favorite.createdAt,
    );
  }

  Favorite toEntity() => Favorite(
        id: id,
        userId: userId,
        petId: petId,
        createdAt: createdAt,
      );

  factory FavoriteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FavoriteModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      petId: data['petId'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petId': petId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
