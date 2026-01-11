import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_firestore_service.dart';

class ChatRemoteDataSource {
  final FirebaseFirestoreService _fs;
  ChatRemoteDataSource(this._fs);

  Stream<QuerySnapshot<Map<String, dynamic>>> userThreadsStream(String userId) {
    return _fs
        .col('chat_threads')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  // ✅ FIX: order by createdAt (more reliable for new welcome msg)
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String threadId) {
    return _fs
        .col('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // ✅ changed from sentAt
        .snapshots();
  }

  // Future<String> createThreadIfNeeded({
  //   required List<String> participantIds,
  //   String? petId,
  // }) async {
  //   final ids = [...participantIds]..sort();
  //   final threadId = '${ids.join("_")}_${petId ?? "noPet"}';

  //   final ref = _fs.col('chat_threads').doc(threadId);
  //   final snap = await ref.get();

  //   if (!snap.exists) {
  //     await ref.set({
  //       'participantIds': ids,
  //       'petId': petId,
  //       'lastMessage': null,
  //       'lastMessageAt': FieldValue.serverTimestamp(),
  //       // ✅ ADD ONLY
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });
  //   }
  //   return threadId;
  // }

Future<String> createThreadIfNeeded({
  required List<String> participantIds,
  String? petId,
}) async {
  // 1) Normalize participants order
  final ids = [...participantIds]..sort();

  //IMPORTANT: thread is per pair ONLY (ignore petId in threadId)
  final threadId = ids.join("_");

  final ref = _fs.col('chat_threads').doc(threadId);
  final snap = await ref.get();

  if (!snap.exists) {
    await ref.set({
      'participantIds': ids,
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),

      // optional: keep track of related pets (doesn't affect thread identity)
      'petIds': <String>[],
      'lastPetId': null,
    });
  }

  // 2) If a petId is provided, attach it to the SAME thread (no new thread)
  final normalizedPetId = (petId == null) ? null : petId.trim();
  if (normalizedPetId != null && normalizedPetId.isNotEmpty) {
    await ref.update({
      'lastPetId': normalizedPetId,
      'petIds': FieldValue.arrayUnion([normalizedPetId]),
    });
  }

  return threadId;
}



  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final threadRef = _fs.col('chat_threads').doc(threadId);
    final msgRef = threadRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    // 1) write message + update thread
    await _fs.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': senderId,
        'text': text,
        'sentAt': now,      
        'createdAt': now,   
      });

      tx.update(threadRef, {
        'lastMessage': text,
        'lastMessageAt': now,
      });
    });

    final senderProfileSnap = await _fs.col('profiles').doc(senderId).get();
    final senderData = senderProfileSnap.data();
    final senderName = senderData?['displayName'] ?? 'Someone';

    // 2) After success -> notify other participants
    final threadSnap = await threadRef.get();
    final data = threadSnap.data();
    if (data == null) return;

    final participants = List<String>.from(data['participantIds'] ?? const []);
    final receivers = participants.where((id) => id != senderId).toList();
    if (receivers.isEmpty) return;

    for (final uid in receivers) {
      await _fs.col('profiles/$uid/notifications').add({
        'title': 'New Message has been sent by $senderName',
        'body': text,
        'type': 'chat',
        'deepLink': '/chat/thread/$threadId',
        'data': {'threadId': threadId, 'senderId': senderId},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
