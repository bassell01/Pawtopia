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

// Firestore implementation of AdoptionRemoteDataSource
class AdoptionRemoteDataSourceImpl implements AdoptionRemoteDataSource {
  final FirebaseFirestore firestore;

  AdoptionRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('adoption_requests');

  // TTL: request expires after 7 days (user can re-request after expiry)
  static const int _ttlDays = 7;

  Timestamp _nowTs() => Timestamp.fromDate(DateTime.now());

  // Create request document and return its generated ID
  @override
  Future<String> createRequest(AdoptionRequestModel request) async {
    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final expiresAt =
          Timestamp.fromDate(now.add(const Duration(days: _ttlDays)));

      // Prevent duplicates ONLY if there is a pending request that is NOT expired
      final existing = await _col
          .where('petId', isEqualTo: request.petId)
          .where('requesterId', isEqualTo: request.requesterId)
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isGreaterThan: nowTs)
          .limit(1)
          .get();

      //If exists: PATCH missing summary fields (requesterName + pet summary)
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final data = doc.data(); // Map<String, dynamic>

        final patch = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
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

      // No duplicate found -> create a new request document
      //Create NEW doc each time (so after 7 days, user can request again)
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

  ///-----------------UPDATE STATE-------------
  // Update adoption request status; on accept also create chat thread + welcome message + mark pet adopted
  @override
  Future<void> updateStatus({
    required String requestId,
    required String status,
    String? threadId,
  }) async {
    try {
      // Reference to adoption_requests/{requestId}
      final reqRef = _col.doc(requestId);

      String petId = '';
      String ownerId = '';
      String requesterId = '';
      String requesterName = '';
      String petName = '';

      await firestore.runTransaction((tx) async {
        // ================= READS FIRST =================
        final reqSnap = await tx.get(reqRef);
        if (!reqSnap.exists) throw ServerException('Request not found');

        final data = reqSnap.data() as Map<String, dynamic>;
        petId = (data['petId'] ?? '') as String;
        ownerId = (data['ownerId'] ?? '') as String;
        requesterId = (data['requesterId'] ?? '') as String;
        requesterName = ((data['requesterName'] ?? '') as String).trim();
        petName = ((data['petName'] ?? '') as String).trim();

        final oldStatus = (data['status'] ?? '') as String;

        //prevent re-accept (stops duplicates)
        if (status == 'accepted' && oldStatus == 'accepted') {
          return;
        }

        // ONE thread per pair (owner + requester), even if different pets.
        final ids = [ownerId, requesterId]..sort();
        final resolvedThreadId = '${ids.join("_")}_noPet';

        //Using EXISTING chat system collections
        final chatThreadRef =
            firestore.collection('chat_threads').doc(resolvedThreadId);

        // welcome message per accepted request (so each accepted pet sends a message)
        final welcomeMsgRef =
            chatThreadRef.collection('messages').doc('welcome_$requestId');

        DocumentSnapshot<Map<String, dynamic>>? threadSnap;
        DocumentSnapshot<Map<String, dynamic>>? welcomeSnap;

        String ownerName = '';

        if (status == 'accepted') {
          // READ thread + welcome FIRST
          threadSnap = await tx.get(chatThreadRef);
          welcomeSnap = await tx.get(welcomeMsgRef);

          // READ owner profile FIRST
          final ownerProfileRef = firestore.collection('profiles').doc(ownerId);
          final ownerProfileSnap = await tx.get(ownerProfileRef);
          final ownerData = ownerProfileSnap.data();
          ownerName = ((ownerData?['displayName'] ?? '') as String).trim();
        }

        // ================= WRITES =================
        // 1) update request + store threadId
        tx.update(reqRef, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          if (status == 'accepted') 'threadId': resolvedThreadId,
        });

        // 2) if accepted: pet adopted + create chat thread + welcome msg
        if (status == 'accepted' && petId.isNotEmpty) {
          // mark pet adopted
          final petRef = firestore.collection('pets').doc(petId);
          tx.update(petRef, {
            'isAdopted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // create thread doc if not exists (schema matches your chat system)
          if (threadSnap == null || !threadSnap.exists) {
            tx.set(chatThreadRef, {
              'participantIds': [ownerId, requesterId],
              'petId': null, // per pair thread
              'requestId': requestId,
              'lastMessage': null,
              'lastMessageAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          // welcome message per request (only once for this requestId)
          if (welcomeSnap == null || !welcomeSnap.exists) {
            final hiName = requesterName.isNotEmpty ? requesterName : 'there';
            final oName = ownerName.isNotEmpty ? ownerName : 'Owner';
            final pName = petName.isNotEmpty ? petName : 'pet';

            final text =
                'Hi, $hiName 👋\n'
                '$oName With You\n'
                'Do you Want more details about the $pName you requested';

            tx.set(welcomeMsgRef, {
              'senderId': ownerId,
              'text': text,
              'sentAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

            // update preview
            tx.set(
              chatThreadRef,
              {
                'lastMessage': text,
                'lastMessageAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      });

      // ================= AFTER TRANSACTION =================
      // reject other pending requests for same pet
      if (status == 'accepted' && petId.isNotEmpty) {
        final others = await firestore
            .collection('adoption_requests')
            .where('petId', isEqualTo: petId)
            .where('status', isEqualTo: 'pending')
            .get();

        final batch = firestore.batch();
        for (final d in others.docs) {
          if (d.id == requestId) continue;
          batch.update(d.reference, {
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      throw ServerException('Failed to update request status: $e');
    }
  }
}
