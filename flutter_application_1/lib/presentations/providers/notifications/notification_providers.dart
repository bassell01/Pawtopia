import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_firestore_service.dart';
import '../../../data/datasources/notifications/notification_remote_data_source.dart';
import '../../../data/repositories_impl/notification_repository_impl.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../domain/usecases/notifications/get_notification_stream.dart';
import '../../../domain/usecases/notifications/mark_notification_read.dart';
import '../../../domain/usecases/notifications/save_device_token.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreServiceProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(remote: ref.watch(notificationRemoteDataSourceProvider));
});

final saveDeviceTokenUseCaseProvider = Provider<SaveDeviceToken>((ref) {
  return SaveDeviceToken(ref.watch(notificationRepositoryProvider));
});

final getNotificationStreamUseCaseProvider = Provider<GetNotificationStream>((ref) {
  return GetNotificationStream(ref.watch(notificationRepositoryProvider));
});

final markNotificationReadUseCaseProvider = Provider<MarkNotificationRead>((ref) {
  return MarkNotificationRead(ref.watch(notificationRepositoryProvider));
});
