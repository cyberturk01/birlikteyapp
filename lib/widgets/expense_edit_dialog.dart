import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
    text: initialAmount == null ? '' : fmtMoney(context, initialAmount),
  );
  DateTime date = initialDate ?? DateTime.now();
  String? assignUid =
      initialAssignedToUid ?? FirebaseAuth.instance.currentUser?.uid;
  String? category = initialCategory;
  final recents = RecentExpenseCats.get(limit: 5);
  if (category == null && recents.isNotEmpty) {
    category = recents.first;
  }
  final t = AppLocalizations.of(context)!;

  final allCategories = {
    null: t.uncategorized,
    'Groceries': t.categoryGroceries,
    'Dining': t.categoryDining,
    'Transport': t.categoryTransport,
    'Utilities': t.categoryUtilities,
    'Health': t.categoryHealth,
    'Kids': t.categoryKids,
    'Home': t.categoryHome,
    'Other': t.categoryOther,
    for (final r in recents) r: r,
  };

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
          title: Text(id == null ? t.addExpense : t.editExpense),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  autofocus: true, // ⬅️ Yazmaya hazır gelsin
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: t.titleLabel,
                    border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: t.amountLabel,
                    border: const OutlineInputBorder(),
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
                  label: t.assignTo,
                  nullLabel: t.unassigned,
                ),
                // Dropdown altında küçük bir “+ New category” (opsiyonel)
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(t.newCategory),
                    onPressed: () async {
                      final newCat = await showDialog<String>(
                        context: ctx,
                        builder: (_) {
                          final c = TextEditingController();
                          return AlertDialog(
                            title: Text(t.newCategory),
                            content: TextField(
                              controller: c,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: t.nameLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: Text(t.cancel),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, c.text.trim()),
                                child: Text(t.save),
                              ),
                            ],
                          );
                        },
                      );
                      if (newCat != null && newCat.isNotEmpty) {
                        setLocal(() {
                          category = newCat;
                          RecentExpenseCats.push(newCat);
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(height: 8),
                if (recents.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.recentLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text(t.uncategorized),
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
                  value: allCategories.keys.contains(category)
                      ? category
                      : null,
                  isExpanded: true,
                  items: allCategories.entries.map((e) {
                    return DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (v) => setLocal(() => category = v),
                  decoration: InputDecoration(
                    labelText: t.category,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: !canSubmit
                  ? null
                  : () async {
                      final t = titleC.text.trim();
                      final a = parseAmountFlexible(amountC.text);
                      final tr = AppLocalizations.of(context)!;
                      if (t.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr.titleRequired)),
                        );
                        return;
                      }
                      if (a == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr.enterValidAmount)),
                        );
                        return;
                      }
                      if (a <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr.amountGreaterThanZero)),
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
                        final msg = (id == null)
                            ? tr.addedAmount(money)
                            : tr.updatedAmount(money);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
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
              child: Text(id == null ? t.add : t.save),
            ),
          ],
        );
      },
    ),
  );
}
