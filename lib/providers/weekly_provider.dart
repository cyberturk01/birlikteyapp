// lib/providers/weekly_provider.dart
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../models/weekly_task.dart';
import '../services/notification_service.dart';

class WeeklyProvider extends ChangeNotifier {
  final Box<WeeklyTask> _weeklyBox = Hive.box<WeeklyTask>('weeklyBox');
  final Box<int> _notifBox = Hive.box<int>('weeklyNotifBox');

  List<WeeklyTask> get tasks => _weeklyBox.values.toList();

  List<WeeklyTask> tasksForDay(String day) =>
      _weeklyBox.values.where((t) => t.day == day).toList();

  /// Bugüne ait (haftanın gününe göre) haftalık görevleri getirir
  List<WeeklyTask> tasksFor(DateTime date) {
    final wd = date.weekday; // 1=Mon ... 7=Sun
    final dayStr = _weekdayIntToCanonical(wd); // "Monday" vs.
    return _weeklyBox.values.where((t) {
      // t.day case-insensitive karşılaştır
      return t.day.toLowerCase().startsWith(dayStr.toLowerCase());
    }).toList();
  }

  List<WeeklyTask> todayTasks() => tasksFor(DateTime.now());

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

  /// title/day/assignedTo/saat güncellenebilir
  Future<void> updateWeeklyTask(
    WeeklyTask task, {
    String? title,
    String? day,
    String? assignedTo,
    TimeOfDay? timeOfDay,
  }) async {
    bool needsReschedule = false;

    if (title != null && title.trim().isNotEmpty && title != task.title) {
      task.title = title.trim();
      needsReschedule = true;
    }
    if (day != null && day.trim().isNotEmpty && day != task.day) {
      task.day = day.trim();
      needsReschedule = true;
    }
    if (assignedTo != null) {
      task.assignedTo = assignedTo.trim().isEmpty ? null : assignedTo.trim();
      // gün değişmese de saat değişmese de bildirim başlığı değişebilir
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

  /// Üye ismi değiştiğinde Weekly’deki assignedTo’ları güncelle
  void updateAssignmentsOnRename(String oldName, String newName) {
    for (final w in _weeklyBox.values) {
      if ((w.assignedTo ?? '').toLowerCase() == oldName.toLowerCase()) {
        w.assignedTo = newName;
        w.save();
      }
    }
    notifyListeners();
  }

  /// Toplu ekleme (Templates içinden)
  List<WeeklyTask> addWeeklyBulk(
    List<(String, String)> entries, {
    String? assignedTo,
  }) {
    final created = <WeeklyTask>[];
    for (final e in entries) {
      final day = e.$1.trim();
      final title = e.$2.trim();
      if (day.isEmpty || title.isEmpty) continue;
      final wt = WeeklyTask(day, title, assignedTo: assignedTo);
      _weeklyBox.add(wt);
      created.add(wt);
    }
    if (created.isNotEmpty) notifyListeners();
    return created;
  }

  /// Toplu silme (Undo için yardımcı)
  void removeManyWeekly(Iterable<WeeklyTask> list) {
    for (final t in list) {
      t.delete();
    }
    if (list.isNotEmpty) notifyListeners();
  }

  // ====== GÜNLÜK SENKRON ======

  /// Her gün bir kez: haftalık planın BUGÜNKÜ maddelerini TaskProvider’a aktar.
  /// - Aynı isim + assignedTo için “zaten var” kontrolü yapılır (case-insensitive).
  Future<void> ensureTodaySynced(TaskCloudProvider taskProv) async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getString('lastWeeklySync'); // "yyyy-mm-dd"
    final today = _dateKey(DateTime.now());

    if (last == today) return; // bugün senkron yapılmış

    await syncTodayToTasks(taskProv);
    await sp.setString('lastWeeklySync', today);
  }

  /// Bugünkü weekly görevleri tek tek Task olarak ekler (duplicate koruması var).
  Future<void> syncTodayToTasks(TaskCloudProvider taskProv) async {
    final today = tasksFor(DateTime.now());
    if (today.isEmpty) return;

    final existing = taskProv.tasks; // List<Task>
    for (final w in today) {
      final title = w.title.trim();
      final assg = w.assignedTo?.trim();
      final dup = existing.any(
        (t) =>
            t.name.toLowerCase() == title.toLowerCase() &&
            ((t.assignedTo ?? '').toLowerCase() == (assg ?? '').toLowerCase()),
      );

      if (!dup) {
        taskProv.addTask(Task(title, assignedTo: assg));
      }
    }
  }

  // ====== Notifications helpers ======

  Future<void> _scheduleFor(WeeklyTask task, {int? boxKey}) async {
    final weekday = _dayStringToWeekdayInt(task.day);
    final time = await _resolveTime(task);

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
    if (task.hour != null && task.minute != null) {
      return TimeOfDay(hour: task.hour!, minute: task.minute!);
    }
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('weeklyReminderHour');
    final m = prefs.getInt('weeklyReminderMinute');
    if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    return const TimeOfDay(hour: 19, minute: 0);
  }

  // ====== day helpers ======

  int _dayStringToWeekdayInt(String day) {
    final d = day.trim().toLowerCase();
    if (d.startsWith('pazartesi') || d.startsWith('mon'))
      return DateTime.monday;
    if (d.startsWith('sal') || d.startsWith('tue')) return DateTime.tuesday;
    if (d.startsWith('çar') || d.startsWith('car') || d.startsWith('wed')) {
      return DateTime.wednesday;
    }
    if (d.startsWith('per') || d.startsWith('thu')) return DateTime.thursday;
    if (d.startsWith('cuma') || d.startsWith('fri')) return DateTime.friday;
    if (d.startsWith('cmt') ||
        d.startsWith('cumartesi') ||
        d.startsWith('sat')) {
      return DateTime.saturday;
    }
    if (d.startsWith('paz') || d.startsWith('sun')) return DateTime.sunday;
    return DateTime.monday;
  }

  String _weekdayIntToCanonical(int wd) {
    switch (wd) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
