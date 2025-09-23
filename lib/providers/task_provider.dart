// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
//
// import '../models/task.dart';
//
// class TaskProvider extends ChangeNotifier {
//   final _taskBox = Hive.box<Task>('taskBox');
//
//   List<Task> get tasks => _taskBox.values.toList();
//
//   /// Basit öneriler (istersen Hive ya da analytics’ten dinamikleştiririz)
//   List<String> get suggestedTasks => const [
//     'Take out trash',
//     'Vacuum living room',
//     'Laundry',
//     'Wash dishes',
//     'Cook dinner',
//   ];
//
//   void addTask(Task task) {
//     final exists = _taskBox.values.any(
//       (t) => t.name.toLowerCase() == task.name.toLowerCase(),
//     );
//     if (exists) {
//       return;
//     }
//     _taskBox.add(task);
//     notifyListeners();
//   }
//
//   void toggleTask(Task task, bool value) {
//     task.completed = value;
//     task.save();
//     notifyListeners();
//   }
//
//   void removeTask(Task task) {
//     task.delete();
//     notifyListeners();
//   }
//
//   void updateAssignment(Task task, String? member) {
//     task.assignedToUid = member;
//     task.save();
//     notifyListeners();
//   }
//
//   void clearCompleted({String? forMember}) {
//     final toDelete = _taskBox.values.where((t) {
//       final memberOk = forMember == null
//           ? true
//           : (t.assignedToUid ?? '') == forMember;
//       return memberOk && t.completed;
//     }).toList();
//
//     for (final t in toDelete) {
//       t.delete();
//     }
//     notifyListeners();
//   }
//
//   // İSİM DÜZENLE
//   void renameTask(Task task, String newName) {
//     if (newName.trim().isEmpty) return;
//     task.name = newName.trim();
//     task.save();
//     notifyListeners();
//   }
//
//   void updateAssignmentsOnRename(String oldName, String newName) {
//     for (final t in _taskBox.values) {
//       if ((t.assignedToUid ?? '').toLowerCase() == oldName.toLowerCase()) {
//         t.assignedToUid = newName;
//         t.save();
//       }
//     }
//     notifyListeners();
//   }
//
//   Future<List<Task>> addTasksBulk(
//     List<String> names, {
//     String? assignedToUid,
//     bool skipDuplicates = true,
//   }) async {
//     final created = <Task>[];
//     final existing = tasks.map((t) => t.name.toLowerCase()).toSet();
//
//     for (final n in names) {
//       final name = n.trim();
//       if (name.isEmpty) continue;
//       if (skipDuplicates && existing.contains(name.toLowerCase())) continue;
//
//       final t = Task(name, assignedToUid: assignedToUid);
//       await addTask(t);
//       created.add(t);
//     }
//     if (created.isNotEmpty) notifyListeners();
//     return created;
//   }
//
//   void removeManyTasks(Iterable<Task> list) {
//     for (final t in list) {
//       t.delete();
//     }
//     if (list.isNotEmpty) notifyListeners();
//   }
//
//   bool existsByNameAndAssignee(String name, String? assigned) {
//     final ln = name.toLowerCase();
//     final la = (assigned ?? '').toLowerCase();
//     return tasks.any(
//       (t) =>
//           t.name.toLowerCase() == ln &&
//           (t.assignedToUid ?? '').toLowerCase() == la,
//     );
//   }
// }
