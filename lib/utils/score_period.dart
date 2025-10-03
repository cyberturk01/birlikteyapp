// lib/utils/score_period.dart
enum ScorePeriod { day, week, month }

int _isoWeekNumber(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  final thursday = date.add(
    Duration(days: (4 - (date.weekday == 7 ? 0 : date.weekday))),
  );
  final firstJan = DateTime(thursday.year, 1, 1);
  final days = thursday.difference(firstJan).inDays;
  return 1 + (days / 7).floor();
}

String periodId(ScorePeriod p, DateTime now) {
  switch (p) {
    case ScorePeriod.day:
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      return '${now.year}-$m-$d';
    case ScorePeriod.week:
      final w = _isoWeekNumber(now).toString().padLeft(2, '0');
      return '${now.year}-W$w';
    case ScorePeriod.month:
      final m = now.month.toString().padLeft(2, '0');
      return '${now.year}-$m';
  }
}
