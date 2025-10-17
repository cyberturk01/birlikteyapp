import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/cloud_error_handler.dart';
import '../services/firestore_write_helpers.dart';
import '../services/notification_service.dart';
import '../services/scores_repo.dart';
import '../services/task_service.dart';
import '_base_cloud.dart';

enum ToggleResult { ok, okNoScore, denied, error }

class TaskCloudProvider extends ChangeNotifier with CloudErrorMixin {
  AuthService _auth;
  TaskService _service;
  final ScoresRepo _scores; // <- ekle
  late final FirebaseAuth _fbAuth;
  final _uuid = const Uuid();

  TaskCloudProvider(
    this._auth,
    this._service,
    this._scores, {
    FirebaseAuth? firebaseAuth, // <-- ekle
  }) {
    _fbAuth = firebaseAuth ?? FirebaseAuth.instance; // <-- kritik satır
    _bindAuth(); // mevcut akışın aynısı
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
  Future<void> setFamilyId(String? id) async {
    if (_familyId == id) return;
    _familyId = id;

    await _cancelTaskStream(); // sadece task stream’i kapat
    _tasks.clear();
    clearError();

    if (_currentUser == null || id == null || id.isEmpty) {
      _col = null;
      notifyListeners();
      return;
    }
    _bindTasks(); // yeni family için task stream’i kur
  }

  void _bindAuth() {
    _authSub?.cancel();
    _authSub = _fbAuth.authStateChanges().listen((user) async {
      _currentUser = user;
      await setFamilyId(_familyId); // mevcut family ile task stream’i resetle
    });
  }

  Future<void> _rebindAuth() async {
    await _authSub?.cancel();
    _authSub = null;
    _bindAuth();
    await setFamilyId(_familyId);
  }

  void _bindTasks() {
    final fid = _familyId;
    final uid = _currentUser?.uid;
    if (fid == null || fid.isEmpty || uid == null) {
      _col = null;
      return;
    }

    _col = FirebaseFirestore.instance
        .collection('families')
        .doc(fid)
        .collection('tasks');

    _taskSub?.cancel();
    _taskSub = _col!.snapshots().listen(
      (qs) {
        clearError();
        _tasks
          ..clear()
          ..addAll(
            qs.docs.map((d) {
              final m = d.data();
              final t = Task(
                (m['name'] as String?)?.trim() ?? '',
                completed: (m['completed'] as bool?) ?? false,
                assignedToUid:
                    ((m['assignedToUid'] ?? m['assignedTo']) as String?)
                        ?.trim(),
                origin: m['origin'] as String?,
                dueAt: (m['dueAt'] as Timestamp?)?.toDate(),
                reminderAt: (m['reminderAt'] as Timestamp?)?.toDate(),
              )..remoteId = d.id;
              return t;
            }),
          );
        notifyListeners();
      },
      onError: (e, st) {
        setError(e);
        CloudErrorHandler.showFromException(e);
        notifyListeners();
      },
    );
  }

  Future<void> _cancelTaskStream() async {
    await _taskSub?.cancel();
    _taskSub = null;
  }

  List<String> get suggestedTasks {
    final names = _tasks.map((e) => e.name).where((s) => s.isNotEmpty).toSet();
    return names.take(5).toList();
  }

  Future<void> addTask(Task t) async {
    final col = _ensureCol();
    final id = t.remoteId ?? _uuid.v4();
    final path = '${col.path}/$id';
    debugPrint(
      '[TaskCloud] ADD name=${t.name} fam=$_familyId path=${col.path}',
    );
    final data = {
      'name': t.name,
      'completed': t.completed,
      if ((t.assignedToUid?.trim().isNotEmpty ?? false))
        'assignedToUid': t.assignedToUid!.trim(),
      if (t.origin != null) 'origin': t.origin,
      if (t.dueAt != null) 'dueAt': Timestamp.fromDate(t.dueAt!),
      if (t.reminderAt != null) 'reminderAt': Timestamp.fromDate(t.reminderAt!),
      'createdAt': FieldValue.serverTimestamp(),
    };
    final ref = FirebaseFirestore.instance.doc(path);
    await setDocWithRetryQueue(ref, data, merge: false);
    debugPrint('[TaskCloud] ADDED id=$id');
    t.remoteId = id;
  }

  Future<void> removeTask(Task t) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await deleteDocWithRetryQueue(ref);
    await NotificationService.cancel(_notifIdForTask(t));
  }

  Future<void> updateDueDate(Task t, DateTime? due) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    if (due == null) {
      await safeFieldDeletesWithRetryQueue(ref, {'dueAt': FieldValue.delete()});
    } else {
      await updateDocWithRetryQueue(ref, {'dueAt': Timestamp.fromDate(due)});
    }
    t.dueAt = due;
    notifyListeners();
  }

  Future<void> updateReminder(Task t, DateTime? at) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    if (at == null) {
      await safeFieldDeletesWithRetryQueue(ref, {
        'reminderAt': FieldValue.delete(),
      });
    } else {
      await updateDocWithRetryQueue(ref, {
        'reminderAt': Timestamp.fromDate(at),
      });
    }
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
      await deleteDocWithRetryQueue(d.reference);
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

    final genId = _uuid.v4();
    final ref = FirebaseFirestore.instance.doc('${col.path}/$genId');
    await setDocWithRetryQueue(ref, {
      'name': t.name,
      'completed': t.completed,
      if ((t.assignedToUid?.trim().isNotEmpty ?? false))
        'assignedToUid': t.assignedToUid!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, merge: false);
    t.remoteId = genId;
    return genId;
  }

  int _notifIdForTask(Task t) {
    // remoteId varsa onu kullan; yoksa isim hash’i
    return (t.remoteId?.hashCode ?? t.name.hashCode) & 0x7FFFFFFF;
  }

  Future<void> updateAssignment(Task t, String? memberUid) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(ref, {
      'assignedToUid': (memberUid == null || memberUid.trim().isEmpty)
          ? FieldValue.delete()
          : memberUid.trim(),
    });

    final newAssignee = (memberUid == null || memberUid.trim().isEmpty)
        ? null
        : memberUid.trim();
    final idx = _tasks.indexWhere((x) => x.remoteId == id);
    if (idx != -1) {
      _tasks[idx] = Task(
        t.name,
        completed: t.completed,
        assignedToUid: newAssignee,
      )..remoteId = id;
    } else {
      t.assignedToUid = newAssignee;
    }
    notifyListeners();
  }

  Future<ToggleResult> toggleTask(Task t, bool value) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(
      ref,
      {'completed': value},
      onQueued: () {
        final ctx = navigatorKey.currentContext;
        final tLoc = (ctx != null) ? AppLocalizations.of(ctx) : null;
        final msg =
            tLoc?.queuedTaskToggle ??
            'Offline: Task toggle queued. It will sync when online.';
        CloudErrorHandler.showFromString(msg);
      },
    );
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
            : _currentUser?.uid;

        if (targetUid != null && targetUid.isNotEmpty) {
          final delta = value ? 10 : -10;
          await _scores.addPoints(
            familyId: _familyId!,
            uid: targetUid,
            delta: delta,
          );
          return ToggleResult.ok;
        }
      }
      return ToggleResult.okNoScore;
    } catch (e) {
      debugPrint('[TaskCloud] score write failed: $e');
      setError(e);

      final kind = mapExceptionToKind(e);

      // Kullanıcıya nazikçe anlat
      CloudErrorHandler.show(kind);

      // Task tamamlandı fakat skor yazamadık: izin/oturum/network gibi durumlarda
      if (kind == CloudErrorKind.permissionDenied ||
          kind == CloudErrorKind.unauthenticated ||
          kind == CloudErrorKind.network ||
          kind == CloudErrorKind.unavailable ||
          kind == CloudErrorKind.quota) {
        return ToggleResult.okNoScore;
      }

      return ToggleResult.error;
    }
  }

  Future<void> renameTask(Task t, String newName) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(ref, {'name': newName.trim()});
    t.name = newName.trim();
    notifyListeners();
  }

  Future<void> refreshNow() async {
    await _cancelTaskStream();
    _tasks.clear();
    clearError();

    if (_currentUser != null && (_familyId?.isNotEmpty ?? false)) {
      _bindTasks();
    } else {
      _col = null;
      notifyListeners();
    }
  }

  Future<void> teardown() async {
    await _cancelTaskStream();
    await _authSub?.cancel();
    _authSub = null;

    _tasks.clear();
    clearError();
    _col = null;
    // _familyId = null; // istersen burada da sıfırlayabilirsin
    notifyListeners();
  }

  @override
  void dispose() {
    teardown();
    super.dispose();
  }

  Future<void> upsertByOrigin({
    required String origin, // ör: 'weekly:<weeklyId>'
    required String title,
    String? assignedToUid,
  }) async {
    // 0) Önce yerelde var mı?
    final localIdx = tasks.indexWhere((t) => t.origin == origin);
    if (localIdx != -1) {
      final t = tasks[localIdx];
      if (t.name != title) await renameTask(t, title);
      if ((t.assignedToUid ?? '') != (assignedToUid ?? '')) {
        await updateAssignment(t, assignedToUid);
      }
      return;
    }

    // 1) Bulut’ta var mı? (origin alanı ile)
    final col = _ensureCol(); // kendi kodundaki koleksiyon erişimi
    final snap = await col.where('origin', isEqualTo: origin).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first;
      // Yerel listeye ekle veya güncelle
      final existingIdx = tasks.indexWhere((x) => x.remoteId == d.id);
      if (existingIdx == -1) {
        final t = Task(title, assignedToUid: assignedToUid, origin: origin)
          ..remoteId = d.id;
        tasks.add(t);
        notifyListeners();
      }
      // Alanları güncel tut
      await updateDocWithRetryQueue(col.doc(d.id), {
        'name': title,
        'assignedToUid': (assignedToUid == null || assignedToUid.trim().isEmpty)
            ? FieldValue.delete()
            : assignedToUid.trim(),
      });
      return;
    }

    // 2) Hiç yoksa oluştur (origin ile)
    await addTask(Task(title, assignedToUid: assignedToUid, origin: origin));
  }
}
