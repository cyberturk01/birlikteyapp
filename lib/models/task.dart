import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool completed;

  @HiveField(2)
  String? assignedTo;

  String? remoteId;

  Task(this.name, {this.completed = false, this.assignedTo, this.remoteId});
}
