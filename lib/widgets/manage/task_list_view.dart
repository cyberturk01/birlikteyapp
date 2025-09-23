import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/task.dart';
import '../../providers/task_cloud_provider.dart';
import '../../widgets/swipe_bg.dart';
import '../member_dropdown_uid.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskCloud = context.watch<TaskCloudProvider>();
    final tasks = taskCloud.tasks;

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
              context.read<TaskCloudProvider>().toggleTask(t, !t.completed);
              return false;
            } else {
              final copy = Task(
                t.name,
                completed: t.completed,
                assignedToUid: t.assignedToUid,
              );
              context.read<TaskCloudProvider>().removeTask(t);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
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
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
            leading: Checkbox(
              value: t.completed,
              onChanged: (v) =>
                  context.read<TaskCloudProvider>().toggleTask(t, v ?? false),
            ),
            title: Text(
              t.name,
              overflow: TextOverflow.ellipsis,
              style: t.completed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: (t.assignedToUid != null && t.assignedToUid!.isNotEmpty)
                ? Text('👤 ${t.assignedToUid}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Assign',
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => _showAssignTaskSheetCloud(context, t),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRenameTaskDialogCloud(context, t),
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
  }

  void _showAssignTaskSheetCloud(BuildContext context, Task task) {
    String? selected = task.assignedToUid;
    final taskCloud = context.read<TaskCloudProvider>();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Assign task',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                MemberDropdownUid(
                  value: selected,
                  onChanged: (v) => setLocal(() => selected = v),
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
                        (selected != null && selected!.trim().isNotEmpty)
                            ? selected
                            : null,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRenameTaskDialogCloud(BuildContext context, Task task) {
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
          onSubmitted: (_) async {
            await context.read<TaskCloudProvider>().renameTask(
              task,
              ctrl.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<TaskCloudProvider>().renameTask(
                task,
                ctrl.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
