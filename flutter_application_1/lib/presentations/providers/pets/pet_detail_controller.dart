import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pets/pet.dart';
import '../../../domain/usecases/pets/get_pet_details.dart';
import 'package:flutter_riverpod/legacy.dart';

class PetDetailController extends StateNotifier<AsyncValue<Pet>> {
  PetDetailController({required GetPetDetails getPetDetails})
      : _getPetDetails = getPetDetails,
        super(const AsyncValue.loading());

  final GetPetDetails _getPetDetails;

  Future<void> load(String petId) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _getPetDetails(petId);
      state = AsyncValue.data(pet);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
