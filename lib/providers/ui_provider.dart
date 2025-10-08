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

  String? _activeMember; // UID
  String? get activeMember => _activeMember;
  String? get activeMemberUid => _activeMember;

  Locale? _locale;
  Locale? get locale => _locale;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  BrandSeed _brand = BrandSeed.teal;
  BrandSeed get brand => _brand;

  TimeOfDay? _weeklyDefaultReminder; // null => UI tarafında 19:00 fallback
  TimeOfDay? get weeklyDefaultReminder => _weeklyDefaultReminder;

  // getters
  String? get filterMember => _filterMember;
  HomeSection get section => _section;
  TaskViewFilter get taskFilter => _taskFilter;
  ItemViewFilter get itemFilter => _itemFilter;

  /// Tek giriş noktası: tüm prefs burada okunur
  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();

    // ---- ThemeMode (tek anahtar, tip güvenli) ----
    final tm = sp.get('themeMode');
    if (tm is int) {
      if (tm >= 0 && tm < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[tm];
      }
    } else if (tm is String) {
      _themeMode = _parseThemeModeLegacy(tm); // "light" | "dark" | "system"
      // (opsiyonel): V2'ye migrate et
      await sp.setInt('themeMode', _themeMode.index);
    }

    // ---- BrandSeed (benzer mantık; eskide string tutulmuş olabilir) ----
    final bs = sp.get('brandSeed');
    if (bs is int) {
      if (bs >= 0 && bs < BrandSeed.values.length) {
        _brand = BrandSeed.values[bs];
      }
    } else if (bs is String) {
      final asInt = int.tryParse(bs);
      if (asInt != null && asInt >= 0 && asInt < BrandSeed.values.length) {
        _brand = BrandSeed.values[asInt];
        await sp.setInt('brandSeed', asInt); // migrate
      }
    }

    // ---- Locale ----
    final lc = sp.get('ui_locale_code');
    if (lc is String && lc.isNotEmpty) {
      _locale = Locale(lc);
    }

    // ---- Active member (UID) ----
    final am = sp.get('activeMemberUid') ?? sp.get('activeMember');
    if (am is String && am.trim().isNotEmpty) {
      _activeMember = am.trim();
    }

    // ---- Weekly reminder ----
    final h = sp.getInt('weeklyReminderHour');
    final m = sp.getInt('weeklyReminderMinute');
    if (h != null && m != null) {
      _weeklyDefaultReminder = TimeOfDay(hour: h, minute: m);
    }

    notifyListeners();
  }

  Future<void> setBrand(BrandSeed b) async {
    _brand = b;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('brandSeed', b.index);
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('ui_locale_code', loc.languageCode);
  }

  Future<void> setWeeklyDefaultReminder(TimeOfDay time) async {
    _weeklyDefaultReminder = time;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('weeklyReminderHour', time.hour);
    await sp.setInt('weeklyReminderMinute', time.minute);
  }

  Future<void> setActiveMemberUid(String? uid) async {
    _activeMember = (uid != null && uid.trim().isEmpty) ? null : uid?.trim();
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    if (_activeMember == null) {
      await sp.remove('activeMemberUid');
      // geri uyumluluk anahtarını da temizle
      await sp.remove('activeMember');
    } else {
      await sp.setString('activeMemberUid', _activeMember!);
      // (opsiyonel) bir-iki sürüm sonra bunu yazmayı bırakabilirsin:
      await sp.setString('activeMember', _activeMember!);
    }
  }

  /// Yeni tercih edilen API: UID ver.
  void setFilterMemberUid(String? uid) {
    _filterMember = (uid != null && uid.trim().isEmpty) ? null : uid?.trim();
    notifyListeners();
  }

  String? resolveActiveUid(List<String> memberUids) {
    if (_activeMember != null && memberUids.contains(_activeMember)) {
      return _activeMember;
    }
    return memberUids.isNotEmpty ? memberUids.first : null;
  }

  String? resolveActive(List<String> family) => resolveActiveUid(family);

  TimeOfDay get weeklyReminderOrDefault =>
      _weeklyDefaultReminder ?? const TimeOfDay(hour: 19, minute: 0);

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

  /// Sadece eski string değerleri parse eder (geriye dönük).
  ThemeMode _parseThemeModeLegacy(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Yalnızca tema + weekly reminder sıfırlar
  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _weeklyDefaultReminder = null;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('weeklyReminderHour');
    await sp.remove('weeklyReminderMinute');
    await sp.setInt('themeMode', ThemeMode.system.index); // tek tip: int
  }

  Future<void> resetUi() async {
    _themeMode = ThemeMode.system;
    _brand = BrandSeed.teal;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('themeMode');
    await sp.remove('brandSeed');
  }
}
