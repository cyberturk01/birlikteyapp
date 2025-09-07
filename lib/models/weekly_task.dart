import 'package:hive/hive.dart';

part 'weekly_task.g.dart';

@HiveType(typeId: 2)
class WeeklyTask extends HiveObject {
  @HiveField(0)
  String day; // e.g. Monday, Tuesday

  @HiveField(1)
  String title;

  @HiveField(2)
  String? assignedTo;

  @HiveField(3)
  int? hour; // 0-23

  @HiveField(4)
  int? minute; // 0-59

  WeeklyTask(this.title, this.day, {this.assignedTo, this.hour, this.minute});
}
