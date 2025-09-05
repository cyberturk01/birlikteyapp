import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/task_provider.dart';

enum _ManageTab { tasks, items }

class ManagePage extends StatefulWidget {
  const ManagePage({Key? key}) : super(key: key);

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  _ManageTab _tab = _ManageTab.tasks;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submitTask() {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    context.read<TaskProvider>().addTask(Task(t)); // unassigned
    _textCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _submitItem() {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    context.read<ItemProvider>().addItem(Item(t)); // unassigned
    _textCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final itemProv = context.watch<ItemProvider>();

    final tasks = taskProv.tasks; // tüm görevler
    final items = itemProv.items; // tüm ürünler

    return Scaffold(
      appBar: AppBar(title: const Text('Add Center')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Toggle: Tasks / Market
            SegmentedButton<_ManageTab>(
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
              onSelectionChanged: (s) {
                setState(() {
                  _tab = s.first;
                  _textCtrl.clear();
                });
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),

            // Girdi satırı (sadece metin)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: InputDecoration(
                      hintText: _tab == _ManageTab.tasks
                          ? 'Add a new task…'
                          : 'Add a new item…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _tab == _ManageTab.tasks
                        ? _submitTask()
                        : _submitItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _tab == _ManageTab.tasks
                      ? _submitTask
                      : _submitItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Tam liste
            Expanded(
              child: _tab == _ManageTab.tasks
                  ? _TasksFullList(tasks: tasks)
                  : _ItemsFullList(items: items),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= Tam görev listesi (radio-toggle + delete) =======
class _TasksFullList extends StatelessWidget {
  final List<Task> tasks;
  const _TasksFullList({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = tasks[i];
        final done = t.completed;

        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -2),

          leading: IconButton(
            tooltip: done ? 'Mark as pending' : 'Mark as completed',
            icon: Icon(
              done ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            ),
            onPressed: () => context.read<TaskProvider>().toggleTask(t, !done),
          ),
          title: Text(
            t.name + (t.assignedTo != null ? ' (${t.assignedTo})' : ''),
            overflow: TextOverflow.ellipsis,
            style: done
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          onTap: () => context.read<TaskProvider>().toggleTask(t, !done),

          // ➕ trailing aksiyonlar: Assign • Edit • Delete
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // içerik kadar genişlik
            children: [
              IconButton(
                padding: EdgeInsets.zero, // ikonun tıklama alanını küçült
                constraints:
                    const BoxConstraints(), // default min size’ı kaldır
                tooltip: 'Assign',
                icon: const Icon(Icons.person_add_alt, size: 20),
                onPressed: () => _showAssignTaskSheet(context, t),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showRenameTaskDialog(context, t),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () => context.read<TaskProvider>().removeTask(t),
              ),
            ],
          ),
        );
      },
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
            context.read<TaskProvider>().renameTask(task, ctrl.text);
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
              context.read<TaskProvider>().renameTask(task, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
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
}

// ======= Tam ürün listesi (radio-toggle + delete) =======
class _ItemsFullList extends StatelessWidget {
  final List<Item> items;
  const _ItemsFullList({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = items[i];
        final bought = it.bought;

        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -2),

          leading: IconButton(
            tooltip: bought ? 'Mark as to buy' : 'Mark as bought',
            icon: Icon(
              bought
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onPressed: () =>
                context.read<ItemProvider>().toggleItem(it, !bought),
          ),
          title: Text(
            it.name + (it.assignedTo != null ? ' (${it.assignedTo})' : ''),
            overflow: TextOverflow.ellipsis,
            style: bought
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          onTap: () => context.read<ItemProvider>().toggleItem(it, !bought),

          trailing: Row(
            mainAxisSize: MainAxisSize.min, // içerik kadar genişlik
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Assign',
                icon: const Icon(Icons.person_add_alt, size: 20),
                onPressed: () => _showAssignItemSheet(context, it),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showRenameItemDialog(context, it),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => context.read<ItemProvider>().removeItem(it),
              ),
            ],
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
            child: const Text('Cancel'),
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
