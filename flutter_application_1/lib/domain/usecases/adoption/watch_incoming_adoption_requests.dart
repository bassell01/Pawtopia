import '../../entities/adoption/adoption_request.dart';
import '../../repositories/adoption_repository.dart';

class WatchIncomingAdoptionRequests {
  final AdoptionRepository repo;
  WatchIncomingAdoptionRequests(this.repo);

  Stream<List<AdoptionRequest>> call(String ownerId) {
    return repo.watchIncomingRequests(ownerId);
  }
}
