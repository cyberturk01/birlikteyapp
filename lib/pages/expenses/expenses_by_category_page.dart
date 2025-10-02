import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../utils/formatting.dart';
import '../../widgets/budget_badges.dart';
import '../../widgets/budgets_manager_sheet.dart';
import '../../widgets/expense_edit_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _member = widget.initialMember;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final expProv = context.watch<ExpenseCloudProvider>();
    final map = expProv.totalsByCategory(uid: _member, filter: _filter);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.expensesByCategoryTitle),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.pie_chart), text: t.breakdown),
              Tab(icon: const Icon(Icons.stacked_bar_chart), text: t.trend),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // === TAB 1: Breakdown ===
            ListView(
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
                        label: t.memberFallback,
                        nullLabel: t.allMembers,
                      ),
                    ),
                    SegmentedButton<ExpenseDateFilter>(
                      segments: [
                        ButtonSegment(
                          value: ExpenseDateFilter.thisMonth,
                          label: Text(t.thisMonth),
                          icon: const Icon(Icons.today),
                        ),
                        ButtonSegment(
                          value: ExpenseDateFilter.lastMonth,
                          label: Text(t.lastMonth),
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                        ButtonSegment(
                          value: ExpenseDateFilter.all,
                          label: Text(t.allLabel),
                          icon: const Icon(Icons.all_inclusive),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) =>
                          setState(() => _filter = s.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t.noExpensesForRange),
                    ),
                  )
                else ...[
                  // PIE (drill-down dokunuşu aşağıda)
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
                            pieTouchData: PieTouchData(
                              touchCallback: (event, resp) {
                                if (resp?.touchedSection == null) return;
                                final i =
                                    resp!.touchedSection!.touchedSectionIndex;
                                final cat = entries[i].key;
                                _openDrillDown(
                                  context,
                                  category: cat,
                                  member: _member,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(t.totalsByCategory),
                          trailing: Text(
                            fmtMoney(context, total),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        ...entries.map((e) {
                          final budget = context
                              .read<ExpenseCloudProvider>()
                              .getMonthlyBudgetFor(e.key); // null olabilir
                          final pct = total == 0 ? 0 : (e.value / total * 100);
                          final over = (budget != null) && (e.value > budget);
                          final badge = buildBudgetBadge(
                            context: context,
                            spent: e.value,
                            budget: budget,
                          );
                          return InkWell(
                            onTap: () => _openDrillDown(
                              context,
                              category: e.key,
                              member: _member,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (badge.overChip != null) ...[
                                        const SizedBox(width: 8),
                                        badge.overChip!,
                                      ],
                                      IconButton(
                                        tooltip: t.editBudgetTooltip,
                                        icon: const Icon(
                                          Icons.edit_calendar,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _editBudget(context, e.key),
                                      ),
                                      Text(
                                        '${fmtMoney(context, e.value)}   •  ${pct.toStringAsFixed(1)}%',
                                      ),
                                    ],
                                  ),
                                  if (budget != null) ...[
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: (e.value / budget).clamp(0, 1),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      color: over
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${fmtMoney(context, e.value)} / ${fmtMoney(context, budget)}'
                                        '${badge.overChip != null ? '' : '   •   ${badge.remainingText}'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: over
                                              ? Colors.red
                                              : Colors.grey[700],
                                          fontWeight: over
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // === TAB 2: Trend (son 6 ay stacked) ===
            _MonthlyStackedTrend(memberUid: _member),
          ],
        ),
      ),
    );
  }

  // aynı file’da yardımcı dialog:
  void _editBudget(BuildContext context, String category) async {
    final prov = context.read<ExpenseCloudProvider>();
    final current = prov.getMonthlyBudgetFor(category);
    final c = TextEditingController(
      text: current == null
          ? ''
          : current.toStringAsFixed(current % 1 == 0 ? 0 : 2),
    );
    final t = AppLocalizations.of(context)!;
    final res = await showDialog<double?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.budgetDialogTitle(category)),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: t.monthlyBudgetLabel,
            hintText: t.monthlyBudgetHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: Text(t.remove),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              final raw = c.text.trim();
              if (raw.isEmpty) {
                Navigator.pop(context, 0.0);
                return;
              }
              final v = double.tryParse(raw.replaceAll(',', '.'));
              Navigator.pop(context, v);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (res == null) return; // Cancel
    if (res == 0) {
      await prov.setMonthlyBudget(category, null); // Remove
    } else {
      await prov.setMonthlyBudget(category, res);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.budgetUpdatedFor(category))));
    }
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> entries,
  ) {
    Color colorForCategory(String cat) {
      final hash = cat.hashCode;
      final r = 100 + (hash & 0x7F);
      final g = 100 + ((hash >> 7) & 0x7F);
      final b = 100 + ((hash >> 14) & 0x7F);
      return Color.fromARGB(255, r, g, b);
    }

    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return List.generate(entries.length, (i) {
      final v = entries[i].value;
      final pct = total == 0 ? 0 : (v / total * 100);
      final color = colorForCategory(entries[i].key);
      return PieChartSectionData(
        value: v,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 64,
        color: color,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  void _openDrillDown(
    BuildContext context, {
    required String category,
    String? member,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExpensesFilteredListPage(category: category, memberUid: member),
      ),
    );
  }
}

class _MonthlyStackedTrend extends StatelessWidget {
  final String? memberUid;
  const _MonthlyStackedTrend({required this.memberUid});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final expProv = context.watch<ExpenseCloudProvider>();
    final data = expProv.totalsByMonthAndCategory(
      uid: memberUid,
      lastMonths: 6,
    );

    if (data.isEmpty) {
      return Center(child: Text(t.noDataLastMonths));
    }

    // eksenler ve seriler
    final months = data.keys.toList()..sort(); // 'YYYY-MM'
    final cats = <String>{for (final m in months) ...data[m]!.keys}.toList()
      ..sort();

    // renk paleti (kategoriye deterministik renk)
    final catColors = <String, Color>{
      for (final c in cats) c: _colorForCategory(c),
    };

    // yığın barlar
    final groups = <BarChartGroupData>[];
    final monthTotals = <int, double>{}; // tooltip için
    for (int i = 0; i < months.length; i++) {
      final mMap = data[months[i]]!;
      double acc = 0;
      final stacks = <BarChartRodStackItem>[];
      for (final c in cats) {
        final v = (mMap[c] ?? 0).toDouble();
        stacks.add(BarChartRodStackItem(acc, acc + v, catColors[c]!));
        acc += v;
      }
      monthTotals[i] = acc;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: acc,
              width: 18,
              rodStackItems: stacks,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  t.last6MonthsByCategory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              // Grafik
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    barGroups: groups,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = _mmYY(months[group.x.toInt()]);
                          final total = monthTotals[group.x.toInt()] ?? 0;
                          return BarTooltipItem(
                            '$label\n${_fmtShortMoney(total)}',
                            const TextStyle(fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= months.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _mmYY(months[idx]),
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (val, meta) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _fmtShortMoney(val.toDouble()),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: cats.map((c) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: catColors[c],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(c, style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 'YYYY-MM' -> 'MM/YY'
  String _mmYY(String ym) {
    final p = ym.split('-');
    return '${p[1]}/${p[0].substring(2)}';
    // ör: '2025-09' -> '09/25'
  }

  String _fmtShortMoney(double v) {
    // Basit kısa para biçimi (k, M)
    final abs = v.abs();
    if (abs >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  Color _colorForCategory(String cat) {
    final hash = cat.hashCode;
    final r = 100 + (hash & 0x7F);
    final g = 100 + ((hash >> 7) & 0x7F);
    final b = 100 + ((hash >> 14) & 0x7F);
    return Color.fromARGB(255, r, g, b);
  }
}

class ExpensesFilteredListPage extends StatelessWidget {
  final String category;
  final String? memberUid;
  const ExpensesFilteredListPage({
    super.key,
    required this.category,
    this.memberUid,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseCloudProvider>();
    final t = AppLocalizations.of(context)!;
    final list = p.forCategory(
      category: category,
      uid: memberUid,
    ); // ↓ provider metodu aşağıda
    return Scaffold(
      appBar: AppBar(
        title: Text(t.categoryTitle(category)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'budgets') {
                showBudgetsManagerSheet(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'budgets',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(t.budgetsMenu),
                ),
              ),
            ],
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(child: Text(t.noExpenses))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = list[i];
                return ListTile(
                  title: Text(e.title, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: Text(fmtMoney(context, e.amount)),
                  onTap: () => showExpenseEditDialog(
                    context: context,
                    id: e.id,
                    initialTitle: e.title,
                    initialAmount: e.amount,
                    initialDate: e.date,
                    initialAssignedToUid: e.assignedToUid,
                    initialCategory: e.category,
                  ),
                );
              },
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
              cacheExtent: 800,
            ),
    );
  }
}
