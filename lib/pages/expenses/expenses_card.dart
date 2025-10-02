import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/formatting.dart';
import '../../widgets/expense_edit_dialog.dart';
import 'expenses_insights_page.dart';

class ExpensesCard extends StatefulWidget {
  final String? memberUid;
  const ExpensesCard({super.key, this.memberUid});

  @override
  State<ExpensesCard> createState() => _ExpensesCardState();
}

class _ExpensesCardState extends State<ExpensesCard> {
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth; // default: bu ay

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseCloudProvider>();

    final t = AppLocalizations.of(context)!;
    final expenses = expProv.forMemberFiltered(widget.memberUid, _filter);
    final total = expProv.totalForMember(widget.memberUid, filter: _filter);
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    final categoriesInRange = <String>{};
    for (final e in expenses) {
      if ((e.category ?? '').isNotEmpty) categoriesInRange.add(e.category!);
    }

    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  child: StreamBuilder<Map<String, String>>(
                    stream: dictStream,
                    builder: (_, snap) {
                      final dict = snap.data ?? const {};
                      final label = widget.memberUid == null
                          ? t.allLabel
                          : (dict[widget.memberUid] ?? t.memberFallback);
                      final ch = label.trim().isEmpty
                          ? '?'
                          : label.trim()[0].toUpperCase();
                      return Text(ch);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: StreamBuilder<Map<String, String>>(
                    stream: dictStream,
                    builder: (_, snap) {
                      final dict = snap.data ?? const {};
                      final label = widget.memberUid == null
                          ? t.allMembers
                          : (dict[widget.memberUid] ?? t.memberFallback);
                      return Text(
                        '$label  ${_filterLabel(context, _filter)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                Text(
                  fmtMoney(context, total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tarih filtresi
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

            const SizedBox(height: 8),

            // Liste
            Expanded(
              child: expenses.isEmpty
                  ? Center(child: Text(t.noExpenses))
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      addSemanticIndexes: false,
                      cacheExtent: 800,
                      itemBuilder: (_, i) {
                        final e = expenses[i];
                        final cat = e.category ?? t.otherCategory;
                        final color = _categoryColor(cat);
                        return Dismissible(
                          key: ValueKey(e.id),
                          background: const ColoredBox(
                            color: Colors.redAccent,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                          ),
                          secondaryBackground: const ColoredBox(
                            color: Colors.redAccent,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(t.deleteExpenseTitle),
                                content: Text(t.deleteExpenseBody(e.title)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(t.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(t.delete),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return false;

                            try {
                              final removed = e;
                              await context.read<ExpenseCloudProvider>().remove(
                                removed.id,
                              );
                              if (!context.mounted) return true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t.expenseDeleted),
                                  action: SnackBarAction(
                                    label: t.undo,
                                    onPressed: () {
                                      final p = context
                                          .read<ExpenseCloudProvider>();
                                      p.add(
                                        title: removed.title,
                                        amount: removed.amount,
                                        date: removed.date,
                                        assignedToUid: removed.assignedToUid,
                                        category: removed.category,
                                      );
                                    },
                                  ),
                                ),
                              );
                              return true;
                            } catch (err) {
                              if (!context.mounted) return false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t.deleteFailed(err.toString())),
                                ),
                              );
                              return false;
                            }
                          },
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                            ),
                            onTap: () async {
                              await showExpenseEditDialog(
                                context: context,
                                id: e.id,
                                initialTitle: e.title,
                                initialAmount: e.amount,
                                initialDate: e.date,
                                initialAssignedToUid: e.assignedToUid,
                                initialCategory: e.category,
                              );
                            },
                            leading: CircleAvatar(
                              radius: 10,
                              backgroundColor: color,
                            ),
                            title: Text(
                              '${e.title} • $cat',
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_fmtDate(e.date)),
                            trailing: Text(fmtMoney(context, e.amount)),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: Text(t.addExpense),
                  onPressed: () async {
                    await showExpenseEditDialog(
                      context: context,
                    ); // id null => create
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesInsightsPage(
                          initialMember: widget.memberUid,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: Text(t.insights),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

Color _categoryColor(String c) {
  const palette = [
    Color(0xFF7C4DFF),
    Color(0xFF26A69A),
    Color(0xFFFF7043),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
  ];
  final h = c.codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[h % palette.length];
}

String _filterLabel(BuildContext context, ExpenseDateFilter f) {
  final now = DateTime.now();
  if (f == ExpenseDateFilter.thisMonth) {
    return ' (${DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(now)})';
  }
  if (f == ExpenseDateFilter.lastMonth) {
    final prev = DateTime(now.year, now.month - 1, 1);
    return ' (${DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(prev)})';
  }
  return '';
}
