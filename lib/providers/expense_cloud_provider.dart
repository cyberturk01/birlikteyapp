import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/recent_categories.dart';

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

class ExpenseCloudProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  ExpenseCloudProvider(this._auth, this._db);

  String? _familyId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<ExpenseDoc> _expenses = [];
  List<ExpenseDoc> get expenses => _expenses;

  void updateAuthAndDb(FirebaseAuth a, FirebaseFirestore d) {}

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
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[ExpenseCloud] STREAM ERROR: $e');
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required DateTime date,
    String? assignedTo, // eski isim
    String? category,
  }) {
    return add(
      title: title,
      amount: amount,
      date: date,
      assignedToUid: assignedTo,
      category: category,
    );
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
    final base = (uid == null)
        ? _expenses
        : _expenses.where((e) => e.assignedToUid == uid).toList();

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
