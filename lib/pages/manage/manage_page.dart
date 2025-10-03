import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';
import '../../providers/task_cloud_provider.dart';
import '../../widgets/member_dropdown_uid.dart';
import '../../widgets/swipe_bg.dart';

enum _ManageTab { tasks, items }

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  _ManageTab _tab = _ManageTab.tasks;
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final famId = context.watch<FamilyProvider>().familyId;
    final tasksLen = context.select<TaskCloudProvider, int>(
      (p) => p.tasks.length,
    );
    final itemsLen = context.select<ItemCloudProvider, int>(
      (p) => p.items.length,
    );
    final t = AppLocalizations.of(context)!;
    debugPrint('[ManagePage] fam=$famId tasks=$tasksLen items=$itemsLen');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.quickAddTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              t.quickAddSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sekme
          Center(
            child: SegmentedButton<_ManageTab>(
              segments: [
                ButtonSegment(
                  value: _ManageTab.tasks,
                  icon: const Icon(Icons.task_alt),
                  label: Text(t.tasks),
                ),
                ButtonSegment(
                  value: _ManageTab.items,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(t.market),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
              showSelectedIcon: false,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: _tab == _ManageTab.tasks
                        ? t.enterTaskHintShort
                        : t.enterItemHintShort,
                    prefixIcon: Icon(
                      _tab == _ManageTab.tasks
                          ? Icons.task_alt
                          : Icons.shopping_bag,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleAdd(context),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _handleAdd(context),
                icon: const Icon(Icons.add),
                label: const Text(S.add),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mevcut kayıtlar — ayrı bölüm
          if (_tab == _ManageTab.tasks) ...[
            Text(
              t.allTasksHeader,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _TaskListView(),
          ] else ...[
            Text(
              t.allItemsHeader,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ItemListView(),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context) async {
    final taskProv = context.read<TaskCloudProvider>();
    final itemProv = context.read<ItemCloudProvider>();
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final t = AppLocalizations.of(context)!;

    String what = _tab == _ManageTab.tasks
        ? t.taskAddedToast
        : t.itemAddedToast;

    if (_tab == _ManageTab.tasks) {
      final dup = taskProv.tasks.any(
        (t) => t.name.toLowerCase() == text.toLowerCase(),
      );
      if (dup) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.taskAlreadyExists),
          ),
        );
        return;
      }
      await taskProv.addTask(Task(text));
    } else {
      final dup = itemProv.items.any(
        (i) => i.name.toLowerCase() == text.toLowerCase(),
      );
      if (dup) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.itemAlreadyExists),
          ),
        );
        return;
      }
      await itemProv.addItem(Item(text));
    }

    _input.clear();
    FocusScope.of(context).unfocus();

    // 🎉 minik haptic + “başarılı” snackbar (tasks ve items için aynı)
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 8),
            Text('$what added'),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }
}

// ================== Alt bileşenler: mevcut listeler ==================

class _TaskListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskCloudProvider>();
    final tasks = taskProv.tasks;
    final t = AppLocalizations.of(context)!;
    if (tasks.isEmpty) {
      return Text(t.noTasks);
    }
    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();
    return StreamBuilder<Map<String, String>>(
      stream: dictStream, // { uid: label }
      builder: (_, snap) {
        final dict = snap.data ?? const <String, String>{};
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          cacheExtent: 800,
          itemBuilder: (_, i) {
            final t = tasks[i];

            final uid = t.assignedToUid; // <- UID
            final display = (uid == null || uid.isEmpty)
                ? null
                : (dict[uid] ?? 'Member');

            return Dismissible(
              key: ValueKey('task-${t.remoteId ?? t.name}-${t.hashCode}'),
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
                  context.read<TaskCloudProvider>().toggleTask(t, !t.completed);
                  return false;
                } else {
                  final copy = Task(
                    t.name,
                    completed: t.completed,
                    assignedToUid: t.assignedToUid,
                  );
                  await context.read<TaskCloudProvider>().removeTask(t);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.taskDeleted),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        onPressed: () =>
                            context.read<TaskCloudProvider>().addTask(copy),
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
                leading: Checkbox(
                  value: t.completed,
                  onChanged: (v) async {
                    await context.read<TaskCloudProvider>().toggleTask(
                      t,
                      v ?? false,
                    );
                    if (v == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Great job! Task completed!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                title: Text(
                  t.name,
                  overflow: TextOverflow.ellipsis,
                  style: t.completed
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: display == null ? null : Text('👤 $display'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: AppLocalizations.of(context)!.assign,
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: () => _showAssignTaskSheet(context, t),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: AppLocalizations.of(context)!.edit,
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showRenameDialog(
                        context: context,
                        initial: t.name,
                        hint: AppLocalizations.of(context)!.taskName,
                        onSave: (newName) => context
                            .read<TaskCloudProvider>()
                            .renameTask(t, newName),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: S.delete,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          context.read<TaskCloudProvider>().removeTask(t),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ItemListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final itemProv = context.watch<ItemCloudProvider>();
    final items = itemProv.items;
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Text(t.noItems);
    }

    final dictStream = context.read<FamilyProvider>().watchMemberDirectory();

    return StreamBuilder<Map<String, String>>(
      stream: dictStream,
      builder: (_, snap) {
        final dict = snap.data ?? const <String, String>{};

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          cacheExtent: 800,
          itemBuilder: (_, i) {
            final it = items[i];

            final uid = it.assignedToUid; // <- UID
            final display = (uid == null || uid.isEmpty)
                ? null
                : (dict[uid] ?? 'Member');

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
                  await context.read<ItemCloudProvider>().toggleItem(
                    it,
                    !it.bought,
                  );
                  return false;
                } else {
                  final copy = Item(
                    it.name,
                    bought: it.bought,
                    assignedToUid: it.assignedToUid,
                  );
                  await context.read<ItemCloudProvider>().removeItem(it);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.itemDeleted),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        onPressed: () =>
                            context.read<ItemCloudProvider>().addItem(copy),
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
                leading: Checkbox(
                  value: it.bought,
                  onChanged: (v) async {
                    await context.read<ItemCloudProvider>().toggleItem(
                      it,
                      v ?? false,
                    );
                    if (v == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🛒 Item purchased! Well done!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                title: Text(
                  it.name,
                  overflow: TextOverflow.ellipsis,
                  style: it.bought
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: display == null ? null : Text('👤 $display'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: t.assign,
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: () => _showAssignItemSheet(context, it),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: t.edit,
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showRenameDialog(
                        context: context,
                        initial: it.name,
                        hint: t.itemName,
                        onSave: (newName) => context
                            .read<ItemCloudProvider>()
                            .renameItem(it, newName),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: S.delete,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          context.read<ItemCloudProvider>().removeItem(it),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _showRenameDialog({
  required BuildContext context,
  required String initial,
  required String hint,
  required Future<void> Function(String newName) onSave,
}) async {
  final ctrl = TextEditingController(text: initial);
  final t = AppLocalizations.of(context)!;
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t.editNameTitle),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hint,
          isDense: true,
        ),
        onSubmitted: (_) async {
          await onSave(ctrl.text.trim());
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () async {
            await onSave(ctrl.text.trim());
            Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );
}

// ITEM
void _showAssignItemSheet(BuildContext context, Item item) {
  String? selectedUid = item.assignedToUid; // mevcut atamayı UID olarak başlat

  final t = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.assignItem,
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
                    await context.read<ItemCloudProvider>().updateAssignment(
                      item,
                      (selectedUid != null && selectedUid!.trim().isNotEmpty)
                          ? selectedUid
                          : null,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(t.save),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// TASK
void _showAssignTaskSheet(BuildContext context, Task task) {
  String? selectedUid = task.assignedToUid; // mevcut atamayı UID olarak başlat
  final taskCloud = context.read<TaskCloudProvider>();
  final t = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
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
                    // await taskCloud.refreshNow();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(t.save),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
