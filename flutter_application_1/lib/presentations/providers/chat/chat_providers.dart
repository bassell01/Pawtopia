import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/services/firebase_firestore_service.dart';

import '../../../data/datasources/chat/chat_remote_data_source.dart';
import '../../../data/repositories_impl/chat_repository_impl.dart';
import '../../../domain/repositories/chat_repository.dart';

import '../../../domain/usecases/chat/create_thread_if_needed.dart';
import '../../../domain/usecases/chat/get_messages_stream.dart';
import '../../../domain/usecases/chat/get_user_threads.dart';
import '../../../domain/usecases/chat/send_message.dart';

/// Core service (wrapper)
final firestoreServiceProvider = Provider<FirebaseFirestoreService>((ref) {
  return sl<FirebaseFirestoreService>();
});

/// DataSource
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.read(firestoreServiceProvider));
});

/// Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(chatRemoteDataSourceProvider));
});

/// UseCases
final getUserThreadsProvider = Provider<GetUserThreads>((ref) {
  return GetUserThreads(ref.read(chatRepositoryProvider));
});

final getMessagesStreamProvider = Provider<GetMessagesStream>((ref) {
  return GetMessagesStream(ref.read(chatRepositoryProvider));
});

final createThreadIfNeededProvider = Provider<CreateThreadIfNeeded>((ref) {
  return CreateThreadIfNeeded(ref.read(chatRepositoryProvider));
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.read(chatRepositoryProvider));
});
