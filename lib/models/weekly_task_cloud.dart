// lib/models/weekly_task_cloud.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyTaskCloud {
  String? id; // <-- late final yerine nullable
  String day;
  String title;
  String? assignedToUid;
  int? hour;
  int? minute;
  DateTime createdAt;
  bool notifEnabled;

  WeeklyTaskCloud(
    this.day,
    this.title, {
    this.assignedToUid,
    this.hour,
    this.minute,
    this.id, // <-- opsiyonel, dokümandan gelirse dolar
    DateTime? createdAt,
    this.notifEnabled = true,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WeeklyTaskCloud.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    return WeeklyTaskCloud(
      (m['day'] ?? 'Monday') as String,
      (m['title'] ?? '') as String,
      assignedToUid: m['assignedToUid'] as String?,
      hour: (m['hour'] as num?)?.toInt(),
      minute: (m['minute'] as num?)?.toInt(),
      id: d.id,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notifEnabled: (m['notifEnabled'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMapForCreate() => {
    'day': day,
    'title': title.trim(),
    'assignedToUid': (assignedToUid?.trim().isNotEmpty ?? false)
        ? assignedToUid!.trim()
        : null,
    'hour': hour,
    'minute': minute,
    'notifEnabled': notifEnabled,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toMapForUpdate() => {
    if (day.isNotEmpty) 'day': day,
    if (title.isNotEmpty) 'title': title.trim(),
    'assignedToUid': (assignedToUid?.trim().isNotEmpty ?? false)
        ? assignedToUid!.trim()
        : FieldValue.delete(),
    'hour': hour,
    'minute': minute,
    'notifEnabled': notifEnabled,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
