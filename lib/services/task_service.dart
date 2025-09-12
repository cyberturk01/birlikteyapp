import 'package:cloud_firestore/cloud_firestore.dart';

class RemoteTask {
  final String id;
  final String name;
  final bool completed;
  final String? assignedTo;
  final DateTime createdAt;

  RemoteTask({
    required this.id,
    required this.name,
    required this.completed,
    required this.createdAt,
    this.assignedTo,
  });

  RemoteTask copyWith({
    String? id,
    String? name,
    bool? completed,
    String? assignedTo,
    DateTime? createdAt,
  }) {
    return RemoteTask(
      id: id ?? this.id,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static RemoteTask fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RemoteTask(
      id: doc.id,
      name: d['name'] as String,
      completed: (d['completed'] as bool?) ?? false,
      assignedTo: d['assignedTo'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'completed': completed,
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  Stream<List<RemoteTask>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RemoteTask.fromDoc).toList());
  }

  Future<String> add(
    String uid, {
    required String name,
    String? assignedTo,
  }) async {
    final ref = _col(uid).doc();
    await ref.set({
      'name': name.trim(),
      'completed': false,
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> toggle(String uid, String taskId, bool value) async {
    await _col(uid).doc(taskId).update({'completed': value});
  }

  Future<void> remove(String uid, String taskId) async {
    await _col(uid).doc(taskId).delete();
  }

  Future<void> updateAssignment(
    String uid,
    String taskId,
    String? member,
  ) async {
    await _col(uid).doc(taskId).update({'assignedTo': member});
  }

  Future<void> clearCompleted(String uid, {String? forMember}) async {
    Query<Map<String, dynamic>> q = _col(
      uid,
    ).where('completed', isEqualTo: true);
    if (forMember != null) {
      q = q.where('assignedTo', isEqualTo: forMember);
    }
    final batch = _db.batch();
    final snap = await q.get();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
