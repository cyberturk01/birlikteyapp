// lib/repositories/firestore_scores_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/scores_repo.dart';

class FirestoreScoresRepo implements ScoresRepo {
  final FirebaseFirestore _db;
  FirestoreScoresRepo(this._db);

  @override
  Future<void> addPoints({
    required String familyId,
    required String uid,
    required int delta,
  }) async {
    final now = DateTime.now();

    final ts = now ?? DateTime.now();

    // path helper’ları
    String dayId =
        '${ts.year.toString().padLeft(4, '0')}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}';
    int isoWeek(DateTime date) {
      final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
      final firstThursday = DateTime(thursday.year, 1, 4);
      return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
    }

    final weekId = '${ts.year}-${isoWeek(ts).toString().padLeft(2, '0')}';
    final monthId = '${ts.year}-${ts.month.toString().padLeft(2, '0')}';

    final dayRef = _db
        .collection('families')
        .doc(familyId)
        .collection('scores')
        .doc('day')
        .collection(dayId)
        .doc(uid);
    final weekRef = _db
        .collection('families')
        .doc(familyId)
        .collection('scores')
        .doc('week')
        .collection(weekId)
        .doc(uid);
    final monthRef = _db
        .collection('families')
        .doc(familyId)
        .collection('scores')
        .doc('month')
        .collection(monthId)
        .doc(uid);

    await _db.runTransaction((trx) async {
      // --- TÜM OKUMALAR ÖNCE ---
      final daySnap = await trx.get(dayRef);
      final weekSnap = await trx.get(weekRef);
      final monthSnap = await trx.get(monthRef);

      int _oldPoints(DocumentSnapshot snap) {
        final data = snap.data() as Map<String, dynamic>?; // null olabilir
        final num? p = data?['points'] as num?;
        return p?.toInt() ?? 0;
      }

      final nextDay = _oldPoints(daySnap) + delta;
      final nextWeek = _oldPoints(weekSnap) + delta;
      final nextMonth = _oldPoints(monthSnap) + delta;

      // --- SONRA YAZMALAR ---
      final payload = {
        'points':
            null, // placeholder; her set’te farklı değer verileceği için değişecek
        'updatedAt': FieldValue.serverTimestamp(),
      };

      trx.set(dayRef, {...payload, 'points': nextDay}, SetOptions(merge: true));
      trx.set(weekRef, {
        ...payload,
        'points': nextWeek,
      }, SetOptions(merge: true));
      trx.set(monthRef, {
        ...payload,
        'points': nextMonth,
      }, SetOptions(merge: true));
    });
  }

  String _dayId(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _monthId(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
  }

  String _weekId(DateTime dt) =>
      '${dt.year}-${_isoWeek(dt).toString().padLeft(2, '0')}';
}
