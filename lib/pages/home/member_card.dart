import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_lists.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../models/view_section.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../widgets/member/items_subsection.dart';
import '../../widgets/member/tasks_subsection.dart';

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
    final entriesStream = context.read<FamilyProvider>().watchMemberEntries();

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
                    child: StreamBuilder<List<FamilyMemberEntry>>(
                      stream: entriesStream,
                      builder: (_, snap) {
                        final entries =
                            snap.data ?? const <FamilyMemberEntry>[];
                        FamilyMemberEntry? me;
                        if (widget.memberUid.isEmpty) {
                          // All
                          return const Icon(Icons.group);
                        } else {
                          me = entries.firstWhere(
                            (x) => x.uid == widget.memberUid,
                            orElse: () => FamilyMemberEntry(
                              uid: '',
                              label: 'Member',
                              role: 'editor',
                            ),
                          );
                          final ch = me.label.isEmpty
                              ? '?'
                              : me.label[0].toUpperCase();
                          final url = me.photoUrl;
                          return (url != null && url.isNotEmpty)
                              ? CircleAvatar(backgroundImage: NetworkImage(url))
                              : CircleAvatar(child: Text(ch));
                        }
                      },
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
                            ? TasksSubsection(
                                tasksFiltered: tasksFiltered,
                                expanded: _expandTasks,
                                previewCount: previewTasks,
                                onToggleExpand: () => setState(
                                  () => _expandTasks = !_expandTasks,
                                ),
                                onToggleTask: _toggleTask,
                                onEditTask: (task) =>
                                    _openTaskEditDialog(context, task),
                                showMeta: true,
                              )
                            : ItemsSubsection(
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

  Future<void> _openTaskEditDialog(BuildContext context, Task t) async {
    final prov = context.read<TaskCloudProvider>();
    final nameC = TextEditingController(text: t.name);
    DateTime? due = t.dueAt;
    DateTime? rem = t.reminderAt;

    DateTime _join(DateTime d, TimeOfDay tod) =>
        DateTime(d.year, d.month, d.day, tod.hour, tod.minute);

    Future<DateTime?> _pickDT(DateTime? initial) async {
      final base = initial ?? DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (d == null) return null;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (t == null) return null;
      return _join(d, t);
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Edit task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
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
                          due == null
                              ? 'Set due date'
                              : 'Due: ${due!.day.toString().padLeft(2, '0')}.${due!.month.toString().padLeft(2, '0')} '
                                    '${due!.hour.toString().padLeft(2, '0')}:${due!.minute.toString().padLeft(2, '0')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final picked = await _pickDT(due);
                          setLocal(() => due = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (due != null)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () => setLocal(() => due = null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.alarm),
                        label: Text(
                          rem == null
                              ? 'Set reminder'
                              : 'Remind: ${rem!.day.toString().padLeft(2, '0')}.${rem!.month.toString().padLeft(2, '0')} '
                                    '${rem!.hour.toString().padLeft(2, '0')}:${rem!.minute.toString().padLeft(2, '0')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final picked = await _pickDT(rem);
                          setLocal(() => rem = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (rem != null)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () => setLocal(() => rem = null),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final newName = nameC.text.trim();
                  if (newName.isNotEmpty && newName != t.name) {
                    await prov.renameTask(t, newName);
                  }
                  await prov.updateDueDate(t, due);
                  await prov.updateReminder(t, rem);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openQuickAddTaskSheet(BuildContext context, String memberUid) {
    final memberLabel = widget.memberName;
    final taskProv = context.read<TaskCloudProvider>();

    const defaultTasks = AppLists.defaultTasks;
    final frequent = taskProv.suggestedTasks;
    final existing = taskProv.tasks.map((t) => t.name).toList();
    final suggestions =
        {
            ...frequent,
            ...defaultTasks,
            ...existing,
          }.where((s) => s.trim().isNotEmpty).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final c = TextEditingController();
    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              Future<void> addSelected() async {
                if (selected.isEmpty) return;
                await taskProv.addTasksBulkCloud(
                  selected.toList(),
                  assignedToUid: memberUid,
                );
                if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${selected.length} task(s)')),
                  );
                }
              }

              Future<void> addTyped() async {
                final names = _splitNames(c.text);
                if (names.isEmpty) return;
                await taskProv.addTasksBulkCloud(
                  names,
                  assignedToUid: memberUid,
                );
                if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${names.length} task(s)')),
                  );
                }
              }

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
                          "Add task for $memberLabel",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      hintText: "Enter tasks (comma or new line)…",
                      helperText: "Example: Laundry, Dishes, Take out trash",
                      prefixIcon: Icon(Icons.task_alt),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => addTyped(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 10),
                  if (suggestions.isNotEmpty) ...[
                    Text(
                      "Suggestions",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestions.map((name) {
                            final isSel = selected.contains(name);
                            return FilterChip(
                              label: Text(name),
                              selected: isSel,
                              onSelected: (v) {
                                setLocal(() {
                                  if (v) {
                                    selected.add(name);
                                  } else {
                                    selected.remove(name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text("Add typed list"),
                        onPressed: addTyped,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.library_add_check),
                        label: Text(
                          selected.isEmpty
                              ? "Add selected"
                              : "Add selected (${selected.length})",
                        ),
                        onPressed: selected.isEmpty ? null : addSelected,
                      ),
                    ],
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
    final memberLabel = widget.memberName;
    final itemProv = context.read<ItemCloudProvider>();

    const defaultItems = AppLists.defaultItems;
    final frequent = itemProv.frequentItems;
    final existing = itemProv.items.map((i) => i.name).toList();
    final suggestions =
        {
            ...frequent,
            ...defaultItems,
            ...existing,
          }.where((s) => s.trim().isNotEmpty).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final c = TextEditingController();
    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              Future<void> addSelected() async {
                if (selected.isEmpty) return;
                await itemProv.addItemsBulkCloud(
                  selected.toList(),
                  assignedToUid: memberUid,
                );
                if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${selected.length} item(s)')),
                  );
                }
              }

              Future<void> addTyped() async {
                final names = _splitNames(c.text);
                if (names.isEmpty) return;
                await itemProv.addItemsBulkCloud(
                  names,
                  assignedToUid: memberUid,
                );
                if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${names.length} item(s)')),
                  );
                }
              }

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
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      hintText: "Enter items (comma or new line)…",
                      helperText: "Example: Milk, Bread, Eggs",
                      prefixIcon: Icon(Icons.shopping_bag),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => addTyped(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 10),
                  if (suggestions.isNotEmpty) ...[
                    Text(
                      "Suggestions",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestions.map((name) {
                            final isSel = selected.contains(name);
                            return FilterChip(
                              label: Text(name),
                              selected: isSel,
                              onSelected: (v) {
                                setLocal(() {
                                  if (v) {
                                    selected.add(name);
                                  } else {
                                    selected.remove(name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text("Add typed list"),
                        onPressed: addTyped,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.library_add_check),
                        label: Text(
                          selected.isEmpty
                              ? "Add selected"
                              : "Add selected (${selected.length})",
                        ),
                        onPressed: selected.isEmpty ? null : addSelected,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // void _openQuickAddTaskSheet(BuildContext context, String memberUid) {
  //   final memberLabel = widget.memberName; // sadece başlıkta göstermek için
  //   final taskProv = context.read<TaskCloudProvider>();
  //
  //   const defaultTasks = AppLists.defaultTasks;
  //   final frequent = taskProv.suggestedTasks;
  //   final existing = taskProv.tasks.map((t) => t.name).toList();
  //   final suggestions = {
  //     ...frequent,
  //     ...defaultTasks,
  //     ...existing,
  //   }.where((s) => s.trim().isNotEmpty).toList();
  //
  //   final c = TextEditingController();
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           left: 16,
  //           right: 16,
  //           top: 12,
  //           bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
  //         ),
  //         child: StatefulBuilder(
  //           builder: (ctx, setLocal) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // handle + başlık
  //                 Center(
  //                   child: Container(
  //                     width: 36,
  //                     height: 4,
  //                     margin: const EdgeInsets.only(bottom: 10),
  //                     decoration: BoxDecoration(
  //                       color: Theme.of(context).dividerColor,
  //                       borderRadius: BorderRadius.circular(99),
  //                     ),
  //                   ),
  //                 ),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Text(
  //                         "Add task for $memberLabel",
  //                         style: const TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                     ),
  //                     IconButton(
  //                       icon: const Icon(Icons.close),
  //                       onPressed: () => Navigator.pop(context),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 TextField(
  //                   controller: c,
  //                   decoration: const InputDecoration(
  //                     hintText: "Enter task…",
  //                     prefixIcon: Icon(Icons.task_alt),
  //                     border: OutlineInputBorder(),
  //                     isDense: true,
  //                   ),
  //                   onSubmitted: (_) =>
  //                       _assignOrCreateTask(context, c.text, memberUid),
  //                 ),
  //                 const SizedBox(height: 12),
  //                 if (suggestions.isNotEmpty) ...[
  //                   Text(
  //                     "Suggestions",
  //                     style: Theme.of(context).textTheme.labelLarge,
  //                   ),
  //                   const SizedBox(height: 6),
  //                   ConstrainedBox(
  //                     constraints: const BoxConstraints(maxHeight: 150),
  //                     child: SingleChildScrollView(
  //                       child: Wrap(
  //                         spacing: 6,
  //                         runSpacing: 6,
  //                         children: suggestions.map((name) {
  //                           return ActionChip(
  //                             label: Text(name),
  //                             onPressed: () =>
  //                                 _assignOrCreateTask(context, name, memberUid),
  //                           );
  //                         }).toList(),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 12),
  //                 ],
  //                 Align(
  //                   alignment: Alignment.centerRight,
  //                   child: FilledButton.icon(
  //                     icon: const Icon(Icons.add),
  //                     label: const Text("Add"),
  //                     onPressed: () =>
  //                         _assignOrCreateTask(context, c.text, memberUid),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _openQuickAddItemSheet(BuildContext context, String memberUid) {
  //   final memberLabel = widget.memberName; // sadece başlık için
  //   final itemProv = context.read<ItemCloudProvider>();
  //
  //   const defaultItems = AppLists.defaultItems;
  //   final frequent = itemProv.frequentItems;
  //   final existing = itemProv.items.map((i) => i.name).toList();
  //   final suggestions = {
  //     ...frequent,
  //     ...defaultItems,
  //     ...existing,
  //   }.where((s) => s.trim().isNotEmpty).toList();
  //
  //   final c = TextEditingController();
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           left: 16,
  //           right: 16,
  //           top: 12,
  //           bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
  //         ),
  //         child: StatefulBuilder(
  //           builder: (ctx, setLocal) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 36,
  //                     height: 4,
  //                     margin: const EdgeInsets.only(bottom: 10),
  //                     decoration: BoxDecoration(
  //                       color: Theme.of(context).dividerColor,
  //                       borderRadius: BorderRadius.circular(99),
  //                     ),
  //                   ),
  //                 ),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Text(
  //                         "Add item for $memberLabel",
  //                         style: const TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                     ),
  //                     IconButton(
  //                       icon: const Icon(Icons.close),
  //                       onPressed: () => Navigator.pop(context),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 TextField(
  //                   controller: c,
  //                   decoration: const InputDecoration(
  //                     hintText: "Enter item…",
  //                     prefixIcon: Icon(Icons.shopping_bag),
  //                     border: OutlineInputBorder(),
  //                     isDense: true,
  //                   ),
  //                   onSubmitted: (_) =>
  //                       _assignOrCreateItem(context, c.text, memberUid),
  //                 ),
  //                 const SizedBox(height: 12),
  //                 if (suggestions.isNotEmpty) ...[
  //                   Text(
  //                     "Suggestions",
  //                     style: Theme.of(context).textTheme.labelLarge,
  //                   ),
  //                   const SizedBox(height: 6),
  //                   ConstrainedBox(
  //                     constraints: const BoxConstraints(maxHeight: 150),
  //                     child: SingleChildScrollView(
  //                       child: Wrap(
  //                         spacing: 6,
  //                         runSpacing: 6,
  //                         children: suggestions.map((name) {
  //                           return ActionChip(
  //                             label: Text(name),
  //                             onPressed: () =>
  //                                 _assignOrCreateItem(context, name, memberUid),
  //                           );
  //                         }).toList(),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 12),
  //                 ],
  //                 Align(
  //                   alignment: Alignment.centerRight,
  //                   child: FilledButton.icon(
  //                     icon: const Icon(Icons.add),
  //                     label: const Text("Add"),
  //                     onPressed: () =>
  //                         _assignOrCreateItem(context, c.text, memberUid),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }
}

List<String> _splitNames(String raw) {
  // virgül, satır sonu, noktalı virgül ayırıcıları
  final parts = raw
      .split(RegExp(r'[,;\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  // tekrarları kaldır
  final seen = <String>{};
  final out = <String>[];
  for (final p in parts) {
    final key = p.toLowerCase();
    if (seen.add(key)) out.add(p);
  }
  return out;
}
