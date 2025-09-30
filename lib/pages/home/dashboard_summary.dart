import 'dart:async';

import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/weekly_cloud_provider.dart';
import '../../widgets/due_pill.dart';
import '../../widgets/member_dropdown_uid.dart';
import '../../widgets/task_edit_dialog.dart';
import 'grouped_sheet.dart';

enum SummaryDest { tasks, items, weekly, expenses }

typedef DashboardTap = void Function(SummaryDest dest);

class DashboardSummaryBar extends StatelessWidget {
  final DashboardTap onTap;
  const DashboardSummaryBar({super.key, required this.onTap});

  String _weekdayName(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskCloudProvider>().tasks;
    final items = context.watch<ItemCloudProvider>().items;

    // BUGÜN'e ait weekly sayısı
    final String todayName = _weekdayName(DateTime.now());
    final weeklyProv = Provider.of<WeeklyCloudProvider?>(context, listen: true);
    final List<WeeklyTaskCloud> todaysWeekly =
        weeklyProv?.tasksForDay(todayName) ?? const [];

    final expProv = context.watch<ExpenseCloudProvider>();
    final expensesWatch = expProv.all;

    final pendingTasks = tasks.where((t) => !t.completed).length;
    final toBuyItems = items.where((i) => !i.bought).length;
    final now = DateTime.now();
    final todayOnly = expensesWatch.where((e) {
      final d = DateUtils.dateOnly(e.date); // e.date bir DateTime olmalı
      return DateUtils.isSameDay(d, now);
    }).toList();

    final todayExpenses = todayOnly.length;
    debugPrint(
      '[Summary] expenses(all)=${expensesWatch.length}, today=$todayExpenses',
    );

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 720;
        final cards = <Widget>[
          _SummaryCard(
            icon: Icons.task_alt,
            title: 'Tasks',
            value: '$pendingTasks',
            subtitle: 'Pending today',
            onTap: () {
              onTap(SummaryDest.tasks);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showPendingTasksDialog(context);
              });
            },
          ),
          _SummaryCard(
            icon: Icons.shopping_cart,
            title: 'Market',
            value: '$toBuyItems',
            subtitle: 'To buy',
            onTap: () {
              onTap(SummaryDest.items);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showToBuyItemsDialog(context);
              });
            },
          ),
          // Expenses kutusu (opsiyonel). Provider yoksa sayacı 0 gösterelim.
          _SummaryCard(
            icon: Icons.payments,
            title: 'Expenses',
            value: '$todayExpenses',
            subtitle: 'Total records',
            onTap: () => onTap(SummaryDest.expenses),
          ),
          _SummaryCard(
            icon: Icons.calendar_today,
            title: 'Weekly',
            value: '${todaysWeekly.length}',
            subtitle: todayName,
            onTap: () => onTap(SummaryDest.weekly),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: isWide
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.start,
              children: cards
                  .map(
                    (w) => SizedBox(
                      width: isWide
                          ? (c.maxWidth - 36) / 4
                          : (c.maxWidth - 12) / 2,
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showPendingTasksSheet(BuildContext context) async {
  await showGroupedByMemberSheet<Task>(
    context: context,
    titleAll: 'Pending tasks',
    titleMine: 'My tasks',
    titleUnassigned: 'Unassigned',
    sourceSelector: (ctx) =>
        ctx.watch<TaskCloudProvider>().tasks.where((t) => !t.completed),
    getName: (t) => t.name,
    getAssignedUid: (t) => t.assignedToUid,
    onTogglePrimary: (ctx, t) =>
        ctx.read<TaskCloudProvider>().toggleTask(t, true),
    onDelete: (ctx, t) => ctx.read<TaskCloudProvider>().removeTask(t),
    onEdit: (ctx, t) => _showRenameTaskDialog(ctx, t),
    onAssign: (ctx, t) => _showAssignTaskSheet(ctx, t),
  );
}

Future<void> showToBuyItemsSheet(BuildContext context) async {
  await showGroupedByMemberSheet<Item>(
    context: context,
    titleAll: 'To buy',
    titleMine: 'My list',
    titleUnassigned: 'Unassigned',
    sourceSelector: (ctx) =>
        ctx.watch<ItemCloudProvider>().items.where((i) => !i.bought),
    getName: (it) => it.name,
    getAssignedUid: (it) => it.assignedToUid,
    onTogglePrimary: (ctx, it) =>
        ctx.read<ItemCloudProvider>().toggleItem(it, true),
    onDelete: (ctx, it) => ctx.read<ItemCloudProvider>().removeItem(it),
    onEdit: (ctx, it) => _showRenameItemDialog(ctx, it),
    onAssign: (ctx, it) => _showAssignItemSheet(ctx, it),
  );
}

void _showRenameTaskDialog(BuildContext context, Task task) {
  final ctrl = TextEditingController(text: task.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit task'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Task name',
          isDense: true,
        ),
        onSubmitted: (_) {
          context.read<TaskCloudProvider>().renameTask(task, ctrl.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<TaskCloudProvider>().renameTask(
              task,
              ctrl.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showRenameItemDialog(BuildContext context, Item item) {
  final ctrl = TextEditingController(text: item.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit item'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Item name',
          isDense: true,
        ),
        onSubmitted: (_) {
          context.read<ItemCloudProvider>().renameItem(item, ctrl.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<ItemCloudProvider>().renameItem(
              item,
              ctrl.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showAssignTaskSheet(BuildContext context, Task task) {
  String? selectedUid = task.assignedToUid;

  final taskCloud = context.read<TaskCloudProvider>();
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign task',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            MemberDropdownUid(
              value: selectedUid,
              onChanged: (v) => setLocal(() => selectedUid = v),
              label: 'Assign to',
              nullLabel: 'No one',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await taskCloud.updateAssignment(
                    task,
                    (selectedUid != null && selectedUid!.trim().isNotEmpty)
                        ? selectedUid
                        : null,
                  );
                  taskCloud.refreshNow();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAssignItemSheet(BuildContext context, Item item) {
  String? selectedUid = item.assignedToUid;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Assign item',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StatefulBuilder(
            builder: (ctx, setLocal) {
              return StreamBuilder<Map<String, String>>(
                stream: context
                    .read<FamilyProvider>()
                    .watchMemberDirectory(), // {uid: label}
                builder: (ctx, snap) {
                  final dict = snap.data ?? const <String, String>{};

                  // Dropdown item'ları: value = uid, görünen = label
                  final items = <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No one'),
                    ),
                    ...dict.entries.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    ),
                  ];

                  // Eğer selectedUid artık dict'te yoksa (ör. üye ayrıldı) null'a düş
                  final value = dict.containsKey(selectedUid)
                      ? selectedUid
                      : null;

                  return DropdownButtonFormField<String?>(
                    value: value,
                    isExpanded: true,
                    items: items,
                    onChanged: (v) => setLocal(() => selectedUid = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Assign to',
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<ItemCloudProvider>().updateAssignment(
                  item,
                  (selectedUid != null && selectedUid!.trim().isNotEmpty)
                      ? selectedUid
                      : null,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showPendingTasksDialog(BuildContext context) async {
  final taskProv = context.read<TaskCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetCtx) {
      final searchC = TextEditingController();
      String? memberFilter; // null=All, ''=Unassigned, 'uid'=member
      bool showCompleted = false;

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          // veriyi hazırla
          final all = taskProv.tasks.toList();
          all.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          final pending = all.where((t) => !t.completed).toList();

          // filtreler
          Iterable<Task> src = showCompleted ? all : pending;
          if (memberFilter != null) {
            src = src.where(
              (t) =>
                  (memberFilter!.isEmpty &&
                      (t.assignedToUid == null || t.assignedToUid!.isEmpty)) ||
                  (memberFilter!.isNotEmpty && t.assignedToUid == memberFilter),
            );
          }
          final q = searchC.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            src = src.where((t) => t.name.toLowerCase().contains(q));
          }
          final list = src.toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                // Header
                Row(
                  children: [
                    const Icon(Icons.task_alt, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pending tasks',
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

                // Arama
                TextField(
                  controller: searchC,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search tasks…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 10),

                // Filtre bar: Üye filtresi + Pending/All toggle
                StreamBuilder<Map<String, String>>(
                  stream: famDictStream, // {uid: label}
                  builder: (_, snap) {
                    final dict = snap.data ?? const <String, String>{};
                    final chips = <Widget>[
                      FilterChip(
                        label: const Text('All'),
                        selected: memberFilter == null,
                        onSelected: (_) => setLocal(() => memberFilter = null),
                      ),
                      FilterChip(
                        label: const Text('Unassigned'),
                        selected: memberFilter == '',
                        onSelected: (_) => setLocal(() => memberFilter = ''),
                      ),
                      ...dict.entries.map(
                        (e) => FilterChip(
                          label: Text(e.value),
                          selected: memberFilter == e.key,
                          onSelected: (_) =>
                              setLocal(() => memberFilter = e.key),
                        ),
                      ),
                    ];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Filter by assignee',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        // üst satır: chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: chips
                                .map(
                                  (w) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: w,
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // alt satır: pending / all toggle
                        Center(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.timelapse),
                                label: Text('Pending'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.all_inclusive),
                                label: Text('All'),
                              ),
                            ],
                            selected: {showCompleted},
                            showSelectedIcon: false,
                            onSelectionChanged: (s) =>
                                setLocal(() => showCompleted = s.first),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Liste
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No tasks'))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
                          cacheExtent: 800,
                          itemBuilder: (_, i) => _TaskRowCompact(
                            task: list[i],
                            onToggle: (t, v) async {
                              await context
                                  .read<TaskCloudProvider>()
                                  .toggleTask(t, v);
                            },
                            onRename: (t) => _renameInline(context, t),
                            onDelete: (t) =>
                                context.read<TaskCloudProvider>().removeTask(t),
                            onAssign: (t) => _showAssignTaskSheet(context, t),
                          ),
                        ),
                ),

                const SizedBox(height: 8),
                // Alt aksiyonlar
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear completed'),
                      onPressed: () async {
                        await context.read<TaskCloudProvider>().clearCompleted(
                          forMember:
                              (memberFilter == null || memberFilter!.isEmpty)
                              ? null
                              : memberFilter,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completed tasks cleared'),
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark all done'),
                      onPressed: list.isEmpty
                          ? null
                          : () async {
                              for (final t in list.where((t) => !t.completed)) {
                                await context
                                    .read<TaskCloudProvider>()
                                    .toggleTask(t, true);
                              }
                            },
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

class _TaskRowCompact extends StatelessWidget {
  final Task task;
  final Future<void> Function(Task task, bool value) onToggle;
  final void Function(Task task) onRename;
  final void Function(Task task) onDelete;
  final void Function(Task task) onAssign;

  const _TaskRowCompact({
    required this.task,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.completed;
    final DateTime? dueAt = (task as dynamic).dueAt as DateTime?;

    final cs = Theme.of(context).colorScheme;

    Widget? duePill;
    if (dueAt != null) {
      final st = _dueStatus(dueAt);
      final String? label = (dueAt == null)
          ? null
          : '${dueAt.day}.${dueAt.month}.${dueAt.year % 100}';
      duePill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _dueBg(cs, st),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event, size: 12, color: _dueFg(cs, st)),
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _dueFg(cs, st),
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),

      leading: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onToggle(task, !isDone),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: 2,
            ),
            color: isDone
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : null,
          ),
          child: isDone ? const Icon(Icons.check, size: 16) : null,
        ),
      ),

      title: Row(
        children: [
          Expanded(
            child: Text(
              task.name,
              overflow: TextOverflow.ellipsis,
              style: isDone
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
          ),
          if ((task as dynamic).dueAt != null) ...[
            const SizedBox(width: 8),
            DuePill(
              dueAt: (task as dynamic).dueAt as DateTime?,
              reminderAt: (task as dynamic).reminderAt as DateTime?,
            ),
          ],
        ],
      ),

      onTap: () => onToggle(task, !isDone),

      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'edit':
              showTaskEditDialog(context, task);
              break;
            case 'rename':
              onRename(task);
              break;
            case 'assign':
              onAssign(task);
              break;
            case 'delete':
              onDelete(task);
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.tune),
              title: Text('Edit (due/reminder)'),
            ),
          ),
          PopupMenuItem(
            value: 'rename',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Rename')),
          ),
          PopupMenuItem(
            value: 'assign',
            child: ListTile(leading: Icon(Icons.person), title: Text('Assign')),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DueStatus { overdue, today, soon, later }

_DueStatus _dueStatus(DateTime d) {
  final now = DateTime.now();
  final a = DateUtils.dateOnly(d);
  final b = DateUtils.dateOnly(now);

  if (a.isBefore(b)) return _DueStatus.overdue;
  if (a == b) return _DueStatus.today;

  final diff = a.difference(b).inDays;
  if (diff <= 3) return _DueStatus.soon;
  return _DueStatus.later;
}

Color _dueBg(ColorScheme cs, _DueStatus s) {
  switch (s) {
    case _DueStatus.overdue:
      return cs.errorContainer;
    case _DueStatus.today:
      return cs.tertiaryContainer;
    case _DueStatus.soon:
      return cs.secondaryContainer;
    case _DueStatus.later:
      return cs.surfaceContainerHighest;
  }
}

Color _dueFg(ColorScheme cs, _DueStatus s) {
  switch (s) {
    case _DueStatus.overdue:
      return cs.onErrorContainer;
    case _DueStatus.today:
      return cs.onTertiaryContainer;
    case _DueStatus.soon:
      return cs.onSecondaryContainer;
    case _DueStatus.later:
      return cs.onSurfaceVariant;
  }
}

void _renameInline(BuildContext context, Task task) {
  final c = TextEditingController(text: task.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit task'),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          hintText: 'Task name',
        ),
        onSubmitted: (_) {
          context.read<TaskCloudProvider>().renameTask(task, c.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<TaskCloudProvider>().renameTask(task, c.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showToBuyItemsDialog(BuildContext context) async {
  final itemProv = context.read<ItemCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetCtx) {
      final searchC = TextEditingController();
      String? memberFilter; // null=All, ''=Unassigned, 'uid'
      bool showBought = false; // false => sadece to-buy, true => tümü

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          // veri + sıralama
          final all = itemProv.items.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          final toBuy = all.where((i) => !i.bought).toList();

          // filtreler
          Iterable<Item> src = showBought ? all : toBuy;
          if (memberFilter != null) {
            src = src.where(
              (it) =>
                  (memberFilter!.isEmpty &&
                      (it.assignedToUid == null ||
                          it.assignedToUid!.isEmpty)) ||
                  (memberFilter!.isNotEmpty &&
                      it.assignedToUid == memberFilter),
            );
          }
          final q = searchC.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            src = src.where((it) => it.name.toLowerCase().contains(q));
          }
          final list = src.toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                // Header
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Items',
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

                // Arama
                TextField(
                  controller: searchC,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search items…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 10),

                // Filtre bar: Üye chipleri + alt satırda To buy / All
                StreamBuilder<Map<String, String>>(
                  stream: famDictStream,
                  builder: (_, snap) {
                    final dict = snap.data ?? const <String, String>{};

                    final chips = <Widget>[
                      FilterChip(
                        label: const Text('All'),
                        selected: memberFilter == null,
                        onSelected: (_) => setLocal(() => memberFilter = null),
                      ),
                      FilterChip(
                        label: const Text('Unassigned'),
                        selected: memberFilter == '',
                        onSelected: (_) => setLocal(() => memberFilter = ''),
                      ),
                      ...dict.entries.map(
                        (e) => FilterChip(
                          label: Text(e.value),
                          selected: memberFilter == e.key,
                          onSelected: (_) =>
                              setLocal(() => memberFilter = e.key),
                        ),
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Filter by assignee',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        // üst satır: chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: chips
                                .map(
                                  (w) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: w,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // alt satır: To buy / All
                        Center(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.shopping_basket),
                                label: Text('To buy'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.all_inclusive),
                                label: Text('All'),
                              ),
                            ],
                            selected: {showBought},
                            showSelectedIcon: false,
                            onSelectionChanged: (s) =>
                                setLocal(() => showBought = s.first),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Liste
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No items'))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
                          cacheExtent: 800,
                          itemBuilder: (_, i) => _ItemRowCompact(
                            item: list[i],
                            onToggle: (it, v) async {
                              await context
                                  .read<ItemCloudProvider>()
                                  .toggleItem(it, v);
                            },
                            onRename: (it) => _renameItemInline(context, it),
                            onDelete: (it) => context
                                .read<ItemCloudProvider>()
                                .removeItem(it),
                            onAssign: (it) => _showAssignItemSheet(context, it),
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // Alt aksiyonlar
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear bought'),
                      onPressed: () async {
                        await context.read<ItemCloudProvider>().clearBought(
                          forMember:
                              (memberFilter == null || memberFilter!.isEmpty)
                              ? null
                              : memberFilter,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bought items cleared'),
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark all bought'),
                      onPressed: list.where((it) => !it.bought).isEmpty
                          ? null
                          : () async {
                              for (final it in list.where((x) => !x.bought)) {
                                await context
                                    .read<ItemCloudProvider>()
                                    .toggleItem(it, true);
                              }
                            },
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

class _ItemRowCompact extends StatelessWidget {
  final Item item;
  final Future<void> Function(Item it, bool value) onToggle;
  final void Function(Item it) onRename;
  final void Function(Item it) onDelete;
  final void Function(Item it) onAssign;

  const _ItemRowCompact({
    required this.item,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final bought = item.bought;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Checkbox(
        value: bought,
        onChanged: (v) => onToggle(item, v ?? false),
      ),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
        style: bought
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'rename':
              onRename(item);
              break;
            case 'assign':
              onAssign(item);
              break;
            case 'delete':
              onDelete(item);
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'rename',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit),
              title: Text('Rename'),
            ),
          ),
          PopupMenuItem(
            value: 'assign',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.person_add_alt),
              title: Text('Assign'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Delete'),
            ),
          ),
        ],
      ),
      onTap: () => onToggle(item, !bought),
    );
  }
}

void _renameItemInline(BuildContext context, Item it) {
  final c = TextEditingController(text: it.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit item'),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          hintText: 'Item name',
        ),
        onSubmitted: (_) {
          context.read<ItemCloudProvider>().renameItem(it, c.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<ItemCloudProvider>().renameItem(it, c.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
