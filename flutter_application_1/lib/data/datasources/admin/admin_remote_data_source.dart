import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _db;
  AdminRemoteDataSource(this._db);

  Future<int> _count(String collection) async {
    final snap = await _db.collection(collection).get();
    return snap.size;
  }

  Future<int> _countPendingRequests() async {
    final snap = await _db
        .collection('adoption_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.size;
  }

  Future<Map<String, int>> getStatsCounts() async {
    final pets = await _count('pets');
    final users = await _count('users');
    final pending = await _countPendingRequests();

    return {
      'pets': pets,
      'users': users,
      'pending': pending,
    };
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}
