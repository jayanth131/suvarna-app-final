import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../features/schemes/data/enrolled_scheme_service.dart';
import 'session_manager.dart';

// Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? "Suvarna Jewellers",
    body: message.notification?.body ?? "",
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _baseUrl =
      "https://suvarna-jewellers-customer-backend.vercel.app";

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'suvarna_reminders',
    'Suvarna Reminders',
    description: 'Scheme payment reminders and updates',
    importance: Importance.high,
  );

  // ── INIT ──s
  static Future<void> initialize() async {
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings (IMPORTANT FIX)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create Android channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    // Request Firebase messaging permission (iOS + Android)
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(
        title: message.notification?.title ?? "Suvarna Jewellers",
        body: message.notification?.body ?? "",
      );
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Register FCM token
    await _registerFcmToken();
  }

  // ── REGISTER TOKEN ──
  static Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final authToken = await SessionManager.getToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse("$_baseUrl/api/notifications/register-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({"fcmToken": token}),
      );

      print("FCM Token registered: $token");
    } catch (e) {
      print("FCM token registration failed: $e");
    }
  }

  // ── LOCAL NOTIFICATION ──
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── DUE DATE CHECK ──
  static Future<void> checkAndNotifyDueDates() async {
    try {
      final schemes = await EnrolledSchemeService.getUserSchemes();
      final today = DateTime.now();

      int notifId = 100;

      for (final scheme in schemes) {
        if (scheme.nextDueDate == "Completed") continue;

        final parts = scheme.nextDueDate.split("-");
        if (parts.length != 3) continue;

        final dueDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        final diff = dueDate
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;

        const notifyDays = [10, 7, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -6, -7];

        if (!notifyDays.contains(diff)) continue;

        late String title;
        late String body;

        if (diff == 10) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 10 days to due";
        } else if (diff == 7) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 7 days to due";
        } else if (diff == 5) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 5 days to due";
        } else if (diff == 4) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 4 days to due";
        } else if (diff == 3) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 3 days to due";
        } else if (diff == 2) {
          title = "Scheme Reminder 🔔";
          body = "${scheme.name}: 2 days to due";
        } else if (diff == 1) {
          title = "Payment Due Tomorrow ⚠️";
          body = "${scheme.name}: 1 day left";
        } else if (diff == 0) {
          title = "Pay Today ⚠️";
          body = "${scheme.name}: Last day to pay";
        } else {
          title = "Overdue ❌";
          body = "${scheme.name}: Payment overdue";
        }

        await showLocalNotification(
          title: title,
          body: body,
          id: notifId++,
        );
      }
    } catch (e) {
      print("Due date notification error: $e");
    }
  }
}