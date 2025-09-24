import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_lists.dart';
import '../../constants/app_strings.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/ui_provider.dart';
import '../../widgets/muted_text.dart';
import '../../widgets/swipe_bg.dart';

enum _TaskStatus { pending, completed }

enum _ItemStatus { toBuy, bought }

class MemberCard extends StatefulWidget {
  final String memberUid;
  final String memberName;
  final List<Task> tasks;
  final List<Item> items;
  final HomeSection section;
  final void Function(HomeSection section)? onJumpSection;
  const MemberCard({
    super.key,
    required this.memberUid,
    required this.memberName,
    required this.tasks,
    required this.items,
    required this.section,
    this.onJumpSection,
  });

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  _TaskStatus _taskStatus = _TaskStatus.pending;
  _ItemStatus _itemStatus = _ItemStatus.toBuy;

  bool _expandTasks = false;
  bool _expandItems = false;

  void _toggleTask(Task task) {
    final newVal = !task.completed;
    context.read<TaskCloudProvider>().toggleTask(task, newVal);
    setState(() {});
  }

  void _toggleItem(Item it) {
    final newVal = !it.bought;
    context.read<ItemCloudProvider>().toggleItem(it, newVal);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isShort = media.size.height < 620; // küçük yükseklik eşiği
    final theme = Theme.of(context);

    final totalTasks = widget.tasks.length;
    final completedTasks = widget.tasks.where((t) => t.completed).length;
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    final tasksFiltered = (_taskStatus == _TaskStatus.pending)
        ? widget.tasks.where((t) => !t.completed).toList()
        : widget.tasks.where((t) => t.completed).toList();

    final itemsFiltered = (_itemStatus == _ItemStatus.toBuy)
        ? widget.items.where((i) => !i.bought).toList()
        : widget.items.where((i) => i.bought).toList();

    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final previewTasks = (isLandscape || isShort) ? 2 : 6;
    final previewItems = (isLandscape || isShort) ? 2 : 3;

    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              theme.colorScheme.surface.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) {},
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.memberName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Küçük inline link butonlar
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  ),
                                ),
                                onPressed: () {
                                  widget.onJumpSection?.call(HomeSection.tasks);
                                },
                                child: const Text('Tasks'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  ),
                                ),
                                onPressed: () {
                                  // widget.onOpenItemsPopup?.call();
                                  widget.onJumpSection?.call(HomeSection.items);
                                },
                                child: const Text('Market'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.section == HomeSection.tasks &&
                            totalTasks > 0 &&
                            !_expandTasks)
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0, 1),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('${(progress * 100).round()}%'),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 8),

              // STATUS BAR (centered)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Center(
                  child: (widget.section == HomeSection.tasks)
                      ? SegmentedButton<_TaskStatus>(
                          key: const ValueKey('task-status'),
                          segments: [
                            ButtonSegment(
                              value: _TaskStatus.pending,
                              icon: const Icon(Icons.radio_button_unchecked),
                              label: Text(
                                'Pending (${widget.tasks.where((t) => !t.completed).length})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            ButtonSegment(
                              value: _TaskStatus.completed,
                              icon: const Icon(Icons.check_circle),
                              label: Text(
                                'Completed (${widget.tasks.where((t) => t.completed).length})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          selected: {_taskStatus},
                          onSelectionChanged: (s) =>
                              setState(() => _taskStatus = s.first),
                          showSelectedIcon: false,
                        )
                      : SegmentedButton<_ItemStatus>(
                          key: const ValueKey('item-status'),
                          segments: [
                            ButtonSegment(
                              value: _ItemStatus.toBuy,
                              icon: const Icon(Icons.shopping_basket),
                              label: Text(
                                'To buy (${widget.items.where((i) => !i.bought).length})',
                              ),
                            ),
                            ButtonSegment(
                              value: _ItemStatus.bought,
                              icon: const Icon(Icons.check_circle),
                              label: Text(
                                'Bought (${widget.items.where((i) => i.bought).length})',
                              ),
                            ),
                          ],
                          selected: {_itemStatus},
                          onSelectionChanged: (s) =>
                              setState(() => _itemStatus = s.first),
                          showSelectedIcon: false,
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // CONTENT
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  layoutBuilder: (currentChild, _) =>
                      currentChild ?? const SizedBox.shrink(),
                  child: SingleChildScrollView(
                    key: ValueKey(
                      '${widget.section}-${widget.section == HomeSection.tasks ? (_expandTasks ? "all" : "less") : (_expandItems ? "all" : "less")}',
                    ),
                    padding: const EdgeInsets.only(right: 2, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (widget.section == HomeSection.tasks)
                            ? _TasksSubsection(
                                tasksFiltered: tasksFiltered,
                                expanded: _expandTasks,
                                previewCount: previewTasks,
                                onToggleExpand: () => setState(
                                  () => _expandTasks = !_expandTasks,
                                ),
                                onToggleTask: _toggleTask,
                              )
                            : _ItemsSubsection(
                                itemsFiltered: itemsFiltered,
                                expanded: _expandItems,
                                previewCount: previewItems,
                                onToggleExpand: () => setState(
                                  () => _expandItems = !_expandItems,
                                ),
                                onToggleItem: _toggleItem,
                              ),
                        const SizedBox(height: 8),
                        // --- CLEAR (Completed / Bought) with UNDO ---
                        if (widget.section == HomeSection.tasks &&
                            _taskStatus == _TaskStatus.completed &&
                            tasksFiltered.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Clear completed'),
                              onPressed: () => _clearCompletedForMember(
                                context,
                                widget.memberUid,
                              ),
                            ),
                          )
                        else if (widget.section == HomeSection.items &&
                            _itemStatus == _ItemStatus.bought &&
                            itemsFiltered.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Clear bought'),
                              onPressed: () => _clearBoughtForMember(
                                context,
                                widget.memberUid,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // ACTIONS (tek buton)
                  if (widget.section == HomeSection.tasks)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _openQuickAddTaskSheet(context, widget.memberUid),
                        icon: const Icon(Icons.add_task),
                        label: const Text(
                          'Add task',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            _openQuickAddItemSheet(context, widget.memberUid),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text(
                          'Add item',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearCompletedForMember(BuildContext context, String memberUid) {
    final prov = context.read<TaskCloudProvider>();

    final removed = prov.tasks
        .where((t) => (t.assignedToUid ?? '') == memberUid && t.completed)
        .map(
          (t) => Task(
            t.name,
            completed: t.completed,
            assignedToUid: t.assignedToUid,
          ),
        )
        .toList();

    prov.clearCompleted(forMember: memberUid);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared – Undo'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final t in removed) {
              context.read<TaskCloudProvider>().addTask(t);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _clearBoughtForMember(BuildContext context, String memberUid) {
    final prov = context.read<ItemCloudProvider>();

    final removed = prov.items
        .where((i) => (i.assignedToUid ?? '') == memberUid && i.bought)
        .map(
          (i) => Item(i.name, bought: i.bought, assignedToUid: i.assignedToUid),
        )
        .toList();

    prov.clearBought(forMember: memberUid);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared – Undo'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final it in removed) {
              context.read<ItemCloudProvider>().addItem(it);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openQuickAddTaskSheet(BuildContext context, String memberUid) {
    final memberLabel = widget.memberName; // sadece başlıkta göstermek için
    final taskProv = context.read<TaskCloudProvider>();

    const defaultTasks = AppLists.defaultTasks;
    final frequent = taskProv.suggestedTasks;
    final existing = taskProv.tasks.map((t) => t.name).toList();
    final suggestions = {
      ...frequent,
      ...defaultTasks,
      ...existing,
    }.where((s) => s.trim().isNotEmpty).toList();

    final c = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // handle + başlık
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Add task for $memberLabel",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      hintText: "Enter task…",
                      prefixIcon: Icon(Icons.task_alt),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) =>
                        _assignOrCreateTask(context, c.text, memberUid),
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isNotEmpty) ...[
                    Text(
                      "Suggestions",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestions.map((name) {
                            return ActionChip(
                              label: Text(name),
                              onPressed: () =>
                                  _assignOrCreateTask(context, name, memberUid),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      onPressed: () =>
                          _assignOrCreateTask(context, c.text, memberUid),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openQuickAddItemSheet(BuildContext context, String memberUid) {
    final memberLabel = widget.memberName; // sadece başlık için
    final itemProv = context.read<ItemCloudProvider>();

    const defaultItems = AppLists.defaultItems;
    final frequent = itemProv.frequentItems;
    final existing = itemProv.items.map((i) => i.name).toList();
    final suggestions = {
      ...frequent,
      ...defaultItems,
      ...existing,
    }.where((s) => s.trim().isNotEmpty).toList();

    final c = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Add item for $memberLabel",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      hintText: "Enter item…",
                      prefixIcon: Icon(Icons.shopping_bag),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) =>
                        _assignOrCreateItem(context, c.text, memberUid),
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isNotEmpty) ...[
                    Text(
                      "Suggestions",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestions.map((name) {
                            return ActionChip(
                              label: Text(name),
                              onPressed: () =>
                                  _assignOrCreateItem(context, name, memberUid),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      onPressed: () =>
                          _assignOrCreateItem(context, c.text, memberUid),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ====== Subsections ======

class _TasksSubsection extends StatelessWidget {
  final List<Task> tasksFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Task) onToggleTask;

  const _TasksSubsection({
    required this.tasksFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = tasksFiltered.length;
    final showAll = expanded || total <= previewCount;
    final visible = showAll
        ? tasksFiltered
        : tasksFiltered.take(previewCount).toList();
    final hiddenCount = showAll ? 0 : (total - previewCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (tasksFiltered.isEmpty)
          const MutedText('No tasks')
        else
          ...visible.map((task) {
            final isDone = task.completed;
            return Dismissible(
              direction: DismissDirection.endToStart,
              key: ValueKey(
                task.remoteId ??
                    '${task.name}|${task.assignedToUid ?? //
                        ""}',
              ), // HiveObject.key (Task, HiveObject'tan türemeli)
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

              // Kaydırma davranışı:
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // SOL → SAĞ : Toggle (tamamla/geri al) — dismiss ETME
                  onToggleTask(task);
                  return false; // tile listeden düşmesin
                } else {
                  // SAĞ → SOL : Delete — dismiss ET
                  final removed = task;
                  // Önce Hive’dan sil
                  context.read<TaskCloudProvider>().removeTask(task);

                  // Undo SnackBar
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // Not: yeniden eklenir (yeni key alır); sıra üstte olur
                          context.read<TaskCloudProvider>().addTask(removed);
                        },
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
                leading: Checkbox(
                  value: isDone,
                  onChanged: (v) async {
                    await _handleToggleTask(context, task);
                    if (v == true && context.mounted) {
                      _celebrate(context, '🎉 Task ${task.name} is completed!');
                    }
                  },
                ),

                title: Text(
                  task.name,
                  overflow: TextOverflow.ellipsis,
                  style: isDone
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onTap: () => _handleToggleTask(context, task),
                trailing: IconButton(
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<TaskCloudProvider>().removeTask(task),
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

class _ItemsSubsection extends StatelessWidget {
  final List<Item> itemsFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Item) onToggleItem;

  const _ItemsSubsection({
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
                  // Toggle (satırı listeden ÇIKARMA)
                  _handleToggleItem(context, it);
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
                onTap: () => _handleToggleItem(context, it),
                leading: IconButton(
                  icon: Icon(
                    bought
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  onPressed: () => _handleToggleItem(context, it),
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

// ---- toggle handlers keep auto-switch behavior via UiProvider ----
Future<void> _handleToggleTask(BuildContext context, Task t) async {
  final ui = context.read<UiProvider>();
  final newVal = !t.completed;

  // toggleTask zaten Future dönüyorsa bunu await’le
  await context.read<TaskCloudProvider>().toggleTask(t, newVal);

  if (newVal && ui.taskFilter == TaskViewFilter.pending) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.completed);
  } else if (!newVal && ui.taskFilter == TaskViewFilter.completed) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.pending);
  }
}

Future<void> _handleToggleItem(BuildContext context, Item it) async {
  final ui = context.read<UiProvider>();
  final newVal = !it.bought;

  await context.read<ItemCloudProvider>().toggleItem(it, newVal);

  if (newVal && ui.itemFilter == ItemViewFilter.toBuy) {
    context.read<UiProvider>().setItemFilter(ItemViewFilter.bought);
  } else if (!newVal && ui.itemFilter == ItemViewFilter.bought) {
    context.read<UiProvider>().setItemFilter(ItemViewFilter.toBuy);
  }
}

// ====== assign or create helpers ======
Task? _pickTaskByName(List<Task> list, String name) {
  final lower = name.trim().toLowerCase();
  final unassigned = list.where(
    (t) =>
        t.name.toLowerCase() == lower &&
        (t.assignedToUid == null || t.assignedToUid!.isEmpty) &&
        !t.completed,
  );
  if (unassigned.isNotEmpty) return unassigned.first;

  final anyUnassigned = list.where(
    (t) =>
        t.name.toLowerCase() == lower &&
        (t.assignedToUid == null || t.assignedToUid!.isEmpty),
  );
  if (anyUnassigned.isNotEmpty) return anyUnassigned.first;

  try {
    return list.firstWhere((t) => t.name.toLowerCase() == lower);
  } catch (_) {
    return null;
  }
}

Item? _pickItemByName(List<Item> list, String name) {
  final lower = name.trim().toLowerCase();
  final unassigned = list.where(
    (i) =>
        i.name.toLowerCase() == lower &&
        (i.assignedToUid == null || i.assignedToUid!.isEmpty) &&
        !i.bought,
  );
  if (unassigned.isNotEmpty) return unassigned.first;

  final anyUnassigned = list.where(
    (i) =>
        i.name.toLowerCase() == lower &&
        (i.assignedToUid == null || i.assignedToUid!.isEmpty),
  );
  if (anyUnassigned.isNotEmpty) return anyUnassigned.first;

  try {
    return list.firstWhere((i) => i.name.toLowerCase() == lower);
  } catch (_) {
    return null;
  }
}

void _celebrate(BuildContext context, String message) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _assignOrCreateTask(BuildContext context, String name, String memberUid) {
  final prov = context.read<TaskCloudProvider>();
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;

  final existing = _pickTaskByName(prov.tasks, trimmed);
  if (existing != null) {
    context.read<TaskCloudProvider>().updateAssignment(existing, memberUid);
  } else {
    prov.addTask(Task(trimmed, assignedToUid: memberUid));
  }
  Navigator.pop(context);
}

void _assignOrCreateItem(BuildContext context, String name, String memberUid) {
  final prov = context.read<ItemCloudProvider>();
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;

  final existing = _pickItemByName(prov.items, trimmed);
  if (existing != null) {
    context.read<ItemCloudProvider>().updateAssignment(existing, memberUid);
  } else {
    prov.addItem(Item(trimmed, assignedToUid: memberUid));
  }
  Navigator.pop(context);
}
