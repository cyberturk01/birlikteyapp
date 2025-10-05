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

  Map<String, dynamic> toMapForCreate() {
    final m = <String, dynamic>{
      'day': day,
      'title': title.trim(),
      'notifEnabled': notifEnabled,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (assignedToUid?.trim().isNotEmpty == true) {
      m['assignedToUid'] = assignedToUid!.trim();
    }
    if (hour != null) m['hour'] = hour;
    if (minute != null) m['minute'] = minute;
    return m;
  }

  Map<String, dynamic> toMapForUpdate() {
    final m = <String, dynamic>{
      if (day.isNotEmpty) 'day': day,
      if (title.isNotEmpty) 'title': title.trim(),
      'notifEnabled': notifEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // assignedToUid
    if (assignedToUid?.trim().isNotEmpty == true) {
      m['assignedToUid'] = assignedToUid!.trim();
    } else {
      m['assignedToUid'] = FieldValue.delete();
    }

    // hour
    if (hour != null) {
      m['hour'] = hour;
    } else {
      m['hour'] = FieldValue.delete();
    }

    // minute
    if (minute != null) {
      m['minute'] = minute;
    } else {
      m['minute'] = FieldValue.delete();
    }

    return m;
  }
}
