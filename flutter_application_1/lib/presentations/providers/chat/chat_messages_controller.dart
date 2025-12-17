import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/chat/message.dart';
import 'chat_providers.dart';

final chatMessagesControllerProvider =
    StreamProvider.family<List<Message>, String>((ref, threadId) {
  return ref.read(getMessagesStreamProvider).call(threadId);
});
