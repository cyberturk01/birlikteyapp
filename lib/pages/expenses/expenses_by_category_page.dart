import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/formatting.dart';
import '../../widgets/member_dropdown_uid.dart';

class ExpensesByCategoryPage extends StatefulWidget {
  final String? initialMember;
  const ExpensesByCategoryPage({super.key, this.initialMember});

  @override
  State<ExpensesByCategoryPage> createState() => _ExpensesByCategoryPageState();
}

class _ExpensesByCategoryPageState extends State<ExpensesByCategoryPage> {
  String? _member;
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth;
  static const _allKey = '__ALL__';

  @override
  void initState() {
    super.initState();
    _member = widget.initialMember;
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;
    final expProv = context.watch<ExpenseCloudProvider>();

    final memberForFilter = (_member == _allKey) ? null : _member;
    final map = expProv.totalsByCategory(uid: memberForFilter, filter: _filter);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // büyükten küçüğe

    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses — By Category')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: MemberDropdownUid(
                  value: _member,
                  onChanged: (v) => setState(() => _member = v),
                  label: 'Member',
                  nullLabel: 'All members',
                ),
              ),
              SegmentedButton<ExpenseDateFilter>(
                segments: const [
                  ButtonSegment(
                    value: ExpenseDateFilter.thisMonth,
                    label: Text('This month'),
                    icon: Icon(Icons.today),
                  ),
                  ButtonSegment(
                    value: ExpenseDateFilter.lastMonth,
                    label: Text('Last month'),
                    icon: Icon(Icons.calendar_today_outlined),
                  ),
                  ButtonSegment(
                    value: ExpenseDateFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No expenses for selected range.'),
              ),
            )
          else ...[
            // PIE
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: _buildPieSections(entries),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Legend + totals
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Totals by category'),
                    trailing: Text(
                      fmtMoney(context, total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...entries.map((e) {
                    final pct = total == 0 ? 0 : (e.value / total * 100);
                    return ListTile(
                      dense: true,
                      title: Text(e.key),
                      trailing: Text(
                        '${fmtMoney(context, e.value)}   •  ${pct.toStringAsFixed(1)}%',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> entries,
  ) {
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return List.generate(entries.length, (i) {
      final v = entries[i].value;
      final pct = total == 0 ? 0 : (v / total * 100);
      return PieChartSectionData(
        value: v,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 64,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
