import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/profile/user_profile.dart';

abstract class ProfileRepository {
  /// Get user profile by ID
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);

  /// Update user profile
  Future<Either<Failure, UserProfile>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  });

  /// Upload and update profile image
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required String imagePath,
  });

  /// Stream of profile changes
  Stream<UserProfile> watchUserProfile(String userId);
}
