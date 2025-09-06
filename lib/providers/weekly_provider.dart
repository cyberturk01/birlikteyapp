import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/weekly_task.dart';
import '../services/notification_service.dart';

class WeeklyProvider extends ChangeNotifier {
  final Box<WeeklyTask> _weeklyBox = Hive.box<WeeklyTask>('weeklyBox');
  final Box<int> _notifBox = Hive.box<int>(
    'weeklyNotifBox',
  ); // weeklyTask.key -> notifId

  static const TimeOfDay _defaultTime = TimeOfDay(hour: 19, minute: 0);

  List<WeeklyTask> get allPlans => _weeklyBox.values.toList();
  List<WeeklyTask> get tasks => _weeklyBox.values.toList();

  List<WeeklyTask> tasksForDay(String day) {
    return _weeklyBox.values.where((t) => t.day == day).toList();
  }

  Future<void> addWeeklyTask(WeeklyTask task) async {
    final key = await _weeklyBox.add(task);

    final weekday = _dayStringToWeekdayInt(task.day);
    final notifId = await NotificationService.scheduleWeekly(
      title: 'Weekly task',
      body:
          '${task.task}${task.assignedTo != null ? " – ${task.assignedTo}" : ""}', // <-- title
      weekday: weekday,
      timeOfDay: _defaultTime,
    );

    await _notifBox.put(key, notifId);
    notifyListeners();
  }

  Future<void> removeWeeklyTask(int index) async {
    final task = _weeklyBox.getAt(index);
    if (task == null) return;

    await _cancelFor(task);
    await _weeklyBox.deleteAt(index);
    notifyListeners();
  }

  Future<void> addTask(WeeklyTask task) async {
    await addWeeklyTask(task);
  }

  Future<void> removeTask(WeeklyTask task) async {
    await _cancelFor(task);
    await task.delete();
    notifyListeners();
  }

  Future<void> updateWeeklyTask(
    WeeklyTask task, {
    String? title, // <-- name yerine title
    String? day,
    String? assignedTo,
    TimeOfDay? timeOfDay,
  }) async {
    bool needsReschedule = false;

    if (title != null && title.trim().isNotEmpty) {
      task.task = title.trim(); // <-- title
      needsReschedule = true;
    }
    if (day != null && day.trim().isNotEmpty && day != task.day) {
      task.day = day.trim();
      needsReschedule = true;
    }
    if (assignedTo != null) {
      task.assignedTo = assignedTo.trim().isEmpty ? null : assignedTo.trim();
      needsReschedule = true;
    }

    await task.save();

    if (needsReschedule) {
      await _cancelFor(task);
      final weekday = _dayStringToWeekdayInt(task.day);
      final notifId = await NotificationService.scheduleWeekly(
        title: 'Weekly task',
        body:
            '${task.task}${task.assignedTo != null ? " – ${task.assignedTo}" : ""}', // <-- title
        weekday: weekday,
        timeOfDay: timeOfDay ?? _defaultTime,
      );
      await _notifBox.put(task.key, notifId);
    }

    notifyListeners();
  }

  Future<void> _cancelFor(WeeklyTask t) async {
    final id = _notifBox.get(t.key);
    if (id != null) {
      await NotificationService.cancel(id);
      await _notifBox.delete(t.key);
    }
  }

  int _dayStringToWeekdayInt(String day) {
    final d = day.trim().toLowerCase();

    // TR
    if (d.startsWith('pazartesi')) return DateTime.monday;
    if (d.startsWith('salı') || d.startsWith('sali')) return DateTime.tuesday;
    if (d.startsWith('çar') || d.startsWith('car')) return DateTime.wednesday;
    if (d.startsWith('per')) return DateTime.thursday;
    if (d.startsWith('cuma')) return DateTime.friday;
    if (d.startsWith('cmt') || d.startsWith('cumartesi'))
      return DateTime.saturday;
    if (d.startsWith('paz')) return DateTime.sunday;

    // EN
    if (d.startsWith('mon')) return DateTime.monday;
    if (d.startsWith('tue')) return DateTime.tuesday;
    if (d.startsWith('wed')) return DateTime.wednesday;
    if (d.startsWith('thu')) return DateTime.thursday;
    if (d.startsWith('fri')) return DateTime.friday;
    if (d.startsWith('sat')) return DateTime.saturday;
    if (d.startsWith('sun')) return DateTime.sunday;

    return DateTime.monday;
  }
}
