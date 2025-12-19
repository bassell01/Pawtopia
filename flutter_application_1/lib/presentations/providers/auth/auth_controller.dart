import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/auth/user.dart';
import '../../../domain/usecases/auth/get_current_user.dart';
import '../../../domain/usecases/auth/reset_password.dart';
import '../../../domain/usecases/auth/sign_in_with_email.dart';
import '../../../domain/usecases/auth/sign_in_with_google.dart';
import '../../../domain/usecases/auth/sign_out.dart';
import '../../../domain/usecases/auth/sign_up_with_email.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  }) : isAuthenticated = user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final SignInWithEmail signInWithEmailUseCase;
  final SignUpWithEmail signUpWithEmailUseCase;
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  final ResetPassword resetPasswordUseCase;

  AuthController({
    required this.signInWithEmailUseCase,
    required this.signUpWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthState());

  Future<void> checkAuthState() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          clearUser: true,
        );
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await signInWithEmailUseCase(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.user,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await signUpWithEmailUseCase(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await signInWithGoogleUseCase();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await signOutUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          clearError: true,
        );
      },
    );
  }

  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await resetPasswordUseCase(email: email);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
