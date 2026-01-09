import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/exceptions.dart';
import '../../models/adoption/adoption_request_model.dart';

abstract class AdoptionRemoteDataSource {
  Future<String> createRequest(AdoptionRequestModel request);

  /// pending requests (not expired)
  Stream<List<AdoptionRequestModel>> watchMyRequests(String requesterId);

  /// incoming pending requests (not expired)
  Stream<List<AdoptionRequestModel>> watchIncomingRequests(String ownerId);

  /// accepted history (not expired)
  Stream<List<AdoptionRequestModel>> watchMyAcceptedRequests(String requesterId);

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

  static const int _ttlDays = 7;

  Timestamp _nowTs() => Timestamp.fromDate(DateTime.now());

  @override
  Future<String> createRequest(AdoptionRequestModel request) async {
    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final expiresAt =
          Timestamp.fromDate(now.add(const Duration(days: _ttlDays)));

      // ✅ Prevent duplicates ONLY if there is a pending request that is NOT expired
      final existing = await _col
          .where('petId', isEqualTo: request.petId)
          .where('requesterId', isEqualTo: request.requesterId)
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isGreaterThan: nowTs)
          .limit(1)
          .get();

      // ✅ If exists: PATCH missing summary fields (requesterName + pet summary)
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final data = doc.data(); // Map<String, dynamic>

        final patch = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
          // OPTIONAL: refresh ttl whenever user re-submits the request
          'expiresAt': expiresAt,
        };

        // ---- requesterName: only set if old doc missing/empty
        final oldRequesterName = (data['requesterName'] as String?)?.trim();
        final newRequesterName = request.requesterName?.trim();
        if ((oldRequesterName == null || oldRequesterName.isEmpty) &&
            newRequesterName != null &&
            newRequesterName.isNotEmpty) {
          patch['requesterName'] = newRequesterName;
        }

        // ---- pet summary: fill if missing in old doc
        if ((data['petName'] == null) &&
            request.petName != null &&
            request.petName!.trim().isNotEmpty) {
          patch['petName'] = request.petName;
        }

        if ((data['petType'] == null) &&
            request.petType != null &&
            request.petType!.trim().isNotEmpty) {
          patch['petType'] = request.petType;
        }

        if ((data['petLocation'] == null) &&
            request.petLocation != null &&
            request.petLocation!.trim().isNotEmpty) {
          patch['petLocation'] = request.petLocation;
        }

        if ((data['petPhotoUrl'] == null) &&
            request.petPhotoUrl != null &&
            request.petPhotoUrl!.trim().isNotEmpty) {
          patch['petPhotoUrl'] = request.petPhotoUrl;
        }

        await doc.reference.set(patch, SetOptions(merge: true));
        return doc.id;
      }

      // ✅ Create NEW doc each time (so after 7 days, user can request again)
      final doc = _col.doc();

      final data = request.toJson()
        ..['id'] = doc.id
        ..['status'] = 'pending'
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp()
        ..['expiresAt'] = expiresAt;

      await doc.set(data, SetOptions(merge: true));
      return doc.id;
    } catch (e) {
      throw ServerException('Failed to create adoption request: $e');
    }
  }

  @override
  Stream<List<AdoptionRequestModel>> watchMyRequests(String requesterId) {
    final nowTs = _nowTs();

    return _col
        .where('requesterId', isEqualTo: requesterId)
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: nowTs)
        // required because we filter on expiresAt
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdoptionRequestModel.fromJson(d.data(), id: d.id))
            .toList());
  }

  @override
  Stream<List<AdoptionRequestModel>> watchIncomingRequests(String ownerId) {
    final nowTs = _nowTs();

    return _col
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: nowTs)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdoptionRequestModel.fromJson(d.data(), id: d.id))
            .toList());
  }

  @override
  Stream<List<AdoptionRequestModel>> watchMyAcceptedRequests(
      String requesterId) {
    final nowTs = _nowTs();

    return _col
        .where('requesterId', isEqualTo: requesterId)
        .where('status', isEqualTo: 'accepted')
        .where('expiresAt', isGreaterThan: nowTs)
        .orderBy('expiresAt')
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

        // ✅ If accepted: mark pet adopted + reject other pending for same pet
        if (status == 'accepted' && petId.isNotEmpty) {
          final petRef = firestore.collection('pets').doc(petId);
          tx.update(petRef, {
            'isAdopted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final others = await firestore
              .collection('adoption_requests')
              .where('petId', isEqualTo: petId)
              .where('status', isEqualTo: 'pending')
              .get();

          for (final d in others.docs) {
            if (d.id == requestId) continue;
            tx.update(d.reference, {
              'status': 'rejected',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } catch (e) {
      throw ServerException('Failed to update request status: $e');
    }
  }
}
