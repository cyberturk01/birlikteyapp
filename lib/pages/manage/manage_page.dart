import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../constants/app_templates.dart';
import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/swipe_bg.dart';

enum _ManageTab { tasks, items }

class ManagePage extends StatefulWidget {
  const ManagePage({Key? key}) : super(key: key);

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
    final taskProv = context.watch<TaskProvider>();
    final itemProv = context.watch<ItemProvider>();
    final family = context.watch<FamilyProvider>().familyMembers;
    String? assignTo;

    // --- Hazır listeler ---
    const defaultTasks = AppLists.defaultTasks;

    const defaultItems = AppLists.defaultItems;

    // --- Öneriler (dedupe + alfabetik) ---
    final taskSuggestions = _buildSuggestions(
      frequent: taskProv.suggestedTasks,
      defaults: defaultTasks,
      existing: taskProv.tasks.map((t) => t.name).toList(),
    );
    final itemSuggestions = _buildSuggestions(
      frequent: itemProv.frequentItems,
      defaults: defaultItems,
      existing: itemProv.items.map((i) => i.name).toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Center')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sekme
          Center(
            child: SegmentedButton<_ManageTab>(
              segments: const [
                ButtonSegment(
                  value: _ManageTab.tasks,
                  icon: Icon(Icons.task_alt),
                  label: Text('Tasks'),
                ),
                ButtonSegment(
                  value: _ManageTab.items,
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Market'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
              showSelectedIcon: false,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Giriş satırı (Assign kaldırıldı)
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: _tab == _ManageTab.tasks
                        ? 'Enter task…'
                        : 'Enter item…',
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
            Text('All tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _TaskListView(),
          ] else ...[
            Text('All items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ItemListView(),
          ],
        ],
      ),
    );
  }

  List<String> _buildSuggestions({
    required List<String> frequent,
    required List<String> defaults,
    required List<String> existing,
  }) {
    final set = <String>{};
    for (final s in frequent) {
      final t = s.trim();
      if (t.isNotEmpty) set.add(t);
    }
    for (final s in defaults) {
      final t = s.trim();
      if (t.isNotEmpty) set.add(t);
    }
    for (final s in existing) {
      final t = s.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void _handleAdd(BuildContext context) {
    final taskProv = context.read<TaskProvider>();
    final itemProv = context.read<ItemProvider>();
    final text = _input.text.trim();
    if (text.isEmpty) return;

    if (_tab == _ManageTab.tasks) {
      final dup = taskProv.tasks.any(
        (t) => t.name.toLowerCase() == text.toLowerCase(),
      );
      if (dup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This task already exists')),
        );
        return;
      }
      taskProv.addTask(Task(text));
    } else {
      final dup = itemProv.items.any(
        (i) => i.name.toLowerCase() == text.toLowerCase(),
      );
      if (dup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item already exists')),
        );
        return;
      }
      itemProv.addItem(Item(text));
    }

    _input.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added')));
  }
}

// ================== Alt bileşenler: mevcut listeler ==================

class _TaskListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final tasks = taskProv.tasks;

    if (tasks.isEmpty) {
      return const Text('No tasks yet');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = tasks[i];
        return Dismissible(
          key: ValueKey('task-${t.key ?? t.name}-${t.hashCode}'),
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
              context.read<TaskProvider>().toggleTask(t, !t.completed);
              return false;
            } else {
              final copy = Task(
                t.name,
                completed: t.completed,
                assignedTo: t.assignedTo,
              );
              context.read<TaskProvider>().removeTask(t);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => context.read<TaskProvider>().addTask(copy),
                  ),
                ),
              );
              return true;
            }
          },
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
            leading: Checkbox(
              value: t.completed,
              onChanged: (v) =>
                  context.read<TaskProvider>().toggleTask(t, v ?? false),
            ),
            title: Text(
              t.name,
              overflow: TextOverflow.ellipsis,
              style: t.completed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: (t.assignedTo != null && t.assignedTo!.isNotEmpty)
                ? Text('👤 ${t.assignedTo}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Assign',
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => _showAssignTaskSheet(context, t),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRenameTaskDialog(context, t),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => context.read<TaskProvider>().removeTask(t),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final itemProv = context.watch<ItemProvider>();
    final items = itemProv.items;

    if (items.isEmpty) {
      return const Text('No items yet');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = items[i];
        return Dismissible(
          key: ValueKey('item-${it.key ?? it.name}-${it.hashCode}'),
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
              context.read<ItemProvider>().toggleItem(it, !it.bought);
              return false;
            } else {
              final copy = Item(
                it.name,
                bought: it.bought,
                assignedTo: it.assignedTo,
              );
              context.read<ItemProvider>().removeItem(it);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Item deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => context.read<ItemProvider>().addItem(copy),
                  ),
                ),
              );
              return true;
            }
          },
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
            leading: Checkbox(
              value: it.bought,
              onChanged: (v) =>
                  context.read<ItemProvider>().toggleItem(it, v ?? false),
            ),
            title: Text(
              it.name,
              overflow: TextOverflow.ellipsis,
              style: it.bought
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: (it.assignedTo != null && it.assignedTo!.isNotEmpty)
                ? Text('👤 ${it.assignedTo}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Assign',
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => _showAssignItemSheet(context, it),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRenameItemDialog(context, it),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => context.read<ItemProvider>().removeItem(it),
                ),
              ],
            ),
          ),
        );
      },
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
            context.read<ItemProvider>().renameItem(item, ctrl.text);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<ItemProvider>().renameItem(item, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignItemSheet(BuildContext context, Item item) {
    final family = context.read<FamilyProvider>().familyMembers;
    String? selected = item.assignedTo;

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
            DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('No one')),
                ...family.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m)),
                ),
              ],
              onChanged: (v) => selected = v,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.read<ItemProvider>().updateAssignment(
                    item,
                    (selected != null && selected!.trim().isNotEmpty)
                        ? selected
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
          context.read<TaskProvider>().renameTask(task, ctrl.text);
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () {
            context.read<TaskProvider>().renameTask(task, ctrl.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _applyTemplate(BuildContext context, TemplatePack tpl, String? assignTo) {
  final taskProv = context.read<TaskProvider>();
  final itemProv = context.read<ItemProvider>();

  final createdTasks = taskProv.addTasksBulk(tpl.tasks, assignedTo: assignTo);
  final createdItems = itemProv.addItemsBulk(tpl.items, assignedTo: assignTo);

  final total = createdTasks.length + createdItems.length;

  if (total == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nothing to add (all duplicates?)')),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Added $total from "${tpl.name}"'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          taskProv.removeManyTasks(createdTasks);
          itemProv.removeManyItems(createdItems);
        },
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void _showAssignTaskSheet(BuildContext context, Task task) {
  final family = context.read<FamilyProvider>().familyMembers;
  String? selected = task.assignedTo;

  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Assign task',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('No one')),
              ...family.map((m) => DropdownMenuItem(value: m, child: Text(m))),
            ],
            onChanged: (v) => selected = v,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<TaskProvider>().updateAssignment(
                  task,
                  (selected != null && selected!.trim().isNotEmpty)
                      ? selected
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
