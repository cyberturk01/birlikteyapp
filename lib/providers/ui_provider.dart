import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/view_section.dart';

enum TaskViewFilter { pending, completed }

enum ItemViewFilter { toBuy, bought }

class UiProvider extends ChangeNotifier {
  // ====== mevcut alanlar ======
  String? _filterMember;
  HomeSection _section = HomeSection.tasks;
  TaskViewFilter _taskFilter = TaskViewFilter.pending;
  ItemViewFilter _itemFilter = ItemViewFilter.toBuy;
  String? _activeMember;
  String? get activeMember => _activeMember;

  // ====== tema modu ======
  ThemeMode _themeMode = ThemeMode.system;

  // getters
  String? get filterMember => _filterMember;
  HomeSection get section => _section;
  TaskViewFilter get taskFilter => _taskFilter;
  ItemViewFilter get itemFilter => _itemFilter;
  ThemeMode get themeMode => _themeMode;

  // init (prefs yükle)
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode'); // 'system' | 'light' | 'dark'
    if (saved != null) {
      _themeMode = _parseThemeMode(saved);
    }
    _activeMember = prefs.getString('activeMember');
    notifyListeners();
  }

  Future<void> setActiveMember(String? name) async {
    _activeMember = (name != null && name.trim().isEmpty) ? null : name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_activeMember == null) {
      await prefs.remove('activeMember');
    } else {
      await prefs.setString('activeMember', _activeMember!);
    }
  }

  String? resolveActive(List<String> family) {
    if (_activeMember != null && family.contains(_activeMember)) {
      return _activeMember;
    }
    return family.isNotEmpty ? family.first : null;
  }

  // setters
  void setMember(String? member) {
    _filterMember = (member != null && member.trim().isEmpty) ? null : member;
    notifyListeners();
  }

  void setSection(HomeSection s) {
    _section = s;
    notifyListeners();
  }

  void setTaskFilter(TaskViewFilter f) {
    _taskFilter = f;
    notifyListeners();
  }

  void setItemFilter(ItemViewFilter f) {
    _itemFilter = f;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.name);
  }

  void resetFilters() {
    _filterMember = null;
    _section = HomeSection.tasks;
    _taskFilter = TaskViewFilter.pending;
    _itemFilter = ItemViewFilter.toBuy;
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
