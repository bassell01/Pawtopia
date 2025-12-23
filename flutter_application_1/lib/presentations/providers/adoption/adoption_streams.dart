import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/adoption/adoption_request.dart';
import 'adoption_providers.dart';

final myAdoptionRequestsStreamProvider =
    StreamProvider.autoDispose.family<List<AdoptionRequest>, String>((ref, requesterId) {
  return ref.read(watchMyRequestsProvider).call(requesterId);
});

final incomingAdoptionRequestsStreamProvider =
    StreamProvider.autoDispose.family<List<AdoptionRequest>, String>((ref, ownerId) {
  return ref.read(watchIncomingRequestsProvider).call(ownerId);
});
