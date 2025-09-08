import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FamilyProvider extends ChangeNotifier {
  final _familyBox = Hive.box<String>('familyBox');

  List<String> get familyMembers => _familyBox.values.toList();

  void addMember(String name) {
    _familyBox.add(name);
    notifyListeners();
  }

  void removeMember(int index) {
    _familyBox.deleteAt(index);
    notifyListeners();
  }

  void renameMember({required int index, required String newName}) {
    _familyBox.putAt(index, newName);
    notifyListeners();
  }
}
