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

  void updateAssignmentsOnRename(String oldName, String newName) {
    for (final i in _itemBox.values) {
      if ((i.assignedTo ?? '').toLowerCase() == oldName.toLowerCase()) {
        i.assignedTo = newName;
        i.save();
      }
    }
    notifyListeners();
  }

  List<Item> addItemsBulk(
    List<String> names, {
    String? assignedTo,
    bool skipDuplicates = true,
  }) {
    final created = <Item>[];
    final existing = items.map((i) => i.name.toLowerCase()).toSet();

    for (final n in names) {
      final name = n.trim();
      if (name.isEmpty) continue;
      if (skipDuplicates && existing.contains(name.toLowerCase())) continue;

      final it = Item(name, assignedTo: assignedTo);
      _itemBox.add(it);

      // (İsteğe bağlı) frekans sayacı artırmak istemezsen, burayı atla:
      final current = _itemCountBox.get(name, defaultValue: 0)!;
      _itemCountBox.put(name, current + 1);

      created.add(it);
    }
    if (created.isNotEmpty) notifyListeners();
    return created;
  }

  void removeManyItems(Iterable<Item> list) {
    for (final it in list) {
      it.delete();
    }
    if (list.isNotEmpty) notifyListeners();
  }
}
