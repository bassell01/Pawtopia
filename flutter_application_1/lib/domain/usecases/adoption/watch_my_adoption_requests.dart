import '../../entities/adoption/adoption_request.dart';
import '../../repositories/adoption_repository.dart';

class WatchMyAdoptionRequests {
  final AdoptionRepository repo;
  WatchMyAdoptionRequests(this.repo);

  Stream<List<AdoptionRequest>> call(String requesterId) {
    return repo.watchMyRequests(requesterId);
  }
}
