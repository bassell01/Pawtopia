import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/adoption/adoption_request.dart';
import '../../repositories/adoption_repository.dart';

class UpdateAdoptionStatus {
  final AdoptionRepository repo;
  UpdateAdoptionStatus(this.repo);

  Future<Either<Failure, void>> call({
    required String requestId,
    required AdoptionStatus status,
    String? threadId, 
  }) {
    return repo.updateStatus(
      requestId: requestId,
      status: status,
      threadId: threadId,
    );
  }
}
