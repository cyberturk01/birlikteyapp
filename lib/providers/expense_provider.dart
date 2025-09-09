import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/expense.dart';

enum ExpenseDateFilter { thisMonth, lastMonth, all }

class ExpenseProvider extends ChangeNotifier {
  final _box = Hive.box<Expense>('expenseBox');

  List<Expense> get all {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  List<Expense> forMember(String? member) {
    final list = (member == null)
        ? _box.values.toList()
        : _box.values.where((e) => e.assignedTo == member).toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  // ---- Yeni: tarih filtresi ile
  List<Expense> forMemberFiltered(String? member, ExpenseDateFilter filter) {
    final base = forMember(member); // already sorted desc
    if (filter == ExpenseDateFilter.all) return base;

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);

    bool inThisMonth(DateTime d) =>
        !d.isBefore(firstDayThisMonth) && d.isBefore(firstDayNextMonth);

    bool inLastMonth(DateTime d) =>
        !d.isBefore(firstDayLastMonth) && d.isBefore(firstDayThisMonth);

    switch (filter) {
      case ExpenseDateFilter.thisMonth:
        return base.where((e) => inThisMonth(e.date)).toList();
      case ExpenseDateFilter.lastMonth:
        return base.where((e) => inLastMonth(e.date)).toList();
      case ExpenseDateFilter.all:
        return base;
    }
  }

  // year için 12 aylık toplam (member filtreli)
  List<double> monthlyTotals({required int year, String? member}) {
    final list = forMember(member);
    final buckets = List<double>.filled(12, 0.0);
    for (final e in list) {
      if (e.date.year == year) {
        final m = e.date.month; // 1..12
        buckets[m - 1] += e.amount;
      }
    }
    return buckets;
  }

  double totalForMember(
    String? member, {
    ExpenseDateFilter filter = ExpenseDateFilter.all,
  }) {
    final list = forMemberFiltered(member, filter);
    return list.fold(0.0, (sum, e) => sum + e.amount);
  }

  void add(Expense e) {
    _box.add(e);
    notifyListeners();
  }

  void remove(Expense e) {
    e.delete();
    notifyListeners();
  }

  void removeMany(Iterable<Expense> exps) {
    for (final e in exps) {
      e.delete();
    }
    notifyListeners();
  }
}
