import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/task.dart';
import '../../providers/task_cloud_provider.dart';
import '../../widgets/muted_text.dart';
import '../../widgets/swipe_bg.dart';

class TasksSubsection extends StatelessWidget {
  final List<Task> tasksFiltered;
  final bool expanded;
  final int previewCount;
  final VoidCallback onToggleExpand;
  final void Function(Task) onToggleTask;

  const TasksSubsection({
    super.key,
    required this.tasksFiltered,
    required this.expanded,
    required this.previewCount,
    required this.onToggleExpand,
    required this.onToggleTask,
  });

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
          const MutedText('No tasks')
        else
          ...visible.map((task) {
            final isDone = task.completed;
            return Dismissible(
              direction: DismissDirection.endToStart,
              key: ValueKey(
                task.remoteId ?? '${task.name}|${task.assignedTo ?? ""}',
              ),
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
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  onToggleTask(task);
                  return false;
                } else {
                  final removed = task;
                  context.read<TaskCloudProvider>().removeTask(task);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: const Text('Task deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => context
                              .read<TaskCloudProvider>()
                              .addTask(removed),
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
                  tooltip: S.delete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<TaskCloudProvider>().removeTask(task),
                ),
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
