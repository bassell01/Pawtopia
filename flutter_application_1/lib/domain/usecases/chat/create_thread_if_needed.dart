import '../../repositories/chat_repository.dart';

class CreateThreadIfNeeded {
  final ChatRepository repo;
  CreateThreadIfNeeded(this.repo);

  Future<String> call(List<String> participantIds, {String? petId}) {
    return repo.createThreadIfNeeded(participantIds, petId: petId);
  }
}
