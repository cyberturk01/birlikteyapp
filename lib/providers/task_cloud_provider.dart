import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class TaskCloudProvider extends ChangeNotifier {
  AuthService _auth;
  TaskService _service;

  User? _currentUser;
  String? _familyId; // <— eklendi
  CollectionReference<Map<String, dynamic>>? _col;

  // Ekranda gösterilen liste
  final List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  // Abonelikler
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _taskSub;

  TaskCloudProvider(this._auth, this._service) {
    _bindAuth();
  }

  /// ProxyProvider.update(...) çağrısından gelir.
  void update(AuthService newAuth, TaskService newService) {
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
    _taskSub?.cancel();
    _taskSub = null;
    _tasks.clear();
    notifyListeners();
    debugPrint('[TaskCloud] bind user=${_currentUser?.uid} fam=$_familyId');

    final user = _currentUser;
    // 👇 Kullanıcı YOKSA veya familyId YOKSA bağlanma!
    if (user == null || _familyId == null || _familyId!.isEmpty) {
      _col = null;
      return;
    }

    _col = FirebaseFirestore.instance
        .collection('families')
        .doc(_familyId!)
        .collection('tasks');

    _taskSub = _col!
        // .orderBy('createdAt', descending: true) // <-- ŞİMDİLİK KALDIR
        .orderBy(FieldPath.documentId, descending: true) // güvenli
        .snapshots()
        .listen(
          (qs) {
            _tasks
              ..clear()
              ..addAll(
                qs.docs.map((d) {
                  final data = d.data();
                  final t = Task(
                    (data['name'] as String?)?.trim() ?? '',
                    completed: (data['completed'] as bool?) ?? false,
                    assignedTo: (data['assignedTo'] as String?)?.trim(),
                  );
                  t.remoteId = d.id;
                  debugPrint(
                    '[TaskCloud] snapshot size=${qs.size} fam=$_familyId',
                  );
                  return t;
                }),
              );
            notifyListeners();
          },
          onError: (e, st) {
            debugPrint('Task stream error: $e');
            // Listeyi boşaltmayın; mevcut UI çökmesin
          },
        );
  }

  List<String> get suggestedTasks {
    final names = _tasks.map((e) => e.name).where((s) => s.isNotEmpty).toSet();
    return names.take(5).toList();
  }

  Future<void> addTask(Task t) async {
    final col = _ensureCol();
    final doc = await col.add({
      'name': t.name,
      'completed': t.completed,
      'assignedTo': t.assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
    });
    t.remoteId = doc.id;
  }

  Future<void> removeTask(Task t) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).delete();
  }

  Future<void> clearCompleted({String? forMember}) async {
    final col = _ensureCol();
    Query<Map<String, dynamic>> q = col.where('completed', isEqualTo: true);
    if (forMember != null) {
      q = q.where('assignedTo', isEqualTo: forMember);
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
  List<Task> addTasksBulk(
    List<String> names, {
    String? assignedTo,
    bool skipDuplicates = true,
  }) {
    final created = <Task>[];
    final existing = tasks.map((t) => t.name.toLowerCase()).toSet();

    for (final n in names) {
      final name = n.trim();
      if (name.isEmpty) continue;
      if (skipDuplicates && existing.contains(name.toLowerCase())) continue;

      final t = Task(name, assignedTo: assignedTo);
      _tasks.add(t);
      created.add(t);
    }
    if (created.isNotEmpty) notifyListeners();
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
      'assignedTo': t.assignedTo, // null olabilir
      'createdAt': FieldValue.serverTimestamp(),
    });
    t.remoteId = doc.id;
    return doc.id;
  }

  // TaskCloudProvider.updateAssignment(...)
  Future<void> updateAssignment(Task t, String? member) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).update({'assignedTo': member});

    // 👇 Optimistic local update
    final idx = _tasks.indexWhere((x) => x.remoteId == id);
    if (idx != -1) {
      _tasks[idx] = Task(t.name, completed: t.completed, assignedTo: member)
        ..remoteId = id;
      notifyListeners();
    }
  }

  Future<void> toggleTask(Task t, bool value) async {
    final col = _ensureCol();
    final id = await _ensureId(col, t);
    await col.doc(id).update({'completed': value});
    t.completed = value;
    notifyListeners();
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
    await col.doc(id).update({'name': newName});
    // local model’i de güncelle ki UI’da anında görünsün
    t.name = newName;
    notifyListeners();
  }

  void refreshNow() {
    _rebindTasks(); // mevcut stream'i iptal edip yeniden bağlar, _tasks'ı temizleyip yeniden doldurur
  }
}
