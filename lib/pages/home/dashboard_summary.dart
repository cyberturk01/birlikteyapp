import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/expense_cloud_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../widgets/due_pill.dart';
import '../../widgets/member_dropdown_uid.dart';
import '../../widgets/task_edit_dialog.dart';
import '../locations/location_card_ui.dart';
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

    final famProv = context.read<FamilyProvider>();
    final famId = famProv.familyId ?? '';

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
          // TASKS
          _SummaryCard(
            icon: Icons.task_alt,
            title: t.tasks,
            value: '$pendingTasks',
            subtitle: t.pendingToday,
            onTap: () {
              onTap(SummaryDest.tasks);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showPendingTasksDialog(context);
                }
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
                if (context.mounted) {
                  showToBuyItemsDialog(context);
                }
              });
            },
          ),
          _SummaryCard(
            icon: Icons.payments,
            title: t.expenses,
            value: '$todayExpenses',
            subtitle: t.totalRecords,
            onTap: () {
              onTap(SummaryDest.expenses);
            },
          ),
          LocationCard(familyId: famId),
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
      String? memberFilter; // null=All, ''=

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final all = ctx.watch<TaskCloudProvider>().tasks.toList();
          all.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          final pending = all.where((t) => !t.completed).toList();
          String? editingId;
          final TextEditingController renameC = TextEditingController();
          // filtreler
          Iterable<Task> src = pending;
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
                          itemBuilder: (_, i) {
                            final task = list[i];
                            final isEditing =
                                (editingId ==
                                task.remoteId); // remoteId yoksa name+origin kullan
                            return _TaskRowCompact(
                              task: task,
                              isEditing: isEditing,
                              initialText: isEditing ? renameC.text : task.name,
                              onStartInlineRename: (t) {
                                renameC.text = t.name;
                                setLocal(
                                  () => editingId =
                                      t.remoteId ?? '${t.origin}|${t.name}',
                                );
                              },
                              onSubmitInlineRename: (t, newName) async {
                                final v = newName.trim();
                                if (v.isNotEmpty && v != t.name) {
                                  await ctx
                                      .read<TaskCloudProvider>()
                                      .renameTask(t, v);
                                }
                                setLocal(() {
                                  editingId = null;
                                });
                              },
                              onCancelInlineRename: (_) {
                                setLocal(() {
                                  editingId = null;
                                });
                              },
                              onToggle: (t, v) async {
                                await context
                                    .read<TaskCloudProvider>()
                                    .toggleTask(t, v);
                              },
                              onRename: (t) {
                                // menüden "Rename" gelirse de inline’a al
                                renameC.text = t.name;
                                setLocal(
                                  () => editingId =
                                      t.remoteId ?? '${t.origin}|${t.name}',
                                );
                              },
                              onDelete: (t) => context
                                  .read<TaskCloudProvider>()
                                  .removeTask(t),
                              onAssign: (t) => _showAssignTaskSheet(context, t),
                            );
                          },
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
  final bool isEditing;
  final String initialText;
  final void Function(Task task) onStartInlineRename;
  final Future<void> Function(Task task, bool value) onToggle;
  final void Function(Task task) onRename;
  final void Function(Task task) onDelete;
  final void Function(Task task) onAssign;
  final Future<void> Function(Task task, String newName) onSubmitInlineRename;
  final void Function(Task task) onCancelInlineRename;

  const _TaskRowCompact({
    required this.task,
    required this.isEditing,
    required this.initialText,
    required this.onStartInlineRename,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAssign,
    required this.onSubmitInlineRename,
    required this.onCancelInlineRename,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.completed;
    final t = AppLocalizations.of(context)!;

    Widget titleWidget;
    if (isEditing) {
      final ctrl = TextEditingController(text: initialText);
      titleWidget = Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) onCancelInlineRename(task);
        },
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event.logicalKey == LogicalKeyboardKey.escape &&
                event is KeyDownEvent) {
              onCancelInlineRename(task);
            }
          },
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onSubmitted: (v) => onSubmitInlineRename(task, v),
          ),
        ),
      );
    } else {
      titleWidget = Row(
        children: [
          Expanded(
            child: Text(
              task.name,
              overflow: TextOverflow.ellipsis,
              style: task.completed
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
      );
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),

      leading: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onToggle(task, !task.completed),
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

      title: titleWidget,

      onTap: () => onToggle(task, !task.completed),
      onLongPress: () => onStartInlineRename(task),

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

List<Widget> buildAssigneeChips({
  required BuildContext context,
  required Map<String, String> dict, // {uid: label}
  required String? selected, // memberFilter
  required void Function(String?) onPick, // setLocal(() => memberFilter = ...)
  required String allLabel, // t.allLabel
  required String unassignedLabel, // t.unassigned
}) {
  final myUid = FirebaseAuth.instance.currentUser?.uid;

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

Future<void> showToBuyItemsDialog(BuildContext context) async {
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
      String? editingId;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final all = ctx.watch<ItemCloudProvider>().items.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          final toBuy = all.where((i) => !i.bought).toList();

          // filtreler
          Iterable<Item> src = toBuy;
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
                      context: ctx,
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
                          itemBuilder: (_, i) {
                            final it = list[i];
                            return _ItemRowCompact(
                              item: it,
                              isEditing: editingId == it.remoteId,
                              onStartRename: (_) =>
                                  setLocal(() => editingId = it.remoteId),
                              onCancelRename: () =>
                                  setLocal(() => editingId = null),
                              onSaveRename: (item, newName) async {
                                await ctx.read<ItemCloudProvider>().renameItem(
                                  item,
                                  newName,
                                );
                                if (ctx.mounted) {
                                  setLocal(() => editingId = null);
                                }
                              },
                              onToggle: (item, v) async {
                                await ctx.read<ItemCloudProvider>().toggleItem(
                                  item,
                                  v,
                                );
                              },
                              onDelete: (item) async {
                                await ctx.read<ItemCloudProvider>().removeItem(
                                  item,
                                );
                                if (ctx.mounted && editingId == item.remoteId) {
                                  setLocal(() => editingId = null);
                                }
                              },
                              onAssign: (item) =>
                                  _showAssignItemSheet(ctx, item),
                            );
                          },
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
  final bool isEditing;
  final void Function(Item it) onStartRename;
  final void Function() onCancelRename;
  final Future<void> Function(Item it, String newName) onSaveRename;
  final Future<void> Function(Item it, bool value) onToggle;
  final void Function(Item it) onDelete;
  final void Function(Item it) onAssign;

  const _ItemRowCompact({
    required this.item,
    required this.isEditing,
    required this.onStartRename,
    required this.onCancelRename,
    required this.onSaveRename,
    required this.onToggle,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bought = item.bought;

    Widget titleWidget;
    if (isEditing) {
      final ctrl = TextEditingController(text: item.name);
      titleWidget = Focus(
        onFocusChange: (has) {
          if (!has) onCancelRename();
        },
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            hintText: t.itemName,
          ),
          onSubmitted: (v) async {
            final nn = v.trim();
            if (nn.isNotEmpty && nn != item.name) {
              await onSaveRename(item, nn);
            }
            onCancelRename();
          },
          onEditingComplete: () {}, // enter ile kapanmayı onSubmitted yapıyor
        ),
      );
    } else {
      titleWidget = Text(
        item.name,
        overflow: TextOverflow.ellipsis,
        style: bought
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      );
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Checkbox(
        value: bought,
        onChanged: (v) => onToggle(item, v ?? false),
      ),
      title: titleWidget,
      onTap: () => onToggle(item, !bought),
      trailing: isEditing
          ? IconButton(
              tooltip: t.cancel,
              icon: const Icon(Icons.close),
              onPressed: onCancelRename,
            )
          : PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'rename':
                    onStartRename(item);
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
    );
  }
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
