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
import '../../widgets/member_dropdown_uid.dart';
import '../../widgets/section_lists.dart';
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
      return d.year == now.year && d.month == now.month;
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

Future<void> _showGroupedSheet<T>({
  required BuildContext context,
  required String Function(BuildContext ctx, List<T> list) titleBuilder,
  required Iterable<T> Function(BuildContext ctx) sourceSelector,
  // required IconData leadingIcon,
  required void Function(BuildContext ctx, T item) onTogglePrimary,
  required void Function(BuildContext ctx, T item) onDelete,
  required String Function(T item) getName,
  required String Function(T item) getAssignedTo,
  required String sectionTitle,
  void Function(BuildContext ctx, T item)? onEdit,
  void Function(BuildContext ctx, T item)? onAssign,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          // her setLocal’da veriyi taze çek
          final list = sourceSelector(ctx).toList();

          Future<void> runAndRefresh(FutureOr<void> Function() fn) async {
            await Future.sync(fn);
            if (ctx.mounted) setLocal(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleBuilder(ctx, list),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('No ${sectionTitle.toLowerCase()}'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = list[i];
                        final who = getAssignedTo(e);

                        return ListTile(
                          dense: false,
                          visualDensity: const VisualDensity(
                            horizontal: -3,
                            vertical: -3,
                          ),
                          minLeadingWidth: 30,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          // leading: Icon(leadingIcon, size: 20),
                          title: Text(
                            getName(e),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: who.isEmpty ? null : Text('👤 $who'),
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              if (onAssign != null)
                                IconButton(
                                  tooltip: 'Assign',
                                  icon: const Icon(
                                    Icons.person_add_alt,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      runAndRefresh(() => onAssign(ctx, e)),
                                ),
                              if (onEdit != null)
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      runAndRefresh(() => onEdit(ctx, e)),
                                ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    runAndRefresh(() => onDelete(ctx, e)),
                              ),
                            ],
                          ),
                          onTap: () =>
                              runAndRefresh(() => onTogglePrimary(ctx, e)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
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
                  final display = selectedUid == null
                      ? 'Unassigned'
                      : (dict[selectedUid] ?? 'Member');

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
  // read: dialog builder içinde listen etmeden veri çekiyoruz
  final taskProv = context.read<TaskCloudProvider>();
  final tasks = taskProv.tasks.where((t) => !t.completed).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final pending = taskProv.tasks.where((t) => !t.completed).toList();

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('   All Pending Tasks  📑 '),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 480),
        child: tasks.isEmpty
            ? const Text('No pending tasks')
            : SingleChildScrollView(
                child: TasksSection(
                  tasks: pending,
                  expanded: true,
                  previewCount: 999, // her şeyi göster
                  onToggleTask: (t) => context
                      .read<TaskCloudProvider>()
                      .toggleTask(t, !t.completed),
                  onToggleExpand: null, // “show all” linkini gizlemek için
                  showHeader: false, // başlığı tekrarlamayalım
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          child: const Text('Details'),
          onPressed: () {
            Navigator.pop(context);
            showPendingTasksSheet(context); // alt sheet istersen
          },
        ),
      ],
    ),
  );
}

Future<void> showToBuyItemsDialog(BuildContext context) async {
  final itemProv = context.read<ItemCloudProvider>();
  final items = itemProv.items.where((i) => !i.bought).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final toBuy = itemProv.items.where((i) => !i.bought).toList();

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('   All Items to Buy  🛍️   '),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 480),
        child: items.isEmpty
            ? const Text('No items to buy')
            : SingleChildScrollView(
                child: ItemsSection(
                  items: toBuy,
                  expanded: true,
                  previewCount: 999,
                  onToggleItem: (it) => context
                      .read<ItemCloudProvider>()
                      .toggleItem(it, !it.bought),
                  onToggleExpand: null,
                  showHeader: false,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // mevcut quick add kullan
            showToBuyItemsSheet(context); // alt sheet tercih edersen
          },
          child: const Text('Details'),
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
