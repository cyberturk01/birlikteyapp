import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/cloud_error_handler.dart';
import '../services/firestore_write_helpers.dart';
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
  final _uuid = const Uuid();
  bool _listening = false;
  bool get isListening => _listening;

  ExpenseCloudProvider(this._auth, this._db) {
    _bindAuth();
  }

  // ---- state ----
  String? _familyId;
  User? _currentUser;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _famSub;

  final Map<String, double> _monthlyBudgets = {};
  double? getMonthlyBudgetFor(String category) => _monthlyBudgets[category];

  List<ExpenseDoc> _expenses = [];
  List<ExpenseDoc> get expenses => _expenses;

  List<ExpenseDoc> get all {
    final list = _expenses.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  // ---- helpers ----
  CollectionReference<Map<String, dynamic>>? get _col {
    final fid = _familyId;
    if (fid == null || fid.isEmpty) return null;
    return _db.collection('families/$fid/expenses');
  }

  // ---- lifecycle ----
  Future<void> setFamilyId(String? fid) async {
    if (_familyId == fid) return;

    await _cancelExpenseStream();
    await _cancelFamilyStream();
    _expenses = [];
    _monthlyBudgets.clear();
    clearError();

    _familyId = fid;

    if (_currentUser == null || fid == null || fid.isEmpty) {
      notifyListeners();
      return;
    }

    // LAZY: yalnızca listening açıkken bağlan
    if (_listening) {
      _bindFamilySettings();
      _bindExpenses();
    } else {
      notifyListeners();
    }
  }

  void startListening() {
    if (_listening) return;
    _listening = true;

    // familyId + user uygunsa stream’leri bağla
    if (_currentUser != null && (_familyId?.isNotEmpty ?? false)) {
      _bindFamilySettings();
      _bindExpenses();
    }
  }

  void stopListening({bool clear = false}) {
    if (!_listening) return;
    _listening = false;

    _cancelExpenseStream();
    _cancelFamilyStream();

    if (clear) {
      _expenses = [];
      _monthlyBudgets.clear();
      notifyListeners();
    }
  }

  void _bindAuth() {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((u) async {
      _currentUser = u;
      await setFamilyId(_familyId); // mevcut aileyle yeniden bağlan/temizle
    });
  }

  void _bindExpenses() {
    final c = _col;
    if (!_listening || c == null) {
      // <<< guard
      _expenses = [];
      notifyListeners();
      return;
    }
    _expSub?.cancel();
    _expSub = c
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _expenses = snap.docs.map((d) {
              final data = d.data();
              // Fallback: date yoksa createdAt → DateTime
              final tsDate = data['date'] as Timestamp?;
              final tsCreated = data['createdAt'] as Timestamp?;
              final effectiveDate =
                  tsDate?.toDate() ?? tsCreated?.toDate() ?? DateTime.now();
              return ExpenseDoc(
                id: d.id,
                title: (data['title'] as String).trim(),
                amount: (data['amount'] as num).toDouble(),
                date: effectiveDate, // ✅ fallback uygulanmış
                assignedToUid: data['assignedToUid'] as String?,
                category: (data['category'] as String?)?.trim(),
              );
            }).toList();
            clearError();
            notifyListeners();
          },
          onError: (e, _) {
            debugPrint('[ExpenseCloud] expenses stream error: $e');
            setError(e);
            CloudErrorHandler.showFromException(e);
            notifyListeners();
          },
        );
  }

  void _bindFamilySettings() {
    _famSub?.cancel();
    final fid = _familyId;
    if (!_listening || fid == null || fid.isEmpty) {
      // <<< guard
      _monthlyBudgets.clear();
      notifyListeners();
      return;
    }
    final famDoc = _db.collection('families').doc(fid);
    _famSub = famDoc.snapshots().listen(
      (snap) {
        final data = snap.data();
        final budgets =
            (data?['settings']?['budgets'] as Map<String, dynamic>?) ?? {};
        _monthlyBudgets
          ..clear()
          ..addAll(budgets.map((k, v) => MapEntry(k, (v as num).toDouble())));
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ExpenseCloud] settings stream error: $e');
        setError(e);
        CloudErrorHandler.showFromException(e);
        notifyListeners();
      },
    );
  }

  Future<void> refreshNow() async {
    await _cancelExpenseStream();
    await _cancelFamilyStream();
    _expenses = [];
    _monthlyBudgets.clear();
    clearError();

    if (_currentUser != null &&
        (_familyId?.isNotEmpty ?? false) &&
        _listening) {
      // <<< guard
      _bindFamilySettings();
      _bindExpenses();
    } else {
      notifyListeners();
    }
  }

  Future<void> teardown() async {
    await _cancelExpenseStream();
    await _cancelFamilyStream();
    await _authSub?.cancel();
    _authSub = null;

    _expenses = [];
    _monthlyBudgets.clear();
    clearError();
    // _familyId'ı null yapmak istersen:
    // _familyId = null;

    notifyListeners();
  }

  Future<void> _cancelExpenseStream() async {
    await _expSub?.cancel();
    _expSub = null;
  }

  Future<void> _cancelFamilyStream() async {
    await _famSub?.cancel();
    _famSub = null;
  }

  @override
  void dispose() {
    teardown();
    super.dispose();
  }

  // ---- budgets ----
  Future<void> setMonthlyBudget(String category, double? amount) async {
    final fid = _familyId;
    if (fid == null || fid.isEmpty) {
      _monthlyBudgets.remove(category);
      notifyListeners();
      return;
    }

    final famDoc = _db.collection('families').doc(fid);

    if (amount == null) {
      final field = 'settings.budgets.$category';
      await updateDocWithRetryQueue(famDoc, {field: FieldValue.delete()});
      _monthlyBudgets.remove(category);
    } else {
      await setDocWithRetryQueue(famDoc, {
        'settings': {
          'budgets': {category: amount},
        },
      }, merge: true);
      _monthlyBudgets[category] = amount;
    }
    notifyListeners();
  }

  // ---- CRUD ----
  Future<void> add({
    required String title,
    required double amount,
    required DateTime date,
    String? assignedToUid,
    String? category,
  }) async {
    final c = _col;
    if (c == null) throw StateError('[ExpenseCloud] No active familyId set');

    final id = _uuid.v4();
    final ref = c.doc(id);

    if ((category ?? '').trim().isNotEmpty) {
      RecentExpenseCats.push(category!.trim());
    }

    final data = {
      'title': title.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'assignedToUid': assignedToUid,
      'category': (category?.trim().isEmpty ?? true) ? null : category!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await setDocWithRetryQueue(
      ref,
      data,
      merge: false,
      onQueued: () {
        final ctx = navigatorKey.currentContext;
        final tLoc = (ctx != null) ? AppLocalizations.of(ctx) : null;
        final msg =
            tLoc?.queuedExpenseAdd ??
            'Offline: Expense was queued. It will sync when online.';
        CloudErrorHandler.showFromString(msg);
      },
    );
  }

  Future<void> remove(String id) async {
    final c = _col;
    if (c == null) throw StateError('[ExpenseCloud] No active familyId set');
    await deleteDocWithRetryQueue(c.doc(id));
  }

  Future<void> updateCategory(String id, String? category) async {
    final c = _col;
    if (c == null) throw StateError('[ExpenseCloud] No active familyId set');
    await updateDocWithRetryQueue(c.doc(id), {
      'category': (category?.trim().isEmpty ?? true) ? null : category!.trim(),
    });
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
    if (assignedToUid != null) {
      data['assignedToUid'] = assignedToUid.trim().isEmpty
          ? null
          : assignedToUid.trim();
    }
    if (category != null) {
      data['category'] = category.trim().isEmpty ? null : category.trim();
      if (category.trim().isNotEmpty) {
        RecentExpenseCats.push(category.trim());
      }
    }
    if (data.isEmpty) return;

    await setDocWithRetryQueue(c.doc(id), data, merge: true);
  }

  // ---- queries / aggregates ----
  List<ExpenseDoc> forCategory({required String category, String? uid}) {
    final allList = expenses;
    return allList.where((e) {
      final catOk = (e.category ?? 'Other') == category;
      final uidOk = uid == null ? true : e.assignedToUid == uid;
      return catOk && uidOk;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

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
      if (!out.containsKey(key)) continue;
      final cat = (e.category ?? 'Other');
      out[key]![cat] = (out[key]![cat] ?? 0) + e.amount;
    }
    return out;
  }

  List<ExpenseDoc> forMemberFiltered(String? uid, ExpenseDateFilter filter) {
    List<ExpenseDoc> base;
    if (uid == null) {
      base = _expenses;
    } else if (uid.isEmpty) {
      base = _expenses.where((e) => e.assignedToUid == null).toList();
    } else {
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

  Map<String, double> totalsByCategory({
    required String? uid,
    required ExpenseDateFilter filter,
  }) {
    final list = forMemberFiltered(uid, filter);
    final map = <String, double>{};
    for (final e in list) {
      final key = (e.category?.trim().isEmpty ?? true)
          ? 'Uncategorized'
          : e.category!;
      map.update(key, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return map;
  }
}
