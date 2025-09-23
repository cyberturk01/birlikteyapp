import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart'; // Eğer gerekmiyorsa kaldırabilirsiniz

class ItemCloudProvider extends ChangeNotifier {
  AuthService _auth;
  TaskService _service; // opsiyonel; simetri için duruyor

  User? _currentUser;
  String? _familyId;
  CollectionReference<Map<String, dynamic>>? _col;
  String? _lastError;
  String? get lastError => _lastError;

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

  void _setError(String? msg) {
    _lastError = msg;
    notifyListeners();
  }

  void clearError() => _setError(null);

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
                            ?.trim(), // ← fallback
                  );
                  it.remoteId = d.id;
                  return it;
                }),
              );
            _setError(null);
            notifyListeners();
          },
          onError: (e, st) {
            debugPrint('[ItemCloud] STREAM ERROR: $e');
            _items.clear();
            _setError('ItemCloud: $e');
            notifyListeners();
          },
        );
  }

  Future<void> addItem(Item it) async {
    final col = _ensureCol();
    debugPrint(
      '[ItemCloud] ADD name=${it.name} fam=$_familyId path=${col.path}',
    );
    final doc = await col.add({
      'name': it.name,
      'bought': it.bought,
      'assignedToUid': it.assignedToUid ?? FieldValue.delete(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[ItemCloud] ADDED id=${doc.id}');
    it.remoteId = doc.id;
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
    await col.doc(id).update({'bought': bought});
  }

  Future<void> updateAssignment(Item it, String? memberUid) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await col.doc(id).update({
      'assignedToUid': (memberUid == null || memberUid.trim().isEmpty)
          ? FieldValue.delete()
          : memberUid.trim(),
    });
    it.assignedToUid = (memberUid?.trim().isEmpty ?? true)
        ? null
        : memberUid!.trim();
    notifyListeners();
  }

  Future<void> renameItem(Item it, String newName) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await col.doc(id).update({'name': newName.trim()});
    it.name = newName.trim();
    notifyListeners();
  }

  Future<void> removeItem(Item it) async {
    final col = _ensureCol();
    final id = await _ensureId(col, it);
    await col.doc(id).delete();
  }

  Future<void> clearBought({String? forMember}) async {
    final col = _ensureCol();
    Query<Map<String, dynamic>> q = col.where('bought', isEqualTo: true);
    if (forMember != null) q = q.where('assignedToUid', isEqualTo: forMember);
    final snap = await q.get();
    for (final d in snap.docs) {
      await d.reference.delete();
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

  List<Item> addItemsBulk(
    List<String> names, {
    String? assignedToUid,
    bool skipDuplicates = true,
  }) {
    final created = <Item>[];
    final existing = items.map((i) => i.name.toLowerCase()).toSet();

    for (final n in names) {
      final name = n.trim();
      if (name.isEmpty) continue;
      if (skipDuplicates && existing.contains(name.toLowerCase())) continue;

      final it = Item(name, assignedToUid: assignedToUid);
      _items.add(it);

      // (İsteğe bağlı) frekans sayacı artırmak istemezsen, burayı atla:
      // final current = _itemCountBox.get(name, defaultValue: 0)!;
      // _itemCountBox.put(name, current + 1);

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

  @override
  void dispose() {
    _authSub?.cancel();
    _itemSub?.cancel();
    super.dispose();
  }

  void teardown() => setFamilyId(null);
}
