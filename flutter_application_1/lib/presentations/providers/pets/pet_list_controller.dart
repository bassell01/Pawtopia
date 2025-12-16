import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../domain/entities/pets/pet.dart';
import '../../../domain/usecases/pets/get_pets.dart';

/// Simple UI model for list items
class PetSummaryUiModel {
  final String id;
  final String name;
  final String type;
  final String? location;
  final String? thumbnailUrl;
  final bool isAdopted;

  PetSummaryUiModel({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.thumbnailUrl,
    required this.isAdopted,
  });

  factory PetSummaryUiModel.fromEntity(Pet pet) {
    return PetSummaryUiModel(
      id: pet.id,
      name: pet.name,
      type: pet.type,
      location: pet.location,
      thumbnailUrl: pet.photoUrls.isNotEmpty ? pet.photoUrls.first : null,
      isAdopted: pet.isAdopted,
    );
  }
}

class PetListController
    extends StateNotifier<AsyncValue<List<PetSummaryUiModel>>> {
  PetListController({
    required GetPets getPets,
  })  : _getPets = getPets,
        super(const AsyncValue.loading());

  final GetPets _getPets;

  String? _currentTypeFilter;
  String? _currentLocationFilter;

  Future<void> loadInitial() async {
    await loadPets();
  }

  Future<void> loadPets({
    String? type,
    String? location,
    bool onlyAvailable = true,
  }) async {
    state = const AsyncValue.loading();

    _currentTypeFilter = type;
    _currentLocationFilter = location;

    try {
      final pets = await _getPets(
        type: type,
        location: location,
        onlyAvailable: onlyAvailable,
      );

      final uiModels = pets
          .map(PetSummaryUiModel.fromEntity)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      state = AsyncValue.data(uiModels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// For simple pull-to-refresh in UI.
  Future<void> refresh() async {
    await loadPets(
      type: _currentTypeFilter,
      location: _currentLocationFilter,
    );
  }

  /// Basic updates for filters – can be extended later.
  Future<void> applyTypeFilter(String? type) async {
    await loadPets(type: type, location: _currentLocationFilter);
  }

  Future<void> applyLocationFilter(String? location) async {
    await loadPets(type: _currentTypeFilter, location: location);
  }
}
