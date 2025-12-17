import '../../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repo;
  SendMessage(this.repo);

  Future<void> call({
    required String threadId,
    required String senderId,
    required String text,
  }) {
    return repo.sendMessage(threadId: threadId, senderId: senderId, text: text);
  }
}
