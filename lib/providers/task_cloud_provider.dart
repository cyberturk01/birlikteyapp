import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class TaskCloudProvider extends ChangeNotifier {
  final _col = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('tasks');

  final AuthService auth;
  final TaskService service;

  final List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  StreamSubscription? _authSub;
  StreamSubscription? _taskSub;
  StreamSubscription? _sub;

  TaskCloudProvider(this.auth, this.service) {
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen((qs) {
      _tasks
        ..clear()
        ..addAll(
          qs.docs.map((d) {
            final data = d.data();
            final t = Task(
              data['name'] as String,
              completed: data['completed'] as bool? ?? false,
              assignedTo: (data['assignedTo'] as String?)?.trim(),
            );
            t.remoteId = d.id; // 🔑 UI'da Dismissible key için
            return t;
          }),
        );
      notifyListeners();
    });
  }

  // void _bindAuth() {
  //   _authSub?.cancel();
  //   _authSub = auth.authState().listen((user) {
  //     _taskSub?.cancel();
  //     _tasks = [];
  //     notifyListeners();
  //
  //     if (user == null) return;
  //     _taskSub = service.watch(user.uid).listen((list) {
  //       _tasks = list;
  //       notifyListeners();
  //     });
  //   });
  // }

  List<String> get suggestedTasks {
    final names = _tasks.map((e) => e.name).toSet().toList();
    return names.take(5).toList();
  }

  Future<void> addTask(Task t) async {
    final doc = await _col.add({
      'name': t.name,
      'completed': t.completed,
      'assignedTo': t.assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
    });
    t.remoteId = doc.id; // runtime’da sakla
  }

  // === facade ===
  // Future<void> addTask(String name, {String? assignedTo}) async {
  //   final uid = auth.currentUser?.uid;
  //   if (uid == null) return;
  //   await service.add(uid, name: name, assignedTo: assignedTo);
  // }

  Future<void> toggleTask(Task t, bool value) async {
    final id = await _ensureId(t);
    await _col.doc(id).update({'completed': value});
  }

  Future<void> updateAssignment(Task t, String? member) async {
    final id = await _ensureId(t);
    await _col.doc(id).update({'assignedTo': member});
  }

  Future<void> removeTask(Task t) async {
    final id = await _ensureId(t);
    await _col.doc(id).delete();
  }

  Future<void> clearCompleted({String? forMember}) async {
    final q = forMember == null
        ? _col.where('completed', isEqualTo: true)
        : _col
              .where('completed', isEqualTo: true)
              .where('assignedTo', isEqualTo: forMember);
    final snap = await q.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
  //
  // List<String> get suggestedTasks {
  //   // örnek: en son eklenenlerden adlar (tekrarsız) + sabit öneriler
  //   final names = <String>{};
  //   for (final t in _tasks) {
  //     if (t.name.trim().isNotEmpty) names.add(t.name.trim());
  //     if (names.length >= 10) break;
  //   }
  //   return names.toList();
  // }

  Future<String> _ensureId(Task t) async {
    if (t.remoteId != null) return t.remoteId!;
    // yedek: name+assignedTo ile arama (tam eşleşme)
    final q = await _col
        .where('name', isEqualTo: t.name)
        .where('assignedTo', isEqualTo: t.assignedTo)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      t.remoteId = q.docs.first.id;
      return t.remoteId!;
    }
    // bulunamazsa yeni oluşturmamak için error fırlat
    throw StateError('Cloud doc not found for task "${t.name}"');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Future<void> toggleTask(RemoteTask t, bool value) async {
  //   final uid = auth.currentUser?.uid;
  //   if (uid == null) return;
  //   await service.toggle(uid, t.id, value);
  // }
  //
  // Future<void> removeTask(RemoteTask t) async {
  //   final uid = auth.currentUser?.uid;
  //   if (uid == null) return;
  //   await service.remove(uid, t.id);
  // }
  //
  // Future<void> updateAssignment(RemoteTask t, String? member) async {
  //   final uid = auth.currentUser?.uid;
  //   if (uid == null) return;
  //   await service.updateAssignment(uid, t.id, member);
  // }
  //
  // Future<void> clearCompleted({String? forMember}) async {
  //   final uid = auth.currentUser?.uid;
  //   if (uid == null) return;
  //   await service.clearCompleted(uid, forMember: forMember);
  // }
  //
  // @override
  // void dispose() {
  //   _authSub?.cancel();
  //   _taskSub?.cancel();
  //   super.dispose();
  // }
}
