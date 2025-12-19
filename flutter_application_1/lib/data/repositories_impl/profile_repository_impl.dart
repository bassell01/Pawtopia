import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/profile/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    try {
      final profile = await remoteDataSource.updateUserProfile(
        userId: userId,
        displayName: displayName,
        phoneNumber: phoneNumber,
        bio: bio,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
      );
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final url = await remoteDataSource.uploadProfileImage(
        userId: userId,
        imagePath: imagePath,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<UserProfile> watchUserProfile(String userId) {
    return remoteDataSource.watchUserProfile(userId);
  }
}
