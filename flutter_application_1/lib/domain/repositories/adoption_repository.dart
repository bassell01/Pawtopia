import '../entities/adoption/adoption_request.dart';

abstract class AdoptionRepository {
  Future<void> submitRequest(AdoptionRequest request);

  Future<List<AdoptionRequest>> getUserRequests(String adopterId);

  Future<List<AdoptionRequest>> getShelterRequests(String shelterId);

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  });

  Stream<List<AdoptionRequest>> trackUserRequestsStream(String adopterId);
}
