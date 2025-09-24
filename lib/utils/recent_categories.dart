import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class RecentExpenseCats {
  static const _boxName = 'appBox';
  static const _key = 'recentExpenseCats';

  static List<String> get({int limit = 5}) {
    if (!Hive.isBoxOpen(_boxName)) return const <String>[];
    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_key, defaultValue: const <String>[]);
      final list = List<String>.from(raw ?? const <String>[]);
      return list.take(limit).toList();
    } catch (e, st) {
      debugPrint('[RecentExpenseCats] get error: $e');
      debugPrintStack(stackTrace: st);
      return const <String>[]; // hata olursa boş liste döner
    }
  }

  static void push(String category) {
    final cat = category.trim();
    if (cat.isEmpty) return;
    if (!Hive.isBoxOpen(_boxName)) return;

    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_key, defaultValue: const <String>[]);
      final list = List<String>.from(raw ?? const <String>[]);

      // aynı olanı sil, en başa ekle
      list.removeWhere((e) => e.toLowerCase() == cat.toLowerCase());
      list.insert(0, cat);

      // limit 10 tut
      while (list.length > 10) {
        list.removeLast();
      }

      box.put(_key, list);
    } catch (e, st) {
      debugPrint('[RecentExpenseCats] push error: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
