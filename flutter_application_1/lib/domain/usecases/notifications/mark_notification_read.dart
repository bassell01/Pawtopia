import '../../repositories/notification_repository.dart';

class MarkNotificationRead {
  MarkNotificationRead(this.repo);
  final NotificationRepository repo;

  Future<void> call({required String uid, required String notificationId}) {
    return repo.markAsRead(uid: uid, notificationId: notificationId);
  }
}
