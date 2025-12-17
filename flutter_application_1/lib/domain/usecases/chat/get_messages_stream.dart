import '../../entities/chat/message.dart';
import '../../repositories/chat_repository.dart';

class GetMessagesStream {
  final ChatRepository repo;
  GetMessagesStream(this.repo);

  Stream<List<Message>> call(String threadId) => repo.getMessagesStream(threadId);
}
