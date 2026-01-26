import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._();

  static NotificationService getInstance() {
    _instance ??= NotificationService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Critical alerts bypass silent mode
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
    debugPrint('NotificationService: Initialized');

    // Request permissions on iOS
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // Request critical alert permission for silent mode
      );
      debugPrint('NotificationService: iOS permissions requested');
    }
  }

  /// Show alarm notification that plays sound even in silent mode
  Future<void> showAlarmNotification() async {
    debugPrint('NotificationService: Showing alarm notification');

    const androidDetails = AndroidNotificationDetails(
      'naptap_alarm',
      'NapTap Alarm',
      channelDescription: 'Wake up alarm for NapTap',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Wake Up!',
      'Your nap time is over. Walk 10 steps to dismiss.',
      details,
    );
    debugPrint('NotificationService: Alarm notification shown');
  }

  Future<void> cancelAlarmNotification() async {
    await _notifications.cancel(0);
    debugPrint('NotificationService: Alarm notification cancelled');
  }
}
