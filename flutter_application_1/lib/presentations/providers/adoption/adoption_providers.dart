import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection_container.dart';
import '../../../domain/usecases/adoption/create_adoption_request.dart';
import '../../../domain/usecases/adoption/update_adoption_status.dart';
import '../../../domain/usecases/adoption/watch_incoming_adoption_requests.dart';
import '../../../domain/usecases/adoption/watch_my_adoption_requests.dart';
import '../../../domain/usecases/adoption/watch_my_accepted_adoption_requests.dart';

final createAdoptionRequestProvider =
    Provider<CreateAdoptionRequest>((ref) => sl());

final updateAdoptionStatusProvider =
    Provider<UpdateAdoptionStatus>((ref) => sl());

final watchMyRequestsProvider =
    Provider<WatchMyAdoptionRequests>((ref) => sl());

final watchIncomingRequestsProvider =
    Provider<WatchIncomingAdoptionRequests>((ref) => sl());

final watchMyAcceptedRequestsProvider =
    Provider<WatchMyAcceptedAdoptionRequests>((ref) => sl());
