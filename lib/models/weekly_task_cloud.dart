// lib/models/weekly_task_cloud.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyTaskCloud {
  final String id; // Firestore doc id
  String day; // "Monday"..."Sunday" (or localized forms you already accept)
  String title;
  String? assignedTo; // "You (name)" format continues
  int? hour; // optional reminder hour
  int? minute; // optional reminder minute
  DateTime createdAt;

  WeeklyTaskCloud(
    this.day,
    this.title, {
    this.assignedTo,
    this.hour,
    this.minute,
    String? id, // <-- ARTIK OPTIONAL
    DateTime? createdAt,
  }) : id = id ?? '_pending_', // <-- geçici id
       createdAt = createdAt ?? DateTime.now();

  factory WeeklyTaskCloud.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    return WeeklyTaskCloud(
      (m['day'] ?? 'Monday') as String,
      (m['title'] ?? '') as String,
      assignedTo: m['assignedTo'] as String?,
      hour: (m['hour'] as num?)?.toInt(),
      minute: (m['minute'] as num?)?.toInt(),
      id: d.id,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMapForCreate() => {
    'title': _cap(title),
    'day': day,
    'assignedTo': assignedTo,
    'hour': hour,
    'minute': minute,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toMapForUpdate() => {
    'title': _cap(title),
    'day': day,
    'assignedTo': assignedTo,
    'hour': hour,
    'minute': minute,
  };

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
