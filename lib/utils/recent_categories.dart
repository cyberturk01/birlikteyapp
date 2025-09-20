// lib/utils/recent_categories.dart
import 'package:hive/hive.dart';

class RecentExpenseCats {
  static const _boxName = 'appBox';
  static const _key = 'recentExpenseCats';

  static List<String> get({int limit = 5}) {
    if (!Hive.isBoxOpen(_boxName)) return const <String>[];
    final box = Hive.box(_boxName);
    final raw = box.get(_key, defaultValue: const <String>[]);
    final list = List<String>.from(raw ?? const <String>[]);
    return list.take(limit).toList();
  }

  static void push(String category) {
    final cat = category.trim();
    if (cat.isEmpty) return;
    if (!Hive.isBoxOpen(_boxName)) return;

    final box = Hive.box(_boxName);
    final raw = box.get(_key, defaultValue: const <String>[]);
    final list = List<String>.from(raw ?? const <String>[]);

    // aynı olanı sil, en başa ekle
    list.removeWhere((e) => e.toLowerCase() == cat.toLowerCase());
    list.insert(0, cat);
    while (list.length > 10) list.removeLast();

    box.put(_key, list);
  }
}
