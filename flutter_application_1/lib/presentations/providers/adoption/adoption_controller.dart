import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/adoption/adoption_request.dart';
import '../../providers/adoption/adoption_providers.dart';

class AdoptionControllerState {
  final bool isLoading;
  final String? error;

  const AdoptionControllerState({this.isLoading = false, this.error});

  AdoptionControllerState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AdoptionControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdoptionController extends StateNotifier<AdoptionControllerState> {
  AdoptionController(this.ref) : super(const AdoptionControllerState());
  final Ref ref;

    Future<String?> createRequest({
    required String petId,
    required String ownerId,
    required String requesterId,
    String? message,
    String? threadId,

    // ✅ NEW: pet summary
    required String petName,
    required String petType,
    String? petLocation,
    String? petPhotoUrl, String? requesterName,
  }) async {
    state = const AdoptionControllerState(isLoading: true, error: null);

    try {
      final req = AdoptionRequest(
        id: '',
        petId: petId,
        ownerId: ownerId,
        requesterId: requesterId,
        requesterName: requesterName, // ✅ ADD THIS
        message: message,
        status: AdoptionStatus.pending,
        createdAt: null,
        updatedAt: null,
        threadId: threadId,

        // ✅ NEW
        petName: petName,
        petType: petType,
        petLocation: petLocation,
        petPhotoUrl: petPhotoUrl,
      );

      final usecase = ref.read(createAdoptionRequestProvider);
      final res = await usecase(req);

      return res.fold((fail) {
        state = AdoptionControllerState(isLoading: false, error: fail.message);
        return null;
      }, (id) {
        state = const AdoptionControllerState(isLoading: false, error: null);
        return id;
      });
    } catch (e) {
      state = AdoptionControllerState(isLoading: false, error: e.toString());
      return null;
    }
  }


  Future<bool> updateStatus({
    required String requestId,
    required AdoptionStatus status,
    String? threadId,

  }) async {
    state = const AdoptionControllerState(isLoading: true, error: null);

    try {
      final usecase = ref.read(updateAdoptionStatusProvider);

      final res = await usecase(
        requestId: requestId,
        status: status,
        threadId: threadId,

      );

      return res.fold((fail) {
        state = AdoptionControllerState(isLoading: false, error: fail.message);
        return false;
      }, (_) {
        state = const AdoptionControllerState(isLoading: false, error: null);
        return true;
      });
    } catch (e) {
      state = AdoptionControllerState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adoptionControllerProvider =
    StateNotifierProvider<AdoptionController, AdoptionControllerState>(
  (ref) => AdoptionController(ref),
);
