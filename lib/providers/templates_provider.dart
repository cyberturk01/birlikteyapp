import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/user_template.dart';

class TemplatesProvider extends ChangeNotifier {
  final Box<UserTemplate> _box = Hive.box<UserTemplate>('userTemplates');

  List<UserTemplate> get all => _box.values.toList();

  Future<void> add(UserTemplate t) async {
    await _box.add(t);
    notifyListeners();
  }

  Future<void> updateTemplate(
    UserTemplate t, {
    String? name,
    String? description,
    List<String>? tasks,
    List<String>? items,
    List<WeeklyEntry>? weekly,
  }) async {
    if (name != null) t.name = name;
    if (description != null) t.description = description;
    if (tasks != null) t.tasks = tasks;
    if (items != null) t.items = items;
    if (weekly != null) t.weekly = weekly;
    await t.save();
    notifyListeners();
  }

  Future<void> remove(UserTemplate t) async {
    await t.delete();
    notifyListeners();
  }
}
