
import '../../domain/entities/chat/chat_thread.dart';
import '../../domain/entities/chat/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat/chat_remote_data_source.dart';
import '../models/chat/chat_thread_model.dart';
import '../models/chat/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl(this.remote);

  @override
  Stream<List<ChatThread>> getUserThreads(String userId) {
    return remote.userThreadsStream(userId).map((snap) {
      return snap.docs
          .map((d) => ChatThreadModel.fromMap(d.id, d.data()).toEntity())
          .toList();
    });
  }

  @override
  Stream<List<Message>> getMessagesStream(String threadId) {
    return remote.messagesStream(threadId).map((snap) {
      return snap.docs
          .map((d) => MessageModel.fromMap(d.id, d.data()).toEntity())
          .toList();
    });
  }

  @override
  Future<String> createThreadIfNeeded(List<String> participantIds, {String? petId}) {
    return remote.createThreadIfNeeded(participantIds: participantIds, petId: petId);
  }

  @override
  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
  }) {
    return remote.sendMessage(threadId: threadId, senderId: senderId, text: text);
  }
}
