class Favorite {
  final String id;        // favorite document id
  final String userId;
  final String petId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.petId,
    required this.createdAt,
  });

  Favorite copyWith({
    String? id,
    String? userId,
    String? petId,
    DateTime? createdAt,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
