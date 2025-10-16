import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

enum OpType { set, update, delete }

class OfflineQueue {
  OfflineQueue._();
  static final OfflineQueue I = OfflineQueue._();

  late final Box _box;
  bool _inited = false;

  // flush döngüsü ve reentrancy koruması
  Timer? _flushTimer;
  bool _isFlushing = false;

  // 🔴 YENİ: limit + owner
  int maxOps = 500;
  String? _ownerUid;

  Future<void> init() async {
    if (_inited) return;
    if (!Hive.isBoxOpen('oplog')) {
      await Hive.openBox('oplog');
    }
    _box = Hive.box('oplog');
    _inited = true;

    _flushTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => flush());

    Connectivity().onConnectivityChanged.listen((r) {
      if (r != ConnectivityResult.none) {
        flush();
      }
    });

    debugPrint('[OQ] init ok. existing: ${_box.length}');
  }

  // 🔴 YENİ: auth sahibi
  Future<void> setOwner(String? uid) async {
    if (!_inited) await init();
    if (_ownerUid == uid) return;
    _ownerUid = uid;
    if (_box.isNotEmpty) {
      debugPrint('[OQ] owner changed → clearing queue (${_box.length})');
      await _box.clear();
    }
  }

  List<_Stored> _allRaw() {
    // Hive insertion order’ında döner
    final list = <_Stored>[];
    for (var i = 0; i < _box.length; i++) {
      final key = _box.keyAt(i);
      final raw = _box.getAt(i);
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        list.add(_Stored(key, OfflineOp.fromJson(map)));
      } catch (_) {
        // bozuk kayıt varsa sil
        _box.delete(key);
      }
    }
    return list;
  }

  List<OfflineOp> _all() => _allRaw().map((e) => e.op).toList();

  Future<void> enqueue(OfflineOp op) async {
    await _box.put(op.id, jsonEncode(op.toJson()));
    _trimIfNeeded();
    debugPrint(
      '[OQ] enqueued ${op.type.name} ${op.path} (total: ${_box.length})',
    );
  }

  void _trimIfNeeded() {
    final over = _box.length - maxOps;
    if (over <= 0) return;
    // en eski 'over' kadar kaydı sil
    for (var i = 0; i < over; i++) {
      final key = _box.keyAt(0);
      _box.delete(key);
    }
    debugPrint('[OQ] trimmed to $maxOps');
  }

  Future<void> _remove(String id) async => _box.delete(id);

  Future<void> flush() async {
    if (!_inited) return;
    if (_isFlushing) return;

    final raw = _allRaw();
    if (raw.isEmpty) return;

    _isFlushing = true;
    debugPrint('[OQ] flush start, ${raw.length} ops');

    for (final rec in raw) {
      final op = rec.op;
      try {
        final ref = FirebaseFirestore.instance.doc(op.path);
        switch (op.type) {
          case OpType.set:
            await ref.set(op.data!, SetOptions(merge: op.merge ?? false));
            break;
          case OpType.update:
            await ref.update(op.data!);
            break;
          case OpType.delete:
            await ref.delete();
            break;
        }
        await _remove(op.id);
        debugPrint('[OQ] ✅ applied ${op.type.name} ${op.path}');
      } catch (e) {
        debugPrint('[OQ] ❌ failed ${op.type.name} ${op.path}: $e');
        // başarısız olanı bırak (bir sonraki flush’ta tekrar denenir)
      }
    }

    debugPrint('[OQ] flush done, remaining: ${_box.length}');
    _isFlushing = false;
  }

  // Debug yardımcıları
  int size() => _box.length;
  Future<void> clear() async {
    await _box.clear();
    debugPrint('[OQ] cleared');
  }
}

class _Stored {
  final dynamic key;
  final OfflineOp op;
  _Stored(this.key, this.op);
}

class OfflineOp {
  final String id; // queue id (uuid)
  final String path; // e.g. families/xxx/tasks/yyy
  final OpType type;
  final Map<String, dynamic>? data;
  final bool? merge;

  OfflineOp({
    required this.id,
    required this.path,
    required this.type,
    this.data,
    this.merge,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'type': type.name,
    'data': data,
    'merge': merge,
  };

  static OfflineOp fromJson(Map<String, dynamic> j) => OfflineOp(
    id: j['id'],
    path: j['path'],
    type: OpType.values.firstWhere((t) => t.name == j['type']),
    data: (j['data'] as Map?)?.cast<String, dynamic>(),
    merge: j['merge'] as bool?,
  );
}

bool isTransientFirestoreError(Object e) {
  if (e is FirebaseException) {
    return e.code == 'unavailable' ||
        e.code == 'network-request-failed' ||
        e.code == 'deadline-exceeded';
  }
  return false;
}
