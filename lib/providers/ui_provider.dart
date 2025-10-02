import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/view_section.dart';
import '../theme/brand_seed.dart';

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
  Locale? _locale;
  Locale? get locale => _locale;

  // ====== tema modu ======
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  BrandSeed _brand = BrandSeed.teal;
  BrandSeed get brand => _brand;
  // getters
  String? get filterMember => _filterMember;
  HomeSection get section => _section;
  TaskViewFilter get taskFilter => _taskFilter;
  ItemViewFilter get itemFilter => _itemFilter;
  String? get activeMemberUid => _activeMember;

  TimeOfDay? _weeklyDefaultReminder; // null ise 19:00 fallback
  TimeOfDay? get weeklyDefaultReminder => _weeklyDefaultReminder;

  Future<void> setBrand(BrandSeed b) async {
    _brand = b;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('brandSeed', b.index);
  }

  Future<void> loadPrefs() async {
    final sp = await SharedPreferences.getInstance();

    // ThemeMode
    int? tm = sp.getInt('themeMode');
    if (tm == null) {
      final s = sp.getString('themeMode');
      if (s != null) tm = int.tryParse(s);
    }
    if (tm != null && tm >= 0 && tm < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[tm];
    }

    // BrandSeed
    int? bs = sp.getInt('brandSeed');
    if (bs == null) {
      final s = sp.getString('brandSeed');
      if (s != null) bs = int.tryParse(s);
    }
    if (bs != null && bs >= 0 && bs < BrandSeed.values.length) {
      _brand = BrandSeed.values[bs];
    }
    final code = sp.getString('ui_locale_code');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('ui_locale_code', loc.languageCode);
    notifyListeners();
  }

  Future<void> setWeeklyDefaultReminder(TimeOfDay time) async {
    _weeklyDefaultReminder = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyReminderHour', time.hour);
    await prefs.setInt('weeklyReminderMinute', time.minute);
  }

  // --- load() içinde küçük ekler ---
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('weeklyReminderHour');
    final m = prefs.getInt('weeklyReminderMinute');
    final saved = prefs.getString('themeMode');

    if (saved != null) {
      _themeMode = _parseThemeMode(saved);
    }

    // Önce yeni anahtar (UID), yoksa eskiyi oku
    _activeMember =
        prefs.getString('activeMemberUid') ?? prefs.getString('activeMember');

    if (h != null && m != null) {
      _weeklyDefaultReminder = TimeOfDay(hour: h, minute: m);
    }
    notifyListeners();
  }

  @deprecated
  Future<void> setActiveMember(String? nameOrUid) async {
    // Eski anahtarı da yazmaya devam edelim ki geriye dönük çalışsın.
    _activeMember = (nameOrUid != null && nameOrUid.trim().isEmpty)
        ? null
        : nameOrUid?.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_activeMember == null) {
      await prefs.remove('activeMember');
      await prefs.remove('activeMemberUid');
    } else {
      await prefs.setString('activeMember', _activeMember!);
      await prefs.setString('activeMemberUid', _activeMember!);
    }
  }

  /// Yeni tercih edilen API: UID ver.
  Future<void> setActiveMemberUid(String? uid) async {
    _activeMember = (uid != null && uid.trim().isEmpty) ? null : uid?.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_activeMember == null) {
      await prefs.remove('activeMemberUid');
      // Eski anahtarı da temizle (opsiyonel)
      await prefs.remove('activeMember');
    } else {
      await prefs.setString('activeMemberUid', _activeMember!);
      // Eski anahtarı da doldur (geri uyumluluk için)
      await prefs.setString('activeMember', _activeMember!);
    }
  }

  /// UID listesi üzerinden aktif olanı çöz.
  String? resolveActiveUid(List<String> memberUids) {
    if (_activeMember != null && memberUids.contains(_activeMember)) {
      return _activeMember;
    }
    return memberUids.isNotEmpty ? memberUids.first : null;
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

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('themeMode', m.index);
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

  /// 🔄 Sadece tema + weekly reminder saatini sıfırlar
  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _weeklyDefaultReminder = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weeklyReminderHour');
    await prefs.remove('weeklyReminderMinute');
    await prefs.setString('themeMode', ThemeMode.system.name); // isteğe bağlı
  }

  // istersen reset:
  Future<void> resetUi() async {
    _themeMode = ThemeMode.system;
    _brand = BrandSeed.teal;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('themeMode');
    await sp.remove('brandSeed');
  }
}
