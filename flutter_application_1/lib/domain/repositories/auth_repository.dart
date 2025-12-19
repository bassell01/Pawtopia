import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth/user.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.user,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword({required String email});

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Check if email is verified
  Future<Either<Failure, bool>> isEmailVerified();
}
