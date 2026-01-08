import '../../entities/notifications/app_notification.dart';
import '../../repositories/notification_repository.dart';

class GetNotificationStream {
  GetNotificationStream(this.repo);
  final NotificationRepository repo;

  Stream<List<AppNotification>> call({required String uid}) {
    return repo.notificationsStream(uid: uid);
  }
}
