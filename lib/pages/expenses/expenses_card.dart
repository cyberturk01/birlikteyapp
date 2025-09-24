import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final expenses = expProv.forMemberFiltered(widget.memberUid, _filter);
    final total = expProv.totalForMember(widget.memberUid, filter: _filter);
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

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
                          ? 'All'
                          : (dict[widget.memberUid] ?? 'Member');
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
                          ? 'All members'
                          : (dict[widget.memberUid] ?? 'Member');
                      return Text(
                        '$label ${_filterLabel(_filter)}',
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

            const SizedBox(height: 8),

            // Liste
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text('No expenses'))
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = expenses[i];
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
                                title: const Text('Delete expense?'),
                                content: Text(
                                  '“${e.title}” will be removed. You can undo right after.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return false;

                            try {
                              final removed = e; // undo için sakla
                              await context.read<ExpenseCloudProvider>().remove(
                                removed.id,
                              );
                              if (!context.mounted) return true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Expense deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
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
                                SnackBar(content: Text('Delete failed: $err')),
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
                            title: Text(
                              '${e.title} ${e.category == null ? '' : '• ${e.category}'}',
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
                  label: const Text('Add expense'),
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
                          initialMember: widget.memberUid, // aktif üyeyle aç
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Insights'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(ExpenseDateFilter f) {
    final now = DateTime.now();
    final monthNames = [
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
      return ' (${monthNames[now.month - 1]} ${now.year})';
    }
    if (f == ExpenseDateFilter.lastMonth) {
      final prev = DateTime(now.year, now.month - 1, 1);
      return ' (${monthNames[prev.month - 1]} ${prev.year})';
    }
    return '';
  }

  static String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
