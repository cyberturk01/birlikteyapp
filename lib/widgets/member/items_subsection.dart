import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market',
          style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (itemsFiltered.isEmpty)
          const MutedText('No items')
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
                  _handleToggleItem(context, it, withCelebrate: !it.bought);
                  return false;
                } else {
                  // Delete + Undo
                  final removed = it;
                  final copy = Item(
                    removed.name,
                    bought: removed.bought,
                    assignedToUid: removed.assignedToUid,
                  );
                  context.read<ItemCloudProvider>().removeItem(removed);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item deleted'),
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
                trailing: IconButton(
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<ItemCloudProvider>().removeItem(it),
                ),
              ),
            );
          }),
        if (hiddenCount > 0 || expanded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleExpand,
              child: Text(showAll ? 'Show less' : 'Show all (+$hiddenCount)'),
            ),
          ),
      ],
    );
  }
}

Future<void> _handleToggleItem(
  BuildContext context,
  Item it, {
  bool withCelebrate = false,
}) async {
  final ui = context.read<UiProvider>();
  final willComplete = !it.bought;

  await context.read<ItemCloudProvider>().toggleItem(it, willComplete);

  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.of(context);
      m.clearSnackBars();
      m.showSnackBar(
        const SnackBar(
          content: Text('🎉 Item Bought!'),
          duration: Duration(seconds: 2),
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
