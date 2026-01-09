import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat/message.dart';
import '../auth/auth_providers.dart';
import 'chat_providers.dart';

final chatMessagesControllerProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, threadId) {
  // rebuild/dispose on auth changes
  ref.watch(currentUserIdProvider);

  if (threadId.trim().isEmpty) return const Stream.empty();
  return ref.read(getMessagesStreamProvider).call(threadId);
});
