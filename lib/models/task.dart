import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool completed;

  @HiveField(2)
  String? assignedToUid;

  String? remoteId;

  @HiveField(3)
  String? origin;

  @HiveField(4)
  DateTime? dueAt;

  @HiveField(5)
  DateTime? reminderAt;

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  Task(
    String name, {
    this.completed = false,
    this.assignedToUid,
    this.remoteId,
    this.origin,
    this.dueAt,
    this.reminderAt,
  }) : name = _capitalize(name);

  factory Task.fromSnap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Task(
      (d['name'] as String).trim(),
      completed: (d['completed'] as bool?) ?? false,
      assignedToUid:
          (d['assignedToUid'] as String?) ??
          (d['assignedTo'] as String?), // geri uyum
      origin: d['origin'] as String?,
      dueAt: (d['dueAt'] as Timestamp?)?.toDate(),
      reminderAt: (d['reminderAt'] as Timestamp?)?.toDate(),
    )..remoteId = doc.id;
  }
}
