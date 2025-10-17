import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/cloud_error_handler.dart';
import '../services/firestore_write_helpers.dart';
import '../services/task_service.dart';
import '_base_cloud.dart'; // Eğer gerekmiyorsa kaldırabilirsiniz

class ItemCloudProvider extends ChangeNotifier with CloudErrorMixin {
  AuthService _auth;
  TaskService _service; // opsiyonel; simetri için duruyor

  final _uuid = const Uuid();
  User? _currentUser;
  String? _familyId;
  CollectionReference<Map<String, dynamic>>? _col;

  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemSub;

  ItemCloudProvider(this._auth, this._service) {
    _bindAuth();
  }

  void update(AuthService newAuth, TaskService newService) {
    var changed = false;
    if (!identical(_auth, newAuth)) {
      _auth = newAuth;
      changed = true;
    }
    if (!identical(_service, newService)) {
      _service = newService;
      changed = true;
    }
    if (changed) _rebindAuth();
  }

  // ---- AİLE ID ----
  Future<void> setFamilyId(String? id) async {
    if (_familyId == id) return;
    _familyId = id;
    await _cancelItemStream(); // sadece item stream'i kapat
    _items.clear();
    clearError();

    if (_currentUser == null || id == null || id.isEmpty) {
      _col = null;
      notifyListeners();
      return;
    }
    _bindItems(); // yeni family için item stream
  }

  // ==== Bindings ====

  // ==== Auth binding (BAG'e EKLEME) ====
  void _bindAuth() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _currentUser = user;
      await setFamilyId(
        _familyId,
      ); // mevcut family ile item stream'i yeniden kur/temizle
    });
  }

  Future<void> _rebindAuth() async {
    await _authSub?.cancel();
    _bindAuth();
    await setFamilyId(_familyId);
  }

  // ==== Item stream ====
  void _bindItems() {
    final fid = _familyId;
    final uid = _currentUser?.uid;
    if (fid == null || fid.isEmpty || uid == null) {
      _col = null;
      return;
    }

    _col = FirebaseFirestore.instance
        .collection('families')
        .doc(fid)
        .collection('items');

    _itemSub?.cancel();
    _itemSub = _col!.snapshots().listen(
      (qs) {
        clearError();
        _items
          ..clear()
          ..addAll(
            qs.docs.map((d) {
              final m = d.data();
              final it = Item(
                (m['name'] as String?)?.trim() ?? '',
                bought: (m['bought'] as bool?) ?? false,
                assignedToUid:
                    ((m['assignedToUid'] ?? m['assignedTo']) as String?)
                        ?.trim(),
                category: (m['category'] as String?)?.trim(),
                price: (m['price'] as num?)?.toDouble(),
              )..remoteId = d.id;
              return it;
            }),
          );
        notifyListeners();
      },
      onError: (e, st) {
        _items.clear();
        setError(e);
        CloudErrorHandler.showFromException(e);
        notifyListeners();
      },
    );
  }

  Future<void> _cancelItemStream() async {
    await _itemSub?.cancel();
    _itemSub = null;
  }

  Future<void> addItem(Item it) async {
    final col = _ensureCol();
    final id = it.remoteId ?? _uuid.v4();
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    debugPrint(
      '[ItemCloud] ADD name=${it.name} fam=$_familyId path=${col.path}',
    );
    final data = {
      'name': it.name,
      'bought': it.bought,
      if ((it.assignedToUid ?? '').trim().isNotEmpty)
        'assignedToUid': it.assignedToUid!.trim(),
      if ((it.category ?? '').trim().isNotEmpty)
        'category': it.category!.trim(),
      if (it.price != null) 'price': it.price,
      'createdAt': FieldValue.serverTimestamp(),
    };
    debugPrint('[ItemCloud] ADDED id=$id');
    await setDocWithRetryQueue(
      ref,
      data,
      merge: false,
      onQueued: () {
        final ctx = navigatorKey.currentContext;
        final tLoc = (ctx != null) ? AppLocalizations.of(ctx) : null;
        final msg =
            tLoc?.queuedItemAdd ??
            'Offline: Item was queued. It will sync when online.';
        CloudErrorHandler.showFromString(msg);
      },
    );
    it.remoteId = id;
  }

  Future<void> updateCategory(Item it, String? category) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    final cat = (category?.trim().isEmpty ?? true)
        ? FieldValue.delete()
        : category!.trim();
    if (cat is FieldValue) {
      await safeFieldDeletesWithRetryQueue(ref, {'category': cat});
    } else {
      await updateDocWithRetryQueue(ref, {'category': cat});
    }
    it.category = (category?.trim().isEmpty ?? true) ? null : category!.trim();
    notifyListeners();
  }

  Future<void> updatePrice(Item it, double? price) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    if (price == null) {
      await safeFieldDeletesWithRetryQueue(ref, {'price': FieldValue.delete()});
    } else {
      await updateDocWithRetryQueue(ref, {'price': price});
    }
    it.price = price;
    notifyListeners();
  }

  Future<void> refreshNow() async {
    await _cancelItemStream(); // auth'e dokunma
    _items.clear();
    clearError();
    if (_currentUser != null && (_familyId?.isNotEmpty ?? false)) {
      _bindItems();
    } else {
      _col = null;
      notifyListeners();
    }
  }

  // ==== Public API ====
  List<String> get frequentItems {
    final names = _items.map((e) => e.name).where((s) => s.isNotEmpty).toSet();
    return names.take(5).toList();
  }

  Future<void> toggleItem(Item it, bool bought) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(ref, {'bought': bought});
  }

  Future<void> updateItemFields(
    Item it, {
    String? name,
    double? price,
    String? category,
  }) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (price != null) data['price'] = price;
    if (category != null) {
      data['category'] = category.trim().isEmpty
          ? FieldValue.delete()
          : category.trim();
    }
    if (data.isEmpty) return;
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(ref, data);
    if (name != null) it.name = name.trim();
    if (price != null) it.price = price;
    if (category != null) {
      it.category = category.trim().isEmpty ? null : category.trim();
    }
    notifyListeners();
  }

  Future<void> updateAssignment(Item it, String? memberUid) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);

    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    final v = (memberUid == null || memberUid.trim().isEmpty)
        ? FieldValue.delete()
        : memberUid.trim();
    if (v is FieldValue) {
      await safeFieldDeletesWithRetryQueue(ref, {'assignedToUid': v});
    } else {
      await updateDocWithRetryQueue(ref, {'assignedToUid': v});
    }

    final idx = _items.indexWhere((x) => x.remoteId == id);
    if (idx != -1) {
      _items[idx] = Item(
        it.name,
        bought: it.bought,
        assignedToUid: (memberUid?.trim().isEmpty ?? true)
            ? null
            : memberUid!.trim(),
      )..remoteId = id;

      notifyListeners();
    }
  }

  Future<void> renameItem(Item it, String newName) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await updateDocWithRetryQueue(ref, {'name': newName.trim()});
    it.name = newName.trim();
    notifyListeners();
  }

  Future<void> removeItem(Item it) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    final ref = FirebaseFirestore.instance.doc('${col.path}/$id');
    await deleteDocWithRetryQueue(ref);
  }

  Future<void> clearBought({String? forMember}) async {
    final col = _ensureCol();
    Query<Map<String, dynamic>> q = col.where('bought', isEqualTo: true);
    if (forMember != null) q = q.where('assignedToUid', isEqualTo: forMember);
    final snap = await q.get();
    for (final d in snap.docs) {
      await deleteDocWithRetryQueue(d.reference);
    }
  }

  // ==== Helpers ====
  CollectionReference<Map<String, dynamic>> _ensureCol() {
    final col = _col;
    if (col == null) {
      throw StateError('No authenticated user / items collection not bound.');
    }
    return col;
  }

  Future<String> _ensureId(
    CollectionReference<Map<String, dynamic>> col,
    Item it,
  ) async {
    if (it.remoteId != null) return it.remoteId!;

    Query<Map<String, dynamic>> q = col.where('name', isEqualTo: it.name);
    if ((it.assignedToUid ?? '').isEmpty) {
      q = q.where('assignedToUid', isNull: true);
    } else {
      q = q.where('assignedToUid', isEqualTo: it.assignedToUid);
    }

    final snap = await q.limit(1).get();
    if (snap.docs.isNotEmpty) {
      it.remoteId = snap.docs.first.id;
      return it.remoteId!;
    }

    // --- fallback: oluştur ---
    final genId = const Uuid().v4();
    final ref = FirebaseFirestore.instance.doc('${col.path}/$genId');
    await setDocWithRetryQueue(ref, {
      'name': it.name,
      'bought': it.bought,
      if ((it.assignedToUid ?? '').trim().isNotEmpty)
        'assignedToUid': it.assignedToUid!.trim(),
      if ((it.category ?? '').trim().isNotEmpty)
        'category': it.category!.trim(),
      if (it.price != null) 'price': it.price,
      'createdAt': FieldValue.serverTimestamp(),
    }, merge: false);
    it.remoteId = genId;
    return genId;
  }

  Future<List<Item>> addItemsBulkCloud(
    List<String> names, {
    String? assignedToUid,
  }) async {
    final created = <Item>[];
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final it = Item(name, assignedToUid: assignedToUid);
      await addItem(it);
      created.add(it);
    }
    return created;
  }

  void removeManyItems(Iterable<Item> list) {
    for (final it in list) {
      it.delete();
    }
    if (list.isNotEmpty) notifyListeners();
  }

  // ==== tam temizlik ====
  Future<void> teardown() async {
    await _cancelItemStream();
    await _authSub?.cancel(); // teardown’da auth’u da kapat
    _authSub = null;

    _items.clear();
    clearError();
    _col = null;

    notifyListeners();
  }

  @override
  void dispose() {
    teardown();
    super.dispose();
  }
}
