// lib/services/task_cloud_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskCloudService {
  final FirebaseFirestore _db;
  final String uid;

  TaskCloudService(this._db, this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('tasks');

  // Firestore -> Task
  Task _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return Task(
        data['name'] as String,
        completed: (data['completed'] as bool?) ?? false,
        assignedTo: data['assignedTo'] as String?,
      )
      ..remoteId =
          d.id; // Task’a String? remoteId alanı ekleyebilirsin (opsiyonel)
  }

  Map<String, dynamic> _toMap(Task t) => {
    'name': t.name,
    'completed': t.completed,
    'assignedTo': t.assignedTo,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Stream<List<Task>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> add(Task t) async {
    await _col.add(_toMap(t));
  }

  Future<void> toggle(Task t, bool val) async {
    final id = t.remoteId;
    if (id == null) return;
    await _col.doc(id).update({
      'completed': val,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAssignment(Task t, String? member) async {
    final id = t.remoteId;
    if (id == null) return;
    await _col.doc(id).update({
      'assignedTo': member,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(Task t) async {
    final id = t.remoteId;
    if (id == null) return;
    await _col.doc(id).delete();
  }

  Future<void> clearCompleted({String? forMember}) async {
    Query<Map<String, dynamic>> q = _col.where('completed', isEqualTo: true);
    if (forMember != null) {
      q = q.where('assignedTo', isEqualTo: forMember);
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
