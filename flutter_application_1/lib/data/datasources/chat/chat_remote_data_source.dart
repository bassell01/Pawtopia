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
  }
}
