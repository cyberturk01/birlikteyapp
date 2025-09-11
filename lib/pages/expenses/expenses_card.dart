import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../providers/family_provider.dart';
import 'expenses_insights_page.dart';

class ExpensesCard extends StatefulWidget {
  final String memberName; // aktif üye
  const ExpensesCard({super.key, required this.memberName});

  @override
  State<ExpensesCard> createState() => _ExpensesCardState();
}

class _ExpensesCardState extends State<ExpensesCard> {
  ExpenseDateFilter _filter = ExpenseDateFilter.thisMonth; // default: bu ay

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;
    final expenses = expProv.forMemberFiltered(widget.memberName, _filter);
    final total = expProv.totalForMember(widget.memberName, filter: _filter);

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
                  child: Text(
                    widget.memberName.isNotEmpty
                        ? widget.memberName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.memberName} ${_filterLabel(_filter)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '€ ${total.toStringAsFixed(2)}',
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

            // Liste (yeni: zaten newest first geliyor)
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text('No expenses'))
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = expenses[i];
                        return Dismissible(
                          key: ValueKey(e.key),
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
                            final removed = e;
                            context.read<ExpenseProvider>().remove(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Expense deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () => context
                                      .read<ExpenseProvider>()
                                      .add(removed),
                                ),
                              ),
                            );
                            return true;
                          },
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                            ),
                            title: Text(
                              '${e.title} ${e.category == null ? '' : '• ${e.category}'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_fmtDate(e.date)),
                            trailing: Text('€ ${e.amount.toStringAsFixed(2)}'),
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
                  onPressed: () =>
                      _openAddDialog(context, widget.memberName, family),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesInsightsPage(
                          initialMember: widget.memberName, // aktif üyeyle aç
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

  void _openAddDialog(
    BuildContext context,
    String member,
    List<String> family,
  ) {
    final titleC = TextEditingController();
    final amountC = TextEditingController();

    String assign = member; // varsayılan atanacak kişi
    String? cat; // null => Uncategorized
    const categories = <String>[
      'Groceries',
      'Dining',
      'Transport',
      'Utilities',
      'Health',
      'Kids',
      'Home',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Add expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleC,
                    decoration: const InputDecoration(
                      hintText: 'Title (e.g., Groceries)',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountC,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Amount (e.g., 24.90)',
                      prefixIcon: Icon(Icons.euro),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: assign,
                    isExpanded: true,
                    items: family
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setLocal(() => assign = v ?? member),
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: cat,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Uncategorized'),
                      ),
                      ...categories.map(
                        (c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => cat = v),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final t = titleC.text.trim();
                  final a = double.tryParse(amountC.text.replaceAll(',', '.'));
                  if (t.isEmpty || a == null || a <= 0) return;

                  // YÖNTEM 1: Provider'ın addExpense(...) metodu
                  context.read<ExpenseProvider>().addExpense(
                    title: t,
                    amount: a,
                    date: DateTime.now(),
                    assignedTo: assign,
                    category:
                        cat, // ✅ seçilen kategori (null ise provider 'Uncategorized' set eder)
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
