import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import 'family_manager.dart';

enum _TaskStatus { pending, completed }

enum _ItemStatus { toBuy, bought }

class MemberCard extends StatefulWidget {
  final String memberName;
  final List<Task> tasks;
  final List<Item> items;
  final HomeSection section;

  const MemberCard({
    Key? key,
    required this.memberName,
    required this.tasks,
    required this.items,
    required this.section,
  }) : super(key: key);

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  _TaskStatus _taskStatus = _TaskStatus.pending;
  _ItemStatus _itemStatus = _ItemStatus.toBuy;
  // _MemberCardState içinde:
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

    // progress (top bar)
    final totalTasks = widget.tasks.length;
    final completed = widget.tasks.where((t) => t.completed).length;
    final progress = totalTasks == 0 ? 0.0 : completed / totalTasks;

    // durum bazlı filtreler
    final tasksBase = widget.tasks;
    final tasksFiltered = (_taskStatus == _TaskStatus.pending)
        ? widget.tasks.where((t) => !t.completed).toList()
        : widget.tasks.where((t) => t.completed).toList();
    final totalItems = widget.items.length;
    final itemsBase = widget.items;
    final itemsFiltered = (_itemStatus == _ItemStatus.toBuy)
        ? widget.items.where((i) => !i.bought).toList()
        : widget.items.where((i) => i.bought).toList();

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
              theme.colorScheme.surfaceVariant.withOpacity(0.55),
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER (sadece ad + (opsiyonel) progress)
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

              const SizedBox(height: 12),

              // STATUS BAR — sadece seçili sekmeye göre TEK bar
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: (widget.section == HomeSection.tasks)
                    ? SegmentedButton<_TaskStatus>(
                        key: const ValueKey('task-status'),
                        segments: [
                          ButtonSegment(
                            value: _TaskStatus.pending,
                            icon: const Icon(Icons.radio_button_unchecked),
                            label: Text(
                              'Pending (${widget.tasks.where((t) => !t.completed).length})',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: _TaskStatus.completed,
                            icon: const Icon(Icons.check_circle),
                            label: Text(
                              'Completed (${widget.tasks.where((t) => t.completed).length})',
                              style: TextStyle(fontSize: 12),
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

              const SizedBox(height: 10),

              // CONTENT (tek sekme render edilir)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.linear,
                  switchOutCurve: Curves.linear,
                  // Only fade (no size transition)
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  // Lay out ONLY the current child (no previous children stacked)
                  layoutBuilder: (currentChild, _) =>
                      currentChild ?? const SizedBox.shrink(),
                  // Important: key changes when expanding/collapsing to trigger switch
                  child: SingleChildScrollView(
                    key: ValueKey(
                      '${widget.section}-${widget.section == HomeSection.tasks ? (_expandTasks ? "all" : "less") : (_expandItems ? "all" : "less")}',
                    ),
                    padding: const EdgeInsets.only(right: 2),
                    child: (widget.section == HomeSection.tasks)
                        ? _TasksSubsection(
                            tasksFiltered: tasksFiltered,
                            expanded: _expandTasks,
                            previewCount: _kPreviewTasks,
                            onToggleExpand: () =>
                                setState(() => _expandTasks = !_expandTasks),
                            onToggleTask: _toggleTask, // ⬅️ YENİ
                          )
                        : _ItemsSubsection(
                            itemsFiltered: itemsFiltered,
                            expanded: _expandItems,
                            previewCount: _kPreviewItems,
                            onToggleExpand: () =>
                                setState(() => _expandItems = !_expandItems),
                            onToggleItem: _toggleItem, // ⬅️ YENİ
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ACTIONS
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _openQuickAddTaskSheet(context, widget.memberName),
                    icon: const Icon(Icons.add_task),
                    label: const Text(
                      'Add task',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _openQuickAddItemSheet(context, widget.memberName),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Add item',
                      style: TextStyle(fontSize: 12),
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

  // ---- helper widgets/fonksiyonlar (sende zaten vardıysa aynı kalsın) ----

  void _openQuickAddTaskSheet(BuildContext context, String member) {
    final taskProv = context.read<TaskProvider>();
    final familyProv = context.read<FamilyProvider>();

    // Hazır listeler (istersen constants dosyasına taşı)
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

    final frequent = taskProv.suggestedTasks; // top5 (provider’da var)
    final existing = taskProv.tasks.map((t) => t.name).toList();

    // Tekrarsız birleşik öneriler
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
                        _submitTask(taskProv, c.text, member, context),
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
                                  _submitTask(taskProv, name, member, context),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Kişi değiştirilebilir olsun (default: current member)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign to",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: member,
                    items: familyProv.familyMembers
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        // butonun onPressed'inde tekrar member gönderiyoruz
                        Navigator.pop(context);
                        _openQuickAddTaskSheet(context, val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      onPressed: () =>
                          _submitTask(taskProv, c.text, member, context),
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

    final frequent = itemProv.frequentItems; // top5
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
                        _submitItem(itemProv, c.text, member, context),
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
                                  _submitItem(itemProv, name, member, context),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign to",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: member,
                    items: familyProv.familyMembers
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        Navigator.pop(context);
                        _openQuickAddItemSheet(context, val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      onPressed: () =>
                          _submitItem(itemProv, c.text, member, context),
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

class _TasksSubsection extends StatelessWidget {
  final List<Task> tasksFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Task) onToggleTask;

  const _TasksSubsection({
    Key? key,
    required this.tasksFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleTask,
  }) : super(key: key);

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
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              leading: IconButton(
                tooltip: isDone ? 'Mark as pending' : 'Mark as completed',
                icon: Icon(
                  isDone
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onPressed: () => onToggleTask(task),
              ),
              title: Text(
                task.name,
                overflow: TextOverflow.ellipsis,
                style: isDone
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              onTap: () => onToggleTask(task),
              trailing: IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  context.read<TaskProvider>().removeTask(task);
                },
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
    Key? key,
    required this.itemsFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleItem,
  }) : super(key: key);

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
              onTap: () => onToggleItem(it),
              leading: IconButton(
                icon: Icon(
                  bought
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onPressed: () => onToggleItem(it),
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
                onPressed: () {
                  context.read<ItemProvider>().removeItem(it);
                },
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

class _AvatarWithRing extends StatelessWidget {
  final String text;
  const _AvatarWithRing({required this.text});

  @override
  Widget build(BuildContext context) {
    final initial = text.isNotEmpty ? text[0].toUpperCase() : '?';
    final ring = Theme.of(context).colorScheme.primary.withOpacity(0.25);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: CircleAvatar(radius: 20, child: Text(initial)),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RowItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
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
              theme.colorScheme.surfaceVariant.withOpacity(0.55),
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
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

void _submitTask(
  TaskProvider prov,
  String text,
  String member,
  BuildContext ctx,
) {
  final t = text.trim();
  if (t.isEmpty) return;
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
  prov.addItem(Item(t, assignedTo: member));
  Navigator.pop(ctx);
}
