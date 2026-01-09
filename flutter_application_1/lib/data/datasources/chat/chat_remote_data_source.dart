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

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String threadId) {
    return _fs
        .col('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Future<String> createThreadIfNeeded({
    required List<String> participantIds,
    String? petId,
  }) async {
    final ids = [...participantIds]..sort();
    final threadId = '${ids.join("_")}_${petId ?? "noPet"}';

    final ref = _fs.col('chat_threads').doc(threadId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participantIds': ids,
        'petId': petId,
        'lastMessage': null,
        'lastMessageAt': FieldValue.serverTimestamp(),
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
    });

    tx.update(threadRef, {
      'lastMessage': text,
      'lastMessageAt': now,
    });
  });
  final senderProfileSnap =
      await _fs.col('profiles').doc(senderId).get();

  final senderData = senderProfileSnap.data();
  final senderName =
      senderData?['displayName'] ??
      'Someone';

  // 2) After success -> notify other participants
  final threadSnap = await threadRef.get();
  final data = threadSnap.data();
  if (data == null) return;

  final participants = List<String>.from(data['participantIds'] ?? const []);
  final receivers = participants.where((id) => id != senderId).toList();
  if (receivers.isEmpty) return;

  for (final uid in receivers) {
    await _fs.col('profiles/$uid/notifications').add({
      'title': 'New Message has been sent by '+ senderName,
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
