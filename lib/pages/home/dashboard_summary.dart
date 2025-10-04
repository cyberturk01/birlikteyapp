import 'dart:async';

import 'package:birlikteyapp/models/weekly_task_cloud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskCloudProvider>().tasks;
    final items = context.watch<ItemCloudProvider>().items;

    // BUGÜN'e ait weekly sayısı
    final String todayName = DateFormat('EEEE').format(DateTime.now());
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

    final t = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 720;
        final cards = <Widget>[
          _SummaryCard(
            icon: Icons.task_alt,
            title: t.tasks,
            value: '$pendingTasks',
            subtitle: t.pendingToday,
            onTap: () {
              onTap(SummaryDest.tasks);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showPendingTasksDialog(context);
              });
            },
          ),
          _SummaryCard(
            icon: Icons.shopping_cart,
            title: t.market,
            value: '$toBuyItems',
            subtitle: t.toBuy,
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
            title: t.expenses,
            value: '$todayExpenses',
            subtitle: t.totalRecords,
            onTap: () => onTap(SummaryDest.expenses),
          ),
          _SummaryCard(
            icon: Icons.calendar_today,
            title: t.weekly,
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
  final t = AppLocalizations.of(context)!;
  await showGroupedByMemberSheet<Task>(
    context: context,
    titleAll: t.pendingTasks,
    titleMine: t.myTasks,
    titleUnassigned: t.unassigned,
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
  final t = AppLocalizations.of(context)!;
  await showGroupedByMemberSheet<Item>(
    context: context,
    titleAll: t.toBuy,
    titleMine: t.myTasks,
    titleUnassigned: t.unassigned,
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
  final t = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: task.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editTask),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: t.taskName,
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
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            context.read<TaskCloudProvider>().renameTask(
              task,
              ctrl.text.trim(),
            );
            Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

void _showRenameItemDialog(BuildContext context, Item item) {
  final t = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: item.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editItem),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: t.itemName,
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
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            context.read<ItemCloudProvider>().renameItem(
              item,
              ctrl.text.trim(),
            );
            Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

void _showAssignTaskSheet(BuildContext context, Task task) {
  final t = AppLocalizations.of(context)!;
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
            Text(
              t.assignTask,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            MemberDropdownUid(
              value: selectedUid,
              onChanged: (v) => setLocal(() => selectedUid = v),
              label: t.assignTo,
              nullLabel: t.noOne,
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
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                child: Text(t.save),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAssignItemSheet(BuildContext context, Item item) {
  final t = AppLocalizations.of(context)!;
  String? selectedUid = item.assignedToUid;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.assignItem,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

                  final items = <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(t.noOne),
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
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      labelText: t.assignTo,
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
              onPressed: () async {
                await context.read<ItemCloudProvider>().updateAssignment(
                  item,
                  (selectedUid != null && selectedUid!.trim().isNotEmpty)
                      ? selectedUid
                      : null,
                );
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Text(t.save),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showPendingTasksDialog(BuildContext context) async {
  final t = AppLocalizations.of(context)!;
  final taskProv = context.read<TaskCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();

  await showModalBottomSheet(
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
                    Expanded(
                      child: Text(
                        t.pendingTasks,
                        style: const TextStyle(
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
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.searchTasks,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 10),

                StreamBuilder<Map<String, String>>(
                  stream: famDictStream, // {uid: label}
                  builder: (_, snap) {
                    final dict = snap.data ?? const <String, String>{};
                    final chips = buildAssigneeChips(
                      context: context,
                      dict: dict,
                      selected: memberFilter,
                      onPick: (v) => setLocal(() => memberFilter = v),
                      allLabel: t.allLabel,
                      unassignedLabel: t.unassigned,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            t.filterByAssignee,
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
                            segments: [
                              ButtonSegment(
                                value: false,
                                icon: const Icon(Icons.timelapse),
                                label: Text(t.pendingLabel),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: const Icon(Icons.all_inclusive),
                                label: Text(t.allLabel),
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
                      ? Center(child: Text(t.noTasks))
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
                      label: Text(t.clearCompleted),
                      onPressed: () async {
                        await context.read<TaskCloudProvider>().clearCompleted(
                          forMember:
                              (memberFilter == null || memberFilter!.isEmpty)
                              ? null
                              : memberFilter,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.completedTasksCleared)),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: Text(t.markAllDone),
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
    final t = AppLocalizations.of(context)!;
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
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: Text(t.editDueReminder),
            ),
          ),
          PopupMenuItem(
            value: 'rename',
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t.rename),
            ),
          ),
          PopupMenuItem(
            value: 'assign',
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(t.assign),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t.delete),
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

List<Widget> buildAssigneeChips({
  required BuildContext context,
  required Map<String, String> dict, // {uid: label}
  required String? selected, // memberFilter
  required void Function(String?) onPick, // setLocal(() => memberFilter = ...)
  required String allLabel, // t.allLabel
  required String unassignedLabel, // t.unassigned
}) {
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  // dict'i listeye çevir ve "ben" ilk sıraya, kalanları ada göre sırala
  final entries = dict.entries.toList()
    ..sort((a, b) {
      if (a.key == myUid && b.key != myUid) return -1; // ben önce
      if (b.key == myUid && a.key != myUid) return 1;
      return a.value.toLowerCase().compareTo(b.value.toLowerCase());
    });

  return <Widget>[
    FilterChip(
      label: Text(allLabel),
      selected: selected == null,
      onSelected: (_) => onPick(null),
    ),
    FilterChip(
      label: Text(unassignedLabel),
      selected: selected == '',
      onSelected: (_) => onPick(''),
    ),
    ...entries.map(
      (e) => FilterChip(
        label: Text(e.value),
        selected: selected == e.key,
        onSelected: (_) => onPick(e.key),
      ),
    ),
  ];
}

void _renameInline(BuildContext context, Task task) {
  final t = AppLocalizations.of(context)!;
  final c = TextEditingController(text: task.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editTask),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          hintText: t.taskName,
        ),
        onSubmitted: (_) {
          context.read<TaskCloudProvider>().renameTask(task, c.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            context.read<TaskCloudProvider>().renameTask(task, c.text.trim());
            Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

Future<void> showToBuyItemsDialog(BuildContext context) async {
  final itemProv = context.read<ItemCloudProvider>();
  final famDictStream = context.read<FamilyProvider>().watchMemberDirectory();
  final t = AppLocalizations.of(context)!;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetCtx) {
      final searchC = TextEditingController();
      String? memberFilter;
      bool showBought = false;

      return StatefulBuilder(
        builder: (ctx, setLocal) {
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
                    Expanded(
                      child: Text(
                        t.items,
                        style: const TextStyle(
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
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.searchItems,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 10),

                // Filtre bar: Üye chipleri + alt satırda To buy / All
                StreamBuilder<Map<String, String>>(
                  stream: famDictStream,
                  builder: (_, snap) {
                    final dict = snap.data ?? const <String, String>{};

                    final chips = buildAssigneeChips(
                      context: context,
                      dict: dict,
                      selected: memberFilter,
                      onPick: (v) => setLocal(() => memberFilter = v),
                      allLabel: t.allLabel,
                      unassignedLabel: t.unassigned,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            t.filterByAssignee,
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
                            segments: [
                              ButtonSegment(
                                value: false,
                                icon: const Icon(Icons.shopping_basket),
                                label: Text(t.toBuy),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: const Icon(Icons.all_inclusive),
                                label: Text(t.allLabel),
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
                      ? Center(child: Text(t.noItems))
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
                      label: Text(t.clearBought),
                      onPressed: () async {
                        await context.read<ItemCloudProvider>().clearBought(
                          forMember:
                              (memberFilter == null || memberFilter!.isEmpty)
                              ? null
                              : memberFilter,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.boughtItemsCleared)),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: Text(t.markAllBought),
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
    final t = AppLocalizations.of(context)!;

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
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'rename',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.edit),
              title: Text(t.rename),
            ),
          ),
          PopupMenuItem(
            value: 'assign',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.person_add_alt),
              title: Text(t.assign),
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
              title: Text(t.delete),
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
  final t = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editItem),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: t.itemName,
        ),
        onSubmitted: (_) {
          context.read<ItemCloudProvider>().renameItem(it, c.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            context.read<ItemCloudProvider>().renameItem(it, c.text.trim());
            Navigator.pop(context);
          },
          child: Text(t.save),
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
