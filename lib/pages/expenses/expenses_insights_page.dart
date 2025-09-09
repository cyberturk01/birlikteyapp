import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/family_provider.dart';

class ExpensesInsightsPage extends StatefulWidget {
  final String? initialMember;
  const ExpensesInsightsPage({super.key, this.initialMember});

  @override
  State<ExpensesInsightsPage> createState() => _ExpensesInsightsPageState();
}

class _ExpensesInsightsPageState extends State<ExpensesInsightsPage> {
  String? _member; // null = All members
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth;

  @override
  void initState() {
    super.initState();
    _member = widget.initialMember; // aktif üye ile başla
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>().familyMembers;
    final expProv = context.watch<ExpenseProvider>();

    final expenses = expProv.forMemberFiltered(_member, _filter);
    final total = expProv.totalForMember(_member, filter: _filter);
    final year = DateTime.now().year;
    final monthly = expProv.monthlyTotals(year: year, member: _member);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses — Insights')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // === Üst kontrol paneli ===
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Member seçici
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: DropdownButtonFormField<String?>(
                  value: _member, // null = All
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All members'),
                    ),
                    ...family.map(
                      (m) =>
                          DropdownMenuItem<String?>(value: m, child: Text(m)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _member = v),
                  decoration: const InputDecoration(
                    labelText: 'Member',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),

              // Tarih filtresi
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

              // Export / Share
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _exportCsv(context, expenses),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
              TextButton.icon(
                onPressed: () => _shareCsv(context, expenses),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // === Toplam & Ay etiketi ===
          Row(
            children: [
              Expanded(
                child: Text(
                  _titleWithMonth(_filter),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '€ ${total.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // === Bar Chart (yıllık) ===
          _MonthlyBarChart(data: monthly),

          const SizedBox(height: 16),

          // === Liste (filtrelenmiş, yeni → eski) ===
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Transactions'),
                  subtitle: Text(
                    '${expenses.length} record${expenses.length == 1 ? '' : 's'}',
                  ),
                ),
                const Divider(height: 1),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No expenses for selected range.'),
                  )
                else
                  ...expenses.map(
                    (e) => ListTile(
                      dense: true,
                      title: Text(e.title, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_fmtDate(e.date)} • ${e.assignedTo ?? 'Unassigned'}',
                      ),
                      trailing: Text('€ ${e.amount.toStringAsFixed(2)}'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleWithMonth(ExpenseDateFilter f) {
    final now = DateTime.now();
    final months = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (f == ExpenseDateFilter.thisMonth) {
      return 'This month • ${months[now.month - 1]} ${now.year}';
    }
    if (f == ExpenseDateFilter.lastMonth) {
      final prev = DateTime(now.year, now.month - 1, 1);
      return 'Last month • ${months[prev.month - 1]} ${prev.year}';
    }
    return 'All time';
  }

  static String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _exportCsv(BuildContext context, List<Expense> expenses) async {
    try {
      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member'],
        ...expenses.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            e.assignedTo ?? '',
          ],
        ),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved CSV: ${file.path.split('/').last}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _shareCsv(BuildContext context, List<Expense> expenses) async {
    try {
      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member'],
        ...expenses.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            e.assignedTo ?? '',
          ],
        ),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/expenses_share_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Togetherly — Expenses CSV');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<double> data; // 12 eleman
  const _MonthlyBarChart({required this.data});

  static const _labels = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final maxY =
        ((data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b)) * 1.25) +
        1;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i > 11) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _labels[i],
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(12, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i],
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
