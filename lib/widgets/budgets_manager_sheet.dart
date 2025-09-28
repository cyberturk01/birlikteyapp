// lib/widgets/budgets_manager_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_cloud_provider.dart';

class _BudgetRow {
  String name;
  String amountText; // "" = boş (kaldır anlamına gelebilir)
  _BudgetRow(this.name, this.amountText);
}

Future<void> showBudgetsManagerSheet(BuildContext context) async {
  final prov = context.read<ExpenseCloudProvider>();
  // Kaynakları topla: mevcut bütçeler + harcama verisindeki kategoriler
  final budgetsMap = Map<String, double>.fromEntries(
    (prov.totalsByCategory(uid: null, filter: ExpenseDateFilter.all).keys).map(
      (k) => MapEntry(k, prov.getMonthlyBudgetFor(k) ?? double.nan),
    ),
  );

  // Ayrıca sadece “settings.budgets” içinde olup hiç harcaması olmayanlar da gelsin
  // -> prov tarafında _monthlyBudgets var; ona doğrudan erişmiyoruz ama getter eklediysen
  // getMonthlyBudgetFor() ile isimleri tek tek çekemeyiz; pratik: aşağıdaki isim birleşimi:
  final knownCats = <String>{
    ...budgetsMap.keys,
    ...prov.expenses.map((e) => (e.category ?? 'Uncategorized')).toList(),
  }..removeWhere((s) => s.trim().isEmpty);

  // Satırları hazırla
  final rows = <_BudgetRow>[
    for (final c in knownCats)
      _BudgetRow(
        c,
        (() {
          final b = prov.getMonthlyBudgetFor(c);
          if (b == null) return '';
          return b % 1 == 0 ? b.toStringAsFixed(0) : b.toStringAsFixed(2);
        })(),
      ),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      final listViewKey = GlobalKey();
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          void addBlankRow() {
            setLocal(() {
              rows.add(_BudgetRow('', ''));
            });
            // küçük bir gecikme ile liste sonuna kaydırmak istersen:
            Future.delayed(const Duration(milliseconds: 150), () {
              final p = PrimaryScrollController.maybeOf(sheetCtx);
              p?.animateTo(
                p.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            });
          }

          Future<void> saveAll() async {
            // Boş isimli satırları at, isim ve rakama göre yaz/sil
            for (final r in rows) {
              final name = r.name.trim();
              if (name.isEmpty) continue;
              final raw = r.amountText.trim();
              if (raw.isEmpty) {
                await prov.setMonthlyBudget(name, null); // kaldır
                continue;
              }
              final v = double.tryParse(raw.replaceAll(',', '.'));
              await prov.setMonthlyBudget(name, v);
            }
            if (ctx.mounted) Navigator.pop(sheetCtx);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Budgets updated')));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Budgets',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add or edit monthly limits per category.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: addBlankRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add category'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Liste
                Flexible(
                  child: ListView.separated(
                    key: listViewKey,
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return Row(
                        children: [
                          // Kategori adı
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              initialValue: r.name,
                              onChanged: (v) => r.name = v,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bütçe
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: r.amountText,
                              onChanged: (v) => r.amountText = v,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Monthly limit',
                                hintText: 'e.g. 250',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Clear',
                            onPressed: () => setLocal(() => r.amountText = ''),
                            icon: const Icon(Icons.backspace_outlined),
                          ),
                          IconButton(
                            tooltip: 'Remove row',
                            onPressed: () => setLocal(() => rows.removeAt(i)),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: addBlankRow,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: saveAll,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
