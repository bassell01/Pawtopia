import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/pets/pet.dart';

class PetModel extends Pet {
  const PetModel({
    required super.id,
    required super.name,
    required super.type,
    super.breed,
    super.ageInMonths,
    super.gender,
    super.size,
    super.description,
    super.location,
    super.photoUrls = const [],
    super.isAdopted = false,
    required super.ownerId,
    required super.createdAt,
    super.updatedAt,
  });

  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      id: pet.id,
      name: pet.name,
      type: pet.type,
      breed: pet.breed,
      ageInMonths: pet.ageInMonths,
      gender: pet.gender,
      size: pet.size,
      description: pet.description,
      location: pet.location,
      photoUrls: pet.photoUrls,
      isAdopted: pet.isAdopted,
      ownerId: pet.ownerId,
      createdAt: pet.createdAt,
      updatedAt: pet.updatedAt,
    );
  }

  Pet toEntity() => Pet(
        id: id,
        name: name,
        type: type,
        breed: breed,
        ageInMonths: ageInMonths,
        gender: gender,
        size: size,
        description: description,
        location: location,
        photoUrls: photoUrls,
        isAdopted: isAdopted,
        ownerId: ownerId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory PetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PetModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      breed: data['breed'] as String?,
      ageInMonths: (data['ageInMonths'] as num?)?.toInt(),
      gender: data['gender'] as String?,
      size: data['size'] as String?,
      description: data['description'] as String?,
      location: data['location'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isAdopted: data['isAdopted'] as bool? ?? false,
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'breed': breed,
      'ageInMonths': ageInMonths,
      'gender': gender,
      'size': size,
      'description': description,
      'location': location,
      'photoUrls': photoUrls,
      'isAdopted': isAdopted,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }
}
