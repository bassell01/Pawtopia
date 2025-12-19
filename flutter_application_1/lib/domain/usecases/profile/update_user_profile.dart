import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/profile/user_profile.dart';
import '../../repositories/profile_repository.dart';

class UpdateUserProfile {
  final ProfileRepository repository;

  UpdateUserProfile(this.repository);

  Future<Either<Failure, UserProfile>> call({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    return await repository.updateUserProfile(
      userId: userId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      bio: bio,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
    );
  }
}
