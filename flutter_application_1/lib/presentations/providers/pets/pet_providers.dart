import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../../data/datasources/pets/pet_local_data_source.dart';
import '../../../data/datasources/pets/pet_remote_data_source.dart';
import '../../../data/repositories_impl/pet_repository_impl.dart';
import '../../../domain/entities/pets/pet.dart';
import '../../../domain/repositories/pet_repository.dart';
import '../../../domain/usecases/pets/add_pet.dart';
import '../../../domain/usecases/pets/delete_pet.dart';
import '../../../domain/usecases/pets/filter_pets.dart';
import '../../../domain/usecases/pets/get_pet_details.dart';
import '../../../domain/usecases/pets/get_pets.dart';
import '../../../domain/usecases/pets/search_pets.dart';
import '../../../domain/usecases/pets/update_pet.dart';
import '../../../domain/usecases/pets/mark_adopted.dart';

import 'pet_detail_controller.dart';
import 'pet_list_controller.dart';
import 'mark_adopted_controller.dart';

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>((ref) {
  final fs = ref.watch(firebaseFirestoreServiceProvider);
  return PetRemoteDataSourceImpl(fs);
});

final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  return PetLocalDataSourceImpl();
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepositoryImpl(
    remoteDataSource: ref.watch(petRemoteDataSourceProvider),
    localDataSource: ref.watch(petLocalDataSourceProvider),
  );
});

final getPetsUseCaseProvider =
    Provider((ref) => GetPets(ref.watch(petRepositoryProvider)));

final getPetDetailsUseCaseProvider =
    Provider((ref) => GetPetDetails(ref.watch(petRepositoryProvider)));

final searchPetsUseCaseProvider =
    Provider((ref) => SearchPets(ref.watch(petRepositoryProvider)));

final filterPetsUseCaseProvider =
    Provider((ref) => FilterPets(ref.watch(petRepositoryProvider)));

final addPetUseCaseProvider =
    Provider((ref) => AddPet(ref.watch(petRepositoryProvider)));

final updatePetUseCaseProvider =
    Provider((ref) => UpdatePet(ref.watch(petRepositoryProvider)));

final deletePetUseCaseProvider =
    Provider((ref) => DeletePet(ref.watch(petRepositoryProvider)));

final markAdoptedUseCaseProvider =
    Provider((ref) => MarkAdopted(ref.watch(petRepositoryProvider)));

class PetsStreamFilter {
  final String? type;
  final String? location;
  final bool onlyAvailable;

  const PetsStreamFilter({
    this.type,
    this.location,
    this.onlyAvailable = true,
  });
}

final petsStreamProvider =
    StreamProvider.autoDispose.family<List<Pet>, PetsStreamFilter>((ref, f) {
  return ref.watch(petRepositoryProvider).watchPets(
        type: f.type,
        location: f.location,
        onlyAvailable: f.onlyAvailable,
      );
});

final petDetailControllerProvider =
    StateNotifierProvider.autoDispose.family<PetDetailController, AsyncValue<Pet>, String>(
        (ref, id) {
  final c =
      PetDetailController(getPetDetails: ref.watch(getPetDetailsUseCaseProvider));
  c.load(id);
  return c;
});

final markAdoptedControllerProvider =
    StateNotifierProvider.autoDispose<MarkAdoptedController, AsyncValue<void>>(
        (ref) {
  return MarkAdoptedController(
    markAdopted: ref.watch(markAdoptedUseCaseProvider),
  );
});
