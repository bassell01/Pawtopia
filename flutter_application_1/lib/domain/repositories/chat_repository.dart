import '../entities/chat/chat_thread.dart';
import '../entities/chat/message.dart';

abstract class ChatRepository {
  Stream<List<ChatThread>> getUserThreads(String userId);
  Stream<List<Message>> getMessagesStream(String threadId);
  Future<String> createThreadIfNeeded(List<String> participantIds, {String? petId});
  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
  });
}
