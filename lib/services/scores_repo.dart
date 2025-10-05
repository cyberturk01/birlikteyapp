// lib/services/scores_repo.dart

abstract class ScoresRepo {
  Future<void> addPoints({
    required String familyId,
    required String uid,
    required int delta, // -20..+20
  });
}
