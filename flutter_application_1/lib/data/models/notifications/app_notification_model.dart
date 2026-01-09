import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/notifications/app_notification.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final String? deepLink;
  final bool isRead;
  final Timestamp createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.deepLink,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data() ?? <String, dynamic>{};
    return AppNotificationModel(
      id: doc.id,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: (json['type'] ?? 'system') as String,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      deepLink: json['deepLink'] as String?,
      isRead: (json['isRead'] ?? false) as bool,
      createdAt: (json['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      deepLink: deepLink,
      isRead: isRead,
      createdAt: createdAt.toDate(),
    );
  }
}
