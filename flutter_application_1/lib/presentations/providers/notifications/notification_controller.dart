import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/notifications/app_notification.dart';
import '../../../domain/usecases/notifications/get_notification_stream.dart';
import '../../../domain/usecases/notifications/mark_notification_read.dart';

class NotificationController {
  NotificationController({
    required this.getStream,
    required this.markRead,
  });

  final GetNotificationStream getStream;
  final MarkNotificationRead markRead;

  Stream<List<AppNotification>> streamForUser(String uid) {
    return getStream(uid: uid);
  }

  Future<void> markAsRead(String uid, String notificationId) {
    return markRead(uid: uid, notificationId: notificationId);
  }
}
