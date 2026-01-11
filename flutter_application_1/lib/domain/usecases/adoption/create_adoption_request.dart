import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/adoption/adoption_request.dart';
import '../../repositories/adoption_repository.dart';


// Use case responsible for creating a new adoption request
class CreateAdoptionRequest {
  final AdoptionRepository repo;
  CreateAdoptionRequest(this.repo);

  Future<Either<Failure, String>> call(AdoptionRequest request) {
    return repo.createRequest(request);
  }
}
