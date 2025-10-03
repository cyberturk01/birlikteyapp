import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/ui_provider.dart';
import '../../widgets/muted_text.dart';
import '../../widgets/swipe_bg.dart';

class ItemsSubsection extends StatelessWidget {
  final List<Item> itemsFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Item) onToggleItem;

  const ItemsSubsection({
    super.key,
    required this.itemsFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = itemsFiltered.length;
    final showAll = expanded || total <= previewCount;
    final visible = showAll
        ? itemsFiltered
        : itemsFiltered.take(previewCount).toList();
    final hiddenCount = showAll ? 0 : (total - previewCount);
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.market,
          style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (itemsFiltered.isEmpty)
          MutedText(tr.noItems)
        else
          ...visible.map((it) {
            final bought = it.bought;
            return Dismissible(
              key: ValueKey('item-${it.remoteId ?? it.name}-${it.hashCode}'),
              background: const SwipeBg(
                color: Colors.green,
                icon: Icons.check,
                align: Alignment.centerLeft,
              ),
              secondaryBackground: const SwipeBg(
                color: Colors.red,
                icon: Icons.delete,
                align: Alignment.centerRight,
              ),
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.startToEnd) {
                  await _handleToggleItem(
                    context,
                    it,
                    withCelebrate: !it.bought,
                  );
                  return false;
                } else {
                  // Delete + Undo
                  final removed = it;
                  final copy = Item(
                    removed.name,
                    bought: removed.bought,
                    assignedToUid: removed.assignedToUid,
                  );
                  await context.read<ItemCloudProvider>().removeItem(removed);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.itemDeleted),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () =>
                            context.read<ItemCloudProvider>().addItem(copy),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  return true;
                }
              },
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -2,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Checkbox(
                  value: bought,
                  onChanged: (v) async {
                    await _handleToggleItem(
                      context,
                      it,
                      withCelebrate: v == true,
                    );
                  },
                ),
                title: Text(
                  it.name,
                  overflow: TextOverflow.ellipsis,
                  style: bought
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((it.category ?? '').isNotEmpty)
                      _CategoryPill(it.category!),
                    if (it.price != null) ...[
                      const SizedBox(width: 6),
                      _PricePill(it.price!),
                    ],
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _showEditItemDialog(context, it);
                        } else if (v == 'delete') {
                          await context.read<ItemCloudProvider>().removeItem(
                            it,
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.edit),
                            title: Text(tr.edit),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            title: Text(tr.delete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        if (hiddenCount > 0 || expanded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleExpand,
              child: Text(showAll ? tr.showLess : tr.showAllCount(hiddenCount)),
            ),
          ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  const _CategoryPill(this.category);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final fg = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category, size: 12),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void _showEditItemDialog(BuildContext context, Item it) {
  final cCat = TextEditingController(text: it.category ?? '');
  final cPrice = TextEditingController(
    text: it.price == null ? '' : _formatMoneyForInput(context, it.price!),
  );
  final t = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editItem),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: cCat,
            decoration: InputDecoration(
              labelText: t.category,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: cPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: t.price,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final cat = cCat.text.trim();
            final price = double.tryParse(cPrice.text.replaceAll(',', '.'));
            final prov = context.read<ItemCloudProvider>();
            await prov.updateCategory(it, cat.isEmpty ? null : cat);
            await prov.updatePrice(it, price);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

class _PricePill extends StatelessWidget {
  final double price;
  const _PricePill(this.price);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.secondaryContainer;
    final fg = Theme.of(context).colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments, size: 12),
          const SizedBox(width: 4),
          Text(
            _formatMoneyDisplay(context, price),
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoneyDisplay(BuildContext context, double v) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  // Varsayılan yerel para birimi simgesi; istersen currencyCode geçirilebilir
  return NumberFormat.simpleCurrency(locale: locale).format(v);
}

String _formatMoneyForInput(BuildContext context, double v) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dec = NumberFormat.decimalPattern(locale);
  // Tam sayı ise ondalık ekleme
  if (v == v.roundToDouble()) return dec.format(v);
  return dec.format(v);
}

Future<void> _handleToggleItem(
  BuildContext context,
  Item it, {
  bool withCelebrate = false,
}) async {
  final ui = context.read<UiProvider>();
  final willComplete = !it.bought;
  final t = AppLocalizations.of(context)!;

  await context.read<ItemCloudProvider>().toggleItem(it, willComplete);

  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.of(context);
      m.clearSnackBars();
      m.showSnackBar(
        SnackBar(
          content: Text(t.itemBoughtToast),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  if (willComplete && ui.itemFilter == ItemViewFilter.toBuy) {
    context.read<UiProvider>().setItemFilter(ItemViewFilter.bought);
  } else if (!willComplete && ui.itemFilter == ItemViewFilter.bought) {
    context.read<UiProvider>().setItemFilter(ItemViewFilter.toBuy);
  }
}
