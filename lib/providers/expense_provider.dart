import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final _box = Hive.box<Expense>('expenseBox');

  List<Expense> get all => _box.values.toList();

  void addExpense(Expense e) {
    _box.add(e);
    notifyListeners();
  }

  void removeExpense(Expense e) {
    e.delete();
    notifyListeners();
  }

  double get total => all.fold(0, (sum, e) => sum + e.amount);
}
