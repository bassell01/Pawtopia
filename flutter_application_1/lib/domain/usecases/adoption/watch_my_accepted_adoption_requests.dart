import '../../entities/adoption/adoption_request.dart';
import '../../repositories/adoption_repository.dart';

class WatchMyAcceptedAdoptionRequests {
  final AdoptionRepository repository;
  WatchMyAcceptedAdoptionRequests(this.repository);

  Stream<List<AdoptionRequest>> call(String requesterId) {
    return repository.watchMyAcceptedRequests(requesterId);
  }
}
