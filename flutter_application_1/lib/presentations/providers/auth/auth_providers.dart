import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/datasources/auth/auth_remote_data_source.dart';
import '../../../data/repositories_impl/auth_repository_impl.dart';
import '../../../domain/entities/auth/user.dart' as domain;
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/get_current_user.dart';
import '../../../domain/usecases/auth/reset_password.dart';
import '../../../domain/usecases/auth/sign_in_with_email.dart';
import '../../../domain/usecases/auth/sign_in_with_google.dart';
import '../../../domain/usecases/auth/sign_out.dart';
import '../../../domain/usecases/auth/sign_up_with_email.dart';

import 'auth_controller.dart';
import 'auth_state_provider.dart';
import 'user_role_provider.dart';

// ✅ Google Sign-In
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// ✅ Data source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider) as firebase_auth.FirebaseAuth,
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

// ✅ Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// ✅ Use cases
final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signUpWithEmailProvider = Provider<SignUpWithEmail>((ref) {
  return SignUpWithEmail(ref.watch(authRepositoryProvider));
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

final resetPasswordProvider = Provider<ResetPassword>((ref) {
  return ResetPassword(ref.watch(authRepositoryProvider));
});

// ✅ Auth controller (actions + UI state)
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    signInWithEmailUseCase: ref.watch(signInWithEmailProvider),
    signUpWithEmailUseCase: ref.watch(signUpWithEmailProvider),
    signInWithGoogleUseCase: ref.watch(signInWithGoogleProvider),
    signOutUseCase: ref.watch(signOutProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserProvider),
    resetPasswordUseCase: ref.watch(resetPasswordProvider),
  );
});

/// ---------------------------
/// Optional helpers (safe)
/// ---------------------------

final currentUserProvider = Provider<domain.User?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final currentUserRoleProvider = Provider<domain.UserRole?>((ref) {
  return ref.watch(authControllerProvider).user?.role;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.id;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

// Role-based access providers (from controller domain user)
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role?.isAdmin ?? false;
});

final isShelterProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role?.isShelter ?? false;
});

final canManagePetsProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role?.canManagePets ?? false;
});
