import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request FCM Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialize timezone database for scheduling
    tz.initializeTimeZones();

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click
      },
    );

    // Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'agrifarm_notifications',
      'AgriFarm Reminders',
      description: 'Notifikasi untuk jadwal pemupukan, penyemprotan, dan stok AgriFarm',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'AgriFarm Alert',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // Get device token for target notification targeting
  Future<String?> getDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      return null;
    }
  }

  // Show immediate local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agrifarm_notifications',
      'AgriFarm Reminders',
      channelDescription: 'Notifikasi untuk jadwal pemupukan, penyemprotan, dan stok AgriFarm',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(id, title, body, platformDetails);
  }

  // Schedule a notification for a specific date/time (e.g. Schedule fertilizing/spraying activity)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Check if scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agrifarm_notifications',
      'AgriFarm Reminders',
      channelDescription: 'Notifikasi untuk jadwal pemupukan, penyemprotan, dan stok AgriFarm',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a specific scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
