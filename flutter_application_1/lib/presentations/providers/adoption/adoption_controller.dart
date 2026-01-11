import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/adoption/adoption_request.dart';
import '../../providers/adoption/adoption_providers.dart';
import '../../providers/chat/chat_providers.dart';

class AdoptionControllerState {
  final bool isLoading;
  final String? error;

  const AdoptionControllerState({this.isLoading = false, this.error});

  AdoptionControllerState copyWith({bool? isLoading, String? error}) {
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
    String? threadId, // kept to not break other calls, but NOT used
    required String petName,
    required String petType,
    String? petLocation,
    String? petPhotoUrl,
    String? requesterName,
  }) async {
    state = const AdoptionControllerState(isLoading: true, error: null);

    try {
      final req = AdoptionRequest(
        id: '',
        petId: petId,
        ownerId: ownerId,
        requesterId: requesterId,
        requesterName: requesterName,
        message: message,
        status: AdoptionStatus.pending,
        createdAt: null,
        updatedAt: null,

        // ✅ IMPORTANT: do NOT create thread at request time
        threadId: null,

        petName: petName,
        petType: petType,
        petLocation: petLocation,
        petPhotoUrl: petPhotoUrl,
      );

      final usecase = ref.read(createAdoptionRequestProvider);
      final res = await usecase(req);

      return res.fold(
        (fail) {
          state = AdoptionControllerState(
            isLoading: false,
            error: fail.message,
          );
          return null;
        },
        (id) {
          state = const AdoptionControllerState(isLoading: false, error: null);
          return id;
        },
      );
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
      String? ensuredThreadId = threadId;

      //Feature 1: Create chat ONLY when owner ACCEPTS (and threadId is missing)
      if (status == AdoptionStatus.accepted &&
          (ensuredThreadId == null || ensuredThreadId.trim().isEmpty)) {
        final reqSnap = await FirebaseFirestore.instance
            .collection('adoption_requests') // ✅ change if different
            .doc(requestId)
            .get();

        final data = reqSnap.data();
        if (data == null) {
          state = const AdoptionControllerState(
            isLoading: false,
            error: 'Request not found',
          );
          return false;
        }

        final ownerId = (data['ownerId'] ?? '').toString().trim();
        final requesterId = (data['requesterId'] ?? '').toString().trim();

        if (ownerId.isEmpty || requesterId.isEmpty) {
          state = const AdoptionControllerState(
            isLoading: false,
            error: 'Invalid request data',
          );
          return false;
        }

        final createThread = ref.read(createThreadIfNeededProvider);
        ensuredThreadId = await createThread.call([
          ownerId,
          requesterId,
        ], petId: null);
      }

      final usecase = ref.read(updateAdoptionStatusProvider);

      final res = await usecase(
        requestId: requestId,
        status: status,
        threadId: ensuredThreadId,
      );

      // keep your structure: fold returns bool
      final ok = res.fold(
        (fail) {
          state = AdoptionControllerState(
            isLoading: false,
            error: fail.message,
          );
          return false;
        },
        (_) {
          state = const AdoptionControllerState(isLoading: false, error: null);
          return true;
        },
      );

      // Feature 2: Send the exact automatic message AFTER accept success
      if (ok &&
          status == AdoptionStatus.accepted &&
          ensuredThreadId != null &&
          ensuredThreadId.trim().isNotEmpty) {
        // read request to build message
        final reqSnap = await FirebaseFirestore.instance
            .collection('adoption_requests')
            .doc(requestId)
            .get();

        final data = reqSnap.data();

        final ownerId = (data?['ownerId'] ?? '').toString().trim();
        final requesterName = (data?['requesterName'] ?? '').toString().trim();
 
        // optional: owner display name
        String ownerName = '';
        if (ownerId.isNotEmpty) {
          final ownerProfile = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(ownerId)
              .get();
          ownerName = (ownerProfile.data()?['displayName'] ?? '')
              .toString()
              .trim();
        }

        final finalRequesterName = requesterName.isNotEmpty
            ? requesterName
            : 'there';
        final finalOwnerName = ownerName.isNotEmpty ? ownerName : 'Owner';

        // prevent duplicate welcome message (send only if thread has no lastMessage)
        final threadSnap = await FirebaseFirestore.instance
            .collection('chat_threads')
            .doc(ensuredThreadId)
            .get();

        final lastMsg = (threadSnap.data()?['lastMessage']);
        final shouldSendWelcome =
            lastMsg == null || lastMsg.toString().trim().isEmpty;

        final petName = (data?['petName'] ?? 'pet').toString().trim();
        final finalPetName = petName.isNotEmpty ? petName : 'pet';


        if (shouldSendWelcome && ownerId.isNotEmpty) {
          final text =
              'Hi, $finalRequesterName 👋\n'
              '$finalOwnerName With You\n'
              'Do you Want more details about the $finalPetName  you requested';

          final send = ref.read(sendMessageProvider);
          await send.call(
            threadId: ensuredThreadId,
            senderId: ownerId,
            text: text,
          );
        }
      }

      return ok;
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
