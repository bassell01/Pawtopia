import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/admin/dashboard_stats.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _db;
  AdminRemoteDataSource(this._db);

  Future<int> _countQuery(Query q) async {
    final snap = await q.get();
    return snap.size;
  }

  Future<DashboardStats> getDashboardStats() async {
    final r = await Future.wait<int>([
      // pets
      _countQuery(_db.collection('pets')),
      _countQuery(_db.collection('pets').where('isAdopted', isEqualTo: false)), // ✅ available
      _countQuery(_db.collection('pets').where('isAdopted', isEqualTo: true)),  // ✅ adopted

      // users roles (NOT profiles)
      _countQuery(_db.collection('users').where('role', isEqualTo: 'user')),
      _countQuery(_db.collection('users').where('role', isEqualTo: 'shelter')),
      _countQuery(_db.collection('users').where('role', isEqualTo: 'admin')),

      // adoption requests
      _countQuery(_db.collection('adoption_requests').where('status', isEqualTo: 'pending')),
      _countQuery(_db.collection('adoption_requests').where('status', isEqualTo: 'approved')),
      _countQuery(_db.collection('adoption_requests').where('status', isEqualTo: 'rejected')),
      _countQuery(_db.collection('adoption_requests').where('status', isEqualTo: 'completed')),
    ]);

    return DashboardStats(
      totalPets: r[0],
      availablePets: r[1],
      adoptedPets: r[2],
      totalAdopters: r[3],
      totalShelters: r[4],
      totalAdmins: r[5],
      pendingRequests: r[6],
      approvedRequests: r[7],
      rejectedRequests: r[8],
      completedRequests: r[9],
    );
  }

  // ---------- Users ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _db.collection('users').snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }
  //Create user doc (Firestore only)
Future<String> createUserDoc(Map<String, dynamic> data) async {
  final doc = _db.collection('users').doc(); // auto id
  await doc.set({
    ...data,
    'id': doc.id,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  return doc.id;
}

  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set(
      {'role': role, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  //Update user doc (adds/updates fields)
Future<void> updateUserInfo({
  required String uid,
  required Map<String, dynamic> data,
}) async {
  await _db.collection('users').doc(uid).set(
    {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true), //important: merge adds fields without deleting others
  );
}
//Delete user doc (Firestore only)
Future<void> deleteUserDoc(String uid) async {
  await _db.collection('users').doc(uid).delete();
}
Future<void> deleteUserField({
  required String uid,
  required String fieldName,
}) async {
  await _db.collection('users').doc(uid).update({
    fieldName: FieldValue.delete(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}




  // ---------- Pets ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> petsStream() {
    return _db.collection('pets').orderBy('createdAt', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPetDoc(String petId) {
    return _db.collection('pets').doc(petId).get();
  }

  Future<void> setPetAdopted({
    required String petId,
    required bool isAdopted,
  }) async {
    await _db.collection('pets').doc(petId).update({
      'isAdopted': isAdopted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePetInfo({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('pets').doc(petId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getUserNameById(String uid) async {
  final doc = await _db.collection('users').doc(uid).get();
  if (!doc.exists) return null;

  final data = doc.data();
  return (data?['name'] ?? data?['fullName'])?.toString();
}


  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
  }

  ////////// adoption request
  Stream<QuerySnapshot<Map<String, dynamic>>> adoptionRequestsStream() {
  return _db
      .collection('adoption_requests')
      .orderBy('createdAt', descending: true)
      .snapshots();
}
Future<Map<String, dynamic>?> getUserById(String uid) async {
  if (uid.isEmpty) return null;
  final doc = await _db.collection('users').doc(uid).get();
  return doc.data();
}

Future<Map<String, dynamic>?> getPetById(String petId) async {
  if (petId.isEmpty) return null;
  final doc = await _db.collection('pets').doc(petId).get();
  return doc.data();
}


}
