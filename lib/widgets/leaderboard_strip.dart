import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_provider.dart';

enum LBPeriod { day, week, month }

int _isoWeekNumber(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  // ISO: hafta Pazartesi başlar, haftanın Perşembe günü yılını belirler
  final thursday = date.add(
    Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)),
  );
  final firstJan = DateTime(thursday.year, 1, 1);
  final days = thursday.difference(firstJan).inDays;
  return 1 + (days / 7).floor();
}

class LeaderboardStrip extends StatefulWidget {
  const LeaderboardStrip({super.key});

  @override
  State<LeaderboardStrip> createState() => _LeaderboardStripState();
}

class _LeaderboardStripState extends State<LeaderboardStrip> {
  LBPeriod _p = LBPeriod.day;

  String _periodId(LBPeriod p, DateTime now) {
    switch (p) {
      case LBPeriod.day:
        final m = now.month.toString().padLeft(2, '0');
        final d = now.day.toString().padLeft(2, '0');
        return '${now.year}$m$d'; // 20250924
      case LBPeriod.week:
        final w = _isoWeekNumber(now).toString().padLeft(2, '0');
        return '${now.year}-$w'; // 2025-39  (DİKKAT: W harfi yok)
      case LBPeriod.month:
        final m = now.month.toString().padLeft(2, '0');
        return '${now.year}$m'; // 202509
    }
  }

  String _periodName(LBPeriod p) => p == LBPeriod.day
      ? 'day'
      : p == LBPeriod.week
      ? 'week'
      : 'month';

  @override
  Widget build(BuildContext context) {
    final famId = context.watch<FamilyProvider>().familyId;
    if (famId == null) return const SizedBox.shrink();

    final pid = _periodId(_p, DateTime.now());
    final scoresCol = FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .collection('scores')
        .doc(_periodName(_p))
        .collection(pid) // <-- pid artık ISO güvenli
        .orderBy('points', descending: true)
        .limit(3);

    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return Card(
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            SegmentedButton<LBPeriod>(
              segments: const [
                ButtonSegment(value: LBPeriod.day, label: Text('Today')),
                ButtonSegment(value: LBPeriod.week, label: Text('Week')),
                ButtonSegment(value: LBPeriod.month, label: Text('Month')),
              ],
              selected: {_p},
              onSelectionChanged: (s) => setState(() => _p = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: const VisualDensity(
                  horizontal: -3,
                  vertical: -3,
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder(
                stream: scoresCol.snapshots(),
                builder:
                    (
                      _,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
                    ) {
                      if (!snap.hasData) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No scores yet',
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }

                      return StreamBuilder<Map<String, String>>(
                        stream: dictStream,
                        builder: (_, dictSnap) {
                          final dict =
                              dictSnap.data ?? const <String, String>{};
                          final chips = docs.map((d) {
                            final uid = d.id;
                            final labelFull = dict[uid] ?? 'Member';
                            final points =
                                (d.data()['points'] as num?)?.toInt() ?? 0;
                            final labelShort = (labelFull.length <= 12)
                                ? labelFull
                                : '${labelFull.substring(0, 12)}…';
                            return _ChipAvatar(
                              label: labelShort,
                              fullLabel: labelFull,
                              points: points,
                            );
                          }).toList();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 4),
                                ...chips.map(
                                  (w) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: w,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipAvatar extends StatelessWidget {
  final String label; // kısaltılmış
  final String fullLabel; // tooltip için tam ad
  final int points;
  const _ChipAvatar({
    required this.label,
    required this.fullLabel,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullLabel.isNotEmpty ? fullLabel[0].toUpperCase() : '?';
    return Tooltip(
      message: '$fullLabel • $points',
      waitDuration: const Duration(milliseconds: 300),
      child: Chip(
        avatar: CircleAvatar(
          radius: 12,
          child: Text(initial, style: const TextStyle(fontSize: 12)),
        ),
        label: Text(
          '$label • $points',
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}
