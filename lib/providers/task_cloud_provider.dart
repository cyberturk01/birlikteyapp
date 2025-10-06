import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/offline_queue.dart';
import '../services/retry.dart';
import '../services/scores_repo.dart';
import '../services/task_service.dart';
import '_base_cloud.dart';

enum ToggleResult { ok, okNoScore, denied, error }

class TaskCloudProvider extends ChangeNotifier with CloudErrorMixin {
  AuthService _auth;
  TaskService _service;
  final ScoresRepo _scores; // <- ekle
  late final FirebaseAuth _fbAuth;
  final _uuid = Uuid();

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
  void setFamilyId(String? id) {
    if (_familyId == id) return;
    _familyId = id;
    _rebindTasks();
  }

  void _bindAuth() {
    _authSub = _fbAuth.authStateChanges().listen((user) {
      _currentUser = user;
      _rebindTasks(); // senin mevcut mantığın
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

    debugPrint('[TaskCloud] ADDED id=$id');
    await _qSet(path: path, data: data, merge: false);
    t.remoteId = id;
  }

  Future<void> removeTask(Task t) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await NotificationService.cancel(_notifIdForTask(t));
    await _qDelete(path: '${col.path}/$id');
  }

  Future<void> updateDueDate(Task t, DateTime? due) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        if (due == null)
          'dueAt': FieldValue.delete()
        else
          'dueAt': Timestamp.fromDate(due),
      },
    );
    t.dueAt = due;
    notifyListeners();
  }

  Future<void> updateReminder(Task t, DateTime? at) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);

    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        if (at == null)
          'reminderAt': FieldValue.delete()
        else
          'reminderAt': Timestamp.fromDate(at),
      },
    );
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
      await _qDelete(path: d.reference.path);
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
    await _qSet(
      path: '${col.path}/$genId',
      data: {
        'name': t.name,
        'completed': t.completed,
        if ((t.assignedToUid?.trim().isNotEmpty ?? false))
          'assignedToUid': t.assignedToUid!.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      merge: false,
    );
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
    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        'assignedToUid': (memberUid == null || memberUid.trim().isEmpty)
            ? FieldValue.delete()
            : memberUid.trim(),
      },
    );

    final idx = _tasks.indexWhere((x) => x.remoteId == id);
    if (idx != -1) {
      _tasks[idx] = Task(
        t.name,
        completed: t.completed,
        assignedToUid: (memberUid?.trim().isEmpty ?? true)
            ? null
            : memberUid!.trim(),
      )..remoteId = id;

      notifyListeners();
    }
  }

  Future<ToggleResult> toggleTask(Task t, bool value) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);

    await _qUpdate(path: '${col.path}/$id', data: {'completed': value});

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
      final msg = e.toString();
      debugPrint('[TaskCloud] score write failed: $msg');
      setError(e);

      // rules’dan permission-denied gelirse
      if (msg.contains('permission-denied')) {
        return ToggleResult.okNoScore; // task tamamlandı ama puan yazamadık
      }
      return ToggleResult.error;
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
    await _qUpdate(path: '${col.path}/$id', data: {'name': newName.trim()});
    // local model’i de güncelle ki UI’da anında görünsün
    t.name = newName.trim();
    notifyListeners();
  }

  void refreshNow() {
    _rebindTasks(); // mevcut stream'i iptal edip yeniden bağlar, _tasks'ı temizleyip yeniden doldurur
  }

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
      final safe = _sanitizeForQueue(data);
      await OfflineQueue.I.enqueue(
        OfflineOp(
          id: _uuid.v4(),
          path: path,
          type: OpType.set,
          data: safe,
          merge: merge,
        ),
      );
    }
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
      await col.doc(d.id).update({
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

  Map<String, dynamic> _sanitizeForQueue(Map<String, dynamic> input) {
    final Map<String, dynamic> out = {};
    input.forEach((k, v) {
      if (v is FieldValue) {
        final s = v.toString();
        if (s.contains('serverTimestamp')) {
          out[k] = DateTime.now(); // JSON'a uygun
        }
      } else if (v is Map) {
        out[k] = _sanitizeForQueue(Map<String, dynamic>.from(v));
      } else if (v is List) {
        out[k] = v.map((e) {
          if (e is Map) return _sanitizeForQueue(Map<String, dynamic>.from(e));
          return (e is FieldValue) ? null : e;
        }).toList();
      } else {
        out[k] = v;
      }
    });
    return out;
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
