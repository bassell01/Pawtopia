class Pet {
  final String id;
  final String name;
  final String type;          // e.g. "dog", "cat"
  final String? breed;
  final int? ageInMonths;     // store age in months for simplicity
  final String? gender;       // e.g. "male", "female"
  final String? size;         // e.g. "small", "medium", "large"
  final String? description;
  final String? location;     // city/area
  final List<String> photoUrls;
  final bool isAdopted;
  final String ownerId;       // shelter or individual
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Pet({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    this.ageInMonths,
    this.gender,
    this.size,
    this.description,
    this.location,
    this.photoUrls = const [],
    this.isAdopted = false,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  Pet copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    int? ageInMonths,
    String? gender,
    String? size,
    String? description,
    String? location,
    List<String>? photoUrls,
    bool? isAdopted,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      description: description ?? this.description,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      isAdopted: isAdopted ?? this.isAdopted,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
