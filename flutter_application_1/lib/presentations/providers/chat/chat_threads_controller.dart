import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat/chat_thread.dart';
import '../auth/auth_providers.dart';
import 'chat_providers.dart';

final chatThreadsControllerProvider =
    StreamProvider.autoDispose.family<List<ChatThread>, String>((ref, userId) {
  ref.watch(currentUserIdProvider);

  if (userId.trim().isEmpty) return const Stream.empty();
  return ref.read(getUserThreadsProvider).call(userId);
});
