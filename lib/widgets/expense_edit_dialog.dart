import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_cloud_provider.dart';
import '../providers/family_provider.dart';
import '../utils/formatting.dart';
import '../utils/input_formatters.dart';
import '../utils/recent_categories.dart';
import 'member_dropdown_uid.dart';

class ExpenseEditResult {
  final bool deleted; // ileride kullanmak istersen
  ExpenseEditResult({this.deleted = false});
}

/// Hem "ekle" hem "düzenle" için kullanılan dialog.
/// id null ise -> create, doluysa -> update.
Future<ExpenseEditResult?> showExpenseEditDialog({
  required BuildContext context,
  String? id, // edit için
  String? initialTitle,
  double? initialAmount,
  DateTime? initialDate,
  String? initialAssignedToUid,
  String? initialCategory,
}) async {
  final titleC = TextEditingController(text: initialTitle ?? '');
  final amountC = TextEditingController(
    text: initialAmount == null ? '' : initialAmount.toStringAsFixed(2),
  );
  DateTime date = initialDate ?? DateTime.now();
  String? assignUid = initialAssignedToUid;
  String? category = initialCategory;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2019, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) date = picked;
  }

  final famId = context.read<FamilyProvider>().familyId;
  final canSubmit = famId != null && famId.isNotEmpty;

  return showDialog<ExpenseEditResult>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final recents = RecentExpenseCats.get(limit: 5);
        return AlertDialog(
          title: Text(id == null ? 'Add expense' : 'Edit expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountC,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [AmountInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          await pickDate();
                          setLocal(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // UID dropdown
                MemberDropdownUid(
                  value: assignUid,
                  onChanged: (v) => setLocal(() => assignUid = v),
                  label: 'Assign to',
                  nullLabel: 'Unassigned',
                ),

                const SizedBox(height: 8),
                if (recents.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Uncategorized'),
                        onPressed: () => setLocal(() => category = null),
                      ),
                      ...recents.map(
                        (c) => ActionChip(
                          label: Text(c),
                          onPressed: () => setLocal(() => category = c),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                DropdownButtonFormField<String?>(
                  value: category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Uncategorized'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Groceries',
                      child: Text('Groceries'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Dining',
                      child: Text('Dining'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Transport',
                      child: Text('Transport'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Utilities',
                      child: Text('Utilities'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Health',
                      child: Text('Health'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Kids',
                      child: Text('Kids'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Home',
                      child: Text('Home'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => category = v),
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: !canSubmit
                  ? null
                  : () async {
                      final t = titleC.text.trim();
                      final a = parseAmountFlexible(amountC.text);

                      if (t.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title is required')),
                        );
                        return;
                      }
                      if (a == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount')),
                        );
                        return;
                      }
                      if (a <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Amount must be greater than 0'),
                          ),
                        );
                        return;
                      }

                      try {
                        final prov = context.read<ExpenseCloudProvider>();
                        if (id == null) {
                          // create
                          await prov.add(
                            title: t,
                            amount: a,
                            date: date,
                            assignedToUid: assignUid,
                            category: category,
                          );
                        } else {
                          // update
                          await prov.updateExpense(
                            id,
                            title: t,
                            amount: a,
                            date: date,
                            assignedToUid: assignUid,
                            category: category,
                          );
                        }
                        // 🔹 başarıyla yazdıysa “recent”a ekle
                        if ((category ?? '').trim().isNotEmpty) {
                          RecentExpenseCats.push(category!.trim());
                        }
                        if (!context.mounted) return;
                        Navigator.pop(ctx, ExpenseEditResult());
                        // 🔹 fmtMoney güvenli snackbar
                        String money;
                        try {
                          money = fmtMoney(context, a);
                        } catch (_) {
                          money = a.toStringAsFixed(2); // fallback
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              (id == null ? 'Added ' : 'Updated ') +
                                  fmtMoney(context, a),
                            ),
                          ),
                        );
                      } on StateError catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? 'No active family'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    },
              child: Text(id == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    ),
  );
}
