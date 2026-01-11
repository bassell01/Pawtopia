// dartz Either: functional way to return (Failure OR Success) without throwing exceptions
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/adoption/adoption_request.dart';

abstract class AdoptionRepository {
  /// Create new adoption request
  Future<Either<Failure, String>> createRequest(
    AdoptionRequest request,
  );

  /// My pending adoption requests (as requester)
  Stream<List<AdoptionRequest>> watchMyRequests(
    String requesterId,
  );

  /// My accepted adoption requests (history)
  Stream<List<AdoptionRequest>> watchMyAcceptedRequests(
    String requesterId,
  );

  /// Incoming requests for pets I own
  Stream<List<AdoptionRequest>> watchIncomingRequests(
    String ownerId,
  );

  /// Update request status (accept / reject / cancel)
  Future<Either<Failure, void>> updateStatus({
    required String requestId,
    required AdoptionStatus status,
    String? threadId,
  });
}
