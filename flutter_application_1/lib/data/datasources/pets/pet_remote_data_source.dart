import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../models/pets/pet_model.dart';

abstract class PetRemoteDataSource {
  Future<List<PetModel>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  });

  Future<PetModel> getPetDetails(String petId);

  Future<List<PetModel>> searchPets({
    required String query,
  });

  Future<List<PetModel>> filterPets({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  });

  Future<String> addPet(PetModel pet);

  Future<void> updatePet(PetModel pet);

  Future<void> deletePet(String petId);
}

class PetRemoteDataSourceImpl implements PetRemoteDataSource {
  PetRemoteDataSourceImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _petsCollection =>
      _firestoreService.collection('pets');

  @override
  Future<List<PetModel>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) async {
    Query<Map<String, dynamic>> query = _petsCollection;

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    if (onlyAvailable == true) {
      query = query.where('isAdopted', isEqualTo: false);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(PetModel.fromFirestore).toList();
  }

  @override
  Future<PetModel> getPetDetails(String petId) async {
    final doc = await _petsCollection.doc(petId).get();
    if (!doc.exists) {
      throw Exception('Pet not found');
    }
    return PetModel.fromFirestore(doc);
  }

  @override
  Future<List<PetModel>> searchPets({required String query}) async {
    // Simple implementation: search by name (you can improve later)
    final snapshot = await _petsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map(PetModel.fromFirestore).toList();
  }

  @override
  Future<List<PetModel>> filterPets({
    String? type,
    String? gender,
    String? location,
    int? minAgeInMonths,
    int? maxAgeInMonths,
    bool? onlyAvailable,
  }) async {
    Query<Map<String, dynamic>> query = _petsCollection;

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    if (onlyAvailable == true) {
      query = query.where('isAdopted', isEqualTo: false);
    }

    // Age range is tricky with Firestore; you might store numeric ageInMonths
    if (minAgeInMonths != null) {
      query = query.where('ageInMonths', isGreaterThanOrEqualTo: minAgeInMonths);
    }
    if (maxAgeInMonths != null) {
      query = query.where('ageInMonths', isLessThanOrEqualTo: maxAgeInMonths);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(PetModel.fromFirestore).toList();
  }

  @override
  Future<String> addPet(PetModel pet) async {
    final docRef = await _petsCollection.add(pet.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updatePet(PetModel pet) async {
    await _petsCollection.doc(pet.id).update(pet.toFirestore());
  }

  @override
  Future<void> deletePet(String petId) async {
    await _petsCollection.doc(petId).delete();
  }
}
