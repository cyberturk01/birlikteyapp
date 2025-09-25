import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/task.dart';
import '../../providers/task_cloud_provider.dart';
import '../../providers/ui_provider.dart';
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
              direction: DismissDirection.horizontal,
              key: ValueKey(
                task.remoteId ??
                    '${task.name}|${task.assignedToUid ?? //
                        ""}',
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
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.startToEnd) {
                  await _handleToggleTask(
                    context,
                    task,
                    withCelebrate: !task.completed,
                  );
                  return false; // tile listeden düşmesin
                } else {
                  final removed = task;
                  context.read<TaskCloudProvider>().removeTask(task);

                  // Undo SnackBar
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // Not: yeniden eklenir (yeni key alır); sıra üstte olur
                          context.read<TaskCloudProvider>().addTask(removed);
                        },
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
                leading: Checkbox(
                  value: isDone,
                  onChanged: (v) async {
                    final willComplete = v == true && !task.completed;
                    await _handleToggleTask(
                      context,
                      task,
                      withCelebrate: v == true,
                    );
                    if (willComplete && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 +10 points'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),

                title: Text(
                  task.name,
                  overflow: TextOverflow.ellipsis,
                  style: isDone
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onTap: () => _handleToggleTask(context, task),
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

// ---- toggle handlers keep auto-switch behavior via UiProvider ----
Future<void> _handleToggleTask(
  BuildContext context,
  Task t, {
  bool withCelebrate = false,
}) async {
  final ui = context.read<UiProvider>();
  final willComplete = !t.completed;

  await context.read<TaskCloudProvider>().toggleTask(t, willComplete);

  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.of(context);
      m.clearSnackBars();
      m.showSnackBar(
        const SnackBar(
          content: Text('🎉 Task completed!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  if (withCelebrate && willComplete) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('➕ +10 points'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  if (willComplete && ui.taskFilter == TaskViewFilter.pending) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.completed);
  } else if (!willComplete && ui.taskFilter == TaskViewFilter.completed) {
    context.read<UiProvider>().setTaskFilter(TaskViewFilter.pending);
  }
}
