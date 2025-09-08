import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weekly_task.dart';
import '../services/notification_service.dart';

class WeeklyProvider extends ChangeNotifier {
  final Box<WeeklyTask> _weeklyBox = Hive.box<WeeklyTask>('weeklyBox');
  final Box<int> _notifBox = Hive.box<int>('weeklyNotifBox');

  List<WeeklyTask> get tasks => _weeklyBox.values.toList();
  List<WeeklyTask> tasksForDay(String day) =>
      _weeklyBox.values.where((t) => t.day == day).toList();

  Future<void> addWeeklyTask(WeeklyTask task) async {
    final key = await _weeklyBox.add(task);
    await _scheduleFor(task, boxKey: key);
    notifyListeners();
  }

  Future<void> removeWeeklyTask(int index) async {
    final task = _weeklyBox.getAt(index);
    if (task == null) return;
    await _cancelFor(task);
    await _weeklyBox.deleteAt(index);
    notifyListeners();
  }

  Future<void> addTask(WeeklyTask task) async => addWeeklyTask(task);

  Future<void> removeTask(WeeklyTask task) async {
    await _cancelFor(task);
    await task.delete();
    notifyListeners();
  }

  /// title/day/assignedTo ve/veya saat güncellenebilir
  Future<void> updateWeeklyTask(
    WeeklyTask task, {
    String? title, // sende `task.task` ise burayı title→task yap
    String? day,
    String? assignedTo,
    TimeOfDay? timeOfDay, // görev özel saat
  }) async {
    bool needsReschedule = false;

    if (title != null && title.trim().isNotEmpty) {
      task.title = title.trim(); // sende `task.task = ...` olabilir
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
    if (timeOfDay != null) {
      task.hour = timeOfDay.hour;
      task.minute = timeOfDay.minute;
      needsReschedule = true;
    }

    await task.save();

    if (needsReschedule) {
      await _cancelFor(task);
      await _scheduleFor(task); // kendi saatini ya da defaultu kullanır
    }
    notifyListeners();
  }

  void updateAssignmentsOnRename(String oldName, String newName) {
    for (final w in _weeklyBox.values) {
      if ((w.assignedTo ?? '').toLowerCase() == oldName.toLowerCase()) {
        w.assignedTo = newName;
        w.save();
      }
    }
    notifyListeners();
  }

  // ========= helpers =========

  Future<void> _scheduleFor(WeeklyTask task, {int? boxKey}) async {
    final weekday = _dayStringToWeekdayInt(task.day);
    final time = await _resolveTime(task); // görev saati yoksa default

    final id = await NotificationService.scheduleWeekly(
      title: 'Weekly task',
      body:
          '${task.title}${task.assignedTo != null ? " – ${task.assignedTo}" : ""}',
      weekday: weekday,
      timeOfDay: time,
    );
    await _notifBox.put(boxKey ?? task.key, id);
  }

  Future<void> _cancelFor(WeeklyTask task) async {
    final id = _notifBox.get(task.key);
    if (id != null) {
      await NotificationService.cancel(id);
      await _notifBox.delete(task.key);
    }
  }

  Future<TimeOfDay> _resolveTime(WeeklyTask task) async {
    // 1) Görev özel saat
    if (task.hour != null && task.minute != null) {
      return TimeOfDay(hour: task.hour!, minute: task.minute!);
    }
    // 2) Configuration’dan varsayılan saat
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('weeklyReminderHour');
    final m = prefs.getInt('weeklyReminderMinute');
    if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    // 3) Fallback: 19:00
    return const TimeOfDay(hour: 19, minute: 0);
  }

  int _dayStringToWeekdayInt(String day) {
    final d = day.trim().toLowerCase();
    if (d.startsWith('pazartesi')) return DateTime.monday;
    if (d.startsWith('salı') || d.startsWith('sali')) return DateTime.tuesday;
    if (d.startsWith('çar') || d.startsWith('car')) return DateTime.wednesday;
    if (d.startsWith('per')) return DateTime.thursday;
    if (d.startsWith('cuma')) return DateTime.friday;
    if (d.startsWith('cmt') || d.startsWith('cumartesi'))
      return DateTime.saturday;
    if (d.startsWith('paz')) return DateTime.sunday;
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
