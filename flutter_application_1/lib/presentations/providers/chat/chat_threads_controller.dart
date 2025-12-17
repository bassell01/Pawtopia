import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/chat/chat_thread.dart';
import 'chat_providers.dart';

final chatThreadsControllerProvider =
    StreamProvider.family<List<ChatThread>, String>((ref, userId) {
  return ref.read(getUserThreadsProvider).call(userId);
});
