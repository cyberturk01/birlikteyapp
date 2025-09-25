// lib/repositories/scores_repo.dart (ör.)
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/score_period.dart'; // <- Buradan geliyor

class ScoresRepo {
  final FirebaseFirestore _db;
  ScoresRepo(this._db);

  int _isoWeekNumber(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    final thursday = date.add(
      Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)),
    );
    final firstJan = DateTime(thursday.year, 1, 1);
    final days = thursday.difference(firstJan).inDays;
    return 1 + (days / 7).floor();
  }

  String _periodId(ScorePeriod p, DateTime now) {
    switch (p) {
      case ScorePeriod.day:
        final m = now.month.toString().padLeft(2, '0');
        final d = now.day.toString().padLeft(2, '0');
        return '${now.year}$m$d'; // 20250924
      case ScorePeriod.week:
        final w = _isoWeekNumber(now).toString().padLeft(2, '0');
        return '${now.year}-$w'; // 2025-39
      case ScorePeriod.month:
        final m = now.month.toString().padLeft(2, '0');
        return '${now.year}$m'; // 202509
    }
  }

  Future<void> addPoints({
    required String familyId,
    required String uid,
    required int delta,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final batch = _db.batch();

    for (final period in ScorePeriod.values) {
      final pid = _periodId(period, ts);
      final ref = _db
          .collection('families')
          .doc(familyId)
          .collection('scores')
          .doc(_periodName(period)) // day/week/month
          .collection(pid) // 20250924 / 2025-39 / 202509
          .doc(uid);

      batch.set(ref, {
        'points': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  String _periodName(ScorePeriod p) => p.name;
}
