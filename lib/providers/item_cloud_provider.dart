import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/offline_queue.dart';
import '../services/retry.dart';
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

  // Aile id'si App boot’ta/FamilyProvider’dan gelir
  void setFamilyId(String? id) {
    if (_familyId == id) return;
    _familyId = id;
    _rebindItems();
  }

  // ==== Bindings ====
  void _bindAuth() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      _rebindItems();
    });
  }

  void _rebindAuth() {
    _authSub?.cancel();
    _authSub = null;
    _bindAuth();
  }

  void _rebindItems() {
    debugPrint('[ItemCloud] REBIND → user=${_currentUser?.uid} fam=$_familyId');

    _itemSub?.cancel();
    _itemSub = null;
    _items.clear();
    notifyListeners();

    if (_currentUser == null || _familyId == null || _familyId!.isEmpty) {
      _col = null;
      debugPrint('[ItemCloud] SKIP (user/family null)');
      return;
    }

    _col = FirebaseFirestore.instance
        .collection('families')
        .doc(_familyId!)
        .collection('items');

    debugPrint('[ItemCloud] PATH = ${_col!.path}');

    _itemSub = _col!
        //.orderBy(FieldPath.documentId, descending: true) // test için kapalı
        .snapshots()
        .listen(
          (qs) {
            clearError();
            debugPrint('[ItemCloud] SNAP size=${qs.size}');
            _items
              ..clear()
              ..addAll(
                qs.docs.map((d) {
                  final data = d.data();
                  debugPrint('[ItemCloud] doc ${d.id} => $data');
                  final it = Item(
                    (data['name'] as String?)?.trim() ?? '',
                    bought: (data['bought'] as bool?) ?? false,
                    assignedToUid:
                        ((data['assignedToUid'] ?? data['assignedTo'])
                                as String?)
                            ?.trim(),
                    category: (data['category'] as String?)?.trim(),
                    price: (data['price'] as num?)?.toDouble(),
                  );
                  it.remoteId = d.id;
                  return it;
                }),
              );
            clearError();
            notifyListeners();
          },
          onError: (e, st) {
            debugPrint('[ItemCloud] STREAM ERROR: $e');
            _items.clear();
            setError(e);
            notifyListeners();
          },
        );
  }

  // addItem çağrısında (eğer ileriye dönük set etmek istersen parametre ekleyebilirsin)
  Future<void> addItem(Item it) async {
    final col = _ensureCol();
    final id = it.remoteId ?? _uuid.v4();
    final path = '${col.path}/$id';
    debugPrint(
      '[ItemCloud] ADD name=${it.name} fam=$_familyId path=${col.path}',
    );
    final data = {
      'name': it.name,
      'bought': it.bought,
      if ((it.assignedToUid ?? '').trim().isEmpty)
        'assignedToUid': FieldValue.delete()
      else
        'assignedToUid': it.assignedToUid!.trim(),
      if ((it.category ?? '').trim().isNotEmpty)
        'category': it.category!.trim(),
      if (it.price != null) 'price': it.price,
      'createdAt': FieldValue.serverTimestamp(),
    };
    debugPrint('[ItemCloud] ADDED id=${id}');
    await _qSet(path: path, data: data, merge: false);
    it.remoteId = id;
  }

  Future<void> updateCategory(Item it, String? category) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        'category': (category?.trim().isEmpty ?? true)
            ? FieldValue.delete()
            : category!.trim(),
      },
    );
    it.category = (category?.trim().isEmpty ?? true) ? null : category!.trim();
    notifyListeners();
  }

  Future<void> updatePrice(Item it, double? price) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        if (price == null) 'price': FieldValue.delete() else 'price': price,
      },
    );
    it.price = price;
    notifyListeners();
  }

  // İsteğe bağlı: dışarıdan manuel tetiklemek için
  Future<void> refreshNow() async {
    _rebindItems();
  }

  // ==== Public API ====
  List<String> get frequentItems {
    final names = _items.map((e) => e.name).where((s) => s.isNotEmpty).toSet();
    return names.take(5).toList();
  }

  Future<void> toggleItem(Item it, bool bought) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await _qUpdate(path: '${col.path}/$id', data: {'bought': bought});
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
    await _qUpdate(path: '${col.path}/$id', data: data);
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
    await _qUpdate(
      path: '${col.path}/$id',
      data: {
        'assignedToUid': (memberUid == null || memberUid.trim().isEmpty)
            ? FieldValue.delete()
            : memberUid.trim(),
      },
    );
    it.assignedToUid = (memberUid?.trim().isEmpty ?? true)
        ? null
        : memberUid!.trim();
    notifyListeners();
  }

  Future<void> renameItem(Item it, String newName) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await _qUpdate(path: '${col.path}/$id', data: {'name': newName.trim()});
    it.name = newName.trim();
    notifyListeners();
  }

  Future<void> removeItem(Item it) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await _qDelete(path: '${col.path}/$id');
  }

  Future<void> clearBought({String? forMember}) async {
    final col = _ensureCol();
    Query<Map<String, dynamic>> q = col.where('bought', isEqualTo: true);
    if (forMember != null) q = q.where('assignedToUid', isEqualTo: forMember);
    final snap = await q.get();
    for (final d in snap.docs) {
      await _qDelete(path: d.reference.path);
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
    throw StateError('Cloud doc not found for item "${it.name}"');
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

  @override
  void dispose() {
    _authSub?.cancel();
    _itemSub?.cancel();
    super.dispose();
  }

  void teardown() => setFamilyId(null);

  Future<void> _qSet({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    Future<void> write() async => FirebaseFirestore.instance
        .doc(path)
        .set(data, SetOptions(merge: merge));
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(
          id: _uuid.v4(),
          path: path,
          type: OpType.set,
          data: data,
          merge: merge,
        ),
      );
    }
  }

  Future<void> _qUpdate({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    Future<void> write() async =>
        FirebaseFirestore.instance.doc(path).update(data);
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(id: _uuid.v4(), path: path, type: OpType.update, data: data),
      );
    }
  }

  Future<void> _qDelete({required String path}) async {
    Future<void> write() async => FirebaseFirestore.instance.doc(path).delete();
    try {
      await Retry.attempt(write, retryOn: isTransientFirestoreError);
    } catch (_) {
      await OfflineQueue.I.enqueue(
        OfflineOp(id: _uuid.v4(), path: path, type: OpType.delete),
      );
    }
  }
}
