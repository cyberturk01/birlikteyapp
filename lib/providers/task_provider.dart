import 'package:birlikteyapp/providers/weekly_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final _taskBox = Hive.box<Task>('taskBox');
  final _taskCountBox = Hive.box<int>('taskCountBox'); // new

  List<Task> get tasks => _taskBox.values.toList();

  List<String> get frequentTasks {
    final counts = Map<String, int>.from(_taskCountBox.toMap());
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(5).toList();
  }

  void addTask(Task task) {
    _taskBox.add(task);
    final current = _taskCountBox.get(task.name, defaultValue: 0)!;
    _taskCountBox.put(task.name, current + 1);
    notifyListeners();
  }

  void toggleTask(Task task, bool value) {
    task.completed = value;
    task.save();
    notifyListeners();
  }

  void removeTask(Task task) {
    task.delete();
    notifyListeners();
  }

  void updateAssignment(Task task, String? member) {
    task.assignedTo = member;
    task.save();
    notifyListeners();
  }

  /// Weekly → Bugün günlük listeye kopyala (assignedTo korunur)
  void syncTodayWeeklyTasks(WeeklyProvider weeklyProvider) {
    final today = DateFormat('EEEE').format(DateTime.now());
    final todayWeekly = weeklyProvider.tasksForDay(today);
    for (final wt in todayWeekly) {
      final exists = _taskBox.values.any(
        (t) => t.name == wt.task && t.assignedTo == wt.assignedTo,
      );
      if (!exists) {
        addTask(Task(wt.task, assignedTo: wt.assignedTo));
      }
    }
  }

  void clearCompleted({String? forMember}) {
    final toDelete = _taskBox.values.where((t) {
      final memberOk = forMember == null
          ? true
          : (t.assignedTo ?? '') == forMember;
      return memberOk && t.completed;
    }).toList();

    for (final t in toDelete) {
      t.delete();
    }
    notifyListeners();
  }
}
