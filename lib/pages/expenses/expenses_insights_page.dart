import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/formatting.dart';
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
    final t = AppLocalizations.of(context)!;
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();
    return Scaffold(
      appBar: AppBar(title: Text('${t.expenses} — ${t.insights}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // === Üst kontrol paneli ===
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: MemberDropdownUid(
                  value: _memberUid,
                  onChanged: (v) => setState(() => _memberUid = v),
                  label: t.memberLabel,
                  nullLabel: t.allMembers,
                ),
              ), // Tarih filtresi ve aksiyonlar aşağı taşındı (StreamBuilder’a gerek yok)
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
                onSelectionChanged: (s) => setState(() => _filter = s.first),
                showSelectedIcon: false,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpensesByCategoryPage(initialMember: _memberUid),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pie_chart_outline),
                    label: Text(t.byCategory),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickRangeAndExport(context, _memberUid),
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: Text(t.export),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickRangeAndShare(context, _memberUid),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: Text(t.share),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // === Toplam başlık  aylık grafik ===
              _HeaderAndChart(memberUid: _memberUid, filter: _filter),
              // === Transaction listesi (tek StreamBuilder ile dict) ===
              StreamBuilder<Map<String, String>>(
                stream: dictStream,
                builder: (_, snap) {
                  final dict = snap.data ?? const {};
                  final expProv = context.watch<ExpenseCloudProvider>();
                  final expenses = expProv.forMemberFiltered(
                    _memberUid,
                    _filter,
                  );

                  return Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(t.transactions),
                          subtitle: Text(t.recordsCount(expenses.length)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: t.exportCsvTooltip,
                                icon: const Icon(Icons.download),
                                onPressed: () => _exportCsv(context, expenses),
                              ),
                              IconButton(
                                tooltip: t.shareTooltip,
                                icon: const Icon(Icons.share),
                                onPressed: () => _shareCsv(context, expenses),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (expenses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(t.noExpensesForRange),
                          )
                        else
                          ...expenses.map((e) {
                            final memberLabel = e.assignedToUid == null
                                ? t.unassigned
                                : (dict[e.assignedToUid] ?? t.memberFallback);
                            return ListTile(
                              dense: true,
                              title: Text(
                                e.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${fmtDateYmd(e.date)} • $memberLabel'
                                '${e.category == null ? '' : ' • ${e.category}'}',
                              ),
                              trailing: Text(fmtMoney(context, e.amount)),
                              onLongPress: () =>
                                  _showChangeCategorySheet(context, e),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fileStamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}';
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
    final t = AppLocalizations.of(context)!;
    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final list = _filterByRange(context, memberUid: memberUid, range: picked);

      final rows = <List<dynamic>>[
        [t.csvDate, t.csvTitle, t.csvAmount, t.csvMember, t.csvCategory],
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
        '${dir.path}/$famId${_fmtDate(picked.start)}-${_fmtDate(picked.end)}_${_fileStamp()}.csv',
      ); // aralıklı export

      await file.writeAsString(csv);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.savedCsvWithName(file.path.split('/').last))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.exportFailed(e.toString()))));
    }
  }

  Future<void> _pickRangeAndShare(
    BuildContext context,
    String? memberUid,
  ) async {
    final picked = await _pickRange(context);
    if (picked == null) return;
    final t = AppLocalizations.of(context)!;
    try {
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final list = _filterByRange(context, memberUid: memberUid, range: picked);

      final rows = <List<dynamic>>[
        [t.csvDate, t.csvTitle, t.csvAmount, t.csvMember, t.csvCategory],
        ...list.map(
          (e) => [
            _fmtDate(e.date),
            e.title,
            fmtMoney(context, e.amount),
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

      await Share.shareXFiles([XFile(file.path)], text: t.expensesCsvShareText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.shareFailed(e.toString()))));
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<ExpenseDoc> expenses,
  ) async {
    try {
      final t = AppLocalizations.of(context)!;
      final dict = await context
          .read<FamilyProvider>()
          .watchMemberDirectory()
          .first;
      final rows = <List<dynamic>>[
        [t.csvDate, t.csvTitle, t.csvAmount, t.csvMember, t.csvCategory],
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
        SnackBar(content: Text(t.savedCsvWithName(file.path.split('/').last))),
      );
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.exportFailed(e.toString()))));
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
      final t = AppLocalizations.of(context)!;
      final rows = <List<dynamic>>[
        [t.csvDate, t.csvTitle, t.csvAmount, t.csvMember],
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
      await Share.shareXFiles([XFile(file.path)], text: t.expensesCsvShareText);
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.shareFailed(e.toString()))));
    }
  }
}

// YYYY-MM-DD
String _fmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

void _showChangeCategorySheet(BuildContext context, ExpenseDoc e) {
  final t = AppLocalizations.of(context)!;

  final categories = [
    t.categoryGroceries,
    t.categoryDining,
    t.categoryClothing,
    t.categoryTransport,
    t.categoryUtilities,
    t.categoryHealth,
    t.categoryKids,
    t.categoryHome,
    t.categoryOther,
  ];

  final String? current = e.category;

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
                Expanded(
                  child: Text(
                    t.changeCategory,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text(t.uncategorized),
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
              decoration: InputDecoration(
                labelText: t.customCategory,
                border: const OutlineInputBorder(),
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
                child: Text(t.save),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final List<dynamic> _labels = [
      t.monthShortJan,
      t.monthShortFeb,
      t.monthShortMar,
      t.monthShortApr,
      t.monthShortMay,
      t.monthShortJun,
      t.monthShortJul,
      t.monthShortAug,
      t.monthShortSep,
      t.monthShortOct,
      t.monthShortNov,
      t.monthShortDec,
    ];

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

class _HeaderAndChart extends StatelessWidget {
  final String? memberUid;
  final ExpenseDateFilter filter;
  const _HeaderAndChart({required this.memberUid, required this.filter});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseCloudProvider>();
    final total = expProv.totalForMember(memberUid, filter: filter);
    final monthly = expProv.monthlyTotals(
      year: DateTime.now().year,
      uid: memberUid,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthTitle(filter, DateTime.now()), // 👈 utils
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              fmtMoney(context, total),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MonthlyBarChart(data: monthly),
      ],
    );
  }
}
