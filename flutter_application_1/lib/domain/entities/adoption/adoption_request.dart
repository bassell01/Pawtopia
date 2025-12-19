class AdoptionRequest {
  final String id;
  final String petId;
  final String adopterId;
  final String? shelterId;

  /// pending | approved | rejected
  final String status;

  final String? note;
  final DateTime createdAt;

  const AdoptionRequest({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    required this.note,
    required this.createdAt,
  });
}
