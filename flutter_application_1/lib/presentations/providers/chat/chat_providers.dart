import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/chat/chat_remote_data_source.dart';
import '../../../data/repositories_impl/chat_repository_impl.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/usecases/chat/create_thread_if_needed.dart';
import '../../../domain/usecases/chat/get_messages_stream.dart';
import '../../../domain/usecases/chat/get_user_threads.dart';
import '../../../domain/usecases/chat/send_message.dart';
import '../core/firebase_providers.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.read(firestoreServiceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(chatRemoteDataSourceProvider));
});

final getUserThreadsProvider = Provider((ref) => GetUserThreads(ref.read(chatRepositoryProvider)));
final getMessagesStreamProvider = Provider((ref) => GetMessagesStream(ref.read(chatRepositoryProvider)));
final createThreadIfNeededProvider = Provider((ref) => CreateThreadIfNeeded(ref.read(chatRepositoryProvider)));
final sendMessageProvider = Provider((ref) => SendMessage(ref.read(chatRepositoryProvider)));
