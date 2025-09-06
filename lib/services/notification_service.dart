import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: android,
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// Tek seferlik bildirim
  static Future<int> scheduleOneTime({
    required String title,
    required String body,
    required DateTime whenLocal,
    int? id,
  }) async {
    final nid = id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      nid,
      title,
      body,
      tz.TZDateTime.from(whenLocal, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // 17.x: bu gerekli
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // TEKRAR YOK → matchDateTimeComponents eklemiyoruz
    );
    return nid;
  }

  /// Haftalık tekrarlı bildirim (1=Mon .. 7=Sun)
  static Future<int> scheduleWeekly({
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay timeOfDay,
    int? id,
  }) async {
    final nid = id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
      next = tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      nid,
      title,
      body,
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // 🔁 haftalık tekrar için:
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    return nid;
  }

  static Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
