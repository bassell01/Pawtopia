import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_firestore_service.dart';
import '../../models/notifications/app_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<void> saveDeviceToken({
    required String uid,
    required String token,
  });

  Stream<List<AppNotificationModel>> notificationsStream({
    required String uid,
  });

  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required FirebaseFirestoreService firestore})
      : _firestore = firestore;

  final FirebaseFirestoreService _firestore;

  CollectionReference<Map<String, dynamic>> _userNotifsCol(String uid) =>
    _firestore.col('profiles/$uid/notifications');


  @override
  Future<void> saveDeviceToken({
    required String uid,
    required String token,
  }) async {
    // Store as map: fcmTokens.{token} = true  
    await _firestore.setDoc(
      'profiles/$uid',
      {
        'fcmTokens': {token: true},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );

  }

  @override
  Stream<List<AppNotificationModel>> notificationsStream({required String uid}) {
    return _userNotifsCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => AppNotificationModel.fromDoc(d)).toList(),
        );
  }

  @override
  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await _firestore.setDoc(
      'profiles/$uid/notifications/$notificationId',
      {'isRead': true},
      merge: true,
    );

  }
}
