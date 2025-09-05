import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/weekly_task.dart';

class WeeklyProvider extends ChangeNotifier {
  final _weeklyBox = Hive.box<WeeklyTask>('weeklyBox');

  List<WeeklyTask> get allPlans => _weeklyBox.values.toList();
  List<WeeklyTask> get tasks => _weeklyBox.values.toList();

  List<WeeklyTask> tasksForDay(String day) {
    return _weeklyBox.values.where((t) => t.day == day).toList();
  }

  void addWeeklyTask(WeeklyTask task) {
    _weeklyBox.add(task);
    notifyListeners();
  }

  void removeWeeklyTask(int index) {
    _weeklyBox.deleteAt(index);
    notifyListeners();
  }

  void addTask(WeeklyTask task) {
    _weeklyBox.add(task);
    notifyListeners();
  }

  void removeTask(WeeklyTask task) {
    task.delete();
    notifyListeners();
  }
}
