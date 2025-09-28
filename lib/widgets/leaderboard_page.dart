import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_provider.dart';

enum LBPeriod { day, week, month }

int _isoWeekNumber(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  final thursday = date.add(
    Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)),
  );
  final firstJan = DateTime(thursday.year, 1, 1);
  final days = thursday.difference(firstJan).inDays;
  return 1 + (days / 7).floor();
}

String _periodId(LBPeriod p, DateTime now) {
  switch (p) {
    case LBPeriod.day:
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      return '${now.year}$m$d'; // 20250924
    case LBPeriod.week:
      final w = _isoWeekNumber(now).toString().padLeft(2, '0');
      return '${now.year}-$w'; // 2025-39   (W yok → query ile uyumlu)
    case LBPeriod.month:
      final m2 = now.month.toString().padLeft(2, '0');
      return '${now.year}$m2'; // 202509
  }
}

String _periodName(LBPeriod p) => p == LBPeriod.day
    ? 'day'
    : p == LBPeriod.week
    ? 'week'
    : 'month';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  LBPeriod _p = LBPeriod.day;

  @override
  Widget build(BuildContext context) {
    final famId = context.watch<FamilyProvider>().familyId;
    if (famId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pid = _periodId(_p, DateTime.now());
    final query = FirebaseFirestore.instance
        .collection('families')
        .doc(famId)
        .collection('scores')
        .doc(_periodName(_p))
        .collection(pid)
        .orderBy('points', descending: true)
        .limit(50);

    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
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
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize:
                        Theme.of(context).textTheme.bodySmall?.fontSize ?? 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Liste
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No scores yet'));
              }

              return StreamBuilder<Map<String, String>>(
                stream: dictStream,
                builder: (_, dictSnap) {
                  final dict = dictSnap.data ?? const <String, String>{};
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    addSemanticIndexes: false,
                    cacheExtent: 800,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final uid = d.id;
                      final label = dict[uid] ?? 'Member';
                      final pts = (d.data()['points'] as num?)?.toInt() ?? 0;

                      return ListTile(
                        leading: _RankBadge(rank: i + 1),
                        title: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '+$pts',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});
  @override
  Widget build(BuildContext context) {
    final bg = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.grey
        : rank == 3
        ? Colors.brown
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return CircleAvatar(backgroundColor: bg, child: Text('$rank'));
  }
}
