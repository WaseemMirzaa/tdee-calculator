import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';

/// Local notifications — the plan-level "restock" reminder that fires a day or
/// two before the meal plan runs out, plus per-item low-stock reminders that
/// fire before an individual pantry item's supply runs out.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const int _restockId = 7001;

  /// Stable per-item notification id (8000–8999). FNV-1a so it survives app
  /// restarts (unlike String.hashCode, which the language doesn't pin).
  static int _itemId(String item) {
    var h = 0x811c9dc5;
    for (final c in item.toLowerCase().codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return 8000 + (h % 1000);
  }

  static const _restockDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'restock',
      'Restock reminders',
      channelDescription: 'Reminds you to shop before food runs out.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

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
        _restockDetails,
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

  // --- Per-item low-stock reminders --------------------------------------

  /// (Re)schedule a low-stock reminder for every tracked kitchen item so it
  /// fires [leadDays] before that item's supply runs out (at 6pm). Untracked
  /// items, or all items when [leadDays] <= 0, are cancelled. Called on every
  /// kitchen change, so it fully reconciles the current set.
  Future<void> syncKitchenReminders(List<KitchenItem> items, {required int leadDays}) async {
    await init();
    final now = DateTime.now();
    for (final it in items) {
      final id = _itemId(it.item);
      try {
        await _plugin.cancel(id); // clear any prior schedule for this item
      } catch (_) {}
      if (leadDays <= 0 || !it.tracked) continue;
      final runOut = it.runOutDate();
      if (runOut == null) continue;
      final when = DateTime(runOut.year, runOut.month, runOut.day - leadDays, 18);
      if (!when.isAfter(now)) continue;
      try {
        final scheduled = tz.TZDateTime.from(when.toUtc(), tz.UTC);
        await _plugin.zonedSchedule(
          id,
          'Running low: ${it.item}',
          "You're about to run out of ${it.item} — add it to your shopping list.",
          scheduled,
          _restockDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Schedule item reminder failed: $e');
      }
    }
  }

  Future<void> cancelKitchenItem(String item) async {
    await init();
    try {
      await _plugin.cancel(_itemId(item));
    } catch (_) {}
  }

  /// Cancels every scheduled notification (used only on full data reset).
  Future<void> cancelAllKitchenReminders() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
