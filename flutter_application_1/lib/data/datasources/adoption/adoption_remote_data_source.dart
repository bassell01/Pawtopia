import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/exceptions.dart';
import '../../models/adoption/adoption_request_model.dart';

abstract class AdoptionRemoteDataSource {
  Future<String> createRequest(AdoptionRequestModel request);

  Stream<List<AdoptionRequestModel>> watchMyRequests(String requesterId);

  Stream<List<AdoptionRequestModel>> watchIncomingRequests(String ownerId);

  Future<void> updateStatus({
    required String requestId,
    required String status, // pending/accepted/rejected/cancelled
    String? threadId,
  });
}

class AdoptionRemoteDataSourceImpl implements AdoptionRemoteDataSource {
  final FirebaseFirestore firestore;

  AdoptionRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('adoption_requests');

  @override
  Future<String> createRequest(AdoptionRequestModel request) async {
    try {
      final existing = await _col
          .where('petId', isEqualTo: request.petId)
          .where('requesterId', isEqualTo: request.requesterId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final doc = _col.doc();

      final data = request.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await doc.set(data, SetOptions(merge: true));

      return doc.id;
    } catch (e) {
      throw ServerException('Failed to create adoption request: $e');
    }
  }

  @override
  Stream<List<AdoptionRequestModel>> watchMyRequests(String requesterId) {
    return _col
        .where('requesterId', isEqualTo: requesterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdoptionRequestModel.fromJson(d.data(), id: d.id))
            .toList());
  }

  @override
  Stream<List<AdoptionRequestModel>> watchIncomingRequests(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdoptionRequestModel.fromJson(d.data(), id: d.id))
            .toList());
  }

  @override
  Future<void> updateStatus({
    required String requestId,
    required String status,
    String? threadId,
  }) async {
    try {
      final reqRef = _col.doc(requestId);

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(reqRef);
        if (!snap.exists) throw ServerException('Request not found');

        final data = snap.data() as Map<String, dynamic>;
        final petId = (data['petId'] ?? '') as String;

        tx.update(reqRef, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          if (threadId != null) 'threadId': threadId,
        });

        if (status == 'accepted' && petId.isNotEmpty) {
          final petRef = firestore.collection('pets').doc(petId);
          tx.update(petRef, {
            'isAdopted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw ServerException('Failed to update request status: $e');
    }
  }
}
