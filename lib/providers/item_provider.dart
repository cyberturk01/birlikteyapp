import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/item.dart';

class ItemProvider extends ChangeNotifier {
  final _itemBox = Hive.box<Item>('itemBox');
  final _itemCountBox = Hive.box<int>('itemCountBox'); // new

  List<Item> get items => _itemBox.values.toList();

  List<String> get frequentItems {
    final counts = Map<String, int>.from(_itemCountBox.toMap());
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(5).toList();
  }

  void addItem(Item item) {
    final exists = _itemBox.values.any(
      (i) => i.name.toLowerCase() == item.name.toLowerCase(),
    );
    if (exists) {
      return;
    }
    _itemBox.add(item);
    final current = _itemCountBox.get(item.name, defaultValue: 0)!;
    _itemCountBox.put(item.name, current + 1);
    notifyListeners();
  }

  void toggleItem(Item item, bool value) {
    item.bought = value;
    item.save();
    notifyListeners();
  }

  void removeItem(Item item) {
    item.delete();
    notifyListeners();
  }

  void updateAssignment(Item item, String? member) {
    item.assignedTo = member;
    item.save();
    notifyListeners();
  }

  void clearBought({String? forMember}) {
    final toDelete = _itemBox.values.where((i) {
      final memberOk = forMember == null
          ? true
          : (i.assignedTo ?? '') == forMember;
      return memberOk && i.bought;
    }).toList();

    for (final i in toDelete) {
      i.delete();
    }
    notifyListeners();
  }

  // İSİM DÜZENLE
  void renameItem(Item item, String newName) {
    if (newName.trim().isEmpty) return;
    item.name = newName.trim();
    item.save();
    notifyListeners();
  }
}
