import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

class UploadProfileImage {
  final ProfileRepository repository;

  UploadProfileImage(this.repository);

  Future<Either<Failure, String>> call({
    required String userId,
    required String imagePath,
  }) async {
    return await repository.uploadProfileImage(
      userId: userId,
      imagePath: imagePath,
    );
  }
}
