import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/recent_categories.dart';
import '_base_cloud.dart';

enum ExpenseDateFilter { thisMonth, lastMonth, all }

class ExpenseDoc {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String? assignedToUid;
  final String? category;

  ExpenseDoc({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.assignedToUid,
    this.category,
  });

  factory ExpenseDoc.fromSnap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ExpenseDoc(
      id: doc.id,
      title: (d['title'] as String).trim(),
      amount: (d['amount'] as num).toDouble(),
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedToUid: d['assignedToUid'] as String?,
      category: (d['category'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'assignedToUid': assignedToUid,
    'category': category,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class ExpenseCloudProvider extends ChangeNotifier with CloudErrorMixin {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final Map<String, double> _monthlyBudgets = {}; // kategori -> bütçe

  double? getMonthlyBudgetFor(String category) => _monthlyBudgets[category];
  ExpenseCloudProvider(this._auth, this._db);

  String? _familyId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<ExpenseDoc> _expenses = [];
  List<ExpenseDoc> get expenses => _expenses;

  List<ExpenseDoc> get all {
    final list = _expenses.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  void setFamilyId(String? fid) {
    if (_familyId == fid) return;
    _familyId = fid;
    _bind();
  }

  CollectionReference<Map<String, dynamic>>? get _col {
    final fid = _familyId;
    if (fid == null) return null;
    return _db.collection('families/$fid/expenses');
  }

  Future<void> setMonthlyBudget(String category, double? amount) async {
    if (amount == null) {
      _monthlyBudgets.remove(category);
    } else {
      _monthlyBudgets[category] = amount;
    }
    notifyListeners();
    // TODO: Firestore’a yaz
    // await db.collection('families').doc(familyId).set({
    //   'settings': {
    //     'budgets': _monthlyBudgets,
    //   }
    // }, SetOptions(merge: true));
  }

  /// Drill-down için basit filtre:
  List<ExpenseDoc> forCategory({required String category, String? uid}) {
    final all = expenses; // mevcut liste
    return all.where((e) {
      final catOk = (e.category ?? 'Other') == category;
      final uidOk = uid == null ? true : e.assignedToUid == uid;
      return catOk && uidOk;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Stacked bar için: son N ay kategorilere göre toplam
  /// return: { 'YYYY-MM': { 'Groceries': 120.0, 'Dining': 80.0, ... }, ... }
  Map<String, Map<String, double>> totalsByMonthAndCategory({
    String? uid,
    int lastMonths = 6,
  }) {
    final now = DateTime.now();
    final monthsKeys = List.generate(lastMonths, (i) {
      final d = DateTime(now.year, now.month - (lastMonths - 1 - i), 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    final out = {for (final k in monthsKeys) k: <String, double>{}};

    for (final e in expenses) {
      if (uid != null && e.assignedToUid != uid) continue;
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      if (!out.containsKey(key)) continue; // sadece son N ay
      final cat = (e.category ?? 'Other');
      out[key]![cat] = (out[key]![cat] ?? 0) + e.amount;
    }
    return out;
  }

  void _bind() {
    _sub?.cancel();
    final c = _col;
    if (c == null) {
      _expenses = [];
      notifyListeners();
      return;
    }
    _sub = c
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _expenses = snap.docs.map((d) => ExpenseDoc.fromSnap(d)).toList();
            clearError();
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[ExpenseCloud] STREAM ERROR: $e');
            setError(e);
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> add({
    required String title,
    required double amount,
    required DateTime date,
    String? assignedToUid,
    String? category,
  }) async {
    final c = _col;
    if (c == null) {
      throw StateError('[ExpenseCloud] No active familyId set');
    }
    if ((category ?? '').trim().isNotEmpty) {
      RecentExpenseCats.push(category!.trim());
    }
    await c.add({
      'title': title.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'assignedToUid': assignedToUid,
      'category': (category?.trim().isEmpty ?? true) ? null : category!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) async {
    final c = _col;
    if (c == null) throw StateError('[ExpenseCloud] No active familyId set');
    await c.doc(id).delete();
  }

  Future<void> updateCategory(String id, String? category) async {
    final c = _col;
    if (c == null) throw StateError('[ExpenseCloud] No active familyId set');
    await c.doc(id).update({
      'category': (category?.trim().isEmpty ?? true) ? null : category!.trim(),
    });
  }

  // yardımcılar (UI filtreleri)
  List<ExpenseDoc> forMemberFiltered(String? uid, ExpenseDateFilter filter) {
    List<ExpenseDoc> base;

    if (uid == null) {
      // All members
      base = _expenses;
    } else if (uid.isEmpty) {
      // Unassigned
      base = _expenses.where((e) => e.assignedToUid == null).toList();
    } else {
      // Belirli üye UID
      base = _expenses.where((e) => e.assignedToUid == uid).toList();
    }

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

  double totalForMember(
    String? uid, {
    ExpenseDateFilter filter = ExpenseDateFilter.all,
  }) {
    final list = forMemberFiltered(uid, filter);
    return list.fold(0.0, (sum, e) => sum + e.amount);
  }

  List<double> monthlyTotals({required int year, String? uid}) {
    final list = (uid == null)
        ? _expenses
        : _expenses.where((e) => e.assignedToUid == uid).toList();
    final buckets = List<double>.filled(12, 0.0);
    for (final e in list) {
      if (e.date.year == year) {
        buckets[e.date.month - 1] += e.amount;
      }
    }
    return buckets;
  }

  Future<void> updateExpense(
    String id, {
    String? title,
    double? amount,
    DateTime? date,
    String? assignedToUid,
    String? category,
  }) async {
    final c = _col;
    if (c == null) throw StateError('No active family/collection');

    final data = <String, dynamic>{};
    if (title != null) data['title'] = title.trim();
    if (amount != null) data['amount'] = amount;
    if (date != null) data['date'] = Timestamp.fromDate(date);
    // assignedToUid null gelirse kategorik olarak temizlemek isteyebiliriz:
    if (assignedToUid != null) {
      data['assignedToUid'] = assignedToUid.trim().isEmpty
          ? null
          : assignedToUid.trim();
    }
    if (category != null) {
      data['category'] = category.trim().isEmpty ? null : category.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      RecentExpenseCats.push(category.trim());
    }
    if (data.isEmpty) return;

    await c.doc(id).set(data, SetOptions(merge: true));
  }

  Map<String, double> totalsByCategory({
    required String? uid,
    required ExpenseDateFilter filter,
  }) {
    final list = forMemberFiltered(uid, filter);
    final map = <String, double>{};
    for (final e in list) {
      final key = (e.category?.trim().isEmpty ?? true)
          ? 'Uncategorized'
          : e.category!.trim();
      map.update(key, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return map;
  }

  void teardown() => setFamilyId(null);
}
