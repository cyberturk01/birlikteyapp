import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ui_provider.dart';
import 'family_manager.dart';

enum _TaskStatus { pending, completed }

enum _ItemStatus { toBuy, bought }

class MemberCard extends StatefulWidget {
  final String memberName;
  final List<Task> tasks;
  final List<Item> items;
  final HomeSection section;

  const MemberCard({
    super.key,
    required this.memberName,
    required this.tasks,
    required this.items,
    required this.section,
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
    context.read<TaskProvider>().toggleTask(task, newVal);
    // Sekmeyi DEĞİŞTİRME — kullanıcı hangi sekmedeyse orada kalır.
    // Gerekirse minik bir setState ile "preview/show all" animasyonları tetiklenir:
    setState(() {});
  }

  void _toggleItem(Item it) {
    final newVal = !it.bought;
    context.read<ItemProvider>().toggleItem(it, newVal);
    setState(() {});
  }

  static const int _kPreviewTasks = 4;
  static const int _kPreviewItems = 3;

  @override
  Widget build(BuildContext context) {
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

    // responsive: dar ekranda daha az preview + daha az padding
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final int previewTasks = isNarrow ? 3 : _kPreviewTasks;
    final int previewItems = isNarrow ? 2 : _kPreviewItems;

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
              theme.colorScheme.surface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  _AvatarWithRing(text: widget.memberName),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.only(right: 2),
                    child: (widget.section == HomeSection.tasks)
                        ? _TasksSubsection(
                            tasksFiltered: tasksFiltered,
                            expanded: _expandTasks,
                            previewCount: previewTasks,
                            onToggleExpand: () =>
                                setState(() => _expandTasks = !_expandTasks),
                            onToggleTask: _toggleTask,
                          )
                        : _ItemsSubsection(
                            itemsFiltered: itemsFiltered,
                            expanded: _expandItems,
                            previewCount: previewItems,
                            onToggleExpand: () =>
                                setState(() => _expandItems = !_expandItems),
                            onToggleItem: _toggleItem,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ACTIONS (tek buton)
              if (widget.section == HomeSection.tasks)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        _openQuickAddTaskSheet(context, widget.memberName),
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
                        _openQuickAddItemSheet(context, widget.memberName),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Add item',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Quick add sheets (assign OR create) =====

  void _openQuickAddTaskSheet(BuildContext context, String member) {
    final taskProv = context.read<TaskProvider>();
    final familyProv = context.read<FamilyProvider>();

    const defaultTasks = [
      "Take out the trash",
      "Clean the kitchen",
      "Do the laundry",
      "Vacuum the living room",
      "Wash the dishes",
      "Water the plants",
      "Cook dinner",
      "Organize the fridge",
      "Change bedsheets",
      "Iron clothes",
    ];

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
                          "Add task for $member",
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
                        _assignOrCreateTask(context, c.text, member),
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
                                  _assignOrCreateTask(context, name, member),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Assign dropdown kaldırıldı – sadece bu member’a ekliyoruz
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      onPressed: () =>
                          _assignOrCreateTask(context, c.text, member),
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

  void _openQuickAddItemSheet(BuildContext context, String member) {
    final itemProv = context.read<ItemProvider>();
    final familyProv = context.read<FamilyProvider>();

    const defaultItems = [
      "Milk",
      "Bread",
      "Eggs",
      "Butter",
      "Cheese",
      "Rice",
      "Pasta",
      "Tomatoes",
      "Potatoes",
      "Onions",
      "Apples",
      "Bananas",
      "Chicken",
      "Beef",
      "Fish",
      "Olive oil",
      "Salt",
      "Sugar",
      "Coffee",
      "Tea",
    ];

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
                          "Add item for $member",
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
                        _assignOrCreateItem(context, c.text, member),
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
                                  _assignOrCreateItem(context, name, member),
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
                          _assignOrCreateItem(context, c.text, member),
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
          const _MutedText('No tasks')
        else
          ...visible.map((task) {
            final isDone = task.completed;
            return Dismissible(
              key: ValueKey(
                task.key,
              ), // HiveObject.key (Task, HiveObject'tan türemeli)
              background: Container(
                color: Colors.green.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
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
                  context.read<TaskProvider>().removeTask(task);

                  // Undo SnackBar
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // Not: yeniden eklenir (yeni key alır); sıra üstte olur
                          context.read<TaskProvider>().addTask(removed);
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
                leading: IconButton(
                  tooltip: isDone ? 'Mark as pending' : 'Mark as completed',
                  icon: Icon(
                    isDone
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  onPressed: () => _handleToggleTask(context, task),
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
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<TaskProvider>().removeTask(task),
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
          const _MutedText('No items')
        else
          ...visible.map((it) {
            final bought = it.bought;
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
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
                tooltip: 'Delete',
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => context.read<ItemProvider>().removeItem(it),
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

// ====== Small widgets & helpers ======

class _AvatarWithRing extends StatelessWidget {
  final String text;
  const _AvatarWithRing({required this.text});
  @override
  Widget build(BuildContext context) {
    final initial = text.isNotEmpty ? text[0].toUpperCase() : '?';
    final ring = Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: CircleAvatar(radius: 20, child: Text(initial)),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;
  const _MutedText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---- toggle handlers keep auto-switch behavior via UiProvider ----
void _handleToggleTask(BuildContext context, Task t) {
  final ui = context.read<UiProvider>();
  final newVal = !t.completed;
  context.read<TaskProvider>().toggleTask(t, newVal);

  if (newVal && ui.taskFilter == TaskViewFilter.pending) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.completed);
  } else if (!newVal && ui.taskFilter == TaskViewFilter.completed) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.pending);
  }
}

void _handleToggleItem(BuildContext context, Item it) {
  final ui = context.read<UiProvider>();
  final newVal = !it.bought;
  context.read<ItemProvider>().toggleItem(it, newVal);

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
        (t.assignedTo == null || t.assignedTo!.isEmpty) &&
        !t.completed,
  );
  if (unassigned.isNotEmpty) return unassigned.first;

  final anyUnassigned = list.where(
    (t) =>
        t.name.toLowerCase() == lower &&
        (t.assignedTo == null || t.assignedTo!.isEmpty),
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
        (i.assignedTo == null || i.assignedTo!.isEmpty) &&
        !i.bought,
  );
  if (unassigned.isNotEmpty) return unassigned.first;

  final anyUnassigned = list.where(
    (i) =>
        i.name.toLowerCase() == lower &&
        (i.assignedTo == null || i.assignedTo!.isEmpty),
  );
  if (anyUnassigned.isNotEmpty) return anyUnassigned.first;

  try {
    return list.firstWhere((i) => i.name.toLowerCase() == lower);
  } catch (_) {
    return null;
  }
}

void _assignOrCreateTask(BuildContext context, String name, String member) {
  final prov = context.read<TaskProvider>();
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;

  final existing = _pickTaskByName(prov.tasks, trimmed);
  if (existing != null) {
    context.read<TaskProvider>().updateAssignment(existing, member);
  } else {
    prov.addTask(Task(trimmed, assignedTo: member));
  }
  Navigator.pop(context);
}

void _assignOrCreateItem(BuildContext context, String name, String member) {
  final prov = context.read<ItemProvider>();
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;

  final existing = _pickItemByName(prov.items, trimmed);
  if (existing != null) {
    context.read<ItemProvider>().updateAssignment(existing, member);
  } else {
    prov.addItem(Item(trimmed, assignedTo: member));
  }
  Navigator.pop(context);
}

void _submitTask(
  TaskProvider prov,
  String text,
  String member,
  BuildContext ctx,
) {
  final t = text.trim();
  if (t.isEmpty) return;
  final exists = prov.tasks.any(
    (task) => task.name.toLowerCase() == t.toLowerCase(),
  );
  if (exists) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(const SnackBar(content: Text('This task already exists')));
    return;
  }
  prov.addTask(Task(t, assignedTo: member));
  Navigator.pop(ctx);
}

void _submitItem(
  ItemProvider prov,
  String text,
  String member,
  BuildContext ctx,
) {
  final t = text.trim();
  if (t.isEmpty) return;
  final exists = prov.items.any(
    (task) => task.name.toLowerCase() == t.toLowerCase(),
  );
  if (exists) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(const SnackBar(content: Text('This item already exists')));
    return;
  }
  prov.addItem(Item(t, assignedTo: member));
  Navigator.pop(ctx);
}

class EmptyFamilyCard extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyFamilyCard({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              theme.colorScheme.surface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom, size: 40),
                const SizedBox(height: 10),
                Text(
                  'No family members yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => showFamilyManager(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
