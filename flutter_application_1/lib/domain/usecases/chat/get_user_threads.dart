import '../../entities/chat/chat_thread.dart';
import '../../repositories/chat_repository.dart';

class GetUserThreads {
  final ChatRepository repo;
  GetUserThreads(this.repo);

  Stream<List<ChatThread>> call(String userId) => repo.getUserThreads(userId);
}
