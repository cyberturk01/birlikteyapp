import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_write_helpers.dart';

class TaskService {
  TaskService(this.familyId);
  final String familyId;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('families')
      .doc(familyId)
      .collection('tasks');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRaw() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }

  Future<String> add({
    required String id, // provider genelde uuid üretip verir
    required Map<String, dynamic> data,
  }) async {
    final ref = _col.doc(id);
    await setDocWithRetryQueue(ref, data, merge: false);
    return id;
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    await updateDocWithRetryQueue(_col.doc(id), patch);
  }

  Future<void> remove(String id) async {
    await deleteDocWithRetryQueue(_col.doc(id));
  }

  Future<void> clearCompleted({String? forMember}) async {
    Query<Map<String, dynamic>> q = _col.where('completed', isEqualTo: true);
    if (forMember != null) {
      q = q.where('assignedToUid', isEqualTo: forMember);
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      await deleteDocWithRetryQueue(d.reference);
    }
  }
}
