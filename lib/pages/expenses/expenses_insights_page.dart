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
import 'expenses_by_category_page.dart';

class ExpensesInsightsPage extends StatefulWidget {
  final String? initialMember;
  const ExpensesInsightsPage({super.key, this.initialMember});

  @override
  State<ExpensesInsightsPage> createState() => _ExpensesInsightsPageState();
}

class _ExpensesInsightsPageState extends State<ExpensesInsightsPage> {
  // _member: dropdown seçimi. Özel anahtar: __ALL__ => tüm üyeler
  static const String _allKey = '__ALL__';

  String? _member; // label | '' (unassigned) | __ALL__
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth;

  @override
  void initState() {
    super.initState();
    // initialMember gelebilir (örn: "You (yigitgokhan1)")
    _member = widget.initialMember; // normalize'ı build içinde yapacağız
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();

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
              // Member seçici (CANLI: Firestore labels)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: StreamBuilder<List<String>>(
                  stream: context.read<FamilyProvider>().watchMemberLabels(),
                  builder: (context, snap) {
                    final labels = (snap.data ?? const <String>[]).toList();

                    // __ALL__ anahtarı ve normalize
                    const allKey = '__ALL__';
                    String? current = _member;
                    if (current == null) {
                      current = allKey;
                    } else if (current.isNotEmpty &&
                        !labels.contains(current)) {
                      current = labels.isNotEmpty ? labels.first : allKey;
                    }
                    final memberForFilter = (current == allKey)
                        ? null
                        : current;

                    // Hesaplamalar (artık StreamBuilder içinde; labels’a göre)
                    final expProv = context.watch<ExpenseProvider>();
                    final expenses = expProv.forMemberFiltered(
                      memberForFilter,
                      _filter,
                    );
                    final total = expProv.totalForMember(
                      memberForFilter,
                      filter: _filter,
                    );
                    final year = DateTime.now().year;
                    final monthly = expProv.monthlyTotals(
                      year: year,
                      member: memberForFilter,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // 1) Üye seçici sadece 280px ile sınırlı
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: DropdownButtonFormField<String?>(
                                value: current,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: allKey,
                                    child: Text('All members'),
                                  ),
                                  const DropdownMenuItem<String?>(
                                    value: '',
                                    child: Text('Unassigned'),
                                  ),
                                  ...labels.map(
                                    (m) => DropdownMenuItem<String?>(
                                      value: m,
                                      child: Text(m),
                                    ),
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

                            // 2) Tarih filtresi — wrap içinde serbest
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
                              onSelectionChanged: (s) =>
                                  setState(() => _filter = s.first),
                              showSelectedIcon: false,
                            ),

                            // 3) Aksiyonlar — ROW DEĞİL, WRAP!
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ExpensesByCategoryPage(
                                          initialMember: memberForFilter,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.pie_chart_outline),
                                  label: const Text('By category'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _exportCsv(context, expenses),
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
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Toplam başlık
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        _MonthlyBarChart(data: monthly),
                        const SizedBox(height: 16),

                        // Liste
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
                                  child: Text(
                                    'No expenses for selected range.',
                                  ),
                                )
                              else
                                ...expenses.map(
                                  (e) => ListTile(
                                    dense: true,
                                    title: Text(
                                      e.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${_fmtDate(e.date)} • ${e.assignedTo ?? 'Unassigned'}'
                                      '${e.category == null ? '' : ' • ${e.category}'}',
                                    ),
                                    trailing: Text(
                                      '€ ${e.amount.toStringAsFixed(2)}',
                                    ),
                                    onLongPress: () =>
                                        _showChangeCategorySheet(context, e),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
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
        ['date', 'title', 'amount', 'member', 'category'],
        ...expenses.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            e.assignedTo ?? '',
            e.category ?? '',
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

void _showChangeCategorySheet(BuildContext context, Expense e) {
  const categories = <String>[
    'Groceries',
    'Dining',
    'Clothing',
    'Transport',
    'Utilities',
    'Health',
    'Kids',
    'Home',
    'Other',
  ];
  String? current = e.category;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      final ctrl = TextEditingController(text: current ?? '');
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Change category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Hızlı seçimler
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Uncategorized'),
                  onPressed: () {
                    context.read<ExpenseProvider>().updateCategory(e, null);
                    Navigator.pop(context);
                  },
                ),
                ...categories.map(
                  (c) => ActionChip(
                    label: Text(c),
                    onPressed: () {
                      context.read<ExpenseProvider>().updateCategory(e, c);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Özel kategori
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Custom category',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (val) {
                context.read<ExpenseProvider>().updateCategory(
                  e,
                  val.trim().isEmpty ? null : val.trim(),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  final val = ctrl.text.trim();
                  context.read<ExpenseProvider>().updateCategory(
                    e,
                    val.isEmpty ? null : val,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    },
  );
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
