import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/adoption/adoption_request.dart';

abstract class AdoptionRepository {
  Future<Either<Failure, String>> createRequest(AdoptionRequest request);

  Stream<List<AdoptionRequest>> watchMyRequests(String requesterId);
  Stream<List<AdoptionRequest>> watchIncomingRequests(String ownerId);

  Future<Either<Failure, void>> updateStatus({
    required String requestId,
    required AdoptionStatus status,
    String? threadId, 
  });
}
