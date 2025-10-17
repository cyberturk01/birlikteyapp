import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import 'cloud_error_handler.dart';
import 'offline_queue.dart';
import 'retry.dart';

final _uuid = const Uuid();

/// Kullanıcıya kısa bilgi (isteğe bağlı).
void _notifyQueuedWrite() {
  final ctx = navigatorKey.currentContext;
  final t = (ctx != null) ? AppLocalizations.of(ctx) : null;
  final msg =
      t?.offlineQueued ??
      'Offline: Your action was queued and will sync when you are back online.';
  CloudErrorHandler.showFromString(msg);
}

bool isTransientFirestoreError(Object e) {
  if (e is FirebaseException) {
    return e.code == 'unavailable' ||
        e.code == 'network-request-failed' ||
        e.code == 'deadline-exceeded';
  }
  return false;
}

/// Kuyruğa konacak veriyi JSON-safe hale getir.
/// - serverTimestamp -> DateTime.now()
/// - FieldValue.delete() ve diğer FieldValue türleri -> **KALDIR** (queue’lamayız)
Map<String, dynamic> _jsonifyForQueue(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  input.forEach((k, v) {
    if (v is FieldValue) {
      final s = v.toString();
      if (s.contains('serverTimestamp')) {
        out[k] = DateTime.now();
      }
      // delete/diğer FieldValue türlerini kuyrukta TUTMAYIZ
      return;
    } else if (v is Map) {
      out[k] = _jsonifyForQueue(Map<String, dynamic>.from(v));
    } else if (v is List) {
      out[k] = v.map((e) {
        if (e is Map) return _jsonifyForQueue(Map<String, dynamic>.from(e));
        // FieldValue list elemanı ise düşür
        if (e is FieldValue) return null;
        return e;
      }).toList();
    } else {
      out[k] = v;
    }
  });
  return out;
}

OfflineOp _opSet(
  DocumentReference ref,
  Map<String, dynamic> data, {
  bool merge = false,
}) => OfflineOp(
  id: _uuid.v4(),
  path: ref.path,
  type: OpType.set,
  data: data,
  merge: merge,
);

OfflineOp _opUpdate(DocumentReference ref, Map<String, dynamic> data) =>
    OfflineOp(id: _uuid.v4(), path: ref.path, type: OpType.update, data: data);

OfflineOp _opDelete(DocumentReference ref) =>
    OfflineOp(id: _uuid.v4(), path: ref.path, type: OpType.delete);

/// GENEL YAZIM YARDIMCISI
Future<void> _writeWithRetryAndMaybeQueue({
  required Future<void> Function() action,
  required OfflineOp Function() buildOpForQueue,
  required bool allowQueue,
  bool notifyOnQueue = true,
  void Function()? onQueued,
}) async {
  try {
    await Retry.attempt(action, retryOn: isTransientFirestoreError);
  } catch (e) {
    final isTransient = isTransientFirestoreError(e);
    if (allowQueue && isTransient) {
      // Kuyruğa al ve BAŞARILI kabul et (hata fırlatma!)
      final op = buildOpForQueue();
      await OfflineQueue.I.enqueue(op);
      debugPrint('[WriteHelper] queued: ${op.type.name} ${op.path}');
      onQueued?.call();
      if (notifyOnQueue) _notifyQueuedWrite();
      return;
    }
    rethrow;
  }
}

/// SET
Future<void> setDocWithRetryQueue(
  DocumentReference ref,
  Map<String, dynamic> data, {
  bool merge = false,
  bool notifyOnQueue = true,
  void Function()? onQueued,
}) async {
  // Kuyruğa konacak veri JSON-safe olsun
  final safeForQueue = _jsonifyForQueue(data);
  await _writeWithRetryAndMaybeQueue(
    action: () => ref.set(data, SetOptions(merge: merge)),
    buildOpForQueue: () => _opSet(ref, safeForQueue, merge: merge),
    allowQueue: true,
    notifyOnQueue: notifyOnQueue,
    onQueued: onQueued,
  );
}

/// UPDATE
Future<void> updateDocWithRetryQueue(
  DocumentReference ref,
  Map<String, dynamic> data, {
  bool notifyOnQueue = true,
  void Function()? onQueued,
}) async {
  // delete içeren alanlar kuyrukta tutulamaz → sanitize et
  final safeForQueue = _jsonifyForQueue(data);
  final canQueue = safeForQueue.isNotEmpty; // delete-only patch ise queue yok

  await _writeWithRetryAndMaybeQueue(
    action: () => ref.update(data),
    buildOpForQueue: () => _opUpdate(ref, safeForQueue),
    allowQueue: canQueue,
    notifyOnQueue: notifyOnQueue,
    onQueued: onQueued,
  );
}

/// DELETE (doc)
Future<void> deleteDocWithRetryQueue(
  DocumentReference ref, {
  bool notifyOnQueue = true,
  void Function()? onQueued,
}) async {
  await _writeWithRetryAndMaybeQueue(
    action: () => ref.delete(),
    buildOpForQueue: () => _opDelete(ref),
    allowQueue: true,
    notifyOnQueue: notifyOnQueue,
    onQueued: onQueued,
  );
}

/// SADECE alan silmeleri (FieldValue.delete) için güvenli helper.
/// Transient hatada **queue yok** (delete semantiğini JSON’da koruyamayız).
Future<void> safeFieldDeletesWithRetryQueue(
  DocumentReference ref,
  Map<String, dynamic> fieldsToDelete, {
  bool notifyOnQueue = false, // queue yok; bildirim de gereksiz
  void Function()? onQueued, // kullanılmayacak
}) async {
  await _writeWithRetryAndMaybeQueue(
    action: () => ref.update(fieldsToDelete),
    buildOpForQueue: () => _opUpdate(ref, const {}), // kullanılmayacak
    allowQueue: false,
    notifyOnQueue: notifyOnQueue,
    onQueued: onQueued,
  );
}
