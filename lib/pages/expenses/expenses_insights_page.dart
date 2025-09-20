import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/formatting.dart';
import '../../widgets/expense_edit_dialog.dart';
import '../../widgets/member_dropdown_uid.dart';
import 'expenses_by_category_page.dart';

class ExpensesInsightsPage extends StatefulWidget {
  final String? initialMember;
  const ExpensesInsightsPage({super.key, this.initialMember});

  @override
  State<ExpensesInsightsPage> createState() => _ExpensesInsightsPageState();
}

class _ExpensesInsightsPageState extends State<ExpensesInsightsPage> {
  String? _memberUid;
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth;

  @override
  void initState() {
    super.initState();
    // initialMember gelebilir (örn: "You (yigitgokhan1)")
    _memberUid = widget.initialMember; // normalize'ı build içinde yapacağız
  }

  @override
  Widget build(BuildContext context) {
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

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
                child: Builder(
                  builder: (context) {
                    final expProv = context.watch<ExpenseCloudProvider>();
                    final expenses = expProv.forMemberFiltered(
                      _memberUid,
                      _filter,
                    );
                    final total = expProv.totalForMember(
                      _memberUid,
                      filter: _filter,
                    );
                    final year = DateTime.now().year;
                    final monthly = expProv.monthlyTotals(
                      year: year,
                      uid: _memberUid,
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
                              child: MemberDropdownUid(
                                value: _memberUid,
                                onChanged: (v) =>
                                    setState(() => _memberUid = v),
                                label: 'Member',
                                nullLabel: 'All members',
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
                                          initialMember: _memberUid,
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
                                TextButton.icon(
                                  onPressed: () =>
                                      _pickRangeAndExport(context, _memberUid),
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('Export (range)'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _pickRangeAndShare(context, _memberUid),
                                  icon: const Icon(Icons.ios_share),
                                  label: const Text('Share (range)'),
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
                              fmtMoney(context, total),
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
                                StreamBuilder<Map<String, String>>(
                                  stream: dictStream,
                                  builder: (_, snapDict) {
                                    final dict = snapDict.data ?? const {};
                                    if (expenses.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'No expenses for selected range.',
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: expenses.map((e) {
                                        final memberLabel =
                                            e.assignedToUid == null
                                            ? 'Unassigned'
                                            : (dict[e.assignedToUid] ??
                                                  'Member');
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            e.title,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            '${_fmtDate(e.date)} • $memberLabel'
                                            '${e.category == null ? '' : ' • ${e.category}'}',
                                          ),
                                          trailing: Text(
                                            fmtMoney(context, e.amount),
                                          ),
                                          onLongPress: () =>
                                              _showChangeCategorySheet(
                                                context,
                                                e,
                                              ),
                                          onTap: () async {
                                            await showExpenseEditDialog(
                                              context: context,
                                              id: e.id,
                                              initialTitle: e.title,
                                              initialAmount: e.amount,
                                              initialDate: e.date,
                                              initialAssignedToUid:
                                                  e.assignedToUid,
                                              initialCategory: e.category,
                                            );
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
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

  String _stampNow() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<DateTimeRange?> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 3, 1, 1);
    final last = DateTime(now.year + 1, 12, 31);
    return await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );
  }

  /// Provider’dan ALLEXPENSES -> member ve tarihe göre filtreler.
  List<ExpenseDoc> _filterByRange(
    BuildContext context, {
    required String? memberUid,
    required DateTimeRange range,
  }) {
    final prov = context.read<ExpenseCloudProvider>();
    // mevcut API’n yoksa ALLEXPENSES’i Exposure et; yoksa allFiltered yaz:
    final all = prov.forMemberFiltered(memberUid, ExpenseDateFilter.all);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endEx = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    ).add(const Duration(days: 1)); // bitiş gününü dahil et
    return all
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(endEx))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _pickRangeAndExport(
    BuildContext context,
    String? memberUid,
  ) async {
    final picked = await _pickRange(context);
    if (picked == null) return;

    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final list = _filterByRange(context, memberUid: memberUid, range: picked);

      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member', 'category'],
        ...list.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2), // CSV’de sayısal kalsın
            (e.assignedToUid == null
                ? ''
                : (dict[e.assignedToUid] ?? e.assignedToUid!)),
            e.category ?? '',
          ],
        ),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final famId = context.read<FamilyProvider>().familyId ?? 'noFamily';
      final file = File(
        '${dir.path}/expenses_${famId}_${_fmtDate(picked.start)}_${_fmtDate(picked.end)}_${_stampNow()}.csv',
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

  Future<void> _pickRangeAndShare(
    BuildContext context,
    String? memberUid,
  ) async {
    final picked = await _pickRange(context);
    if (picked == null) return;

    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final list = _filterByRange(context, memberUid: memberUid, range: picked);

      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member', 'category'],
        ...list.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            (e.assignedToUid == null
                ? ''
                : (dict[e.assignedToUid] ?? e.assignedToUid!)),
            e.category ?? '',
          ],
        ),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final famId = context.read<FamilyProvider>().familyId ?? 'noFamily';
      final file = File(
        '${dir.path}/expenses_share_${famId}_${_fmtDate(picked.start)}_${_fmtDate(picked.end)}_${_stampNow()}.csv',
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

  Future<void> _exportCsv(
    BuildContext context,
    List<ExpenseDoc> expenses,
  ) async {
    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member', 'category'],
        ...expenses.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            (e.assignedToUid == null
                ? ''
                : (dict[e.assignedToUid] ?? e.assignedToUid!)),
            e.category ?? '',
          ],
        ),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final famId = context.read<FamilyProvider>().familyId ?? 'noFamily';
      final file = File('${dir.path}/expenses_${famId}_${_stampNow()}.csv');
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

  Future<void> _shareCsv(
    BuildContext context,
    List<ExpenseDoc> expenses,
  ) async {
    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final rows = <List<dynamic>>[
        ['date', 'title', 'amount', 'member'],
        ...expenses.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            e.amount.toStringAsFixed(2),
            (e.assignedToUid == null
                ? ''
                : (dict[e.assignedToUid] ?? e.assignedToUid!)),
          ],
        ),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final famId = context.read<FamilyProvider>().familyId ?? 'noFamily';
      final file = File(
        '${dir.path}/expenses_share_${famId}_${_stampNow()}.csv',
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

// YYYY-MM-DD
String _fmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String _stampNow() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}${two(now.minute)}';
}

void _showChangeCategorySheet(BuildContext context, ExpenseDoc e) {
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
                    context.read<ExpenseCloudProvider>().updateCategory(
                      e.id,
                      null,
                    );
                    Navigator.pop(context);
                  },
                ),
                ...categories.map(
                  (c) => ActionChip(
                    label: Text(c),
                    onPressed: () {
                      context.read<ExpenseCloudProvider>().updateCategory(
                        e.id,
                        c,
                      );
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
                context.read<ExpenseCloudProvider>().updateCategory(
                  e.id,
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
                  context.read<ExpenseCloudProvider>().updateCategory(
                    e.id,
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
