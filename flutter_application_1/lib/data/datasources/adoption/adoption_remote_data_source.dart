import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/adoption/adoption_request_model.dart';

class AdoptionRemoteDataSource {
  final FirebaseFirestore _db;

  AdoptionRemoteDataSource(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('adoption_requests');

  Future<void> submit(AdoptionRequestModel model) async {
    await _col.doc(model.id).set(model.toMap());
  }

  Future<List<AdoptionRequestModel>> getByAdopter(String adopterId) async {
    final q = await _col.where('adopterId', isEqualTo: adopterId).get();
    return q.docs.map((d) => AdoptionRequestModel.fromMap(d.id, d.data())).toList();
  }

  Future<List<AdoptionRequestModel>> getByShelter(String shelterId) async {
    final q = await _col.where('shelterId', isEqualTo: shelterId).get();
    return q.docs.map((d) => AdoptionRequestModel.fromMap(d.id, d.data())).toList();
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    await _col.doc(requestId).update({'status': status});
  }

  Stream<List<AdoptionRequestModel>> streamByAdopter(String adopterId) {
    return _col
        .where('adopterId', isEqualTo: adopterId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdoptionRequestModel.fromMap(d.id, d.data()))
            .toList());
  }
}
