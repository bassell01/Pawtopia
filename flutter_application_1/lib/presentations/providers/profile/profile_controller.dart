import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/profile/user_profile.dart';
import '../../../domain/usecases/profile/get_user_profile.dart';
import '../../../domain/usecases/profile/update_user_profile.dart';
import '../../../domain/usecases/profile/upload_profile_image.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isUpdating;
  final bool updateSuccess;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isUpdating = false,
    this.updateSuccess = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isUpdating,
    bool? updateSuccess,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUpdating: isUpdating ?? this.isUpdating,
      updateSuccess: updateSuccess ?? this.updateSuccess,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final GetUserProfile getUserProfileUseCase;
  final UpdateUserProfile updateUserProfileUseCase;
  final UploadProfileImage uploadProfileImageUseCase;

  ProfileController({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.uploadProfileImageUseCase,
  }) : super(ProfileState());

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getUserProfileUseCase(userId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (profile) {
        state = state.copyWith(
          profile: profile,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    this.state = this.state.copyWith(
          isUpdating: true,
          updateSuccess: false,
          clearError: true,
        );

    final result = await updateUserProfileUseCase(
      userId: userId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      bio: bio,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
    );

    return result.fold(
      (failure) {
        this.state = this.state.copyWith(
              isUpdating: false,
              updateSuccess: false,
              errorMessage: failure.message,
            );
        return false;
      },
      (profile) {
        this.state = this.state.copyWith(
              profile: profile,
              isUpdating: false,
              updateSuccess: true,
              clearError: true,
            );
        return true;
      },
    );
  }

  Future<bool> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await uploadProfileImageUseCase(
      userId: userId,
      imagePath: imagePath,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (photoUrl) async {
        // Reload profile to get updated photo URL
        await loadProfile(userId);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void resetUpdateSuccess() {
    state = state.copyWith(updateSuccess: false);
  }
}
