import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/profile/profile_remote_data_source.dart';
import '../../../data/repositories_impl/profile_repository_impl.dart';
import '../../../domain/entities/profile/user_profile.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/usecases/profile/get_user_profile.dart';
import '../../../domain/usecases/profile/update_user_profile.dart';
import '../../../domain/usecases/profile/upload_profile_image.dart';
import '../auth/user_role_provider.dart';
import 'profile_controller.dart';

// External dependencies
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Data source
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

// Use cases
final getUserProfileProvider = Provider<GetUserProfile>((ref) {
  return GetUserProfile(ref.watch(profileRepositoryProvider));
});

final updateUserProfileProvider = Provider<UpdateUserProfile>((ref) {
  return UpdateUserProfile(ref.watch(profileRepositoryProvider));
});

final uploadProfileImageProvider = Provider<UploadProfileImage>((ref) {
  return UploadProfileImage(ref.watch(profileRepositoryProvider));
});

// Profile controller
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(
    getUserProfileUseCase: ref.watch(getUserProfileProvider),
    updateUserProfileUseCase: ref.watch(updateUserProfileProvider),
    uploadProfileImageUseCase: ref.watch(uploadProfileImageProvider),
  );
});

// Profile stream provider for a specific user
final profileStreamProvider =
    StreamProvider.autoDispose.family<UserProfile, String>((ref, userId) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchUserProfile(userId);
});

// Current user profile provider
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileControllerProvider).profile;
});
