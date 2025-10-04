// lib/providers/weekly_cloud_provider.dart
import 'dart:async';

import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:birlikteyapp/providers/task_cloud_provider.dart';
import 'package:birlikteyapp/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/offline_queue.dart';
import '../services/retry.dart';
import '_base_cloud.dart';

class WeeklyCloudProvider extends ChangeNotifier with CloudErrorMixin {
  final _db = FirebaseFirestore.instance;

  String? _familyId;
  StreamSubscription<QuerySnapshot>? _sub;

  final Set<String> _syncingOrigins = {};
  final _uuid = const Uuid();

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

    _sub = col
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snap) async {
            clearError();
            _list
              ..clear()
              ..addAll(snap.docs.map(WeeklyTaskCloud.fromDoc));
            clearError();
            notifyListeners();

            await _cleanupOrphans();

            for (final w in _list) {
              if (_notifBox.get(w.id) == null &&
                  w.notifEnabled == true &&
                  w.hour != null &&
                  w.minute != null) {
                await _scheduleFor(w);
              }
            }
          },
          onError: (e) {
            debugPrint('[WeeklyTaskCloud] STREAM ERROR: $e');
            setError(e);
          },
        );
  }

  // ===== queries =====
  Future<void> _cleanupOrphans() async {
    final idsInFirestore = _list
        .map((e) => e.id)
        .whereType<String>()
        .toSet(); // <- null’ları at
    final keysInBox = _notifBox.keys.cast<String>().toList();
    for (final k in keysInBox) {
      if (!idsInFirestore.contains(k)) {
        final nid = _notifBox.get(k);
        if (nid != null) await NotificationService.cancel(nid);
        await _notifBox.delete(k);
      }
    }
  }

  List<WeeklyTaskCloud> tasksForDay(String day) =>
      _list.where((t) => _sameDay(t.day, day)).toList();

  List<WeeklyTaskCloud> tasksFor(DateTime date) {
    final wd = date.weekday; // 1..7
    final canonical = _weekdayIntToCanonical(wd);
    return _list.where((t) => _sameDay(t.day, canonical)).toList();
  }

  List<WeeklyTaskCloud> todayTasks() => tasksFor(DateTime.now());

  // ===== mutations =====
  Future<WeeklyTaskCloud> addWeeklyTask(WeeklyTaskCloud task) async {
    if (_familyId == null) throw StateError('No familyId');

    task.day = _canonicalDay(task.day);
    final colPath = 'families/$_familyId/weekly';
    final id = task.id ?? _uuid.v4();
    final path = '$colPath/$id';

    await _qSet(path: path, data: task.toMapForCreate(), merge: false);

    task.id ??= id;
    _list.add(task);
    notifyListeners();

    await _scheduleFor(task);
    return task;
  }

  Future<void> updateWeeklyTask(
    WeeklyTaskCloud task, {
    String? title,
    String? day,
    String? assignedToUid,
    TimeOfDay? timeOfDay,
    bool? notifEnabled,
  }) async {
    if (_familyId == null) return;

    bool needsReschedule = false;
    bool forceCancel = false;

    if (title != null && title.trim().isNotEmpty && title != task.title) {
      task.title = title.trim();
    }
    if (day != null && day.trim().isNotEmpty) {
      final canon = _canonicalDay(day);
      if (canon != task.day) {
        task.day = canon;
        needsReschedule = true;
      }
    }
    // if (day != null && day.trim().isNotEmpty && day != task.day) {
    //   task.day = day.trim();
    //   needsReschedule = true;
    // }
    if (assignedToUid != null) {
      final v = assignedToUid.trim();
      task.assignedToUid = v.isEmpty ? null : v;
    }
    if (timeOfDay != null) {
      if (timeOfDay.hour == -1 && timeOfDay.minute == -1) {
        // “clear” protokolü
        task.hour = null;
        task.minute = null;
        forceCancel = true; // saat silindiyse iptal
        needsReschedule = false;
      } else {
        task.hour = timeOfDay.hour;
        task.minute = timeOfDay.minute;
        needsReschedule =
            true; // saat değiştiyse yeniden planla (toggle açıksa)
      }
    }
    if (notifEnabled != null && notifEnabled != task.notifEnabled) {
      task.notifEnabled = notifEnabled;
      if (!notifEnabled) {
        forceCancel = true; // toggle kapandıysa iptal
        needsReschedule = false;
      } else {
        // toggle açıldı; saat varsa yeniden planlayacağız
        if (task.hour != null && task.minute != null) {
          needsReschedule = true;
        }
      }
    }
    await _qUpdate(
      path: 'families/$_familyId/weekly/${task.id}',
      data: task.toMapForUpdate(),
    );

    if (forceCancel) {
      await _cancelForId(task.id);
    } else if (needsReschedule) {
      await _cancelForId(task.id);
      await _scheduleFor(task);
    }
  }

  Future<List<WeeklyTaskCloud>> addWeeklyBulk(
    List<(String, String)> entries, {
    String? assignedToUid,
  }) async {
    final created = <WeeklyTaskCloud>[];
    for (final e in entries) {
      final day = e.$1.trim();
      final title = e.$2.trim();
      if (day.isEmpty || title.isEmpty) continue;

      final pending = WeeklyTaskCloud(day, title, assignedToUid: assignedToUid);
      final saved = await addWeeklyTask(pending); // <-- KAYDEDİLENİ AL
      created.add(saved); // <-- GERÇEK id’Lİ OBJ
    }
    return created;
  }

  Future<WeeklyTaskCloud> addTask(WeeklyTaskCloud task) => addWeeklyTask(task);

  Future<void> removeWeeklyTaskById(String? id) async {
    if (_familyId == null || id == null) return;
    await _cancelForId(id);
    await _qDelete(path: 'families/$_familyId/weekly/$id');
  }

  Future<void> removeWeeklyTask(WeeklyTaskCloud task) =>
      removeWeeklyTaskById(task.id);

  // WeeklyCloudProvider içine (opsiyonel şeker):
  Future<void> addSimple({
    required String day,
    required String title,
    String? assignedToUid,
    TimeOfDay? timeOfDay,
  }) async {
    await addWeeklyTask(
      WeeklyTaskCloud(
        day,
        title,
        assignedToUid: assignedToUid,
        hour: timeOfDay?.hour,
        minute: timeOfDay?.minute,
      ),
    );
  }

  Future<void> removeManyWeekly(Iterable<WeeklyTaskCloud> list) async {
    for (final t in list) {
      await removeWeeklyTask(t);
    }
  }

  String _canonicalDay(String s) {
    final d = s.trim().toLowerCase();

    // EN
    if (d.startsWith('mon')) return 'Monday';
    if (d.startsWith('tue')) return 'Tuesday';
    if (d.startsWith('wed')) return 'Wednesday';
    if (d.startsWith('thu')) return 'Thursday';
    if (d.startsWith('fri')) return 'Friday';
    if (d.startsWith('sat')) return 'Saturday';
    if (d.startsWith('sun')) return 'Sunday';

    // TR
    if (d.startsWith('pazartesi') || d.startsWith('pzt') || d.startsWith('pts'))
      return 'Monday';
    if (d.startsWith('sal')) return 'Tuesday';
    if (d.startsWith('çar') || d.startsWith('car')) return 'Wednesday';
    if (d.startsWith('per')) return 'Thursday';
    if (d.startsWith('cuma')) return 'Friday';
    if (d.startsWith('cumartesi') || d.startsWith('cmt')) return 'Saturday';
    if (d.startsWith('pazar') || d.startsWith('paz')) return 'Sunday';

    // DE
    if (d.startsWith('montag') || d == 'mo') return 'Monday';
    if (d.startsWith('dienstag') || d == 'di') return 'Tuesday';
    if (d.startsWith('mittwoch') || d == 'mi') return 'Wednesday';
    if (d.startsWith('donnerstag') || d == 'do') return 'Thursday';
    if (d.startsWith('freitag') || d == 'fr') return 'Friday';
    if (d.startsWith('samstag') || d.startsWith('sonnabend') || d == 'sa')
      return 'Saturday';
    if (d.startsWith('sonntag') || d == 'so') return 'Sunday';

    return 'Monday';
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

    for (final w in today) {
      await taskProv.upsertByOrigin(
        origin: 'weekly:${w.id}',
        title: w.title.trim(),
        assignedToUid: w.assignedToUid?.trim(),
      );
    }
  }

  // ===== notifications =====

  Future<void> _scheduleFor(WeeklyTaskCloud task) async {
    if (task.notifEnabled != true) return;
    if (task.hour == null || task.minute == null) return;
    if (task.id == null) return;

    final weekday = _dayStringToWeekdayInt(task.day);
    final time = await _resolveTime(task);
    final nid = await NotificationService.scheduleWeekly(
      title: 'Weekly task',
      body: task.title,
      weekday: weekday,
      timeOfDay: time,
    );
    await _notifBox.put(task.id, nid);
  }

  Future<void> _cancelForId(String? docId) async {
    if (docId == null) return;
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

  bool _sameDay(String a, String b) => _canonicalDay(a) == _canonicalDay(b);

  int _dayStringToWeekdayInt(String day) {
    switch (_canonicalDay(day)) {
      case 'Monday':
        return DateTime.monday;
      case 'Tuesday':
        return DateTime.tuesday;
      case 'Wednesday':
        return DateTime.wednesday;
      case 'Thursday':
        return DateTime.thursday;
      case 'Friday':
        return DateTime.friday;
      case 'Saturday':
        return DateTime.saturday;
      case 'Sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
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

  Future<void> _qSet({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    Future<void> write() async => FirebaseFirestore.instance
        .doc(path)
        .set(data, SetOptions(merge: merge));
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(
          id: _uuid.v4(),
          path: path,
          type: OpType.set,
          data: data,
          merge: merge,
        ),
      );
    }
  }

  Future<void> _qUpdate({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    Future<void> write() async =>
        FirebaseFirestore.instance.doc(path).update(data);
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(id: _uuid.v4(), path: path, type: OpType.update, data: data),
      );
    }
  }

  Future<void> _qDelete({required String path}) async {
    Future<void> write() async => FirebaseFirestore.instance.doc(path).delete();
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(id: _uuid.v4(), path: path, type: OpType.delete),
      );
    }
  }
}
