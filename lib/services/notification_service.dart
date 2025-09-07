import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static Future<int> scheduleOneTime({
    required String title,
    required String body,
    required DateTime whenLocal,
    int? id,
  }) async {
    final nid = id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _zonedScheduleWithFallback(
      id: nid,
      title: title,
      body: body,
      schedule: tz.TZDateTime.from(whenLocal, tz.local),
      // tek seferlikte matchDateTimeComponents YOK
    );
    return nid;
  }

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

    await _zonedScheduleWithFallback(
      id: nid,
      title: title,
      body: body,
      schedule: next,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime, // haftalık tekrar
    );
    return nid;
  }

  static Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime schedule,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'main_channel',
        'Main Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // 1) exact dene
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        schedule,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return;
    } on PlatformException catch (e) {
      // 2) exact izin yoksa inexact ile tekrar dene
      if (e.code == 'exact_alarms_not_permitted') {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          schedule,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        return;
      }
      rethrow;
    }
  }

  // Android 13+ izin isteme
  static Future<void> requestPermissions() async {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    // iOS için:
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // 30 saniye sonra tek seferlik bildirim
  static Future<void> debugTestIn30s() async {
    final when = DateTime.now().add(const Duration(seconds: 30));
    await scheduleOneTime(
      title: 'Test Notification',
      body: 'This is a 30s test ping',
      whenLocal: when,
    );
  }

  // Haftalık testi: “1 dk sonra” olacak şekilde bir defa planla ve weekly modda tekrar et
  static Future<void> debugWeeklyIn1Minute() async {
    final now = tz.TZDateTime.now(tz.local);
    final target = now.add(const Duration(minutes: 1));
    await _zonedScheduleWithFallback(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Weekly Test',
      body: 'Weekly reminder (debug)',
      schedule: tz.TZDateTime(
        tz.local,
        target.year,
        target.month,
        target.day,
        target.hour,
        target.minute,
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
