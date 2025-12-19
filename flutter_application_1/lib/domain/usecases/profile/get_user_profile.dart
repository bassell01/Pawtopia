import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/profile/user_profile.dart';
import '../../repositories/profile_repository.dart';

class GetUserProfile {
  final ProfileRepository repository;

  GetUserProfile(this.repository);

  Future<Either<Failure, UserProfile>> call(String userId) async {
    return await repository.getUserProfile(userId);
  }
}
