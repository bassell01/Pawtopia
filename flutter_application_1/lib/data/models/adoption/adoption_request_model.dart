import '../../../domain/entities/adoption/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
  const AdoptionRequestModel({
    required super.id,
    required super.petId,
    required super.adopterId,
    required super.shelterId,
    required super.status,
    required super.note,
    required super.createdAt,
  });

  factory AdoptionRequestModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    DateTime parsedCreatedAt;
    if (createdAt is DateTime) {
      parsedCreatedAt = createdAt;
    } else if (createdAt != null && createdAt.toString().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return AdoptionRequestModel(
      id: id,
      petId: (map['petId'] ?? '') as String,
      adopterId: (map['adopterId'] ?? '') as String,
      shelterId: map['shelterId'] as String?,
      status: (map['status'] ?? 'pending') as String,
      note: map['note'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'petId': petId,
        'adopterId': adopterId,
        'shelterId': shelterId,
        'status': status,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  AdoptionRequest toEntity() => AdoptionRequest(
        id: id,
        petId: petId,
        adopterId: adopterId,
        shelterId: shelterId,
        status: status,
        note: note,
        createdAt: createdAt,
      );
}
