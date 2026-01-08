import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationTapEvent {
  final String? deepLink;
  final Map<String, dynamic> data;

  const NotificationTapEvent({
    required this.deepLink,
    required this.data,
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  final StreamController<NotificationTapEvent> _tapController =
      StreamController<NotificationTapEvent>.broadcast();

  Stream<NotificationTapEvent> get onTap => _tapController.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();
    await _initLocalNotifications();
    _listenToFcmEvents();
  }

  Future<NotificationSettings> _requestPermissions() {
    return _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<String?> getToken() => _fcm.getToken();

  Future<void> subscribeToTopic(String topic) => _fcm.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) => _fcm.unsubscribeFromTopic(topic);

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;

        final parsed = _decodePayload(payload);
        _tapController.add(
          NotificationTapEvent(
            deepLink: parsed['deepLink'] as String?,
            data: (parsed['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
          ),
        );
      },
    );

    // Android channel
    const channel = AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'General notifications',
      importance: Importance.high,
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  void _listenToFcmEvents() {
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_emitTapFromRemoteMessage);

    // Terminated -> opened via notification
    _fcm.getInitialMessage().then((m) {
      if (m != null) _emitTapFromRemoteMessage(m);
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final deepLink = message.data['deepLink'] as String?;
    final payload = _encodePayload(deepLink: deepLink, data: message.data);

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }

  void _emitTapFromRemoteMessage(RemoteMessage message) {
    final deepLink = message.data['deepLink'] as String?;
    _tapController.add(
      NotificationTapEvent(
        deepLink: deepLink,
        data: message.data,
      ),
    );
  }

  String _encodePayload({
    required String? deepLink,
    required Map<String, dynamic> data,
  }) {
    // simple querystring-ish payload (avoids jsonEncode issues)
    final buf = StringBuffer();
    buf.write('deepLink=${Uri.encodeComponent(deepLink ?? '')}');
    data.forEach((k, v) {
      buf.write('&$k=${Uri.encodeComponent('$v')}');
    });
    return buf.toString();
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final out = <String, dynamic>{'data': <String, dynamic>{}};
    final parts = payload.split('&');

    for (final p in parts) {
      final idx = p.indexOf('=');
      if (idx == -1) continue;
      final key = p.substring(0, idx);
      final value = Uri.decodeComponent(p.substring(idx + 1));

      if (key == 'deepLink') {
        out['deepLink'] = value.isEmpty ? null : value;
      } else {
        (out['data'] as Map<String, dynamic>)[key] = value;
      }
    }
    return out;
  }

  void dispose() {
    _tapController.close();
  }
}
