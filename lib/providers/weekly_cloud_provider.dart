// lib/providers/weekly_cloud_provider.dart
import 'dart:async';

import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class WeeklyCloudProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  String? _familyId;
  StreamSubscription<QuerySnapshot>? _sub;

  final List<WeeklyTaskCloud> _list = [];
  List<WeeklyTaskCloud> get tasks => List.unmodifiable(_list);

  /// Bildirim id’leri: key=docId, value=notificationId
  final Box<int> _notifBox = Hive.box<int>('weeklyNotifCloudBox');

  // ===== binding =====

  void setFamilyId(String? fam) {
    if (_familyId == fam) return;
    _familyId = fam;
    _rebind();
  }

  void _rebind() {
    _sub?.cancel();
    _list.clear();
    if (_familyId == null) {
      notifyListeners();
      return;
    }
    final col = _db.collection('families/$_familyId/weekly');

    _sub = col.orderBy('createdAt', descending: false).snapshots().listen((
      snap,
    ) async {
      _list
        ..clear()
        ..addAll(snap.docs.map(WeeklyTaskCloud.fromDoc));
      notifyListeners();

      // Auto-reschedule safety (opsiyonel): yeni gelenler için id yoksa planla
      for (final w in _list) {
        if (_notifBox.get(w.id) == null) {
          await _scheduleFor(w);
        }
      }
    });
  }

  // ===== queries =====

  List<WeeklyTaskCloud> tasksForDay(String day) =>
      _list.where((t) => _sameDay(t.day, day)).toList();

  List<WeeklyTaskCloud> tasksFor(DateTime date) {
    final wd = date.weekday; // 1..7
    final canonical = _weekdayIntToCanonical(wd);
    return _list.where((t) => _sameDay(t.day, canonical)).toList();
  }

  List<WeeklyTaskCloud> todayTasks() => tasksFor(DateTime.now());

  // ===== mutations =====

  Future<void> addWeeklyTask(WeeklyTaskCloud task) async {
    if (_familyId == null) return;
    final col = _db.collection('families/$_familyId/weekly');
    final ref = await col.add(task.toMapForCreate());
    // docId lazımsa elde var:
    final doc = await ref.get();
    final created = WeeklyTaskCloud.fromDoc(doc);
    await _scheduleFor(created);
    // Stream zaten listeyi güncelleyecek; notify dinamikten gelecek.
  }

  /// Convenience: eski API’nize benzer kısa yol
  Future<void> addTask(WeeklyTaskCloud task) => addWeeklyTask(task);

  Future<void> removeWeeklyTaskById(String id) async {
    if (_familyId == null) return;
    await _cancelForId(id);
    await _db.doc('families/$_familyId/weekly/$id').delete();
  }

  Future<void> removeWeeklyTask(WeeklyTaskCloud task) =>
      removeWeeklyTaskById(task.id);

  // WeeklyCloudProvider içine (opsiyonel şeker):
  Future<void> addSimple({
    required String day,
    required String title,
    String? assignedTo,
    TimeOfDay? timeOfDay,
  }) async {
    await addWeeklyTask(
      WeeklyTaskCloud(
        day,
        title,
        assignedTo: assignedTo,
        hour: timeOfDay?.hour,
        minute: timeOfDay?.minute,
      ),
    );
  }

  /// Eski API’nizle uyumlu update
  Future<void> updateWeeklyTask(
    WeeklyTaskCloud task, {
    String? title,
    String? day,
    String? assignedTo,
    TimeOfDay? timeOfDay,
  }) async {
    if (_familyId == null) return;

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
      final v = assignedTo.trim();
      task.assignedTo = v.isEmpty ? null : v;
      needsReschedule = true;
    }
    if (timeOfDay != null) {
      task.hour = timeOfDay.hour;
      task.minute = timeOfDay.minute;
      needsReschedule = true;
    }

    await _db
        .doc('families/$_familyId/weekly/${task.id}')
        .update(task.toMapForUpdate());

    if (needsReschedule) {
      await _cancelForId(task.id);
      await _scheduleFor(task);
    }
  }

  Future<void> removeManyWeekly(Iterable<WeeklyTaskCloud> list) async {
    for (final t in list) {
      await removeWeeklyTask(t);
    }
  }

  // ===== daily sync to Tasks =====

  Future<void> ensureTodaySynced(TaskCloudProvider taskProv) async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getString('lastWeeklySync');
    final today = _dateKey(DateTime.now());
    if (last == today) return;
    await syncTodayToTasks(taskProv);
    await sp.setString('lastWeeklySync', today);
  }

  Future<void> syncTodayToTasks(TaskCloudProvider taskProv) async {
    final today = todayTasks();
    if (today.isEmpty) return;

    final existing = taskProv.tasks;
    for (final w in today) {
      final title = w.title.trim();
      final assg = w.assignedTo?.trim();
      final dup = existing.any(
        (t) =>
            t.name.toLowerCase() == title.toLowerCase() &&
            ((t.assignedTo ?? '').toLowerCase() == (assg ?? '').toLowerCase()),
      );
      if (!dup) {
        await taskProv.addTask(
          // Capitalize zaten TaskCloudProvider içinde de var; yine de temiz gidelim:
          Task(title, assignedTo: assg),
        );
      }
    }
  }

  // ===== notifications =====

  Future<void> _scheduleFor(WeeklyTaskCloud task) async {
    final weekday = _dayStringToWeekdayInt(task.day);
    final time = await _resolveTime(task);
    final id = await NotificationService.scheduleWeekly(
      title: 'Weekly task',
      body:
          '${task.title}${task.assignedTo != null ? " – ${task.assignedTo}" : ""}',
      weekday: weekday,
      timeOfDay: time,
    );
    await _notifBox.put(task.id, id);
  }

  Future<void> _cancelForId(String docId) async {
    final id = _notifBox.get(docId);
    if (id != null) {
      await NotificationService.cancel(id);
      await _notifBox.delete(docId);
    }
  }

  Future<TimeOfDay> _resolveTime(WeeklyTaskCloud task) async {
    if (task.hour != null && task.minute != null) {
      return TimeOfDay(hour: task.hour!, minute: task.minute!);
    }
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('weeklyReminderHour');
    final m = prefs.getInt('weeklyReminderMinute');
    if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    return const TimeOfDay(hour: 19, minute: 0);
  }

  // ===== helpers =====

  bool _sameDay(String a, String b) {
    final aa = a.trim().toLowerCase();
    final bb = b.trim().toLowerCase();
    final n = (aa.length < 3 || bb.length < 3) ? 1 : 3;
    return aa.substring(0, n) == bb.substring(0, n);
  }

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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // istersen açık bir teardown metodu
  void teardown() => setFamilyId(null);
}
