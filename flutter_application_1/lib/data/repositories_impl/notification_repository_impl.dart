import '../../domain/entities/notifications/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notifications/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this.remote});
  final NotificationRemoteDataSource remote;

  @override
  Future<void> saveDeviceToken({required String uid, required String token}) {
    return remote.saveDeviceToken(uid: uid, token: token);
  }

  @override
  Stream<List<AppNotification>> notificationsStream({required String uid}) {
    return remote.notificationsStream(uid: uid).map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<void> markAsRead({required String uid, required String notificationId}) {
    return remote.markAsRead(uid: uid, notificationId: notificationId);
  }
}
