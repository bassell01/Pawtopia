import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../models/pets/pet_model.dart';

abstract class PetRemoteDataSource {
  Future<List<PetModel>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  });

  Stream<List<PetModel>> watchPets({
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

  Future<void> markAdopted({
    required String petId,
    required bool isAdopted,
  });
}

class PetRemoteDataSourceImpl implements PetRemoteDataSource {
  PetRemoteDataSourceImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _pets =>
      _firestoreService.col('pets');

  @override
  Future<List<PetModel>> getPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) async {
    Query<Map<String, dynamic>> q = _pets;

    if (type != null) q = q.where('type', isEqualTo: type);
    if (location != null) q = q.where('location', isEqualTo: location);
    if (onlyAvailable == true) {
      q = q.where('isAdopted', isEqualTo: false);
    }

    final snap = await q.get();
    return snap.docs.map(PetModel.fromFirestore).toList();
  }


  @override
  Stream<List<PetModel>> watchPets({
    String? type,
    String? location,
    bool? onlyAvailable,
  }) {
    Query<Map<String, dynamic>> q = _pets;

    if (type != null) q = q.where('type', isEqualTo: type);
    if (location != null) q = q.where('location', isEqualTo: location);
    if (onlyAvailable == true) {
      q = q.where('isAdopted', isEqualTo: false);
    }

    return q.snapshots().map((s) {
      final list = s.docs.map(PetModel.fromFirestore).toList();

      // ✅ Client-side sort (no index needed)
      list.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        return bd.compareTo(ad); // newest first
      });

      return list;
    });
  }

  @override
  Future<PetModel> getPetDetails(String petId) async {
    final doc = await _pets.doc(petId).get();
    if (!doc.exists) throw Exception('Pet not found');
    return PetModel.fromFirestore(doc);
  }

  @override
  Future<List<PetModel>> searchPets({required String query}) async {
    final snap = await _pets
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snap.docs.map(PetModel.fromFirestore).toList();
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
    Query<Map<String, dynamic>> q = _pets;

    if (type != null) q = q.where('type', isEqualTo: type);
    if (gender != null) q = q.where('gender', isEqualTo: gender);
    if (location != null) q = q.where('location', isEqualTo: location);
    if (onlyAvailable == true) {
      q = q.where('isAdopted', isEqualTo: false);
    }
    if (minAgeInMonths != null) {
      q = q.where('ageInMonths', isGreaterThanOrEqualTo: minAgeInMonths);
    }
    if (maxAgeInMonths != null) {
      q = q.where('ageInMonths', isLessThanOrEqualTo: maxAgeInMonths);
    }

    final snap = await q.get();
    return snap.docs.map(PetModel.fromFirestore).toList();
  }

  @override
Future<String> addPet(PetModel pet) async {
  // Create pet doc
  final ref = await _pets.add(pet.toFirestore());
  final petId = ref.id;

  //Create in-app notification for the owner (shows in NotificationsCenterPage)
  final ownerId = pet.ownerId;
  if (ownerId.isNotEmpty) {
    await _firestoreService.col('profiles/$ownerId/notifications').add({
      'title': 'Pet added',
      'body': '${pet.name} is now listed for adoption.',
      'type': 'pet',
      'deepLink': '/pets/$petId',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'petId': petId,
      },
    });
  }

  return petId;
}

  @override
  Future<void> updatePet(PetModel pet) async {
    await _pets.doc(pet.id).update(pet.toFirestore());
  }

  @override
  Future<void> deletePet(String petId) async {
    await _pets.doc(petId).delete();
  }

  @override
  Future<void> markAdopted({
    required String petId,
    required bool isAdopted,
  }) async {
    await _pets.doc(petId).update({
      'isAdopted': isAdopted,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
