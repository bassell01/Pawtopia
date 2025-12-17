import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../domain/usecases/pets/mark_adopted.dart';

class MarkAdoptedController extends StateNotifier<AsyncValue<void>> {
  MarkAdoptedController({required MarkAdopted markAdopted})
      : _markAdopted = markAdopted,
        super(const AsyncData(null));

  final MarkAdopted _markAdopted;

  Future<void> toggle({
    required String petId,
    required bool isAdopted,
  }) async {
    state = const AsyncLoading();
    try {
      await _markAdopted(petId: petId, isAdopted: isAdopted);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
