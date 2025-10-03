// widgets/section_lists.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../providers/item_cloud_provider.dart';
import '../providers/task_cloud_provider.dart';
import '../widgets/muted_text.dart';
import '../widgets/swipe_bg.dart';

class TasksSection extends StatelessWidget {
  final List<Task> tasks;
  final bool expanded;
  final int previewCount;
  final VoidCallback? onToggleExpand;
  final void Function(Task) onToggleTask;
  final bool showHeader; // yeni
  final String headerText; // yeni

  const TasksSection({
    super.key,
    required this.tasks,
    required this.expanded,
    required this.previewCount,
    required this.onToggleTask,
    this.onToggleExpand,
    this.showHeader = true,
    this.headerText = 'Tasks',
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = tasks.length;
    final showAll = expanded || total <= previewCount;
    final visible = showAll ? tasks : tasks.take(previewCount).toList();
    final hiddenCount = showAll ? 0 : (total - previewCount);
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Text(
            headerText,
            style: t.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        if (tasks.isEmpty)
          MutedText(tr.noTasks)
        else
          ...visible.map((task) {
            final isDone = task.completed;
            return Dismissible(
              direction: DismissDirection.endToStart,
              key: ValueKey(
                task.remoteId ?? '${task.name}|${task.assignedToUid ?? ""}',
              ),
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
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  onToggleTask(task);
                  return false;
                } else {
                  final removed = task;
                  await context.read<TaskCloudProvider>().removeTask(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.taskDeleted),
                      action: SnackBarAction(
                        label: tr.undo,
                        onPressed: () =>
                            context.read<TaskCloudProvider>().addTask(removed),
                      ),
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
                title: Text(
                  '${task.name}${(task.assignedToUid != null && task.assignedToUid!.isNotEmpty) ? " " : ""}',
                  overflow: TextOverflow.ellipsis,
                  style: isDone
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onTap: () => onToggleTask(task),
                trailing: IconButton(
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<TaskCloudProvider>().removeTask(task),
                ),
              ),
            );
          }),
        if ((hiddenCount > 0 || expanded) && onToggleExpand != null)
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

class ItemsSection extends StatelessWidget {
  final List<Item> items;
  final bool expanded;
  final int previewCount;
  final VoidCallback? onToggleExpand;
  final void Function(Item) onToggleItem;
  final bool showHeader; // yeni
  final String headerText; // yeni

  const ItemsSection({
    super.key,
    required this.items,
    required this.expanded,
    required this.previewCount,
    required this.onToggleItem,
    this.onToggleExpand,
    this.showHeader = true,
    this.headerText = 'Market',
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = items.length;
    final showAll = expanded || total <= previewCount;
    final visible = showAll ? items : items.take(previewCount).toList();
    final hiddenCount = showAll ? 0 : (total - previewCount);
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Text(
            headerText,
            style: t.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        if (items.isEmpty)
          MutedText(tr.noItems)
        else
          ...visible.map((it) {
            final bought = it.bought;
            return Dismissible(
              key: ValueKey(
                'item-${it.remoteId ?? it.name.toUpperCase()}-${it.hashCode}',
              ),
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
                  onToggleItem(it);
                  return false;
                } else {
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
                        label: tr.undo,
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
                onTap: () => onToggleItem(it),
                title: Text(
                  '${it.name}${(it.assignedToUid != null && it.assignedToUid!.isNotEmpty) ? " " : ""}',
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
        if ((hiddenCount > 0 || expanded) && onToggleExpand != null)
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
