import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/auth/user.dart';
import '../../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    return await repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
}
