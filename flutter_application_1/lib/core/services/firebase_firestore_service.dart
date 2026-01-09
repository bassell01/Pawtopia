import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseFirestoreService {
  FirebaseFirestoreService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> col(String path) => _db.collection(path);


  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String path) {
    return _db.collection(path).snapshots();
  }

  Future<void> setDoc(String docPath, Map<String, dynamic> data, {bool merge = true}) {
    return _db.doc(docPath).set(data, SetOptions(merge: merge));
  }
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction tx) handler,
  ) {
    return _db.runTransaction(handler);
  }
}

final firebaseFirestoreServiceProvider = Provider<FirebaseFirestoreService>((ref) {
  return FirebaseFirestoreService(FirebaseFirestore.instance);
});

final firestoreServiceProvider = firebaseFirestoreServiceProvider;
  

