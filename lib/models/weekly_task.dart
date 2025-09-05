import 'package:hive/hive.dart';

part 'weekly_task.g.dart';

@HiveType(typeId: 2)
class WeeklyTask extends HiveObject {
  @HiveField(0)
  String day; // e.g. Monday, Tuesday

  @HiveField(1)
  String task;

  @HiveField(2)
  String? assignedTo;

  WeeklyTask(this.day, this.task, {this.assignedTo});
}
