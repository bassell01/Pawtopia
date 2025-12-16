import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../../data/datasources/pets/pet_local_data_source.dart';
import '../../../data/datasources/pets/pet_remote_data_source.dart';
import '../../../data/repositories_impl/pet_repository_impl.dart';
import '../../../domain/repositories/pet_repository.dart';
import '../../../domain/usecases/pets/get_pets.dart';
import '../../../domain/usecases/pets/get_pet_details.dart';
import '../../../domain/usecases/pets/search_pets.dart';
import '../../../domain/usecases/pets/filter_pets.dart';
import '../../../domain/usecases/pets/add_pet.dart';
import '../../../domain/usecases/pets/update_pet.dart';
import '../../../domain/usecases/pets/delete_pet.dart';

import 'pet_list_controller.dart';

/// NOTE:
/// Assumes you have a provider for FirebaseFirestoreService in core/services,
/// e.g.:
/// final firebaseFirestoreServiceProvider = Provider<FirebaseFirestoreService>((ref) { ... });

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>((ref) {
  final firestoreService = ref.watch(firebaseFirestoreServiceProvider);
  return PetRemoteDataSourceImpl(firestoreService);
});

final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  return PetLocalDataSourceImpl();
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final remote = ref.watch(petRemoteDataSourceProvider);
  final local = ref.watch(petLocalDataSourceProvider);
  return PetRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

/// Usecases

final getPetsUseCaseProvider = Provider<GetPets>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return GetPets(repo);
});

final getPetDetailsUseCaseProvider = Provider<GetPetDetails>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return GetPetDetails(repo);
});

final searchPetsUseCaseProvider = Provider<SearchPets>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return SearchPets(repo);
});

final filterPetsUseCaseProvider = Provider<FilterPets>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return FilterPets(repo);
});

final addPetUseCaseProvider = Provider<AddPet>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return AddPet(repo);
});

final updatePetUseCaseProvider = Provider<UpdatePet>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return UpdatePet(repo);
});

final deletePetUseCaseProvider = Provider<DeletePet>((ref) {
  final repo = ref.watch(petRepositoryProvider);
  return DeletePet(repo);
});

/// Controller provider for the pet list page

final petListControllerProvider = StateNotifierProvider<PetListController,
    AsyncValue<List<PetSummaryUiModel>>>((ref) {
  final getPets = ref.watch(getPetsUseCaseProvider);
  return PetListController(getPets: getPets)..loadInitial();
});
