import '../entities/notifications/app_notification.dart';

abstract class NotificationRepository {
  Future<void> saveDeviceToken({required String uid, required String token});
  Stream<List<AppNotification>> notificationsStream({required String uid});
  Future<void> markAsRead({required String uid, required String notificationId});
}
