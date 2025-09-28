import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/scores_repo.dart';
import '../services/task_service.dart';
import '_base_cloud.dart';

class TaskCloudProvider extends ChangeNotifier with CloudErrorMixin {
  AuthService _auth;
  TaskService _service;
  final ScoresRepo _scores; // <- ekle

  TaskCloudProvider(this._auth, this._service, this._scores) {
    _bindAuth();
  }

  User? _currentUser;
  String? _familyId; // <— eklendi
  CollectionReference<Map<String, dynamic>>? _col;

  // Ekranda gösterilen liste
  final List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  // Abonelikler
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _taskSub;

  /// ProxyProvider.update(...) çağrısından gelir.
  void update(AuthService newAuth, TaskService newService, ScoresRepo scores) {
    var changed = false;
    if (!identical(_auth, newAuth)) {
      _auth = newAuth;
      changed = true;
    }
    if (!identical(_service, newService)) {
      _service = newService;
      changed = true;
    }
    if (changed) {
      // Auth/Service değiştiyse auth dinleyicisini yeniden kur
      _rebindAuth();
    }
  }

  // === Binding ===
  // <<< AİLE ID SETTERI
  void setFamilyId(String? id) {
    if (_familyId == id) return;
    _familyId = id;
    _rebindTasks();
  }

  void _bindAuth() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      _rebindTasks(); // kullanıcı değişti: task akışını yeniden bağla
    });
  }

  void _rebindAuth() {
    _authSub?.cancel();
    _authSub = null;
    _bindAuth();
  }

  void _rebindTasks() {
    debugPrint('[TaskCloud] REBIND → user=${_currentUser?.uid} fam=$_familyId');

    _taskSub?.cancel();
    _taskSub = null;
    _tasks.clear();
    notifyListeners();

    if (_currentUser == null || _familyId == null || _familyId!.isEmpty) {
      _col = null;
      debugPrint('[TaskCloud] SKIP (user/family null)');
      return;
    }

    _col = FirebaseFirestore.instance
        .collection('families')
        .doc(_familyId!)
        .collection('tasks');

    debugPrint('[TaskCloud] PATH = ${_col!.path}');

    // TEST: orderBy'ı geçici kaldır → snapshot geliyor mu görelim
    _taskSub = _col!
        //.orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .listen(
          (qs) {
            clearError();
            debugPrint('[TaskCloud] SNAP size=${qs.size}');
            _tasks
              ..clear()
              ..addAll(
                qs.docs.map((d) {
                  final data = d.data();
                  debugPrint('[TaskCloud] doc ${d.id} => $data');
                  final t = Task(
                    (data['name'] as String?)?.trim() ?? '',
                    completed: (data['completed'] as bool?) ?? false,
                    assignedToUid:
                        ((data['assignedToUid'] ?? data['assignedTo'])
                                as String?)
                            ?.trim(),
                    origin: data['origin'] as String?,
                    dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
                    reminderAt: (data['reminderAt'] as Timestamp?)?.toDate(),
                  );
                  t.remoteId = d.id;
                  return t;
                }),
              );
            clearError();
            notifyListeners();
          },
          onError: (e, st) {
            debugPrint('[TaskCloud] STREAM ERROR: $e');
            setError(e);
          },
        );
  }

  List<String> get suggestedTasks {
    final names = _tasks.map((e) => e.name).where((s) => s.isNotEmpty).toSet();
    return names.take(5).toList();
  }

  Future<void> addTask(Task t) async {
    final col = _ensureCol();
    debugPrint(
      '[TaskCloud] ADD name=${t.name} fam=$_familyId path=${col.path}',
    );
    final doc = await col.add({
      'name': t.name,
      'completed': t.completed,
      'assignedToUid': t.assignedToUid ?? FieldValue.delete(),
      if (t.origin != null) 'origin': t.origin,
      if (t.dueAt != null) 'dueAt': Timestamp.fromDate(t.dueAt!),
      if (t.reminderAt != null) 'reminderAt': Timestamp.fromDate(t.reminderAt!),
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[TaskCloud] ADDED id=${doc.id}');
    t.remoteId = doc.id;
  }

  Future<void> removeTask(Task t) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await NotificationService.cancel(_notifIdForTask(t));
    await col.doc(id).delete();
  }

  Future<void> updateDueDate(Task t, DateTime? due) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).update({
      if (due == null)
        'dueAt': FieldValue.delete()
      else
        'dueAt': Timestamp.fromDate(due),
    });
    t.dueAt = due;
    notifyListeners();
  }

  Future<void> updateReminder(Task t, DateTime? at) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);

    await col.doc(id).update({
      if (at == null)
        'reminderAt': FieldValue.delete()
      else
        'reminderAt': Timestamp.fromDate(at),
    });
    t.reminderAt = at;
    notifyListeners();

    final nid = _notifIdForTask(t);
    if (at != null && at.isAfter(DateTime.now()) && !t.completed) {
      await NotificationService.scheduleOneTime(
        id: nid,
        title: 'Reminder',
        body: t.name,
        whenLocal: at,
      );
    } else {
      await NotificationService.cancel(nid);
    }
  }

  Future<void> clearCompleted({String? forMember}) async {
    final col = _ensureCol();
    Query<Map<String, dynamic>> q = col.where('completed', isEqualTo: true);
    if (forMember != null) {
      q = q.where('assignedToUid', isEqualTo: forMember);
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  // === Helpers ===

  CollectionReference<Map<String, dynamic>> _ensureCol() {
    final col = _col;
    if (col == null) {
      throw StateError(
        'No authenticated user / Firestore collection not bound.',
      );
    }
    return col;
  }

  // TaskCloudProvider.dart
  Future<List<Task>> addTasksBulkCloud(
    List<String> names, {
    String? assignedToUid,
  }) async {
    final created = <Task>[];
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final t = Task(name, assignedToUid: assignedToUid);
      await addTask(t); // Firestore’a yazar ve remoteId setler
      created.add(t);
    }
    return created;
  }

  void removeManyTasks(Iterable<Task> list) {
    for (final t in list) {
      t.delete();
    }
    if (list.isNotEmpty) notifyListeners();
  }

  Future<String> _ensureId(
    CollectionReference<Map<String, dynamic>> col,
    Task t,
  ) async {
    if (t.remoteId != null) return t.remoteId!;

    // Yalnızca isme göre en yeni kaydı ara
    final byName = await col
        .where('name', isEqualTo: t.name)
        // createdAt tüm kayıtlarda yoksa şu satırı kaldırabilirsiniz:
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (byName.docs.isNotEmpty) {
      t.remoteId = byName.docs.first.id;
      return t.remoteId!;
    }

    // Bulunamadı → yeni doküman oluştur
    final doc = await col.add({
      'name': t.name,
      'completed': t.completed,
      'assignedToUid': t.assignedToUid, // null olabilir
      'createdAt': FieldValue.serverTimestamp(),
    });
    t.remoteId = doc.id;
    return doc.id;
  }

  int _notifIdForTask(Task t) {
    // remoteId varsa onu kullan; yoksa isim hash’i
    return (t.remoteId?.hashCode ?? t.name.hashCode) & 0x7FFFFFFF;
  }

  // TaskCloudProvider.updateAssignment(...)
  Future<void> updateAssignment(Task t, String? memberUid) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).update({
      'assignedToUid': (memberUid == null || memberUid.trim().isEmpty)
          ? FieldValue.delete()
          : memberUid.trim(),
    });
    t.assignedToUid = (memberUid?.trim().isEmpty ?? true)
        ? null
        : memberUid!.trim();

    final idx = _tasks.indexWhere((x) => x.remoteId == id);
    if (idx != -1) {
      _tasks[idx] = Task(
        t.name,
        completed: t.completed,
        assignedToUid: memberUid,
      )..remoteId = id;
      notifyListeners();
    }
  }

  Future<void> toggleTask(Task t, bool value) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);

    await col.doc(id).update({'completed': value});

    if (value == true && t.reminderAt != null) {
      await NotificationService.cancel(_notifIdForTask(t));
    }
    t.completed = value;
    notifyListeners();

    try {
      if (_familyId != null && _familyId!.isNotEmpty) {
        final targetUid =
            (t.assignedToUid != null && t.assignedToUid!.trim().isNotEmpty)
            ? t.assignedToUid!.trim()
            : _currentUser?.uid; // atama yoksa işi yapan kullanıcıya yaz
        if (targetUid != null && targetUid.isNotEmpty) {
          final delta = value ? 10 : -10;
          await _scores.addPoints(
            familyId: _familyId!,
            uid: targetUid,
            delta: delta,
          );
        }
      }
    } catch (e) {
      debugPrint('[TaskCloud] score write failed: $e');
      setError(e);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _taskSub?.cancel();
    super.dispose();
  }

  Future<void> renameTask(Task t, String newName) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).update({'name': newName.trim()});
    // local model’i de güncelle ki UI’da anında görünsün
    t.name = newName.trim();
    notifyListeners();
  }

  void refreshNow() {
    _rebindTasks(); // mevcut stream'i iptal edip yeniden bağlar, _tasks'ı temizleyip yeniden doldurur
  }

  void teardown() => setFamilyId(null);
}
