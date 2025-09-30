import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

enum OpType { set, update, delete }

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

class OfflineQueue {
  OfflineQueue._();
  static final OfflineQueue I = OfflineQueue._();
  late final Box _box;
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    // kutu zaten açıksa kullan, değilse aç
    if (!Hive.isBoxOpen('oplog')) {
      await Hive.openBox('oplog');
    }
    _box = Hive.box('oplog');

    _inited = true;
  }

  List<OfflineOp> _all() => _box.values
      .map((e) => OfflineOp.fromJson(Map<String, dynamic>.from(jsonDecode(e))))
      .toList()
      .cast<OfflineOp>();

  Future<void> enqueue(OfflineOp op) async =>
      _box.put(op.id, jsonEncode(op.toJson()));

  Future<void> _remove(String id) async => _box.delete(id);

  Future<void> flush() async {
    final ops = _all();
    for (final op in ops) {
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
      } catch (_) {
        // bağ yoksa/başarısızsa kuyrukta kalsın
      }
    }
  }
}

bool isTransientFirestoreError(Object e) {
  if (e is FirebaseException) {
    return e.code == 'unavailable' ||
        e.code == 'network-request-failed' ||
        e.code == 'deadline-exceeded';
  }
  return false;
}
