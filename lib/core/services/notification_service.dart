import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications — used for the "restock" reminder that fires a day or
/// two before the meal plan runs out.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const int _restockId = 7001;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  /// Ask the OS for permission (Android 13+ / iOS). Returns whether granted.
  Future<bool> requestPermission() async {
    await init();
    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? false;
      }
      final ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.requestPermissions(alert: true, badge: true, sound: true)) ?? false;
      }
    } catch (e) {
      debugPrint('Notification permission failed: $e');
    }
    return false;
  }

  /// Schedule the restock reminder for the absolute [when] moment. Replaces any
  /// existing one. No-op if [when] is in the past.
  Future<void> scheduleRestockReminder({required DateTime when, required int planDays}) async {
    await init();
    await cancelRestockReminder();
    if (when.isBefore(DateTime.now())) return;
    try {
      final scheduled = tz.TZDateTime.from(when.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        _restockId,
        'Time to restock 🛒',
        'Your $planDays-day meal plan is almost finished — prep your shopping list.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'restock',
            'Restock reminders',
            channelDescription: 'Reminds you to shop before your meal plan runs out.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Schedule restock failed: $e');
    }
  }

  Future<void> cancelRestockReminder() async {
    await init();
    try {
      await _plugin.cancel(_restockId);
    } catch (_) {}
  }
}
