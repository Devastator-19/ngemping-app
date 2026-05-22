import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

/// Background message handler — harus top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase sudah diinit di main.dart sebelum handler ini dipanggil
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'ngemping_default';
  static const _channelName = 'ngemping';
  static const _channelDesc = 'Notifikasi umum ngemping';

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notifications untuk foreground
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Buat notification channel Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // Minta permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Tampilkan notifikasi saat app foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Ambil FCM token dan kirim ke backend
  Future<void> registerToken() async {
    try {
      // iOS: tunggu APNS token siap sebelum minta FCM token
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) return;
      }

      final token = await _messaging.getToken();
      if (token == null) return;
      await ApiClient.instance.patch('/users/me/fcm-token', data: {'fcmToken': token});

      // Update token jika berubah
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await ApiClient.instance.patch('/users/me/fcm-token', data: {'fcmToken': newToken});
        } catch (_) {}
      });
    } catch (_) {}
  }
}
