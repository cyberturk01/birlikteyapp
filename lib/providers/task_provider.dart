import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final _taskBox = Hive.box<Task>('taskBox');

  List<Task> get tasks => _taskBox.values.toList();

  /// Basit öneriler (istersen Hive ya da analytics’ten dinamikleştiririz)
  List<String> get suggestedTasks => const [
    'Take out trash',
    'Vacuum living room',
    'Laundry',
    'Wash dishes',
    'Cook dinner',
  ];

  void addTask(Task task) {
    final exists = _taskBox.values.any(
      (t) => t.name.toLowerCase() == task.name.toLowerCase(),
    );
    if (exists) {
      return;
    }
    _taskBox.add(task);
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

  // İSİM DÜZENLE
  void renameTask(Task task, String newName) {
    if (newName.trim().isEmpty) return;
    task.name = newName.trim();
    task.save();
    notifyListeners();
  }
}
